module l_step_count_octa #(parameter DATA_WIDTH = 32, max_steps = 7) ( 
	input clk,
	input finished1,
	input finished2,
	input finished3,
	input finished4,
	input finished5,
	input finished6,
	input finished7,
	input finished8,	
	input rst, // a reset flag that reset all operations; after lap > max_steps, rst needs to be set high by PS to reset everything
	
	output [DATA_WIDTH-1:0] l_step //
	
	);

	reg [DATA_WIDTH-1:0] l_step_reg = 0; 
	assign l_step = (rst == 1'b0)?  l_step_reg : {(DATA_WIDTH){1'b0}};
	
	always @(posedge clk) begin // need to double check if it should be posedge or negedge
		if (rst == 1'b0 && finished1 == 1'b1 && finished2 == 1'b1 && finished3 == 1'b1 && finished4 == 1'b1 && finished5 == 1'b1 && finished6 == 1'b1 && finished7 == 1'b1 && finished8 == 1'b1 && l_step_reg < max_steps) begin
			l_step_reg = l_step_reg + 1;
		end
	end



endmodule

	