module scheduler_generate_octa #(parameter ADDR_WIDTH = 13, PARALLEL=8, DATA_WIDTH = 32, lower_addr = 0, upper_addr = 4) ( 
    input clk,
    input [DATA_WIDTH-1:0] data_mem,
    input [ADDR_WIDTH*PARALLEL-1:0] addrFM, // from verilog M module
    input [DATA_WIDTH*PARALLEL-1:0] dataFM,  // from verilog M module
    input [PARALLEL-1:0] write_en,

    output [DATA_WIDTH-1:0] data, // goes out to bram memory
    output [ADDR_WIDTH-1:0] addr, // addr goes out to bram memory
    output [DATA_WIDTH*PARALLEL-1:0] dataM, // goes out to verilog M module


	output write_mem_en,

    output [PARALLEL-1:0] conflict


    );


    wire conflict_AB, conflict_AC, conflict_AD, conflict_BC, conflict_BD, conflict_CD;
    reg selA = 1'b0, selB = 1'b0, selC = 1'b0, selD = 1'b0;
	
	////////////// nov 15 generate /////////
	wire [PARALLEL-1:0] conflict_intermediate [0:PARALLEL-1];
	wire [ADDR_WIDTH-1:0] addr_FM [0:PARALLEL-1];
	wire [DATA_WIDTH-1:0] data_FM [0:PARALLEL-1];

	reg sel[0:PARALLEL-1]; // can't assing 4'b0000 like this .... it will cause functional error
	reg [PARALLEL-1:0] conflict_final = 0;

	//////////////
	



	genvar i,j,k;
	genvar a, b;	


	generate
		for (a=0; a < PARALLEL-1; a = a+1) begin

			for (b=a+1; b < PARALLEL; b = b+1) begin
			
				conflict_block #(.ADDR_WIDTH(ADDR_WIDTH), .lower_addr(lower_addr), .upper_addr(upper_addr)) conflict_ins (
					.clk(clk),
					.addrA(addr_FM[a]),
					.addrB(addr_FM[b]), 
					.conflict(conflict_intermediate[a][b])
				);			
				
			end
	
		end
		
	endgenerate
	
	////////////// nov 15 generate /////////
	
	
	generate
		for (i=0; i < PARALLEL; i = i+1) begin	
			assign addr_FM[i] = addrFM[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH];
			assign data_FM[i] = dataFM[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];

			assign dataM[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = (sel[i] == 1'b1)? data_mem: {(DATA_WIDTH){1'bz}};
			assign data = (sel[i] == 1'b1)? data_FM[i]: {(DATA_WIDTH){1'bz}};
			assign addr = (sel[i] == 1'b1)? addr_FM[i]-lower_addr: {(ADDR_WIDTH){1'bz}};
			assign write_mem_en = (sel[i] == 1'b1)? write_en[i]: {1'bz};
		end
		
	endgenerate
	////////////////////////////////////////



    //reg first_second_half_reg;    
    always @(*) begin

		if ((addr_FM[0] >= lower_addr && addr_FM[0] <= upper_addr) || (addr_FM[1] >= lower_addr && addr_FM[1] <= upper_addr) || (addr_FM[2] >= lower_addr && addr_FM[2] <= upper_addr) || (addr_FM[3] >= lower_addr && addr_FM[3] <= upper_addr )
		||  (addr_FM[4] >= lower_addr && addr_FM[4] <= upper_addr) ||(addr_FM[5] >= lower_addr && addr_FM[5] <= upper_addr) || (addr_FM[6] >= lower_addr && addr_FM[6] <= upper_addr) || (addr_FM[7] >= lower_addr && addr_FM[7] <= upper_addr)) begin

            // there is conflict, priority M1 > M2 > M3 > M4
                
                if (addr_FM[0] >= lower_addr && addr_FM[0] <= upper_addr) begin
					sel[0] = 1'b1;
					sel[1] = 1'b0;
					sel[2] = 1'b0;
					sel[3] = 1'b0;
					sel[4] = 1'b0;
					sel[5] = 1'b0;
					sel[6] = 1'b0;					
					sel[7] = 1'b0;

										
                end else if (addr_FM[1] >= lower_addr && addr_FM[1] <= upper_addr) begin
					sel[0] = 1'b0;
					sel[1] = 1'b1;
					sel[2] = 1'b0;
					sel[3] = 1'b0;
					sel[4] = 1'b0;
					sel[5] = 1'b0;
					sel[6] = 1'b0;					
					sel[7] = 1'b0;

				end else if (addr_FM[2] >= lower_addr && addr_FM[2] <= upper_addr) begin
					sel[0] = 1'b0;
					sel[1] = 1'b0;
					sel[2] = 1'b1;
					sel[3] = 1'b0;
					sel[4] = 1'b0;
					sel[5] = 1'b0;
					sel[6] = 1'b0;					
					sel[7] = 1'b0;
        
				end else if (addr_FM[3] >= lower_addr && addr_FM[3] <= upper_addr) begin
					sel[0] = 1'b0;
					sel[1] = 1'b0;
					sel[2] = 1'b0;
					sel[3] = 1'b1;
					sel[4] = 1'b0;
					sel[5] = 1'b0;
					sel[6] = 1'b0;					
					sel[7] = 1'b0;

                end else if (addr_FM[4] >= lower_addr && addr_FM[4] <= upper_addr) begin
					sel[0] = 1'b0;
					sel[1] = 1'b0;
					sel[2] = 1'b0;
					sel[3] = 1'b0;
					sel[4] = 1'b1;
					sel[5] = 1'b0;
					sel[6] = 1'b0;					
					sel[7] = 1'b0;


                end else if (addr_FM[5] >= lower_addr && addr_FM[5] <= upper_addr) begin
					sel[0] = 1'b0;
					sel[1] = 1'b0;
					sel[2] = 1'b0;
					sel[3] = 1'b0;
					sel[4] = 1'b0;
					sel[5] = 1'b1;
					sel[6] = 1'b0;					
					sel[7] = 1'b0;


                end else if (addr_FM[6] >= lower_addr && addr_FM[6] <= upper_addr) begin
					sel[0] = 1'b0;
					sel[1] = 1'b0;
					sel[2] = 1'b0;
					sel[3] = 1'b0;
					sel[4] = 1'b0;
					sel[5] = 1'b0;
					sel[6] = 1'b1;					
					sel[7] = 1'b0;


                end else if (addr_FM[7] >= lower_addr && addr_FM[7] <= upper_addr) begin
					sel[0] = 1'b0;
					sel[1] = 1'b0;
					sel[2] = 1'b0;
					sel[3] = 1'b0;
					sel[4] = 1'b0;
					sel[5] = 1'b0;
					sel[6] = 1'b0;					
					sel[7] = 1'b1;


                end



        end else begin // if not even one addr is within address boundary, no one is selected
					sel[0] = 1'b0;
					sel[1] = 1'b0;
					sel[2] = 1'b0;
					sel[3] = 1'b0;
					sel[4] = 1'b0;
					sel[5] = 1'b0;
					sel[6] = 1'b0;					
					sel[7] = 1'b0;

        end   
	
	////////////// nov 15 generate /////////

		conflict_final[0] <= 1'b0;
		conflict_final[1] <= conflict_intermediate[0][1];
		conflict_final[2] <= conflict_intermediate[0][2] | conflict_intermediate[1][2];
		conflict_final[3] <= conflict_intermediate[0][3] | conflict_intermediate[1][3] | conflict_intermediate[2][3];
		conflict_final[4] <= conflict_intermediate[0][4] | conflict_intermediate[1][4] | conflict_intermediate[2][4] | conflict_intermediate[3][4];
		conflict_final[5] <= conflict_intermediate[0][5] | conflict_intermediate[1][5] | conflict_intermediate[2][5] | conflict_intermediate[3][5] | conflict_intermediate[4][5];
		conflict_final[6] <= conflict_intermediate[0][6] | conflict_intermediate[1][6] | conflict_intermediate[2][6] | conflict_intermediate[3][6] | conflict_intermediate[4][6] | conflict_intermediate[5][6];
		conflict_final[7] <= conflict_intermediate[0][7] | conflict_intermediate[1][7] | conflict_intermediate[2][7] | conflict_intermediate[3][7] | conflict_intermediate[4][7] | conflict_intermediate[5][7] | conflict_intermediate[6][7];
	
		//conflict_final = {conflict_intermediate[0][3] | conflict_intermediate[1][3] | conflict_intermediate[2][3], conflict_intermediate[0][2] | conflict_intermediate[1][2], conflict_intermediate[0][1], 1'b0};
	////////////////////////////////////////

    end
	
	
	////////////// nov 15 generate /////////
	assign conflict = conflict_final;
	////////////////////////////////////////

endmodule