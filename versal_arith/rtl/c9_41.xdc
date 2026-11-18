# Packs the two majority LUT3s of a c9_41 into one physical LUT.
#
# Load after synthesis, scoped to the module (scoped_gpc_xdc.tcl does it), and
# for implementation only. Scoped this way it applies at every instance in any
# hierarchy, and Vivado makes the group name unique per instance.
set_property LUTNM c9_pair [get_cells LUT3_inst0]
set_property LUTNM c9_pair [get_cells LUT3_inst1]
