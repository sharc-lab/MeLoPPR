

// DEPTH = 2^ADDR_WIDTH; 8192 = 2^13; DEPTH is the each BRAM_score_table size
// node_num means how many nodes in 1 bram_score_table
// lower_addr1 =0, upper_addr1 = 2^NODE_NUM - 1; lower_addr2 = 2^NODE_NUM, upper_addr2 = 2^(NODE_NUM*2)-1
// nei_table_offset is not used in here, need to remove it all all hierarchy
module top_dual_tb #(parameter period = 10, 
                                ADDR_WIDTH = 13, 
                                DEPTH = 8192, 
                                DATA_WIDTH = 32, 
                                nei_table_offset = 10, 
                                node_num = 2, 
                                max_steps = 100, 
                                lower_addr1=0, 
                                upper_addr1=3, 
                                lower_addr2=4, 
                                upper_addr2=7) ( 
    );
    integer data_file ; // file handler
	reg [DATA_WIDTH-1:0] memory_a [0:DEPTH-1], memory_b [0:DEPTH-1], memory_c [0:DEPTH-1], memory_d [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] data_in_reg;
    reg [ADDR_WIDTH-1:0] address_reg;
	
    integer i,j,k;
    reg clk, mask;

    wire [DATA_WIDTH-1:0] mem1_data_in_s, mem2_data_in_s, m1_data_in_g, m2_data_in_g, mem1_data_out_s, mem2_data_out_s;
    wire [DATA_WIDTH-1:0] mem1_data_to_bram_s, mem2_data_to_bram_s, m1_data_to_bram_g, m2_data_to_bram_g;
    reg [DATA_WIDTH-1:0] mem1_data_to_bram_reg_s, mem2_data_to_bram_reg_s, m1_data_to_bram_reg_g, m2_data_to_bram_reg_g;

    wire [ADDR_WIDTH-1:0] mem1_address_s, mem2_address_s, m1_address_g, m2_address_g;
    wire [ADDR_WIDTH-1:0] mem1_address_bram_s, mem2_address_bram_s, m1_address_bram_g, m2_address_bram_g;
    reg [ADDR_WIDTH-1:0] mem1_address_bram_reg_s, mem2_address_bram_reg_s, m1_address_bram_reg_g, m2_address_bram_reg_g;

    wire mem1_write_en, mem2_write_en, m1_write_enable_g, m2_write_enable_g, clk_diffusion_rw;
    wire mem1_write_enable_s, mem2_write_enable_s, m1_write_en_bram_g, m2_write_en_bram_g;
    reg mem1_write_enable_reg_s, mem2_write_enable_reg_s, m1_write_en_bram_reg_g, m2_write_en_bram_reg_g;


    top_dual #(.period(period), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .nei_table_offset(nei_table_offset), .node_num(node_num), .max_steps(max_steps), .lower_addr1(lower_addr1), .upper_addr1(upper_addr1), .lower_addr2(lower_addr2), .upper_addr2(upper_addr2)) top_dual_ins( 
    .clk(clk_diffusion_rw),
	.rdy_flag(mask),
    .mem1_data_in_s(mem1_data_in_s),
    .mem2_data_in_s(mem2_data_in_s),
    .m1_data_in_g(m1_data_in_g),
    .m2_data_in_g(m2_data_in_g),
    
    .mem1_address_s(mem1_address_s),
    .mem1_write_en(mem1_write_en),  
    .mem1_data_out_s(mem1_data_out_s),

    .mem2_address_s(mem2_address_s),
    .mem2_write_en(mem2_write_en),
    .mem2_data_out_s(mem2_data_out_s),

    .m1_address_g(m1_address_g),
    .m1_write_enable_g(m1_write_enable_g),

    .m2_address_g(m2_address_g),
    .m2_write_enable_g(m2_write_enable_g) //

    );

    // when mask == 1'b0, PS will write to subgraph and initial score to BRAM_subgraph and BRAM_score_table respectively
    assign clk_diffusion_rw = clk & mask;
	assign mem1_data_to_bram_s = (mask == 1'b0)? mem1_data_to_bram_reg_s : mem1_data_out_s;
	//assign data_out = (ready == 1'b0)? data_out_reg : {(DATA_WIDTH){1'bz}};
	assign mem1_write_enable_s = (mask == 1'b0)? mem1_write_enable_reg_s : mem1_write_en;
	assign mem1_address_bram_s = (mask == 1'b0)? mem1_address_bram_reg_s : mem1_address_s;


	assign mem2_data_to_bram_s = (mask == 1'b0)? mem2_data_to_bram_reg_s : mem2_data_out_s;
	assign mem2_write_enable_s = (mask == 1'b0)? mem2_write_enable_reg_s : mem2_write_en;
	assign mem2_address_bram_s = (mask == 1'b0)? mem2_address_bram_reg_s : mem2_address_s;


	assign m1_data_to_bram_g = (mask == 1'b0)? m1_data_to_bram_reg_g : {(DATA_WIDTH){1'bz}};
	assign m1_write_en_bram_g = (mask == 1'b0)? m1_write_en_bram_reg_g : m1_write_enable_g;
	assign m1_address_bram_g = (mask == 1'b0)? m1_address_bram_reg_g : m1_address_g;

	assign m2_data_to_bram_g = (mask == 1'b0)? m2_data_to_bram_reg_g : {(DATA_WIDTH){1'bz}};
	assign m2_write_en_bram_g = (mask == 1'b0)? m2_write_en_bram_reg_g : m2_write_enable_g;
	assign m2_address_bram_g = (mask == 1'b0)? m2_address_bram_reg_g : m2_address_g;


    bram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) bram_score_table_1 (
        .i_clk(clk),
        .i_addr(mem1_address_bram_s),
        .i_write(mem1_write_enable_s),
        .i_data(mem1_data_to_bram_s),
        .o_data(mem1_data_in_s));


    bram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) bram_score_table_2 (
        .i_clk(clk),
        .i_addr(mem2_address_bram_s),
        .i_write(mem2_write_enable_s),
        .i_data(mem2_data_to_bram_s),
        .o_data(mem2_data_in_s));


    bram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) bram_subgraph_1 (
        .i_clk(clk),
        .i_addr(m1_address_bram_g),
        .i_write(m1_write_en_bram_g), 
        .i_data(m1_data_to_bram_g),  // connect to PS; in the test bench here, the test bench will write the data in 
        .o_data(m1_data_in_g)); // connect to top_dual only, because PS will not read from it

    bram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) bram_subgraph_2 (
        .i_clk(clk),
        .i_addr(m2_address_bram_g),
        .i_write(m2_write_en_bram_g), 
        .i_data(m2_data_to_bram_g), 
        .o_data(m2_data_in_g));



    initial begin
        clk = 1;
        for (i=0; i < 1000000000; i=i+1) begin
            # (period/2) clk = ~clk;
        end

    end 

    initial begin
		$readmemh("C:/Users/Administrator/Downloads/bram_score_table_1.txt", memory_a);
		$readmemh("C:/Users/Administrator/Downloads/bram_score_table_2.txt", memory_b);
		$readmemh("C:/Users/Administrator/Downloads/bram_subgraph_1.txt", memory_c);
		$readmemh("C:/Users/Administrator/Downloads/bram_subgraph_2.txt", memory_d);
		
		mem1_data_to_bram_reg_s = 0;
		mem2_data_to_bram_reg_s = 0;
		m1_data_to_bram_reg_g = 0;
		m2_data_to_bram_reg_g = 0;
		#(period/2);
		mem1_address_bram_reg_s = 0;       
		mem2_address_bram_reg_s = 0; 
		m1_address_bram_reg_g = 0;
		m2_address_bram_reg_g = 0;
		for (j=0;j<DEPTH; j=j+1) begin
            mem1_data_to_bram_reg_s = memory_a[j];
            mem2_data_to_bram_reg_s = memory_b[j];
			m1_data_to_bram_reg_g = memory_c[j];
			m2_data_to_bram_reg_g = memory_d[j];

            #(period*2);
			mem1_address_bram_reg_s = mem1_address_bram_reg_s +1'b1; // address adds 1 every 2 periods because write and read will access the same address
            mem2_address_bram_reg_s = mem2_address_bram_reg_s +1'b1;
			m1_address_bram_reg_g = m1_address_bram_reg_g + 1'b1;
			m2_address_bram_reg_g = m2_address_bram_reg_g + 1'b1;			


	
		end

    end

    initial begin
        #(period/2);
		mem1_write_enable_reg_s = 1; // offset 90 degree
		mem2_write_enable_reg_s = 1;
		m1_write_en_bram_reg_g = 1;
		m2_write_en_bram_reg_g = 1;
        for (k=0; k< DEPTH; k = k+1) begin
            #(period);
			mem1_write_enable_reg_s = ~mem1_write_enable_reg_s; // write enable signal period is 2x of clock's because there will be 1 write and 1 read
			mem2_write_enable_reg_s = ~mem2_write_enable_reg_s; // write enable signal period is 2x of clock's because there will be 1 write and 1 read
			m1_write_en_bram_reg_g = ~m1_write_en_bram_reg_g;
			m2_write_en_bram_reg_g = ~m2_write_en_bram_reg_g;	    
		end        
    end   
	
	
	initial begin
        mask = 1'b0;
		#(period * DEPTH*2) mask = 1'b1;
	
	end

endmodule