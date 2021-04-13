 module Divide(  
   input      clk,  
       input                     reset,  
   input      start,  
   input [31:0]  A,  
   input [31:0]  B,  
   output [31:0]  D,  
   output [31:0]  R,  
   output     ok ,   // =1 when ready to get the result   
       output err  
   );  
   reg       active;   // True if the divider is running  
   reg [4:0]    cycle;   // Number of cycles to go  
   reg [31:0]   result;   // Begin with A, end with D  
   reg [31:0]   denom;   // B  
   reg [31:0]   work;    // Running R  
   // Calculate the current digit  
   wire [32:0]   sub = { work[30:0], result[31] } - denom;  
   reg ok_reg = 0;
       assign err = !B;  
   // Send the results to our master  
   assign D = result;  
   assign R = work;  
 // fpga4student.com FPGA projects, Verilog projects, VHDL projects   
   // The state machine  
   always @(posedge clk,posedge reset) begin  
	if (ok == 1) begin
		ok_reg <=0 ;
        cycle <= 5'd31;  
	end     
	
	if (reset) begin  
       active <= 0;  
       cycle <= 0;  
       result <= 0;  
       denom <= 0;  
       work <= 0;  
     end  
     if(start) begin  
         cycle <= 5'd31;  
         result <= A;  
         denom <= B;  
         work <= 32'b0;  
         active <= 1;  	 
	 end  

       if (active) begin  
         // Run an iteration of the divide.  
         if (sub[32] == 0) begin  
           work <= sub[31:0];  
           result <= {result[30:0], 1'b1};  
         end  
         else begin  
           work <= {work[30:0], result[31]};  
           result <= {result[30:0], 1'b0};  
         end  
         if (cycle == 0) begin  
           active <= 0;  
         end else begin
			cycle <= cycle - 5'd1; 
		 end
       end  
	 if (cycle == 0 && ok == 0) begin
		ok_reg <= 1;
	 end
   end

	assign ok = ok_reg;
   
 endmodule  
