import os
import re
from random import randint


def width_expr(v: int, w: int) -> str:
    if v > 0:
        return f"[{v:<{w}} : 0]"
    else:
        return " "*w


def read_nonneg_int_list(filepath):
    numbers = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for lineno, line in enumerate(f, start=1):
            line = line.strip()
            if not line:      # skip the vacant line
                continue
            try:
                num = int(line)
            except ValueError:
                raise ValueError(f"line {lineno} is not an integer: {line}")
            if num < 0:
                raise ValueError(f"line {lineno} is not a non-negative integer: {line}")
            numbers.append(num)
    return numbers


def gen_bitheap_testvectors(number_list: list, test_size: int=1000, col_names: list[str] | None = None) -> None:
    folder = "testvectors"
    os.makedirs(folder, exist_ok=True)
    testvectors = []
    number_of_columns = len(number_list)
    if col_names is None:
        col_names = [f"in_col{col}" for col in range(number_of_columns)]
    for col in range(number_of_columns):
        col_vector = []
        for i in range(test_size):
            col_vector.append(randint(0, 2**number_list[col]-1))
        testvectors.append(col_vector)
        file_path = os.path.join(folder, f"{col_names[col]}.txt")
        with open(file_path, "w", encoding="utf-8") as f:
            for v in col_vector:
                v_str = format(v, 'x')
                f.write(f"{v_str}\n")
    comp_out_list = []
    for i in range(test_size):
        comp_out = 0
        for col in range(number_of_columns):
            comp_out += testvectors[col][i].bit_count() * (2**col)
        comp_out_list.append(comp_out)
    file_path = os.path.join(folder, "comp_out.txt")
    with open(file_path, "w", encoding="utf-8") as f:
        for v in comp_out_list:
            v_str = format(v, 'x')
            f.write(f"{v_str}\n")



def to_twos_complement_hex(x, n_bits):
    if x < 0:
        x = (1 << n_bits) + x
    hex_width = (n_bits + 3) // 4
    return f"{x:0{hex_width}X}"



def tb_settle_delay(latency: int) -> int:
    """Nanoseconds a generated testbench waits after `latency` clock periods
    before sampling the DUT.

    The driver assigns vector i at `#1` after its posedge; a registered DUT
    (latency >= 1) is sampled `#1` after the posedge `latency` cycles later,
    where its outputs have been stable for a full cycle. A combinational DUT
    (latency 0) is sampled the same cycle the vector is driven: `#1` there
    would race the driver's own `#1` assignment, and which of the two initial
    blocks runs first at that timestamp is not defined. `#2` puts the sample
    strictly after the drive; the zero-delay logic has settled by then."""
    return 1 if latency > 0 else 2


def rtl_static_issues(sv: str) -> list[str]:
    """Static sanity of generated SystemVerilog, per module: a scalar `logic`
    that some expression indexes, a `layer<n>_col<m>` / terminal signal used
    but never declared, and a part-select or bit-select past a signal's
    declared width. Each is something xsim refuses or, worse, reads as X
    (the compressor campaigns of Sept 2026 found one of each). Returns one
    line per issue, empty when clean."""
    issues: list[str] = []
    for m in re.finditer(r'\bmodule\s+(\w+).*?\bendmodule', sv, re.S):
        mod, body = m.group(1), m.group(0)
        widths: dict[str, int | None] = {}
        for dm in re.finditer(r'^\s*(?:input|output)?\s*logic\s*(?:signed\s+)?(?:\[\s*(\d+)\s*:\s*0\s*\])?\s*(\w+)\s*[;,)]', body, re.M):
            widths[dm.group(2)] = int(dm.group(1)) + 1 if dm.group(1) else None
        for dm in re.finditer(r'(?:input|output)\s+logic\s*(?:signed\s+)?(?:\[\s*(\d+)\s*:\s*0\s*\])?\s*(\w+)', body):
            widths.setdefault(dm.group(2), int(dm.group(1)) + 1 if dm.group(1) else None)
        for um in re.finditer(r'\b(\w+)\s*\[\s*(\d+)\s*(?::\s*(\d+))?\s*\]', body):
            name, hi = um.group(1), int(um.group(2))
            if name not in widths:
                if re.match(r'layer\d+_col\d+$|terminal_\w+', name):
                    issues.append(f"{mod}: {name} used but never declared")
                continue
            w = widths[name]
            if w is None:
                issues.append(f"{mod}: scalar {name} indexed [{um.group(2)}]")
            elif hi >= w:
                issues.append(f"{mod}: {name}[{um.group(2)}{':' + um.group(3) if um.group(3) else ''}] past its declared width {w}")
        for name in set(re.findall(r'\b(layer\d+_col\d+)\b', body)):
            if name not in widths:
                issues.append(f"{mod}: {name} used but never declared")
    return sorted(set(issues))


