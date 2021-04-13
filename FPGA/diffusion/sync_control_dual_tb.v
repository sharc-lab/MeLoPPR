module sync_control_dual_tb #(parameter period =10 ,DATA_WIDTH = 32, max_steps = 7) ( 
	);

    integer i, j;
    reg clk, finished1, finished2, rst;
    wire [DATA_WIDTH-1:0] l_step;

    sync_control_dual #(.DATA_WIDTH(DATA_WIDTH), .max_steps(max_steps)) lap_control( 
	.clk(clk),
	.finished1(finished1),
	.finished2(finished2),
	.rst(rst), // a reset flag that reset all operations; after lap > max_steps, rst needs to be set high by PS to reset everything
	
	.rdy1(rdy1),
	.rdy2(rdy2), //
	.l_step(l_step) //
	);


    initial begin
        clk = 0;
        for (i=1; i<100; i= i+1) begin
            #(period/2) clk = ~clk; 
        end
    end


    initial begin

        rst = 0;
		for(j=0; j< 10; j=j+1) begin
            finished1 = 0;
            finished2 = 0;
        
            # period;
            finished1 = 1;

            # period;
            finished2 = 1;

            # period;
        end
    end
	
	initial begin
		#(period * 100) rst = 1;
	end


endmodule
