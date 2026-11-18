"""Push inverted and constant heap bits into the GPCs' LUT contents.

A butterfly's bit heap holds source bits, inverted source bits and constant
ones. Written as `~aIn[5]` and `1'b1` on the heap's input wires, they leave it
to the tools to absorb them into the LUTs, which also have to see through the
primitive-level structure of the GPCs to do it. Instead the wrapper connects
the plain source bit, or a tied 0 for a constant, and each GPC input that reads
such a bit takes it through its `C<k>_INV` mask, which rewrites the LUT's truth
table at elaboration. A constant one is an inverted tied 0, so the two cases
are one mechanism.

This pass runs on a compressor's emitted text, so it sees exactly the wires the
chain, floating-GPC and terminal generators wrote, whichever of them wrote them.
Bits are followed from layer 0 through pass-through assigns and registers:

    a GPC input        takes the mask, except on a LUT6CY's I4 pin
    a pass-through     carries the kind on to the next layer; a register on a
                       constant is dropped, since a constant needs no delay
    anything else      (LOOKAHEAD8 CIN, comp_out, a behavioural adder operand)
                       gets the true value spelled out, `~wire` or a literal

A LUT6CY's I4 cannot read inverted through its INIT: PROP looks up INIT[15:0]
whatever I4 is, while O51 and O52 depend on it, so no truth table gives both. A
GPC adds its same-weight inputs, so a pushed bit on an I4 pin swaps with a plain
bit of the same port. Only when the port has no plain bit to give does that pin
get the true value spelled out, which is why tied-1 and `~wire` can still appear.

A chain's first LUT shares its I4 net with the LOOKAHEAD8's CIN, and the placer
needs them on one net ("Could not do net assignment on LUT"). A CIN that read the
bit which left the pin therefore follows the pin, keeping the two the same net.
"""
from __future__ import annotations

import re
from functools import lru_cache
from pathlib import Path

PLAIN, INVERTED, ZERO, ONE = "w", "n", "0", "1"

_DECL = re.compile(r"\blogic\s*(?:\[\s*(\d+)\s*:\s*0\s*\])?\s*(\w+)\s*;")
_PORT = re.compile(r"\b(?:input|output)\s+logic\s*(?:\[\s*(\d+)\s*:\s*0\s*\])?\s*(\w+)\s*[,)\n]")
_ASSIGN = re.compile(r"^(\s*)assign\s+(\w+(?:\s*\[[^\]]*\])?)\s*=\s*(.+?)\s*;\s*$")
_REG = re.compile(r"^(\s*)(\w+(?:\s*\[[^\]]*\])?)\s*<=\s*(.+?)\s*;\s*$")
_INST = re.compile(r"\b(c\d+_\d+)\s*#\((.*?)\)\s*(\w+)\s*\((.*?)\);", re.S)
_CONN = re.compile(r"\.(\w+)\s*\(\s*(\w+)\s*\)")
_TERM = re.compile(r"^(\w+)\s*(?:\[\s*(\d+)\s*(?::\s*(\d+)\s*)?\])?$")
_PASS = re.compile(r"layer\d+_col\d+$")


@lru_cache(maxsize=1)
def lut6cy_i4_pins() -> dict[str, set[tuple[str, int | None]]]:
    """Per GPC module, its (port, index) inputs that reach a LUT6CY's I4 pin."""
    rtl_dir = Path(__file__).resolve().parent.parent / "rtl"
    pins: dict[str, set] = {}
    for path in sorted(rtl_dir.glob("c*.sv")):
        found = set()
        for body in re.findall(r"LUT6CY\s*#\(.*?\)\s*\w+\s*\((.*?)\);", path.read_text(), re.S):
            m = re.search(r"\.I4\s*\(\s*(C\d)(?:\[(\d+)\])?\s*\)", body)
            if m:
                found.add((m[1], int(m[2]) if m[2] is not None else None))
        pins[path.stem] = found
    return pins


def _bits(expr: str, widths: dict) -> list | None:
    """The bits of `expr`, LSB first, as (name, index) or literals; None when
    the expression is not a plain wire, part-select, literal or concatenation
    (a behavioural expression the pass does not need to look inside)."""
    expr = expr.strip()
    if expr.startswith("{"):
        if not expr.endswith("}"):
            return None
        out: list = []
        for part in reversed(expr[1:-1].split(",")):
            bits = _bits(part, widths)
            if bits is None:
                return None
            out += bits
        return out
    # Literals, and a `~wire` this pass spelled out: true values, carrying no kind.
    if re.fullmatch(r"1'b[01]|~\w+(\[\d+\])?", expr):
        return [expr]
    m = _TERM.match(expr)
    if not m or m[1] not in widths:
        return None
    name = m[1]
    if m[2] is None:
        width = widths[name]
        return [(name, None)] if width is None else [(name, i) for i in range(width)]
    if m[3] is None:
        return [(name, int(m[2]))]
    return [(name, i) for i in range(int(m[3]), int(m[2]) + 1)]


