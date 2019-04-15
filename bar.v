module bar(
		input clk,
		input resetn,
		input start,
		input fire,
		input move,
		input [7:0] cooldown,
		input no_colour,
		input ld_colour,
		
		output [7:0] x,
		output [6:0] y,
		output [2:0] c_out,
		output done);

		wire ld_all, enable;

		datapath_bar d0(
				.clk(clk),
				.resetn(resetn),
				.ld_all(ld_all),
				.enable(enable),
				.fire(fire),
				.move(move),
				.cooldown(cooldown),
				.no_colour(no_colour),
				.ld_colour(ld_colour),

				.x(x),
				.y(y),
				.c_out(c_out));

		control_bar c0(
				.clk(clk),
				.resetn(resetn),
				.start(start),

				.ld_all(ld_all),
				.enable(enable),
				.done(done));


endmodule


module datapath_bar(
    input clk,
    input resetn,
    input ld_all,
	 input enable,
	 input fire,
	 input move,
	 input [7:0] cooldown,
	 input no_colour,
	 input ld_colour,

    output reg [7:0] x,
	 output reg [6:0] y,
	 output reg [2:0] c_out);

	 reg [7:0] x_hold;
	 reg [6:0] y_hold;
	 reg [2:0] c_hold;


	 reg [9:0] counter;
	 reg double;
	 reg [3:0] increment;

	 // Registers x_hold, y_hold, c_hold with respective input logic
    always @ (posedge clk) begin
        if (!resetn)
		  begin
            x_hold <= 8'd0; // Top left x coordinates of bar
				y_hold <= 7'd0; // Top left y coordinates of bar
				c_hold <= 3'd0;
        end
		  else if (fire)
		  begin
            x_hold <= 8'd127; // Top left x coordinates of bar
				y_hold <= 7'd75; // Top left y coordinates of bar
				c_hold <= 3'd7;
        end
		  else if (ld_all)
		  begin
				x_hold <= 8'd75; // Top left x coordinates of bar
				y_hold <= 7'd120; // Top left y coordinates of bar
				c_hold <= 3'd7;
		  end
			else if (move)
			begin
				if (y_hold < 7'd124)
				begin
					y_hold = y_hold + 1'd1;
				end
			end
			if (ld_colour)
			begin
				if (no_colour)
						c_hold <= 3'd0;
				else
						c_hold <= 3'd7;
			end
	 end

	 always @ (posedge clk) begin
		if (!resetn | fire)
		begin
					 x <= 8'd0;
					 y <= 7'd0;
					 c_out <= 3'd0;
		end
		 else if (enable)
		 begin
			 x <= x_hold + increment[3:1];
			 y <= y_hold + increment[0:0];
			 c_out <= c_hold;
		 end
	 end

	 always@(posedge clk)
    begin: increment_counter
        if(!resetn | !enable | fire)
		  begin
            increment <= 4'd0;
		  end
        else if (enable)
		  begin
            increment <= increment + 1'd1;
		  end
    end // increment


endmodule


module control_bar(
    input clk,
    input resetn,
	 input start,

    output reg ld_all,
	 output reg enable,
	 output reg done);

    reg [4:0] current_state, next_state;
	 reg [9:0] counter;

	 wire wait_plot = (counter > 10'd16);

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
            counter <= 10'd0;
		  end
        else
		  begin
            counter <= counter + 1'd1;
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
