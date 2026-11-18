"""Behavioural twin of `rtl_gen.datapath`: every heap a `+`/`-` expression,
every multiplier a `*`, the same registers, the same test vectors. For fast
functional simulation; the hardware flavour is `rtl_gen.datapath`."""
from __future__ import annotations

from rtl_gen.datapath import Datapath_RTL_gen


def Datapath_SimRTL_gen(spec, pipeline_stages=1, gen_testbench: bool = True,
                        visualization: bool = False, vectors: dict | None = None,
                        submodules: dict | None = None, write_xdc: bool = False,
                        clock_ns: float | None = None) -> dict:
    return Datapath_RTL_gen(spec, pipeline_stages, gen_testbench, False, vectors,
                            submodules=None, behavioural=True, write_xdc=False,
                            clock_ns=clock_ns)
