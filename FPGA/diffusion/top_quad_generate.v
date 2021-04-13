module top_quad_generate #(parameter period = 10, DEPTH = 8192, ADDR_WIDTH = 13, DATA_WIDTH = 32, nei_table_offset = 10, node_num = 5, max_steps = 7, PARALLEL = 4, lower_addr1=0, upper_addr1=9, lower_addr2=10, upper_addr2=19, lower_addr3=20, upper_addr3=29, lower_addr4=30, upper_addr4=39) ( 
    input clk,
	input rdy_flag,
    input [DATA_WIDTH*PARALLEL-1:0] mem_data_in_s,
    input [DATA_WIDTH*PARALLEL-1:0] m_datain_g,
	input [DATA_WIDTH*PARALLEL-1:0] mem_data_in_score_sum,
    
    output [ADDR_WIDTH*PARALLEL-1:0] mem_address_s,
    output [PARALLEL-1:0] mem_write_en,  
    output [DATA_WIDTH*PARALLEL-1:0] mem_data_out_s,
    output [ADDR_WIDTH*PARALLEL-1:0] m_addr_g,
    output [PARALLEL-1:0] m_write_en_g,
	
	output [ADDR_WIDTH*PARALLEL-1:0] mem_addr_score_sum,
	output [DATA_WIDTH*PARALLEL-1:0] mem_data_out_score_out_sum,
	output [PARALLEL-1:0] mem_score_write_sum_en	//

    );

    wire [DATA_WIDTH-1:0] l_step;


	genvar a, b, i;
	wire [DATA_WIDTH-1:0] lower_addr [0:PARALLEL-1], upper_addr [0:PARALLEL-1];
	
	wire [DATA_WIDTH-1:0] memVar_data_in [0:PARALLEL-1];
	wire [DATA_WIDTH-1:0] memVar_data_out_s [0:PARALLEL-1];
	wire [DATA_WIDTH-1:0] memVar_address_s [0:PARALLEL-1];
	wire memVar_write_en [0:PARALLEL-1], conflictVar_b [0:PARALLEL-1], conflictVar_c [0:PARALLEL-1], conflictVar_d [0:PARALLEL-1];
	
	wire [DATA_WIDTH-1:0] m_data_in_s [0:PARALLEL-1], m_data_in_g [0:PARALLEL-1], m_data_out_s [0:PARALLEL-1];
	wire [ADDR_WIDTH-1:0] m_address_g [0:PARALLEL-1], m_address_s [0:PARALLEL-1];
	wire conflict [0:PARALLEL-1], rdy [0:PARALLEL-1], m_write_enable_g [0:PARALLEL-1], m_write_enable_s [0:PARALLEL-1], finished [0:PARALLEL-1];
	
	/////////// adds up score Nov 14 2021 ///////////////////////////
	wire [ADDR_WIDTH-1:0] mem_addr_addup [0:PARALLEL-1];
	wire mem_score_write_en_addup [0:PARALLEL-1]; 
	wire finished_final [0:PARALLEL-1];
	wire finished_propagation;
    reg finished_all;

	////////////////////////////////////////////////////////////////
	
	
	
	////////////// nov 15 generate /////////	
	wire [ADDR_WIDTH*PARALLEL-1:0] m_address_aggr_s;
	wire [DATA_WIDTH*PARALLEL-1:0] m_data_out_aggr_s, m_data_in_aggr_s;
	wire [PARALLEL-1:0] m_write_enable_aggr_s;
	wire [PARALLEL-1:0] conflictVar [0:PARALLEL-1];
	////////////////////////////////////////
	
	
	
	generate
		for (a=0; a < PARALLEL; a = a+1) begin
		
			assign memVar_data_in[a] = mem_data_in_s[(a+1)*DATA_WIDTH-1:a*DATA_WIDTH];
			assign m_data_in_g[a] = m_datain_g[(a+1)*DATA_WIDTH-1:a*DATA_WIDTH];
			
			assign mem_address_s[(a+1)*ADDR_WIDTH-1:a*ADDR_WIDTH] = (finished_propagation == 1'b0)? memVar_address_s[a] : mem_addr_addup[a];
			assign mem_write_en[a] = (finished_propagation == 1'b0)? memVar_write_en[a] : mem_score_write_en_addup[a];
			
			
			assign  mem_data_out_s[(a+1)*DATA_WIDTH-1:a*DATA_WIDTH] = memVar_data_out_s[a];

			assign m_addr_g[(a+1)*ADDR_WIDTH-1:a*ADDR_WIDTH] = m_address_g[a];

			assign m_write_en_g[a] = m_write_enable_g[a];

			////////////// nov 15 generate /////////
			assign m_address_aggr_s[(a+1)*ADDR_WIDTH-1:a*ADDR_WIDTH] = m_address_s[a];
			assign m_data_out_aggr_s[(a+1)*DATA_WIDTH-1:a*DATA_WIDTH] = m_data_out_s[a];
			assign m_write_enable_aggr_s[a] = m_write_enable_s[a];
			assign m_data_in_s[a] = m_data_in_aggr_s[(a+1)*DATA_WIDTH-1:a*DATA_WIDTH];
			////////////////////////////////////////
			
			diffusion_rw #(.period(period), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .nei_table_offset(nei_table_offset), .node_num(node_num), .node_offset(node_num*a), .max_steps(max_steps)) M ( 
			.conflict(conflict[a]),
			.clk(clk), 
			.data_in_s(m_data_in_s[a]),
			.data_in_g(m_data_in_g[a]),
			.l_step(l_step),
			.rdy(rdy[a]&rdy_flag),
			.finished_all(finished_all),

			.data_out_s(m_data_out_s[a]), 
			.address_g(m_address_g[a]), 
			.address_s(m_address_s[a]), 
			.write_enable_g(m_write_enable_g[a]),
			.write_enable_s(m_write_enable_s[a]),
			.finished(finished[a]) //
			);
			
			
			
			scheduler_generate_quad #(.ADDR_WIDTH(ADDR_WIDTH), .PARALLEL(PARALLEL), .DATA_WIDTH(DATA_WIDTH), .lower_addr(node_num * a*2), .upper_addr(node_num * (a+1)*2 -1)) scheduler ( 
			.clk(clk),
			.data_mem(memVar_data_in[a]),
			.addrFM(m_address_aggr_s),
			.dataFM(m_data_out_aggr_s),
			.write_en(m_write_enable_aggr_s),

			.data(memVar_data_out_s[a]), // goes out to bram memory
			.addr(memVar_address_s[a]), // addr goes out to bram memory
			.dataM(m_data_in_aggr_s), // goes out to verilog M module


			.write_mem_en(memVar_write_en[a]),

			.conflict(conflictVar[a])


			);

			/////////// adds up score Nov 14 2021 ///////////////////////////
	
			add_up_score #(.period(period), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .max_steps(max_steps), .mem_size(node_num)) add_up_score_ins( 
			.clk(clk),
			.rst(0'b0), // a reset flag that reset all operations; after lap > max_steps, rst needs to be set high by PS to reset everything
			.finished(finished[a]),
			.finished_propagation(finished_propagation),
			.finished_all_addup(finished_all),
			.l_step(l_step), //
			.data_in_score(mem_data_in_s[(a+1)*DATA_WIDTH-1:a*DATA_WIDTH]),
			.data_in_score_sum(mem_data_in_score_sum[(a+1)*DATA_WIDTH-1:a*DATA_WIDTH]),
			
			.rdy_final(rdy[a]),
			.finished_global_score(finished_final[a]),
			
			.addr_score(mem_addr_addup[a]),
			.score_write_en(mem_score_write_en_addup[a]),
			
			.addr_score_sum(mem_addr_score_sum[(a+1)*ADDR_WIDTH-1:a*ADDR_WIDTH]),
			.score_write_sum_en(mem_score_write_sum_en[a]),
			.data_out_score_out_sum(mem_data_out_score_out_sum[(a+1)*DATA_WIDTH-1:a*DATA_WIDTH])
			);
			//////////////////////////////////////////////////////		
			
		end	
	endgenerate


	
	
    l_step_count_quad #(.DATA_WIDTH(DATA_WIDTH), .max_steps(max_steps)) l_step_count_ins ( 
	.clk(clk),
	.finished1(finished_final[0]),
	.finished2(finished_final[1]),
	.finished3(finished_final[2]),
	.finished4(finished_final[3]),
	.rst(1'b0), //  a reset flag that reset all operations; after lap > max_steps, rst needs to be set high by PS to reset everything
	
	.l_step(l_step) //
	);



	/////////// adds up score Nov 14 2021 ///////////////////////////
	
	always @(posedge clk) begin
		finished_all = finished_final[0] & finished_final[1] & finished_final[2] & finished_final[3];
	end
	assign finished_propagation = finished[0] & finished[1] & finished[2] & finished[3];
	
	////////////////////////////////////////////////
	
	
	
	////////////// nov 15 generate /////////	
	assign conflict[0] = 0;
	generate
		for (i=1; i < PARALLEL; i = i+1) begin	
			assign conflict[i] = conflictVar[0][i] | conflictVar[1][i] | conflictVar[2][i] | conflictVar[3][i];
		end
	endgenerate

	////////////////////////////////////////////////

endmodule
