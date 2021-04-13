module scheduler_dual #(parameter ADDR_WIDTH = 13, DATA_WIDTH = 32, lower_addr = 0, upper_addr = 4) ( 
	input clk,
	input [DATA_WIDTH-1:0] data_mem, // input from BRAM memory

	input [ADDR_WIDTH-1:0] addrA,
	input [ADDR_WIDTH-1:0] addrB,

	input [DATA_WIDTH-1:0] dataA,
	input [DATA_WIDTH-1:0] dataB,

	input write_enA,
	input write_enB,

	output [DATA_WIDTH-1:0] data, // goes out to bram memory
	output [ADDR_WIDTH-1:0] addr, // addr goes out to bram memory
	output [DATA_WIDTH-1:0] dataMA, // goes out to verilog M module
	output [DATA_WIDTH-1:0] dataMB,


	output write_mem_en,


	output reg conflict_b //

	);


	wire conflict_AB;
	reg selA = 1'b0, selB = 1'b0;

	assign dataMA = (selA == 1'b1)? data_mem: {(DATA_WIDTH){1'bz}};
	assign data = (selA == 1'b1)? dataA: {(DATA_WIDTH){1'bz}};
	assign addr = (selA == 1'b1)? addrA-lower_addr: {(ADDR_WIDTH){1'bz}};
	assign write_mem_en = (selA == 1'b1)? write_enA: {1'bz};

	assign dataMB = (selB == 1'b1)? data_mem: {(DATA_WIDTH){1'bz}};
	assign data = (selB == 1'b1)? dataB: {(DATA_WIDTH){1'bz}};
	assign addr = (selB == 1'b1)? addrB-lower_addr: {(ADDR_WIDTH){1'bz}};
	assign write_mem_en = (selB == 1'b1)? write_enB: {1'bz};


	conflict_block #(.ADDR_WIDTH(13), .lower_addr(lower_addr), .upper_addr(upper_addr)) conflict_ins_AB (
		.clk(clk),
		.addrA(addrA),
		.addrB(addrB), 
		.conflict(conflict_AB)
	);

	
	//reg first_second_half_reg;    
	always @(*) begin

		if ((addrA >= lower_addr && addrA <= upper_addr) || (addrB >= lower_addr && addrB <= upper_addr)) begin

			// there is conflict, priority M1 > M2 > M3 > M4
				
			if (addrA >= lower_addr && addrA <= upper_addr) begin
					selA = 1'b1;
					selB = 1'b0;
			end else if (addrB >= lower_addr && addrB <= upper_addr) begin
					selA = 1'b0;
					selB = 1'b1;

			end

		end else begin // if not even one addr is within address boundary, no one is selected
			selA = 1'b0;
			selB = 1'b0;
		end 

		conflict_b <= conflict_AB;

	end


endmodule