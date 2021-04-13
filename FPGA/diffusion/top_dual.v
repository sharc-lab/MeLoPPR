module top_dual #(parameter period = 10, ADDR_WIDTH = 13, DATA_WIDTH = 32, nei_table_offset = 10, node_num = 5, max_steps = 7, lower_addr1=0, upper_addr1=9, lower_addr2=10, upper_addr2=19) ( 
    input clk,
	input rdy_flag,
    input [DATA_WIDTH-1:0] mem1_data_in_s,
    input [DATA_WIDTH-1:0] mem2_data_in_s,
    input [DATA_WIDTH-1:0] m1_data_in_g,
    input [DATA_WIDTH-1:0] m2_data_in_g,
    
    output [ADDR_WIDTH-1:0] mem1_address_s,
    output mem1_write_en,  
    output [DATA_WIDTH-1:0] mem1_data_out_s,

    output [ADDR_WIDTH-1:0] mem2_address_s,
    output mem2_write_en,
    output [DATA_WIDTH-1:0] mem2_data_out_s,

    output [ADDR_WIDTH-1:0] m1_address_g,
    output m1_write_enable_g,

    output [ADDR_WIDTH-1:0] m2_address_g,
    output m2_write_enable_g //

    );

    wire [DATA_WIDTH-1:0] l_step;
    wire [DATA_WIDTH-1:0] m1_data_in_s, m1_data_out_s, m2_data_in_s, m2_data_out_s, m2_data_out_g;
    wire [ADDR_WIDTH-1:0] m1_address_s, m2_address_s;

    wire m1_write_enable_s, finished1, conflict_b, m2_write_enable_s, finished2, conflict_b1, conflict_b2, finished_all;

    diffusion_rw #(.period(period), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .nei_table_offset(nei_table_offset), .node_num(node_num), .node_offset(0), .max_steps(max_steps)) M1 ( 
    .conflict(1'b0),
    .clk(clk), 
    .data_in_s(m1_data_in_s),
    .data_in_g(m1_data_in_g),
    .l_step(l_step),
    .rdy(rdy1&rdy_flag),
	.finished_all(finished_all),

    .data_out_s(m1_data_out_s), 
    .address_g(m1_address_g), 
    .address_s(m1_address_s), 
    .write_enable_g(m1_write_enable_g),
    .write_enable_s(m1_write_enable_s),
    .finished(finished1) //
    );

    diffusion_rw #(.period(period), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .nei_table_offset(nei_table_offset), .node_num(node_num), .node_offset(node_num), .max_steps(max_steps)) M2 ( 
    .conflict(conflict_b),
    .clk(clk), 
    .data_in_s(m2_data_in_s),
    .data_in_g(m2_data_in_g),
    .l_step(l_step),
    .rdy(rdy2&rdy_flag),
	.finished_all(finished_all),

    .data_out_s(m2_data_out_s), 
    .address_g(m2_address_g), 
    .address_s(m2_address_s), 
    .write_enable_g(m2_write_enable_g),
    .write_enable_s(m2_write_enable_s),
    .finished(finished2) //
    );

    sync_control_dual #(.DATA_WIDTH(DATA_WIDTH), .max_steps(max_steps)) lap_control ( 
	.clk(clk),
	.finished1(finished1),
	.finished2(finished2),
	.rst(1'b0), //  a reset flag that reset all operations; after lap > max_steps, rst needs to be set high by PS to reset everything
	
	.rdy1(rdy1),
	.rdy2(rdy2), //
	.finished_all(finished_all),
	.l_step(l_step) //
	);


    scheduler_dual #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .lower_addr(lower_addr1), .upper_addr(upper_addr1)) scheduler1 ( 
	.clk(clk),
	.data_mem(mem1_data_in_s), // input from BRAM score table memory

	.addrA(m1_address_s),
	.addrB(m2_address_s),

	.dataA(m1_data_out_s),
	.dataB(m2_data_out_s),

	.write_enA(m1_write_enable_s),
	.write_enB(m2_write_enable_s),

	.data(mem1_data_out_s), // goes out to bram score table memory
	.addr(mem1_address_s), // addr goes out to bram score table memory
	.dataMA(m1_data_in_s), // goes out to verilog M module
	.dataMB(m2_data_in_s),


	.write_mem_en(mem1_write_en),


	.conflict_b(conflict_b1) //

	);


    scheduler_dual #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .lower_addr(lower_addr2), .upper_addr(upper_addr2)) scheduler2 ( 
	.clk(clk),
	.data_mem(mem2_data_in_s), // input from BRAM score table memory

	.addrA(m1_address_s),
	.addrB(m2_address_s),

	.dataA(m1_data_out_s),
	.dataB(m2_data_out_s),

	.write_enA(m1_write_enable_s),
	.write_enB(m2_write_enable_s),

	.data(mem2_data_out_s), // goes out to bram score table memory
	.addr(mem2_address_s), // addr goes out to bram score table memory
	.dataMA(m1_data_in_s), // goes out to verilog M module
	.dataMB(m2_data_in_s),


	.write_mem_en(mem2_write_en),


	.conflict_b(conflict_b2) //

	);

    assign conflict_b = conflict_b1 | conflict_b2; 


endmodule