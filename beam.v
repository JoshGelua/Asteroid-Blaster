module beam(
		input clk,
		input resetn,
		input no_colour,
		input ld_colour,
		input start,
		input[7:0] x_ss,
		
		output [7:0] x,
		output [6:0] y,
		output [2:0] c_out,
		output done);
		
		
		wire ld_all, enable;
		
		datapath_beam d0(
			 .clk(clk),
			 .resetn(resetn),
			 .ld_all(ld_all),
			 .enable(enable),
			 .no_colour(no_colour),
			 .ld_colour(ld_colour),
			 .x_ss(x_ss),

			 .x(x),
			 .y(y),
			 .c_out(c_out));
			 
			 
		control_beam c0(
			 .clk(clk),
			 .resetn(resetn),
			 .start(start),

			 .ld_all(ld_all),
			 .enable(enable),
			 .done(done));
			 
		
endmodule



module datapath_beam(
    input clk,
    input resetn,
    input ld_all,
	 input enable,
	 input no_colour,
	 input ld_colour,
	 input [7:0] x_ss,

    output reg [7:0] x,
	 output reg [6:0] y,
	 output reg [2:0] c_out);

	 reg [7:0] x_hold;
	 reg [6:0] y_hold;
	 reg [2:0] c_hold;
	 
	 // Coordinates to draw on (a Veritcal line)
	 reg [9:0] counter;
	 reg [1:0] x_offset;
	 reg [6:0] y_offset;
	 reg double;

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
				x <= x_hold + x_offset;
				y <= y_hold + y_offset;
				c_out <= c_hold;
		  end
    end

	 // Registers x_hold, y_hold, c_hold with respective input logic
    always @ (posedge clk) begin
        if (!resetn)
		  begin
            x_hold <= 8'd0;
            y_hold <= 7'd0;
				c_hold <= 3'd0;
        end
		  else if (ld_all)
		  begin
				x_hold <= x_ss;
				y_hold <= 7'd0;
		  end
		  if (ld_colour)
		  begin
			  if (no_colour)
					c_hold <= 3'd0;
			  else
					c_hold <= 3'd2;
		  end
    end
	 
	 

	 always@(posedge clk)
    begin: x_y_counter
        if(!resetn | !enable)
		  begin
            counter <= 10'd0;
				x_offset <= 2'd0;
				y_offset <= 7'd0;
		  end
        else if (enable)
		  begin
				if (double == 1'd1)
				begin
					double <= 1'd0;
				end
				else if (counter == 10'd459)
				begin
					counter <= 10'd0;
					x_offset <= 2'd0;
					y_offset <= 7'd0;
					double <= 1'd1;
				end
				
				else if (x_offset == 2'd3)
				begin
					x_offset <= 2'd0;
					y_offset <= y_offset + 1'd1;
					counter <= counter + 1'd1;
					double <= 1'd1;
				end

				else
				begin
					x_offset <= x_offset + 1'd1;
					counter <= counter + 1'd1;
					double <= 1'd1;
				end
		  end
    end // increment

endmodule



module control_beam(
    input clk,
    input resetn,
	 input start,

    output reg ld_all,
	 output reg enable,
	 output reg done);

    reg [4:0] current_state, next_state;
	 reg [10:0] counter;

	 wire wait_plot = (counter > 11'd919);

    localparam  S_DRAW       = 5'd0,
					 S_DONE       = 5'd1,
					 S_INITIAL    = 5'd2,

					 S_START        = 5'd3,
					 S_START_WAIT   = 5'd4;


	   // Next state logic aka our state table for plotting
    always@(*)
    begin: state_table
            case (current_state)
                S_START: next_state = start ? S_DRAW : S_START;
					 S_DRAW: next_state = wait_plot ? S_DONE : S_DRAW;
					 S_DONE: next_state = S_START;
            default:     next_state = S_START;
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
				  S_START:
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
            counter <= 11'd0;
		  end
        else
		  begin
            counter <= counter + 1'd1;
		  end
    end // counter

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn )
		  begin
            current_state <= S_START;
		  end
        else
		  begin
				current_state <= next_state;
		  end
    end // state_FFS
endmodule
