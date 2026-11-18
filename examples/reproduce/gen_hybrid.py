"""Hybrid core matched to AutoNTT's hybrid point for the paper table (2026-11-18): n 4096, 3 stages x 2 groups (24 BUs),
30-bit Barrett, 4 moduli slots loadable at run time, negacyclic, both directions, data port of 4 coefficients (AutoNTT's),
one context (lowest latency). Generates into ooc/<row> and simulates (xsim, 5 polynomials, modulus and direction per
polynomial, value + tag + cycle of every output beat checked against the cycle model: interval 1104, latency 2941)."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 and not sys.argv[1].startswith('-') else os.path.join(REPO, 'work', 'hybrid')
SIM = '--sim' in sys.argv
os.chdir(REPO); sys.path.insert(0, REPO); sys.argv = sys.argv[:1]
import runHybridNTT as H
PTS = [('ev_ld_io4', 4096, 3, 2, ('m', 30, 4), 'barrett', True, 'output', 1, 5, None, 'mix', {'loadable': True, 'ioLanes': 4})]
sys.exit(H.gate2(OUT, SIM, None, points=PTS))