def _literal_or_wire(bit, kind: str) -> str:
    if kind == ONE:
        return "1'b1"
    if kind == ZERO:
        return "1'b0"
    if isinstance(bit, str):
        return bit
    text = bit[0] if bit[1] is None else f"{bit[0]}[{bit[1]}]"
    return f"~{text}" if kind == INVERTED else text


def _statements(lines: list[str], widths: dict) -> list:
    out = []
    for idx, line in enumerate(lines):
        m = _ASSIGN.match(line) or _REG.match(line)
        if m:
            out.append((idx, m, _bits(m[2], widths), _bits(m[3], widths), "<=" in line))
    return out


def _clear_i4_pins(lines: list[str], statements: list, instances: list, widths: dict,
                   kinds: dict, stats: dict) -> tuple[list[str], dict, list]:
    """Leave no inverted or constant bit on a LUT6CY I4 pin (module docstring).
    The ports involved are rewritten bit by bit; other statements keep their
    line numbers. Returns the new lines, what a consumer of a moved bit must read
    instead, and declarations for the inverter nets this adds."""
    drivers: dict = {}
    follow: dict = {}
    decls: list[tuple[str, str]] = []
    for idx, _, lhs, rhs, is_reg in statements:
        if lhs is None or rhs is None or is_reg or len(lhs) != len(rhs):
            continue
        for dst, src in zip(lhs, rhs):
            if isinstance(dst, tuple):
                drivers[dst] = (src, idx)
    pins = lut6cy_i4_pins()
    for m in instances:
        forbidden = pins.get(m[1], set())
        ports = {p: w for p, w in _CONN.findall(m[4]) if re.fullmatch(r"C\d", p)}
        for port, wire in ports.items():
            width = widths[wire]
            bit_keys = [(wire, None)] if width is None else [(wire, i) for i in range(width)]
            locked = [k for k in bit_keys if (port, k[1]) in forbidden]
            if not any(kinds.get(k) for k in locked):
                continue
            free = [k for k in bit_keys if k not in locked and not kinds.get(k)
                    and isinstance(drivers.get(k, (None,))[0], tuple)
                    and _PASS.match(drivers[k][0][0])]
            touched = {drivers[k][1] for k in bit_keys if k in drivers}
            for key in locked:
                if not kinds.get(key):
                    continue
                if free:
                    # Same-weight inputs of one adder: swap which bit reads which pin.
                    other = free.pop()
                    a, b = drivers[key], drivers[other]
                    drivers[key], drivers[other] = (b[0], b[1]), (a[0], a[1])
                    kinds[other] = kinds.pop(key)
                    follow[a[0]] = b[0]
                    stats["i4_swaps"] += 1
                else:
                    src, idx = drivers[key]
                    kind = kinds.pop(key)
                    value = _literal_or_wire(src, kind)
                    if kind == INVERTED:
                        net = f"pushed_inv_{stats['spelled_out']}"
                        decls.append((net, value))
                        value = net
                    drivers[key] = (value, idx)
                    follow[src] = value
                    stats["spelled_out"] += 1
            # Replace the port's assign statements with one line per bit.
            first = min(touched)
            new = []
            for key in bit_keys:
                src = drivers[key][0]
                text = src if isinstance(src, str) else _literal_or_wire(src, PLAIN)
                new.append(f"    assign {_literal_or_wire(key, PLAIN)} = {text};")
            for idx in touched:
                lines[idx] = ""
            lines[first] = "\n".join(new)
    return "\n".join(lines).split("\n"), follow, decls


