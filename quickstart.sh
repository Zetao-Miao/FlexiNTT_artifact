#!/bin/bash
# Quick start: explore the design space for the request in userNTTinput.toml, then generate the RTL of one core
# of the Pareto front. Takes about one minute. Output goes to work/quickstart.
REPO=$(cd "$(dirname "$0")" && pwd); cd "$REPO"; export PYTHONPATH=$REPO:$PYTHONPATH
OUT=$REPO/work/quickstart; mkdir -p "$OUT"
python3 runDse.py userNTTinput.toml --out "$OUT" > "$OUT/explore.log" 2>&1 || { echo "exploration failed, see $OUT/explore.log"; exit 1; }
echo "exploration done: $OUT/front.txt (Pareto front), $OUT/feasible.txt (all cores that meet the request)"
NAME=${1:-$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['front'][0])" "$OUT/result.json")}
python3 generate_core.py "$OUT/result.json" "$NAME" "$OUT/$NAME" > "$OUT/generate.log" 2>&1 || { echo "generation failed, see $OUT/generate.log"; exit 1; }
echo "generated core $NAME: $OUT/$NAME/RTL_generated"
