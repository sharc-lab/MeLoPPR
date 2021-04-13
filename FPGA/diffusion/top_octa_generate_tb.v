

// DEPTH = 2^ADDR_WIDTH; 8192 = 2^13; DEPTH is the each BRAM_score_table size
// node_num means how many nodes in 1 bram_score_table
// lower_addr1 =0, upper_addr1 = 2^NODE_NUM - 1; lower_addr2 = 2^NODE_NUM, upper_addr2 = 2^(NODE_NUM*2)-1
// nei_table_offset is not used in here, need to remove it all all hierarchy
module top_octa_generate_tb #(parameter period = 10, 
                                ADDR_WIDTH = 13, 
                                DEPTH = 8192, 
                                DATA_WIDTH = 32, 
                                nei_table_offset = 10, 
                                node_num = 339, 
								last_node_num = 335,
                                max_steps = 7, 
								PARALLEL = 8) ( 
    );
    integer data_file ; // file handler

	reg [DATA_WIDTH-1:0] memory_score_1 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_2 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_3 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_4 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_5 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_6 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_7 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_8 [0:DEPTH-1];


	reg [DATA_WIDTH-1:0] memory_subgraph_1 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_subgraph_2 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_subgraph_3 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_subgraph_4 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_subgraph_5 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_subgraph_6 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_subgraph_7 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_subgraph_8 [0:DEPTH-1];


	reg [DATA_WIDTH-1:0] memory_score_sum_1 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_sum_2 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_sum_3 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_sum_4 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_sum_5 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_sum_6 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_sum_7 [0:DEPTH-1];
	reg [DATA_WIDTH-1:0] memory_score_sum_8 [0:DEPTH-1];


	
    integer i,j,k;
	integer p, q, r;
	integer l, m, n;
    reg clk, mask;

	wire clk_diffusion_rw;

	
	genvar a, b;
	wire [ADDR_WIDTH-1:0] mem_address_bram_s [0:PARALLEL-1], m_address_bram_g [0:PARALLEL-1];
	wire mem_write_enable_s [0:PARALLEL-1], m_write_en_bram_g [0:PARALLEL-1];
	wire [DATA_WIDTH-1:0] mem_data_to_bram_s [0:PARALLEL-1], m_data_to_bram_g [0:PARALLEL-1];
	wire  [DATA_WIDTH*PARALLEL-1:0] mem_data_in_s, m_data_in_g;
    reg [DATA_WIDTH-1:0] mem_data_to_bram_reg_s[0:PARALLEL-1],  m_data_to_bram_reg_g [0:PARALLEL-1];
    reg [ADDR_WIDTH-1:0] mem_address_bram_reg_s[0:PARALLEL-1], m_address_bram_reg_g [0:PARALLEL-1];
    reg mem_write_enable_reg_s[0:PARALLEL-1], m_write_en_bram_reg_g[0:PARALLEL-1];
	
	wire  [ADDR_WIDTH*PARALLEL-1:0] mem_address_s, m_address_g;
	wire [DATA_WIDTH*PARALLEL-1:0] mem_data_out_s;
	wire [PARALLEL-1:0] mem_write_en, m_write_enable_g;


	/////////////// adds up scores Nov 11 2021 //////////////////
	integer  s, t, u, v, w;
	integer x, y, z;
	reg [ADDR_WIDTH-1:0] mem_addr_score_sum_t [0:PARALLEL-1];
	reg mem_score_write_sum_en_t [0:PARALLEL-1];
	reg [DATA_WIDTH-1:0] mem_data_out_score_out_sum_t [0:PARALLEL-1];
	
	wire [DATA_WIDTH*PARALLEL-1:0] mem_data_out_score_out_sum;
	wire [ADDR_WIDTH*PARALLEL-1:0] mem_addr_score_sum;
	wire [DATA_WIDTH*PARALLEL-1:0] mem_data_in_score_sum;
	wire [PARALLEL-1:0] mem_score_write_sum_en;

	wire [ADDR_WIDTH-1:0] mem_addr_score_sum_f [0:PARALLEL-1];
	wire mem_score_write_sum_en_f [0:PARALLEL-1];
	wire [DATA_WIDTH-1:0] mem_data_out_score_out_sum_f [0:PARALLEL-1];
	
	reg [DATA_WIDTH-1:0] memory_sum_a [0:DEPTH/2-1], memory_sum_b [0:DEPTH/2-1], memory_sum_c [0:DEPTH/2-1], memory_sum_d [0:DEPTH/2-1];

	///////////////////////////////////////////////////////////////////



	top_octa_generate #(.period(period), .DEPTH(DEPTH), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .nei_table_offset(nei_table_offset), .node_num(node_num), .last_node_num(last_node_num), .max_steps(max_steps), .PARALLEL(PARALLEL)) top_octa_ins( 
		.clk(clk_diffusion_rw),
		.rdy_flag(mask),
		.mem_data_in_s(mem_data_in_s),
		.m_datain_g(m_data_in_g),
		.mem_data_in_score_sum(mem_data_in_score_sum),

		
		.mem_address_s(mem_address_s),
		.mem_write_en(mem_write_en),  
		.mem_data_out_s(mem_data_out_s),
		.m_addr_g(m_address_g),
		.m_write_en_g(m_write_enable_g),

		.mem_addr_score_sum(mem_addr_score_sum),
		.mem_data_out_score_out_sum(mem_data_out_score_out_sum),
		.mem_score_write_sum_en(mem_score_write_sum_en)	//

    );

    // when mask == 1'b0, PS will write to subgraph and initial score to BRAM_subgraph and BRAM_score_table respectively
    assign clk_diffusion_rw = clk & mask;
	//assign data_out = (ready == 1'b0)? data_out_reg : {(DATA_WIDTH){1'bz}};


	generate
		for (a=0; a < PARALLEL; a = a+1) begin
			
			assign mem_data_to_bram_s[a] = (mask == 1'b0)? mem_data_to_bram_reg_s[a] : mem_data_out_s[a*DATA_WIDTH+DATA_WIDTH-1:a*DATA_WIDTH];
			assign mem_write_enable_s[a] = (mask == 1'b0)? mem_write_enable_reg_s[a] : mem_write_en[a];
			assign mem_address_bram_s[a] = (mask == 1'b0)? mem_address_bram_reg_s[a] : mem_address_s[a*ADDR_WIDTH+ADDR_WIDTH-1:a*ADDR_WIDTH];

			assign m_data_to_bram_g[a] = (mask == 1'b0)? m_data_to_bram_reg_g[a] : {(DATA_WIDTH){1'bz}};
			assign m_write_en_bram_g[a] = (mask == 1'b0)? m_write_en_bram_reg_g[a] : m_write_enable_g[a];
			assign m_address_bram_g[a] = (mask == 1'b0)? m_address_bram_reg_g[a] : m_address_g[a*ADDR_WIDTH+ADDR_WIDTH-1:a*ADDR_WIDTH];

			/////////// adds up score Nov 14 2021 ///////////////////////////
			assign mem_addr_score_sum_f[a] = (mask == 1'b0)? mem_addr_score_sum_t[a] : mem_addr_score_sum[a*ADDR_WIDTH+ADDR_WIDTH-1:a*ADDR_WIDTH];
			assign mem_score_write_sum_en_f[a] = (mask == 1'b0)? mem_score_write_sum_en_t[a] : mem_score_write_sum_en[a];
			assign mem_data_out_score_out_sum_f[a] = (mask == 1'b0)? mem_data_out_score_out_sum_t[a] : mem_data_out_score_out_sum[a*DATA_WIDTH+DATA_WIDTH-1:a*DATA_WIDTH];
			/////////////////////////////////////////////////////////////////

			
			bram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) bram_score_table (
				.i_clk(clk),
				.i_addr(mem_address_bram_s[a]),
				.i_write(mem_write_enable_s[a]),
				.i_data(mem_data_to_bram_s[a]),
				.o_data(mem_data_in_s[a*DATA_WIDTH+DATA_WIDTH-1:a*DATA_WIDTH]));




			bram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) bram_subgraph (
				.i_clk(clk),
				.i_addr(m_address_bram_g[a]),
				.i_write(m_write_en_bram_g[a]), 
				.i_data(m_data_to_bram_g[a]),  // connect to PS; in the test bench here, the test bench will write the data in 
				.o_data(m_data_in_g[a*DATA_WIDTH+DATA_WIDTH-1:a*DATA_WIDTH])); //

			/////////// adds up score Nov 14 2021 ///////////////////////////

			bram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH/2)) bram_score_sum_table (
				.i_clk(clk),
				.i_addr(mem_addr_score_sum_f[a]),
				.i_write(mem_score_write_sum_en_f[a]),
				.i_data(mem_data_out_score_out_sum_f[a]),
				.o_data(mem_data_in_score_sum[a*DATA_WIDTH+DATA_WIDTH-1:a*DATA_WIDTH])); // data out from bram_sum table is only accessed by add_up module
			/////////////////////////////////////////////////////////////////
		end	
	endgenerate




    initial begin
        clk = 1;
        for (i=0; i < 1000000000; i=i+1) begin
            # (period/2) clk = ~clk;
        end

    end 

    initial begin
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_1.txt", memory_score_1);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_2.txt", memory_score_2);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_3.txt", memory_score_3);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_4.txt", memory_score_4);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_5.txt", memory_score_5);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_6.txt", memory_score_6);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_7.txt", memory_score_7);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_8.txt", memory_score_8);


		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_subgraph_1.txt", memory_subgraph_1);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_subgraph_2.txt", memory_subgraph_2);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_subgraph_3.txt", memory_subgraph_3);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_subgraph_4.txt", memory_subgraph_4);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_subgraph_5.txt", memory_subgraph_5);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_subgraph_6.txt", memory_subgraph_6);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_subgraph_7.txt", memory_subgraph_7);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_subgraph_8.txt", memory_subgraph_8);

		
		for (p=0; p < PARALLEL; p=p+1) begin
			mem_data_to_bram_reg_s[p] = 0;
			m_data_to_bram_reg_g[p] = 0;
			
		end
		

		#(period/2);
		
		for (q=0; q < PARALLEL; q=q+1) begin		
			mem_address_bram_reg_s[q] = 0;       
			m_address_bram_reg_g[q] = 0;

		end 

		for (j=0;j<DEPTH; j=j+1) begin
            mem_data_to_bram_reg_s[0] = memory_score_1[j];
            mem_data_to_bram_reg_s[1] = memory_score_2[j];
            mem_data_to_bram_reg_s[2] = memory_score_3[j];
            mem_data_to_bram_reg_s[3] = memory_score_4[j];
            mem_data_to_bram_reg_s[4] = memory_score_5[j];
            mem_data_to_bram_reg_s[5] = memory_score_6[j];
            mem_data_to_bram_reg_s[6] = memory_score_7[j];
            mem_data_to_bram_reg_s[7] = memory_score_8[j];


            m_data_to_bram_reg_g[0] = memory_subgraph_1[j];
            m_data_to_bram_reg_g[1] = memory_subgraph_2[j];
            m_data_to_bram_reg_g[2] = memory_subgraph_3[j];
            m_data_to_bram_reg_g[3] = memory_subgraph_4[j];
            m_data_to_bram_reg_g[4] = memory_subgraph_5[j];
            m_data_to_bram_reg_g[5] = memory_subgraph_6[j];
            m_data_to_bram_reg_g[6] = memory_subgraph_7[j];
            m_data_to_bram_reg_g[7] = memory_subgraph_8[j];

			
            #(period*2);
			
			for (r=0; r < PARALLEL; r=r+1) begin		
				mem_address_bram_reg_s[r] = mem_address_bram_reg_s[r] +1'b1; // address adds 1 every 2 periods because write and read will access the same address
				m_address_bram_reg_g[r] = m_address_bram_reg_g[r] + 1'b1;
			end 

	
		end

    end

    initial begin
        #(period/2);
		for (l=0; l < PARALLEL; l=l+1) begin		
			mem_write_enable_reg_s[l] = 1; // offset 90 degree
			m_write_en_bram_reg_g[l] = 1;

		end 

        for (k=0; k< DEPTH; k = k+1) begin
            #(period);
			
			for (m=0; m < PARALLEL; m=m+1) begin		
				mem_write_enable_reg_s[m] = ~mem_write_enable_reg_s[m]; // write enable signal period is 2x of clock's because there will be 1 write and 1 read
				m_write_en_bram_reg_g[m] = ~m_write_en_bram_reg_g[m];
			end 

		end        
    end   
	
	
	initial begin
        mask = 1'b0;
		#(period * DEPTH*2) mask = 1'b1;
	
	end


	/////////// adds up score Nov 14 2021 ///////////////////////////
	
    initial begin
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_1.txt", memory_score_sum_1);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_2.txt", memory_score_sum_2);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_3.txt", memory_score_sum_3);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_4.txt", memory_score_sum_4);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_5.txt", memory_score_sum_5);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_6.txt", memory_score_sum_6);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_7.txt", memory_score_sum_7);
		$readmemh("C:/Users/Administrator/Downloads/bram_octa_cora_score_table_8.txt", memory_score_sum_8);

		

		for (u=0; u< PARALLEL; u = u+1) begin
			mem_data_out_score_out_sum_t[u] = 0;
		end

		#(period/2);
		for (v=0; v< PARALLEL; v = v+1) begin
			mem_addr_score_sum_t[v] = 0;       
		end

		for (w=0;w<DEPTH/2; w=w+1) begin
			for (x=0; x< PARALLEL; x = x+1) begin
            	mem_data_out_score_out_sum_t[x] = memory_sum_a[x*2];
			end

            #(period*2);
			for (y=0; y< PARALLEL; y = y+1) begin
				mem_addr_score_sum_t[y] = mem_addr_score_sum_t[y] +1'b1; // address adds 1 every 2 periods because write and read will access the same address
			end

		end

    end
	
	
    initial begin
        #(period/2);
		for (s=0; s< PARALLEL; s = s+1) begin
			mem_score_write_sum_en_t[s] = 1; // offset 90 degree
		end 

        for (t=0; t< DEPTH/2; t = t+1) begin
            #(period);
			for (z=0; z< PARALLEL; z = z+1) begin
				mem_score_write_sum_en_t[z] = ~mem_score_write_sum_en_t[z]; // write enable signal period is 2x of clock's because there will be 1 write and 1 read
			end
		end        
    end   

	////////////////////////////////////////////////

endmodule