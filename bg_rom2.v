

module bg_rom2(
	 input clk,
	 input resetn,
	 input start,
	 
	 output [7:0] x,
	 output [6:0] y,
	 output [2:0] c_out,
	 output done);
	 
	 wire ld_all, enable;
	 
	 
	 datapath_end d0(
			 .clk(clk),
			 .resetn(resetn),
			 .ld_all(ld_all),
			 .enable(enable),

			 .x(x),
			 .y(y),
			 .c_out(c_out));
			 
	 control_end c0(
			 .clk(clk),
			 .resetn(resetn),
			 .start(start),

			 .ld_all(ld_all),
			 .enable(enable),
			 .done(done));	 
		


endmodule

module datapath_end(
    input clk,
    input resetn,
    input ld_all,
	 input enable,

    output reg [7:0] x,
	 output reg [6:0] y,
	 output reg [2:0] c_out);

	 reg [7:0] x_hold;
	 reg [6:0] y_hold;
	 reg [2:0] c_hold;
	 reg [14:0] address;
	 reg [7:0] x_address;
	 reg [6:0] y_address;
	 reg double;
	 wire [2:0] colour;

	 
	 
	 	 
    // Registers x, y, c with respective input logic
    always @ (posedge clk) begin
        if (!resetn)
		  begin
            x <= 8'd0;
            y <= 7'd0;
            c_out <= 3'd0;
        end
		  else if (enable)
		  begin
				x <= x_address;
				y <= y_address;
				c_out <= colour;
		  end
    end


	 always@(posedge clk)
    begin: address_counter
        if(!resetn | !enable)
		  begin
            x_address <= 8'd0;
				y_address <= 7'd0;
				address <= 15'd0;
				double <= 1'd0;
		  end
        else if (enable)
		  begin
		  		if (double == 1'd1)
				begin
					double <= 1'd0;
				end
				else if (address == 15'd19199)
				begin
					x_address <= 8'd0;
					y_address <= 7'd0;
					address <= 15'd0;
					double <= 1'd1;
				end
				else if (x_address == 8'd159)
				begin
					x_address <= 8'd0;
					y_address <= y_address + 1'd1;
					address <= address + 1'd1;
					double <= 1'd1;
				end
				else
				begin
					x_address <= x_address + 1'd1;
					address <= address + 1'd1;
					double <= 1'd1;
				end
		  end
    end // address
	 
	 
	 back_rom2 b0(
			.address(address),
			.clock(clk),
			
			.q(colour));
	 
	 

endmodule




module control_end(
    input clk,
    input resetn,
	 input start,

    output reg ld_all,
	 output reg enable,
	 output reg done);

    reg [4:0] current_state, next_state;
	 reg [15:0] counter;

	 wire wait_plot = (counter > 16'd40000);

    localparam  S_DRAW       = 5'd0,
					 S_DONE       = 5'd1,
					 S_INITIAL    = 5'd2,

					 S_START        = 5'd3,
					 S_START_WAIT   = 5'd4;


	   // Next state logic aka our state table for plotting
    always@(*)
    begin: state_table
            case (current_state)
                S_INITIAL: next_state = start ? S_DRAW : S_INITIAL; // Loads initial x position
                S_START: next_state = start ? S_DRAW : S_START;
					 S_DRAW: next_state = wait_plot ? S_DONE : S_DRAW;
					 S_DONE: next_state = S_START;
            default:     next_state = S_INITIAL;
        endcase
    end // state_table



    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_all = 1'b0;
		  enable = 1'b0;
		  done = 1'b0;
		  case (current_state)
				  S_INITIAL:
				  begin
						ld_all = 1'b1;
				  end
				  S_DRAW:
				  begin
						enable = 1'b1;
				  end
				  S_DONE:
				  begin
						done = 1'b1;
				  end
				default: enable = 1'b0;
		  endcase
    end

	 always@(posedge clk)
    begin: sixteen_counter
        if(!resetn | !enable)
		  begin
            counter <= 16'd0;
		  end
        else
		  begin
            counter <= counter + 16'd1;
		  end
    end // counter

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
		  begin
            current_state <= S_INITIAL;
		  end
        else
		  begin
				current_state <= next_state;
		  end
    end // state_FFS
endmodule
