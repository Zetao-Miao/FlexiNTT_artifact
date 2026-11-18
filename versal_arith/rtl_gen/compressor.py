import os
from bitheap import BitHeap
from counter import Counter
from heuristic import compressAll, formGPCChain, merge_last_stage
from rtl_gen.bit_polarity import push_polarity
from rtl_gen.utils import merge_bit_assigns, pin_chain_cin_nets
from rtl_gen.utils import read_nonneg_int_list, gen_bitheap_testvectors, tb_settle_delay
from rtl_gen.layer import layer_gen, simulate_layers
from rtl_gen.terminal_add import terminalAdd_gen


def reg_flag_list_gen(pipeline_stages: int, num_layers: int) -> list[bool]:
    """The equal-count register split: `num_layers` units into `pipeline_stages`
    groups, a register at the end of each.

    Kept as the tie-break inside `lut_timing.place_registers` and for callers
    that only need a count. The generators no longer place registers with it:
    they call `lut_timing.heap_reg_flags` / `bmult_reg_flags`, which put each
    register where the slowest segment is shortest and fall back to exactly
    this split whenever it is already optimal.

    `pipeline_stages == 0` is purely combinational, no register anywhere. More
    stages than units registers every unit and adds nothing past that.
    """
    from lut_timing import even_split
    return even_split(pipeline_stages, num_layers)


def compressor_gen(counter_list_rearranged: list[list], first_layer_inputs: list[int], comp_output_name: str, comp_output_width: int, last_compression_layer_bitheap: BitHeap, reg_flag_list: list[bool]) -> tuple[str, str]:
    declaration = ""
    instantiation = ""
    xdc = ""
    number_of_layers = len(counter_list_rearranged)
    current_layer_inputs = first_layer_inputs
    if number_of_layers >= 2:
        merge_flag_temp, reduced_inputs = merge_last_stage(last_compression_layer_counter_list=counter_list_rearranged[-1],
                                                           last_compression_layer_bitheap=last_compression_layer_bitheap)
    else:
        merge_flag_temp = False
        reduced_inputs = [[[0]]]
    if merge_flag_temp:
        # `merge_last_stage` judges each last-stage counter on its own against
        # the previous layer's free bits; two of them on one column, or a
        # dropped column-(c+1) input whose bit then stays in the heap, can pass
        # it and still not fit (Sept 2026: a heap in ~60 raised in the terminal
        # adder or read past a column's width). Walk the merged layout the way
        # it will be built and keep the merge only if it fits.
        widths, over = simulate_layers(counter_list_rearranged, first_layer_inputs, True, reduced_inputs)
        if over or max(widths, default=0) > 4:
            print("Last compression stage cannot be merged after all: "
                  + (f"columns over-consumed (layer, column, claimed, available) {over}" if over
                     else f"a terminal column would hold {max(widths)} bits"))
            merge_flag_temp = False
    if merge_flag_temp:
        print("Last compression stage is able to be merged with its previous stage!")
        number_of_layers -= 1
    if len(reg_flag_list) != number_of_layers + 1:
        raise ValueError(
            f"reg_flag_list has {len(reg_flag_list)} entries but this heap compresses in "
            f"{number_of_layers} layer(s) plus the terminal adder; the placement was "
            f"computed for a different heap"
        )
    print(f"Maximum Number of Pipeline Stages of the Compressor Tree: {number_of_layers+1}")
    num_pipe = 0
    for val in reg_flag_list:
        num_pipe += 1 if val else 0
    print(f"Generated compressor tree is pipelined into {num_pipe} stages")
    for no in range(number_of_layers):
        merge_flag = True if merge_flag_temp and no == number_of_layers-1 else False
        next_layer_inputs, layer_comments, layer_declaration, layer_instantaion, layer_xdc = layer_gen(layer_no=no,
                                                                                                       layer_inputs=current_layer_inputs,
                                                                                                       chains_list=counter_list_rearranged[no],
                                                                                                       reg_flag=reg_flag_list[no],
                                                                                                       merge_flag=merge_flag,
                                                                                                       merge_counter_list=counter_list_rearranged[-1],
                                                                                                       reduced_inputs=reduced_inputs)
        declaration += layer_comments
        declaration += layer_declaration
        instantiation += layer_comments
        instantiation += layer_instantaion
        xdc += layer_xdc
        current_layer_inputs = next_layer_inputs
    terminal_declaration, terminal_instantiation = terminalAdd_gen(terminal_layer_no=number_of_layers,
                                                                   terminal_inputs=current_layer_inputs,
                                                                   final_output_name=comp_output_name,
                                                                   final_output_width=comp_output_width,
                                                                   terminal_reg_flag=reg_flag_list[-1])
    declaration += f"""
    
    
    // -------------------------------------------------- TERMINAL ADDITION ------------------------------------------------"""
    declaration += terminal_declaration
    instantiation += f"""
    
    
    // -------------------------------------------------- TERMINAL ADDITION ------------------------------------------------"""
    instantiation += terminal_instantiation
    RTL_compressor = declaration + instantiation
    return RTL_compressor, xdc


