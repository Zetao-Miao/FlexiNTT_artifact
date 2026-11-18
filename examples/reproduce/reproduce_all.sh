#!/bin/bash
# Regenerate the source files of the designs in the paper and compare them with examples/paper_designs.
#
#   bash examples/reproduce/reproduce_all.sh            all twenty designs
#   bash examples/reproduce/reproduce_all.sh hybrid     only the designs whose name contains "hybrid"
#
# Output goes to work/reproduce/<design>. Needs Python only (see README.md, section Requirements).
# The testbench (<top>_tb.sv) is left out of the comparison.
HERE=$(cd "$(dirname "$0")" && pwd); REPO=$(cd "$HERE/../.." && pwd)
export PYTHONPATH=$REPO:$PYTHONPATH
OUT=$REPO/work/reproduce; REF=$REPO/examples/paper_designs; mkdir -p "$OUT"
only=$1; pass=0; fail=0
run() {   # run <design> <command...>, the command writes into $OUT/<design>
  local name=$1; shift
  [[ -n "$only" && "$name" != *"$only"* ]] && return
  local d=$OUT/$name; rm -rf "$d"; mkdir -p "$d"
  if ! ( cd "$d" && "$@" > "$d/generate.log" 2>&1 ); then echo "FAILED     $name (see $d/generate.log)"; fail=$((fail+1)); return; fi
  local rtl=$d/RTL_generated
  [ -d "$rtl" ] || rtl=$(find "$d" -maxdepth 2 -type d -name RTL_generated | grep -v _alt | head -1)
  if diff -rq -x '*_tb.sv' "$rtl" "$REF/$name/rtl" > "$d/diff.txt" 2>&1; then echo "IDENTICAL  $name"; pass=$((pass+1))
  else echo "DIFFERENT  $name (see $d/diff.txt)"; fail=$((fail+1)); fi
}
df() { run "$1" python3 "$HERE/gen_dataflow.py" "$2" rom slot1 "$3" .; }
it() { run "$1" python3 "$HERE/gen_iterative.py" "$2" "$3" . --tgt 350; }
ms() { MS_ROW_FMAX=$3 run "$1" python3 "$HERE/gen_multistep.py" "$2" . 3 --nosim; }
cs() { run "case_study_core_$1" python3 "$REPO/generate_core.py" --record "$REF/case_study_core_$1/record.json" .; }

# Table III, dataflow cores
df table3_dataflow_n4096_q32_12bu    K1_A4096_q32w16_P2c       LDb_rom1
df table3_dataflow_n4096_q64_12bu    K1_A4096_q64w32_P2c       LDc_rom1
df table3_dataflow_n4096_q64_192bu   K1_A4096_q64w32_P32ic     LDd_rom1
df table3_dataflow_n131072_q62       K1_A131072_q62b_P8ci_odd  LDe_rom1
# Table III, iterative cores (row, coefficients per cycle at the data port)
it table3_iterative_n4096_q60_8bu      Ia_n4096_q60w_B8_rns               2
it table3_iterative_n8192_q36_512bu    Ib_n8192_q36b_B512_auto_rns_rec    32
it table3_iterative_n16384_q54_256bu   Ic_n16384_q54b_B256_auto_rns_rec2  32
it table3_iterative_n65536_q52_32bu    Id_n65536_q52w_B32_rns             4
it table3_iterative_n65536_q64_64bu    Ie_n65536_q64b_B64_rns             8
it table3_iterative_n131072_q64_64bu   If_n131072_q64b_B64_r3_rns         8
# Table III, hybrid core
run table3_hybrid_n4096_q30_24bu python3 "$HERE/gen_hybrid.py" .
# Table III, multi-step cores (row, clock target in MHz)
ms table3_multistep_n4096_q60_32pts    MS_N12_q60_P32_tpm  400
ms table3_multistep_n4096_q32_64pts    MS_N12_q32_P64_tpm  400
ms table3_multistep_n16384_q60_32pts   MS_N14_q60_P32_tpm  375
ms table3_multistep_n65536_q60_32pts   MS_N16_q60_P32_tpm  375
# Case study, cores A to E
for c in A B C D E; do cs $c; done
echo "$pass identical, $fail failed or different"
[ $fail -eq 0 ]