_PART_ASSIGN = re.compile(r"^\s*assign\s+(\w+)\s*\[\s*(\d+)\s*(?::\s*(\d+)\s*)?\]\s*=\s*(.+?)\s*;\s*$")
_VECTOR_DECL = re.compile(r"\blogic\s*\[\s*(\d+)\s*:\s*0\s*\]\s*(\w+)\s*;")


def merge_bit_assigns(rtl: str) -> str:
    """Write each vector driven wholly by per-bit or part-select assigns as one assign.

    Vivado 2025.1 xelab raises false multiple-driver errors (VRFC 10-10007) on
    per-bit assigns, naming an unrelated assign as the other driver; which ones
    depends on the design, the source paths and the run folder, even with one
    driver per bit in the source. A vector with no per-bit assigns cannot draw it.
    A vector with any bit driven some other way is left as it is.
    """
    widths = {m[2]: int(m[1]) + 1 for m in _VECTOR_DECL.finditer(rtl)}
    lines = rtl.split("\n")
    parts: dict[str, list[tuple[int, int, int, str]]] = {}
    for idx, line in enumerate(lines):
        m = _PART_ASSIGN.match(line)
        if m and m[1] in widths:
            hi = int(m[2])
            lo = int(m[3]) if m[3] is not None else hi
            parts.setdefault(m[1], []).append((lo, hi, idx, m[4]))
    for name, pieces in parts.items():
        pieces.sort()
        covered = 0
        for lo, hi, _, _ in pieces:
            if lo != covered:
                break
            covered = hi + 1
        if covered != widths[name]:
            continue
        rhs = [p[3] for p in pieces]
        whole = [re.fullmatch(rf"(\w+)\[{p[0]}\]", r) if p[0] == p[1] else None
                 for p, r in zip(pieces, rhs)]
        if (all(whole) and len({w[1] for w in whole}) == 1
                and widths.get(whole[0][1]) == widths[name]):
            value = whole[0][1]
        elif len(rhs) == 1:
            value = rhs[0]
        else:
            value = "{" + ", ".join(reversed(rhs)) + "}"
        first = min(p[2] for p in pieces)
        for p in pieces:
            lines[p[2]] = None
        lines[first] = f"    assign {name} = {value};"
    return "\n".join(line for line in lines if line is not None)


# A chain of one LOOKAHEAD8 assigns its CIN a single heap bit; a longer chain (after
# merge_bit_assigns) assigns a concatenation {COUT_LA..., ..., C0_...[n]} whose last
# element is the chain start. Both forms must be found.
_CHAIN_CIN_ASSIGN = re.compile(r"assign\s+CIN_LA_\w+(?:\s*\[\s*\d+\s*\])?\s*=\s*([^;]+);")
_CHAIN_CIN_BIT = re.compile(r"\b(C\d+_\w+_l0_\w+)\s*\[\s*\d+\s*\]")


def pin_chain_cin_nets(rtl: str) -> str:
    """Mark DONT_TOUCH each first-layer GPC input vector that feeds a chain's CIN.

    A chain's first LOOKAHEAD8 reads its CIN from the same heap bit as its first
    LUT's I4, and place_design builds the CARRY shape only while both pins are on
    one net ("Failed to create CARRY shape ... no available pin to assign the
    net"). A first-layer bit is a module input; when it comes from a register
    with max_fanout outside, synthesis flattens the hierarchy and can hand the
    I4 and the CIN to different replicas (A4096_q64wlm_P4b, Nov 2026: 1 of 2924
    chain starts; MS_N10_q32_P32_tpm60, 1 of 14176, in a chain of two LOOKAHEAD8s
    that the first version of this function did not match). DONT_TOUCH on the
    GPC's input vector keeps that net whole.
    Later layers are driven inside the module and are left alone; so is the
    rest of the heap, which DONT_TOUCH would cost LUTs on (all first-layer
    vectors: +4.5 % LUTs on that design, these alone: +0.2 %, no FF change).
    """
    names = set()
    for rhs in _CHAIN_CIN_ASSIGN.findall(rtl):
        names.update(_CHAIN_CIN_BIT.findall(rhs))
    for name in sorted(names):
        rtl, n = re.subn(rf"^(\s*)logic(\s*\[[^\]]+\]\s*{name}\s*;)",
                         r'\1(* dont_touch = "true" *) logic\2', rtl, count=1, flags=re.M)
        if n != 1:
            raise ValueError(f"pin_chain_cin_nets: no vector declaration of {name}")
    return rtl
