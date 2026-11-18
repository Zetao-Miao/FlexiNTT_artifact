# Attach the GPC placement rules to every c9_41 in the open synthesized design.
#
#     source <rtl dir>/scoped_gpc_xdc.tcl
#
# Synthesis names differently parameterized copies c9_41__parameterized<N>, and
# a -ref scope matches one name only, so each name in the netlist is read.
set gpc_xdc_dir [file dirname [file normalize [info script]]]
set gpc_cells [get_cells -quiet -hierarchical -filter {REF_NAME == c9_41 || ORIG_REF_NAME == c9_41}]
set gpc_refs {}
if {[llength $gpc_cells]} {
    set gpc_refs [lsort -unique [get_property REF_NAME $gpc_cells]]
}
foreach gpc_ref $gpc_refs {
    read_xdc -ref $gpc_ref "$gpc_xdc_dir/c9_41.xdc"
}
puts "scoped_gpc_xdc: c9_41 rule applied to [llength $gpc_refs] module name(s): $gpc_refs"

# The Booth partial-product generators: each module has its generated pairing
# rule, <module>.xdc, in this folder or one named by gpc_xdc_extra_dirs. Inside
# an IP the netlist renames the module (<ip>_<module>, or a _<N> copy) and
# ORIG_REF_NAME keeps the name that the rule file carries.
if {![info exists gpc_xdc_extra_dirs]} { set gpc_xdc_extra_dirs {} }
set pp_cells [get_cells -quiet -hierarchical -filter {REF_NAME =~ "*_bitheap_gen" || ORIG_REF_NAME =~ "*_bitheap_gen"}]
set pp_refs {}
if {[llength $pp_cells]} {
    set pp_refs [lsort -unique [get_property REF_NAME $pp_cells]]
}
foreach pp_ref $pp_refs {
    set pp_orig [get_property ORIG_REF_NAME [lindex [get_cells -quiet -hierarchical -filter "REF_NAME == $pp_ref"] 0]]
    if {$pp_orig eq ""} { set pp_orig $pp_ref }
    set pp_found 0
    foreach pp_dir [concat [list $gpc_xdc_dir] $gpc_xdc_extra_dirs] {
        if {[file exists "$pp_dir/$pp_orig.xdc"]} {
            read_xdc -ref $pp_ref "$pp_dir/$pp_orig.xdc"
            set pp_found 1
            break
        }
    }
    if {!$pp_found} { puts "WARNING: scoped_gpc_xdc: no $pp_orig.xdc found; its LUT5 pairs stay apart" }
}
puts "scoped_gpc_xdc: partial-product rule applied to [llength $pp_refs] module name(s): $pp_refs"