def push_polarity(rtl: str, input_kinds: dict[int, list[str]]) -> tuple[str, dict]:
    """Rewrite one compressor's text. `input_kinds[col][i]` is the kind of bit i
    of heap column `col` as it arrives on the layer-0 input."""
    widths = {m[2]: (int(m[1]) + 1 if m[1] is not None else None) for m in _DECL.finditer(rtl)}
    widths.update({m[2]: (int(m[1]) + 1 if m[1] is not None else None) for m in _PORT.finditer(rtl)})
    kinds: dict = {}
    for col, col_kinds in input_kinds.items():
        name = f"layer0_col{col}"
        if name not in widths:
            raise ValueError(f"{name} is in the descriptor but not in the compressor")
        for i, kind in enumerate(col_kinds):
            if kind != PLAIN:
                kinds[(name, None if widths[name] is None else i)] = kind

    instances = []
    sinks: dict = {}
    for m in _INST.finditer(rtl):
        ports = {port: wire for port, wire in _CONN.findall(m[4]) if re.fullmatch(r"C\d", port)}
        instances.append(m)
        for port, wire in ports.items():
            if wire in sinks:
                raise ValueError(f"{wire} drives two GPC inputs")
            sinks[wire] = (m[3], port)

    lines = rtl.split("\n")
    statements = _statements(lines, widths)

    # Kinds only move forward through the layers, but statements are not all in
    # layer order, so repeat until nothing changes.
    changed = True
    while changed:
        changed = False
        for _, _, lhs, rhs, _ in statements:
            if lhs is None or rhs is None or len(lhs) != len(rhs):
                continue
            for dst, src in zip(lhs, rhs):
                if not isinstance(dst, tuple) or not isinstance(src, tuple):
                    continue
                if not (_PASS.match(dst[0]) or dst[0] in sinks):
                    continue
                kind = kinds.get(src)
                if kind is not None and kinds.get(dst) != kind:
                    kinds[dst] = kind
                    changed = True

    stats = {"masked_inputs": 0, "spelled_out": 0, "registers_dropped": 0, "i4_swaps": 0}
    lines, follow, inverter_decls = _clear_i4_pins(lines, statements, instances, widths, kinds, stats)
    for net, _ in inverter_decls:
        widths[net] = None
    statements = _statements(lines, widths)
    for idx, m, lhs, rhs, is_reg in statements:
        if rhs is None:
            # A behavioural expression may only read wires holding true values.
            used = {w for w in re.findall(r"\b\w+\b", m[3])}
            if any(key[0] in used for key in kinds):
                raise ValueError(f"cannot see through: {lines[idx].strip()}")
            continue
        if lhs is None or len(lhs) != len(rhs):
            if any(kinds.get(b) for b in rhs if isinstance(b, tuple)):
                raise ValueError(f"width mismatch carrying a pushed bit: {lines[idx].strip()}")
            continue
        passes = all(isinstance(d, tuple) and (_PASS.match(d[0]) or d[0] in sinks) for d in lhs)
        if passes:
            if is_reg:
                # Registered constants need no flop: a tied wire is the same value.
                kept = []
                for dst, src in zip(lhs, rhs):
                    if kinds.get(src) in (ZERO, ONE):
                        stats["registers_dropped"] += 1
                        lines.append(f"    assign {_literal_or_wire(dst, PLAIN)} = 1'b0;")
                    else:
                        kept.append(f"{m[1]}{_literal_or_wire(dst, PLAIN)} <= {_literal_or_wire(src, PLAIN)};")
                if len(kept) != len(lhs):
                    lines[idx] = "\n".join(kept)
            continue
        moved = [follow.get(b, b) if isinstance(b, tuple) else b for b in rhs]
        if moved == rhs and not any(isinstance(b, tuple) and kinds.get(b) for b in rhs):
            continue
        stats["spelled_out"] += sum(1 for b in moved if isinstance(b, tuple) and kinds.get(b))
        spelled = [_literal_or_wire(b, kinds.get(b, PLAIN) if isinstance(b, tuple) else PLAIN)
                   for b in moved]
        value = spelled[0] if len(spelled) == 1 else "{" + ", ".join(reversed(spelled)) + "}"
        op = "<=" if is_reg else "="
        prefix = "" if is_reg else "assign "
        lines[idx] = f"{m[1]}{prefix}{m[2]} {op} {value};"

    # Inverter nets are read by assigns anywhere in the body, so declare them
    # first; their sources are declared later, so drive them last.
    first_decl = next(i for i, line in enumerate(lines) if _DECL.search(line))
    lines[first_decl:first_decl] = [f"    logic {net};" for net, _ in inverter_decls]
    lines += [f"    assign {net} = {value};" for net, value in inverter_decls]
    out = "\n".join(lines)

    def with_masks(m: re.Match) -> str:
        ports = {port: wire for port, wire in _CONN.findall(m[4]) if re.fullmatch(r"C\d", port)}
        masks = []
        for port, wire in ports.items():
            width = widths[wire]
            bits = [(wire, None)] if width is None else [(wire, i) for i in range(width)]
            value = sum(1 << i for i, b in enumerate(bits) if kinds.get(b) in (INVERTED, ONE))
            stats["masked_inputs"] += bin(value).count("1")
            if value:
                masks.append(f".{port}_INV({len(bits)}'h{value:x})")
        if not masks:
            return m[0]
        return f"{m[1]} #({', '.join(masks)},\n            {m[2].strip()}) {m[3]}({m[4]});"

    return _INST.sub(with_masks, out), stats
