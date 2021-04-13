module diffusion_rw_tb #(parameter period = 10, ADDR_WIDTH = 13, DATA_WIDTH = 32, nei_table_offset = 10, node_num = 1, node_offset = 0, max_steps = 7) ( 
    );

    reg [DATA_WIDTH-1:0] l_step=0;
    reg rdy1 = 0;
    reg clk;
    reg [DATA_WIDTH-1:0] m1_data_in_s, m1_data_in_g;
    
    wire [DATA_WIDTH-1:0] m1_data_out_s;
    wire [ADDR_WIDTH-1:0] m1_address_s, m1_address_g;
    wire m1_write_enable_g, m1_write_enable_s;
    wire finished1; 
	integer i;

    diffusion_rw #(.period(period), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .nei_table_offset(nei_table_offset), .node_num(node_num), .node_offset(node_offset), .max_steps(max_steps)) M1 ( 
    .conflict(1'b0),
    .clk(clk), 
    .data_in_s(m1_data_in_s),
    .data_in_g(m1_data_in_g),
    .l_step(l_step),
    .rdy(rdy1),

    .data_out_s(m1_data_out_s), 
    .address_g(m1_address_g), 
    .address_s(m1_address_s), 
    .write_enable_g(m1_write_enable_g),
    .write_enable_s(m1_write_enable_s),
    .finished(finished1) //
    );


    initial begin
        clk  = 0;
		for(i=0; i < 100; i=i+1) begin
			#(period/2) clk = ~clk;
		end

    end

    initial begin
        m1_data_in_s = 0;
        #(period*1.5);
        m1_data_in_s = 10;
        m1_data_in_g = 20;

        #period;
        m1_data_in_g = 21;
        #period;
        m1_data_in_g = 2;
        #period;
        m1_data_in_s = 100;
		#period;
        m1_data_in_s = 10;
		
    end
	
	initial begin
		#(period*0.7); 
		rdy1 = 1;
	
	end
	
	initial begin
		#(period * 8.5) l_step = l_step + 1;
	
	end

endmodule
