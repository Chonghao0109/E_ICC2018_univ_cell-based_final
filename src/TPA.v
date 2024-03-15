module TPA(clk, reset_n, 
	   SCL, SDA, 
	   cfg_req, cfg_rdy, cfg_cmd, cfg_addr, cfg_wdata, cfg_rdata
);
	input 		clk; 
	input 		reset_n;
	// Two-Wire Protocol slave interface 
	input 		SCL;  
	inout			SDA;

	// Register Protocal Master interface 
	input									cfg_req;
	output reg						cfg_rdy;
	input									cfg_cmd;
	input				[7:0]			cfg_addr;
	input				[15:0]		cfg_wdata;
	output reg 	[15:0]  	cfg_rdata;

	reg	[15:0] Register_Spaces	[0:255];




	// TWP 
	
	reg [7:0] TWP_addr;
	reg [15:0] TWP_wdata;
	reg TWP_wreq;

	reg [3:0] TWP_state;
	reg [3:0] TWP_state_counter;
	
	reg TWP_mode;

	parameter WAIT_START		=	0;
	parameter MODE_SELECT		=	1;
	parameter READ_ADDR			=	2;
	parameter WRITE_DATA		=	3;
	parameter ADDR_FINISH 	= 4;
	parameter S2M						= 5;
	parameter MASTER_SET		= 6;
	parameter MASTER_START	= 7;
	parameter READ_DATA	 		= 8;
	parameter MASTER_FINISH = 9;
	parameter M2S						= 10;



	wire 	SDAi;
	reg 	SDAo;
	
	assign SDA = (TWP_state>=MASTER_SET && TWP_state <= MASTER_FINISH) ? SDAo : 1'bz; 

	assign SDAi = SDA;

	always@(posedge clk or negedge reset_n)begin
		if(!reset_n)begin
			TWP_state <= WAIT_START;
			TWP_state_counter <= 0;
			TWP_wreq <= 0;
		end
		else begin
				case(TWP_state)
					
					
					WAIT_START:begin
						TWP_wreq <= 0;
						if(!SDA) TWP_state <= MODE_SELECT;
					end
					
					
					MODE_SELECT:begin
						TWP_state <= READ_ADDR;
						TWP_state_counter <= 0;
						TWP_mode <= SDAi;
					end
					
					
					READ_ADDR:begin
						TWP_addr[TWP_state_counter] <= SDA;
						if(TWP_state_counter == 7)begin
							TWP_state <=(TWP_mode) ? WRITE_DATA : ADDR_FINISH;
							TWP_state_counter <= 0;
							TWP_wdata <= 0;
						end
						else TWP_state_counter <= TWP_state_counter+1;
					end
					
					
					WRITE_DATA:begin
						TWP_wdata[TWP_state_counter] <= SDA;
						if(TWP_state_counter == 15)begin
							TWP_wreq <= 1;		
							TWP_state <= WAIT_START;
							TWP_state_counter <= 0;
							//#1 $display("Write ADDR:%d DATA:%h",TWP_addr,TWP_wdata);
						end
						else TWP_state_counter <= TWP_state_counter+1;
					end





					ADDR_FINISH:begin
						TWP_state <= S2M;
					end
					
					
					
					S2M:begin
						TWP_state <= MASTER_SET;
					end
					
					
					
					MASTER_SET:begin
						TWP_state <= MASTER_START;
					end

					
					
					MASTER_START:begin
						//$display("READ ADDR:%d DATA:%h",TWP_addr,Register_Spaces[TWP_addr]);
						TWP_state <= READ_DATA ;
						TWP_state_counter <= 0;
					end
					
					
					
					READ_DATA:begin
						if(TWP_state_counter == 15)begin
							TWP_state <= MASTER_FINISH;
							TWP_state_counter <= 0;
						end
						else TWP_state_counter <= TWP_state_counter + 1;
					end
					
					
					
					
					MASTER_FINISH:begin
						TWP_state <= WAIT_START;
					end
					
					
					



				endcase
		end
	end

	

	always@(*)begin
		case(TWP_state)
			MASTER_SET:begin
				SDAo <= 1;
			end
			MASTER_START:begin
				SDAo <= 0;
			end
			READ_DATA:begin
				SDAo <= Register_Spaces[TWP_addr][TWP_state_counter];
			end
			MASTER_FINISH:begin
				SDAo <= 0;
			end
			default SDAo <= 1'bz;
		endcase
	end












	// Arbiter

	reg [2:0] arbiter_state;

	parameter ARBITER_WAIT_INIS 	=		0;
	parameter ARBITER_GET					=		1;
	parameter ARBITER_FINISH			=		2;
	
	//assign cfg_rdy = arbiter_state==IDLE ? 0:1;
	
	reg [15:0] data_buffer;
	reg [7:0] addr_buffer;
	reg w_buffer;
	always@(posedge clk or negedge reset_n)begin : Arbiter
		if(!reset_n)begin
			arbiter_state <= ARBITER_WAIT_INIS;			
			cfg_rdy <= 0;
		end
		else begin
			case(arbiter_state)
				
				
				
				ARBITER_WAIT_INIS:begin
					if(cfg_req) begin
						arbiter_state <= ARBITER_GET;
						data_buffer <= cfg_wdata;
						addr_buffer <= cfg_addr;
						w_buffer <= cfg_cmd;
					end
					if(TWP_state == WRITE_DATA) Register_Spaces[TWP_addr][TWP_state_counter] <= SDAi; 
				end
				
					
				ARBITER_GET:begin
					cfg_rdy <= 1;
					
					if(TWP_state == WRITE_DATA)begin
						Register_Spaces[TWP_addr][TWP_state_counter] <= SDAi; 
						//$display("TWP Write ADDR:%d DATA:%h",TWP_addr,Register_Spaces[TWP_addr]);//test
					end
					else if(TWP_state == WAIT_START)begin
						arbiter_state <= ARBITER_FINISH;
						if(w_buffer) Register_Spaces[addr_buffer] <= data_buffer;
						else cfg_rdata <= Register_Spaces[addr_buffer];
					end

				end


				ARBITER_FINISH:begin
					if(!cfg_req)begin
						cfg_rdy <= 0;
						arbiter_state <= ARBITER_WAIT_INIS;
					end


					if(TWP_state == WRITE_DATA) Register_Spaces[TWP_addr][TWP_state_counter] <= SDAi; 
				end


			endcase
			


		end
	end


endmodule

