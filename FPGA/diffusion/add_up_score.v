module add_up_score #(parameter period = 10, DATA_WIDTH = 32, ADDR_WIDTH=13, max_steps = 7, mem_size = 8192) ( 
	input clk,
	//input rdy,
	input rst, // a reset flag that reset all operations; after lap > max_steps, rst needs to be set high by PS to reset everything
	input finished,
	input finished_propagation,
	input finished_all_addup,
	//input finished2,
	input [DATA_WIDTH-1:0] l_step, //
	input [DATA_WIDTH-1:0] data_in_score,
	input [DATA_WIDTH-1:0] data_in_score_sum,
	
	output reg rdy_final,
	output reg finished_global_score,
	
	output [ADDR_WIDTH-1:0] addr_score,
	output reg score_write_en,
	
	output [ADDR_WIDTH-1:0] addr_score_sum,
	output score_write_sum_en,
	output [DATA_WIDTH-1:0]  data_out_score_out_sum
	
	
	);
	
	integer mem_process = 0;
	reg read_node_score, read_node_score_sum, write_node_score_sum;
	reg [ADDR_WIDTH-1:0] addr_score_reg, addr_score_sum_reg;
	reg score_write_en_reg = 0, score_write_sum_en_reg = 0;

	reg [DATA_WIDTH-1:0] data_node_score_reg, data_node_score_sum_reg;
	
	assign addr_score = addr_score_reg;
	assign addr_score_sum = addr_score_sum_reg;
    //assign rdy_final = (mem_process == mem_size )? {1'b1}  : rdy ;
    //assign finished_global_score = (mem_process == mem_size)?  {1'b1} : finished;
	assign score_write_sum_en = score_write_sum_en_reg;
	assign data_out_score_out_sum = data_node_score_sum_reg;
	
	integer coeff1 = 15, coeff2 = 16;
	
	always @(*) begin
		if (finished_all_addup == 1) begin
			rdy_final = 1;
		
		end else if (finished == 1) begin
			rdy_final = 0;					
		end else begin
			rdy_final = 1;
		end
	
	end	
	
	always @(*) begin
		if (finished == 0) begin
			finished_global_score = 0;
		
		end else if (mem_process == mem_size) begin
			finished_global_score = 1;					
		end
	
	end
	
	
	always @(negedge clk) begin
		
		if (finished_propagation == 0) begin
			mem_process =  0;
		
		end
	
	
		if (mem_process == mem_size) begin
			write_node_score_sum = 0;  // at the end, turn off the write signal
		
		end

		if (l_step < max_steps && mem_process < mem_size) begin
		
		
			if (finished_propagation == 1 && mem_process == 0) begin
				mem_process =  1;
				read_node_score = 1;
				addr_score_sum_reg = 0;
                if (l_step % 2 == 0) begin		// 			
                    addr_score_reg = 1; // depending on L's value, the score table current propagation score's address alternate
                end else begin
                    addr_score_reg = 0; 
                end 
				
			end else if ((mem_process > 1 && mem_process < mem_size && write_node_score_sum == 1)) begin 
				write_node_score_sum = 0;
				read_node_score	= 1;
				addr_score_reg = addr_score_reg + 2; // plus 2 because of score table stores current & prev scoress
			end else if (mem_process > 0 && mem_process < mem_size && read_node_score == 1) begin
				read_node_score = 0;
				read_node_score_sum = 1;
			end else if (mem_process > 0 && mem_process < mem_size && read_node_score_sum == 1) begin
				read_node_score_sum = 0;
				write_node_score_sum = 1;
				mem_process = mem_process + 1;
			end
			
			
			
			
			
			if (read_node_score == 1) begin
				score_write_en <= 0; // score_write_en = 0 enables reading node's current propagation score; 
				#(period * 0.7) data_node_score_reg = data_in_score;
			
			end else if (read_node_score_sum == 1) begin
				score_write_sum_en_reg = 0;  // score_write_en = 0 enables reading node's score sum; 
				#(period * 0.7) data_node_score_sum_reg = data_in_score_sum;
			end else if (write_node_score_sum == 1) begin
				score_write_sum_en_reg = 1; // write score sum
				data_node_score_sum_reg = data_node_score_sum_reg + coeff1 * data_node_score_reg / coeff2; // sum up and calculate the latest score sum				
				#(period * 0.7) score_write_sum_en_reg = 0; // turn off write enable
				addr_score_sum_reg = addr_score_sum_reg + 1;

			end
			
			
			
			//if (mem_process == mem_size) begin
			//	mem_process = 0;
			//end
		
		
		end
	
	end
	
	
	
endmodule
