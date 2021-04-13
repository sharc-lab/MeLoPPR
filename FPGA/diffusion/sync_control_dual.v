module sync_control_dual #(parameter DATA_WIDTH = 32, max_steps = 7) ( 
	input clk,
	input finished1,
	input finished2,
	input rst, // a reset flag that reset all operations; after lap > max_steps, rst needs to be set high by PS to reset everything
	
	output rdy1,
	output rdy2, //
	output reg finished_all,
	output [DATA_WIDTH-1:0] l_step //
	
	);

	reg [DATA_WIDTH-1:0] l_step_reg = 0; 
	assign l_step = (rst == 1'b0)?  l_step_reg : {(DATA_WIDTH){1'b0}};
	assign rdy1 = (rst == 1'b0)?  (~((finished1 & finished2) ^ finished1)) : {1'b0};
	assign rdy2 = (rst == 1'b0)?  (~((finished1 & finished2) ^ finished2)) : {1'b0};
	//assign finished_all = finished1 & finished2;
	
	always @(posedge clk) begin // need to double check if it should be posedge or negedge
		if (rst == 1'b0 && finished1 == 1'b1 && finished2 == 1'b1 && l_step_reg < max_steps) begin
			l_step_reg = l_step_reg + 1;
		end
		finished_all <= finished1 & finished2;
		//if (l_step_reg == max_steps) begin
		//	l_step_reg = 0;
		//end
	end



endmodule

	