def _col_port_names(number_list: list[int], bitheap_desc: list | None) -> list[str]:
    """Derive per-column port names from bitheap_desc or default to in_col{k}."""
    n = len(number_list)
    names = [f"in_col{col}" for col in range(n)]
    if bitheap_desc is not None:
        for entry in bitheap_desc:
            col_idx = entry[0]
            if col_idx < n and len(entry) > 1:
                sig_name = entry[1][0]  # signal_name from first bit tuple
                if sig_name is not None:
                    names[col_idx] = sig_name
    return names


def compressor_RTL_gen(txt_file_name: str, sv_file_name: str, compressor_module_name: str, tb_out_width: int, reg_flag_list: list[bool], visualization: bool=False, gen_testbench: bool=True, test_size: int=1000, bitheap_desc: list | None = None, input_kinds: dict | None = None, write_xdc: bool = True) -> None:
    """Generate complete compressor tree RTL from a bitheap description file.

    Reads the bitheap .txt file, runs compression heuristics, generates
    SystemVerilog, XDC constraints, and optionally testbenches + test vectors.
    `input_kinds` marks which input bits are inverted or constant, for
    `rtl_gen.bit_polarity.push_polarity`. `write_xdc=False` leaves out the
    per-instance XDC, whose patterns group LUTs of unrelated instances; a design
    with more than one instance uses `rtl/scoped_gpc_xdc.tcl` instead.
    Output files are written to RTL_generated/ and xdc_generated/ directories.

    If bitheap_desc is provided, column port names are derived from Bit
    metadata instead of using the default in_col{k} naming.
    """
    # read .txt to build bit heap instances
    number_list = read_nonneg_int_list(txt_file_name)
    if max(number_list, default=0) <= 2:
        # The heuristic still schedules a layer for such a heap and the
        # quaternary terminal adder then mis-slices its two-operand columns:
        # the RTL compiles and computes the wrong sum (61-design xsim sweep,
        # Sept 2026). A heap this flat is a plain two-operand add -- the
        # constant multiplier's `adder` strategy, the DSP wrapper's `+` --
        # and must be built as one.
        raise ValueError(
            f"{compressor_module_name}: no column of this heap is taller than two bits "
            f"(max {max(number_list, default=0)}); the compressor tree is not built for "
            f"a two-operand add and would compute the wrong sum. Add the two operands "
            f"with a plain adder instead."
        )
    number_of_columns = len(number_list)
    sum_max = 0
    for col in range(number_of_columns):
        sum_max += number_list[col]*(2**col)
    width_bh = sum_max.bit_length()
    bh_inst = BitHeap(width_bh, 0)
    for col in range(number_of_columns):
        bh_inst.add_bits(col, number_list[col])

    # derive per-column port names
    col_names = _col_port_names(number_list, bitheap_desc)

    # generation of the module head
    left_w = max(len(str(v-1)) for v in number_list)
    left_w = max([left_w, len(str(width_bh-1))])
    RTL_str = f"""`timescale 1ns / 1ps

module {compressor_module_name} (
    input  logic  {' '*left_w}      clk,
    """
    for col in range(number_of_columns):
        if number_list[col] == 0:
            continue
        elif number_list[col] == 1:
            RTL_str += f"""input  logic  {' '*left_w}      {col_names[col]},
    """
        else:
            RTL_str += f"""input  logic [{(number_list[col]-1):<{left_w}} : 0] {col_names[col]},
    """
    RTL_str += f"""output logic [{(width_bh-1):<{left_w}} : 0] comp_out
    );

    """

    # compress the bitheap and arrange layers of counters and counter chains
    if visualization:
        bh_inst.visualize(f"original_bitheap", False)
    last_compression_layer_bitheap, raw_counter_list = compressAll(bh_inst, 0, width_bh-1, visualization, True)
    counter_list = formGPCChain(raw_counter_list)

    # generate the RTL for the bit heap compressor obtained above
    first_layer_inputs = []
    for col in range(width_bh):
        if col > len(number_list)-1:
            first_layer_inputs.append(0)
        else:
            first_layer_inputs.append(number_list[col])

    compressor_RTL, compressor_xdc = compressor_gen(counter_list_rearranged=counter_list,
                                                    first_layer_inputs=first_layer_inputs,
                                                    comp_output_name="comp_out",
                                                    comp_output_width=width_bh,
                                                    last_compression_layer_bitheap=last_compression_layer_bitheap,
                                                    reg_flag_list=reg_flag_list)
    RTL_str += compressor_RTL
    # assign the module inputs with compressor inputs
    RTL_str += f"""
    // -------------------------------------- ASSIGNMENT OF MODULE INPUTS AND COMPRESSOR INPUTS --------------------------------------
    """
    # `first_layer_inputs[col]` is `number_list[col]` for every column this loop
    # visits (compressor_RTL_gen builds it that way), so a column is either
    # present or absent -- there is no widening to pad.
    for col in range(number_of_columns):
        if number_list[col] > 0:
            RTL_str += f"""assign layer0_col{col:<{4}} = {col_names[col]};
    """
        # else: layer_gen did not declare layer0_col{col}; nothing to assign

    if input_kinds is not None:
        RTL_str, polarity_stats = push_polarity(RTL_str, input_kinds)
        print(f"  {compressor_module_name}: pushed into LUTs: {polarity_stats}")

    RTL_str = merge_bit_assigns(RTL_str)
    RTL_str = pin_chain_cin_nets(RTL_str)

    # the tail of module
    RTL_str += f"""
endmodule"""
    # write into .sv and .xdc files
    folder = "RTL_generated"
    os.makedirs(folder, exist_ok=True)
    file_path = os.path.join(folder, f"{sv_file_name}.sv")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(RTL_str)
    if write_xdc:
        folder = "xdc_generated"
        os.makedirs(folder, exist_ok=True)
        file_path = os.path.join(folder, f"{sv_file_name}.xdc")
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(compressor_xdc)

    if gen_testbench:
        if tb_out_width > width_bh:
            raise ValueError(
                f"{compressor_module_name}: tb_out_width={tb_out_width} exceeds "
                f"comp_out's {width_bh} bits, so the testbench would select past "
                f"the port. Pass the heap's width (lut_timing.heap_width) or a "
                f"narrower slice."
            )
        tb_str = f"""`timescale 1ns / 1ps
    
module {compressor_module_name}_tb ();
    // ============================== parameters ==============================
    `define CLK_P         10
    `define CLK_HP        5
    `define TS_SIZE       {test_size}
    `define INIT_RESET    200
    
    // ============================== clock ==============================
    logic clk;
    initial clk = 1'b0;
    always #`CLK_HP clk = ~clk;

    // ============================== in/out signals for DUT ==============================
    """
        for col in range(number_of_columns):
            if number_list[col] == 0:
                continue
            elif number_list[col] == 1:
                tb_str += f"""logic  {' '*left_w}      {col_names[col]};
    """
            else:
                tb_str += f"""logic [{(number_list[col]-1):<{left_w}} : 0] {col_names[col]};
    """
        tb_str += f"""logic [{(width_bh-1):<{left_w}} : 0] comp_out;
        """
        w = number_of_columns.bit_length()
        tb_str += f"""
    // ============================== DUT and its port connections ==============================
    {compressor_module_name} dut (
        .clk{' '*(w+1+3)}(clk{' '*(w+1+3)}),
        """
        for col in range(number_of_columns):
            if number_list[col] == 0:
                continue
            else:
                cn = col_names[col]
                tb_str += f""".{cn:<{w+1+7}}({cn:<{w+1+7}}),
        """
        tb_str += f""".comp_out(comp_out));
    """
        tb_str += f"""
    // ============================== testvectors ==============================
    """
        for col in range(number_of_columns):
            if number_list[col] == 0:
                continue
            elif number_list[col] == 1:
                tb_str += f"""logic  {' '*left_w}      {col_names[col]}_ts [`TS_SIZE-1 : 0];
    """
            else:
                tb_str += f"""logic [{(number_list[col]-1):<{left_w}} : 0] {col_names[col]}_ts [`TS_SIZE-1 : 0];
    """
        tb_str += f"""logic [{(width_bh-1):<{left_w}} : 0] comp_out_ts [`TS_SIZE-1 : 0];
    """
        tb_str += f"""
    // ============================== read testvector values ==============================
    initial begin
        """
        for col in range(number_of_columns):
            if number_list[col] == 0:
                continue
            else:
                tb_str += f"""$readmemh("../../../../../testvectors/{col_names[col]}.txt", {col_names[col]}_ts);
        """
        tb_str += f"""$readmemh("../../../../../testvectors/comp_out.txt", comp_out_ts);
    end
    """
        tb_str += f"""
    // ============================== provide test input vectors ==============================
    int i;
    initial begin
        #`INIT_RESET;
        #`CLK_HP;
        #1;
        for (i = 0; i < `TS_SIZE; i = i + 1) begin
            """
        # calculate the number of pipeline stages
        comp_pipeline_stages = 0
        for val in reg_flag_list:
            if val:
                comp_pipeline_stages += 1
        for col in range(number_of_columns):
            if number_list[col] == 0:
                continue
            else:
                cn = col_names[col]
                tb_str += f"""{cn:<{w+7}} = {cn}_ts[i];
            """
        tb_str += f"""#`CLK_P;
        end
    end
    """
        tb_str += f"""
    // ============================== check the correctness of output ==============================
    int j;
    int correct_cnt;
    initial begin
        correct_cnt = 0;
        #`INIT_RESET;
        #`CLK_HP;
        #(`CLK_P*{comp_pipeline_stages});
        #{tb_settle_delay(comp_pipeline_stages)};
        for (j = 0; j < `TS_SIZE; j = j + 1) begin
            if (comp_out[{tb_out_width-1}:0] == comp_out_ts[j][{tb_out_width-1}:0]) begin
                $display("Testvector-%d CORRECT!", j);
                correct_cnt = correct_cnt + 1;
            end else begin
                $display("=================================================================================");
                $display("Testvector-%d WRONG", j);
                $display("module    output: %b", comp_out[{tb_out_width-1}:0]);
                $display("reference output: %b", comp_out_ts[j][{tb_out_width-1}:0]);
                $display("difference:       %b", comp_out_ts[j][{tb_out_width-1}:0] - comp_out[{tb_out_width-1}:0]);
                $display("=================================================================================");
            end
            #`CLK_P;
        end
        if (correct_cnt == `TS_SIZE) begin
            $display("SUCCESS!");
            $display("PASS All %d Testvectors!", `TS_SIZE);
        end else begin
            $display("TO BE DEBUGGED...");
            $display("FAILED: %d out of %d testvectors failed", (`TS_SIZE-correct_cnt), `TS_SIZE);
        end
        $finish();
    end

endmodule"""
        folder = "RTL_generated"
        os.makedirs(folder, exist_ok=True)
        file_path = os.path.join(folder, f"{sv_file_name}_tb.sv")
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(tb_str)
        gen_bitheap_testvectors(number_list=number_list, test_size=test_size, col_names=col_names)

