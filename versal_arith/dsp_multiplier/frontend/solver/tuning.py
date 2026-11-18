# solver/tuning.py
"""Every knob that trades off search speed against solution quality in the
frontend (tiling + Karatsuba search), gathered in one place instead of
scattered across solve.py / tiling_search.py.

These are the values worth sweeping if a search run is too slow, or if
it's leaving DSP/LUT on the table -- as opposed to constants elsewhere
that are geometric facts about a specific tile (K2_CELLS, _LARGE_MAX_EXT
in tiling_search.py) or physical hardware characteristics
(CHAIN_BASE_LATENCY, PCIN_PITCH, ... in seed_tiles.py),
neither of which make sense to tune independently of what they describe.

Note: SPLIT_FLOOR and LARGE_FLOOR happen to share the same value (23*23)
and the same underlying rationale -- "the smallest board that can hold one
DSP58" -- but are kept as two separate constants here since they gate two
different decisions (whether to attempt a Karatsuba split at all, vs.
whether an off-board large tile still covers enough cells to be worth
it); nothing currently forces them to move together.
"""
from __future__ import annotations

import os

# ==================== solve.py: top-level beam search ====================

BEAM = 1
# Each sub-problem ultimately keeps only the BEAM cheapest solutions.

GREEDY_PREFILTER = 5
# Phase A: after a coarse area-based ranking, how many tilings go on to
# exact costing (folds in what used to be TILINGS_PER_NODE).

TILING_MAX_NODES = 200_000
# DFS node cap for a single sub-board -- this is the real throttle on
# runtime.

SPLIT_FLOOR = 529   # 23*23 = 529
# The area floor for attempting a Karatsuba split at all: if the short
# side squared can't even fit one DSP, cutting further only adds merge
# overhead -- better to hand the whole thing straight to tiling+bmult.

# ==================== tiling_search.py: the three-phase tiling search ====================

T_COARSE = 5
# free/K2_CELLS >= T_COARSE -> coarse phase (whole rows);
# free/K2_CELLS <  T_COARSE -> fine phase (single blocks).

DENSITY_M1 = 0.75
# mode1 threshold: past this density, fill a chain directly and take the
# solution outright (no branching).

LARGE_MIN_DSP = 3
# The large-tile phase only considers tiles with at least this many DSPs
# (k2 and up); smaller ones are left for the chain-fill phase instead.

LARGE_FLOOR = 529
# Once a large tile goes off-board, the minimum cells each DSP it uses
# must still cover, or the overhang isn't worth it.

FILL_FLOOR = 50
# Once a DSP58/chain goes off-board during the fill phase, the minimum
# cells each DSP must still cover.

SMALL_MULT_MAX = 5
# At or below this external width a LUT rectangle is a behavioural small
# multiplier, not a Booth one. `lut_cost.estimate_bmult_luts` agrees.

MERGE_PARTIAL_PRODUCTS = os.environ.get("DSP_MERGE_PARTIAL_PRODUCTS", "1") != "0"
# A Booth rectangle whose product one heap reads once puts its partial products
# in that heap instead of resolving them through its own compressor and terminal
# adder (`lowering.merge_partial_products`, THEORY.md section 10). The variable
# exists to build the old form for comparison.

PP_ALIGN_LUTS_PER_BIT = 0.7
# LUTs per operand bit a merged rectangle costs in alignment beside a DSP tile.
# The latency is not known during the search, so this is one number: measured 55
# SRL LUTs on the 82 operand bits of a 64x18 rectangle beside a Toom tile.

PP_ALIGN_MIN_TILE_DSPS = 3
# ... charged beside a tile of at least this many DSPs.

PP_LATENCY = int(os.environ.get("DSP_PP_LATENCY", "1"))
# Register stages on a merged rectangle's partial products, 0 or 1. With 0 they
# save one flip-flop per bit, and the LUT sits in the heap's first stage, a path
# the frontier does not price.
