# Write the functional netlist of `dut` from an open, routed harness, on its own.
#
#     source <rtl dir>/write_dut_netlist.tcl
#     write_dut_netlist <file>
#
# Implementation can replicate a harness input register and feed the copy into dut
# through an extra port, <name>_repN_alias. Nothing drives that port in a testbench
# of dut alone, so it reads Z and the simulation X, though the design is fine. Each
# such port holds the same value as the register it copies, and in a testbench of
# dut that register is simply the input bit, so the port becomes a wire from it.
proc write_dut_netlist {file} {
    write_verilog -force -mode funcsim -cell dut $file
    set wires {}
    foreach pin [get_pins -quiet -filter {DIRECTION == IN && NAME =~ "dut/*_alias"} -of_objects [get_cells dut]] {
        set port [lindex [split $pin /] end]
        set driver [get_cells -of_objects [get_pins -leaf -filter {DIRECTION == OUT} \
            -of_objects [get_nets -of_objects $pin -boundary_type upper]]]
        if {[regexp {^(.*)_reg_reg\[(\d+)\]_replica(_\d+)?$} $driver -> base bit]} {
            lappend wires $port "$base\[$bit\]"
        } elseif {[regexp {^(.*)_reg_reg_replica(_\d+)?$} $driver -> base]} {
            lappend wires $port $base
        } else {
            error "write_dut_netlist: $port is driven by $driver, not a copy of a harness input register"
        }
    }
    if {![llength $wires]} { return }
    set f [open $file r]
    set text [read $f]
    close $f
    # only in the DUT's own module: lower modules can have a port of the same name
    set ref [get_property REF_NAME [get_cells dut]]
    if {![regexp -indices "\nmodule $ref\\M" $text top_at]} { error "write_dut_netlist: no module $ref in $file" }
    set top_start [lindex $top_at 0]
    set top_end [expr {[string first "endmodule" $text $top_start] + 9}]
    set before [string range $text 0 [expr {$top_start - 1}]]
    set rest [string range $text $top_end end]
    set text [string range $text $top_start [expr {$top_end - 1}]]
    foreach {port source} $wires {
        # a name with brackets is written escaped, \name followed by a space
        set id [expr {[string is wordchar $port] ? $port : "\\$port "}]
        regsub -all {[][\\.*+?(){}|^$]} $id {\\&} pat
        regsub -all {[&\\]} "  wire $id = $source;" {\\&} decl
        regsub "\n *$pat *,\n" $text "\n" text
        regsub ",\n *$pat *\\);" $text ");" text
        regsub "\n *input *$pat *;" $text "\n$decl" text
        regsub "\n *wire *$pat *;" $text "\n" text
    }
    set f [open $file w]
    puts -nonewline $f "$before$text$rest"
    close $f
    puts "write_dut_netlist: tied [expr {[llength $wires] / 2}] replica port(s) to their input bits"
}
