#!/usr/bin/env python3
"""Generate the RTL and the self-checking testbench of one core found by the exploration.

  python3 generate_core.py RESULT.json NAME OUTDIR     a core of an exploration result, by its name
  python3 generate_core.py --record RECORD.json OUTDIR  a core saved as a single record

RESULT.json is the file `result.json` that runDse.py writes into its output folder. NAME is the name of a core as
printed in the exploration tables. The RTL is written to OUTDIR/RTL_generated. The last line printed is the name
of the top module and the clock period in ns the core was designed for."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from operator_modeling.dse.record import CoreRecord
from operator_modeling.dse.search import adapter
a = sys.argv[1:]
if len(a) == 3 and a[0] == '--record':
    d, out = json.load(open(a[1])), a[2]
elif len(a) == 3:
    recs = [r for r in json.load(open(a[0]))['records'] if r['name'] == a[1]]
    if not recs:
        sys.exit(f'no core named {a[1]} in {a[0]}')
    d, out = recs[0], a[2]
else:
    sys.exit(__doc__)
d = dict(d); d.pop('row', None)
os.makedirs(out, exist_ok=True)
r = CoreRecord.fromJson(d)
b = adapter(r.arch).build(r, out)
if isinstance(b, tuple):                      # the iterative adapter returns (top, files)
    b = {'top': b[0], 'files': b[1]}
json.dump({k: v for k, v in b.items() if k != 'files'}, open(os.path.join(out, 'build.json'), 'w'), default=str, indent=1)
print(b['top'], f'{1e3 / r.clockMhz:.3f}')
