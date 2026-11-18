'''Resources of the generated RAMs, shared by the iterative and the hybrid NTT.

    MEM_STYLES        the memory styles a scheme may ask for
    ramCost           LUT, FF, block RAM and UltraRAM of one simple dual-port RAM
    lutramGroupLuts   LUTs of LUTRAM banks that share their addresses
'''

#: memory styles of the generated RAMs, and how the model prices them
MEM_STYLES = ('auto', 'atp', 'distributed', 'block', 'ultra')


def lutramGroupLuts(width: int, banks: int) -> int:
    '''LUTs of `banks` simple dual-port LUTRAMs, 33 to 64 deep, that share their addresses. Each bank fills
    width // 7 primitives of 7 bits (RAM64M8, 8 LUTs). The r = width % 7 bits left per bank are merged over the
    banks, whole banks only: min(banks, 7 // r) banks per primitive. A primitive of 1 bit takes 2 LUTs (RAM64X1D),
    of 2 or 3 bits 4 LUTs (RAM64M), of 4 to 7 bits 8 LUTs (RAM64M8). Routed: 36 bit in groups of 8 (one RAM64M8 and
    one RAM64X1D per group) and of 2 (one RAM64M); 30, 44, 52 bit in pairs (one RAM64M8); 60 bit not merged.'''
    prim = lambda bits: 0 if bits <= 0 else 2 if bits == 1 else 4 if bits <= 3 else 8
    r = width % 7
    lut = banks * (width // 7) * 8
    if r:
        k = min(banks, 7 // r)
        lut += banks // k * prim(k * r) + prim(banks % k * r)
    return lut


def ramCost(depth: int, width: int, style: str) -> dict:
    '''Estimated resources of one simple-dual-port RAM (1 write, 1 registered read port):
    {'lut', 'ff', 'bram', 'uram'} (BRAM in 36 Kb blocks, halves allowed). 'auto':
    LUTRAM up to 64 deep, else block RAM, or UltraRAM where it takes fewer BRAM36
    equivalents (one URAM = 8). 'atp': the cheapest by AutoNTT's area weights
    (kLUT = BRAM36 = URAM / 8), which favours LUTRAM up to about 1K deep.'''
    if style == 'atp':
        cands = [ramCost(depth, width, s) for s in ('distributed', 'block', 'ultra')]
        return min(cands, key=lambda c: c['lut'] / 1000 + c['bram'] + 8 * c['uram'])
    if style == 'auto':
        if depth <= 64:
            return ramCost(depth, width, 'distributed')
        bl, ul = ramCost(depth, width, 'block'), ramCost(depth, width, 'ultra')
        return ul if 8 * ul['uram'] < bl['bram'] else bl
    if style == 'distributed':
        # SDP LUTRAM: 64 deep x 7 bits per 8 LUTs (RAM64M8), a mux tree over the 64-deep slices
        sl = -(-depth // 64)
        lut = sl * -(-width // 7) * 8 + (width * (sl - 1) + 2) // 3
        # more than one 64-deep slice: the tool puts the first read register at every slice output, before
        # the slice mux (routed, 256 x 60: 240 'r1_reg_pipe' + 60 'r2' registers per RAM)
        return {'style': 'distributed', 'lut': lut, 'ff': (sl + 1) * width, 'bram': 0, 'uram': 0}
    if style == 'block':
        # 18 Kb halves: 512x36, 1Kx18, 2Kx9, 4Kx4, 8Kx2, 16Kx1; or a whole 36 Kb at 512x72.
        # The memory is built for the whole address range, 2^(address bits) words (routed: a 3072 x 36 ROM
        # with a 12-bit address takes 4 RAMB36, not 3)
        depth = 1 << max(0, (depth - 1).bit_length())
        best = None
        for d, w in ((512, 36), (1024, 18), (2048, 9), (4096, 4), (8192, 2), (16384, 1)):
            h = -(-depth // d) * -(-width // w)
            best = h if best is None else min(best, h)
        best = min(best, 2 * -(-depth // 512) * -(-width // 72))
        return {'style': 'block', 'lut': 0, 'ff': 0, 'bram': best / 2, 'uram': 0}
    if style == 'ultra':
        return {'style': 'ultra', 'lut': 0, 'ff': 0, 'bram': 0, 'uram': -(-depth // 4096) * -(-width // 72)}
    raise ValueError(f'memory style {style!r}: one of {MEM_STYLES}')
