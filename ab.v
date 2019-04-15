
module ab
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		  PS2_CLK,
		  PS2_DAT,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	inout 			PS2_CLK;
	inout				PS2_DAT;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

	wire resetn;
	assign resetn = KEY[0];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	wire left, right, up, down, w, a, s, d, space, enter;

	keyboard_tracker #(.PULSE_OR_HOLD(0)) kb(
		 .clock(CLOCK_50),
		 .reset(resetn),

		 .PS2_CLK(PS2_CLK),
		 .PS2_DAT(PS2_DAT),

		 .w(w),
		 .a(a),
		 .s(s),
		 .d(d),
		 .left(left),
		 .right(right),
		 .up(up),
		 .down(down),
		 .space(space),
		 .enter(enter));


	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "astback.mif";

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may requir

	wire start;
	wire [3:0] select;
	wire no_colour, ld_colour;
	wire done;
	wire move;
	wire done_back, done_heart;
	wire reset_ast;
	wire collided;
	wire end_game;
	wire move_heart;
	wire move_bar;
	wire [7:0] cooldown;
	wire fired;

    // Instansiate control
	 control c0(
		.clk(CLOCK_50),
		.resetn(~space),
		.go(enter),
		.done(done),
		.collided(collided),
		.end_game(end_game),
		.fire(w),

		.select(select),
		.start(start),
		.move(move),
		.plot(writeEn),
		.no_colour(no_colour),
		.ld_colour(ld_colour),

		.reset_ast(reset_ast),
		.move_heart(move_heart),
		.move_bar(move_bar),
		.cooldown(cooldown),
		.fired(fired));

	// Instansiate datapath
	datapath d0(
		.clk(CLOCK_50),
		.resetn(~space),
		.select(select),
		.start(start),
		.move(move),
		.left(a),
		.right(d),
		.ld_colour(ld_colour),
		.no_colour(no_colour),
		.reset_ast(reset_ast),
		.move_heart(move_heart),
		.move_bar(move_bar),
		.cooldown(cooldown),
		.fire(fired),

		.x(x),
		.y(y),
		.c_out(colour),
		.done(done),
		.collided(collided),
		.end_game(end_game));


endmodule

module control(
	input clk,
	input resetn,
	input go,
	input done,
	input collided,
	input end_game,
	input fire,

	output reg [3:0] select,
	output reg start,
	output reg move,
	output reg plot,
	output reg ld_colour,
	output reg no_colour,
	
	output reg reset_ast,
	output reg move_heart,
	output reg move_bar,
	output reg [7:0] cooldown,
	output reg fired);


	reg [5:0] current_state, next_state;
	reg [3:0] frame_counter;
	reg [19:0] rate_counter;
	reg reset_frame;
	reg collided_detected;
	reg drawn_beam;

   wire wait_frame = (frame_counter == 4'd1);


   localparam   S_START					= 6'd1,
					 S_START_WAIT			= 6'd2,
					 S_DRAW1					= 6'd3,
					 S_DRAW1_HOLD			= 6'd4,
					 S_DRAW2					= 6'd5,
					 S_DRAW2_HOLD			= 6'd6,
					 S_DRAW3					= 6'd7,
					 S_DRAW3_HOLD			= 6'd8,
					 S_DRAW4					= 6'd9,
					 S_DRAW4_HOLD			= 6'd10,
					 S_DRAW5					= 6'd11,
					 S_DRAW5_HOLD			= 6'd12,
					 S_DRAW6					= 6'd13,
					 S_DRAW6_HOLD			= 6'd14,
					 S_DRAW7					= 6'd15,
					 S_DRAW7_HOLD			= 6'd16,
					 S_DRAW8					= 6'd17,
					 S_DRAW8_HOLD			= 6'd18,

					 S_DRAW_SS				= 6'd19,

					 S_ERASE1				= 6'd20,
					 S_ERASE1_HOLD			= 6'd21,
					 S_ERASE2				= 6'd22,
					 S_ERASE2_HOLD			= 6'd23,
					 S_ERASE3				= 6'd24,
					 S_ERASE3_HOLD			= 6'd25,
					 S_ERASE4				= 6'd26,
					 S_ERASE4_HOLD			= 6'd27,
					 S_ERASE5				= 6'd28,
					 S_ERASE5_HOLD			= 6'd29,
					 S_ERASE6				= 6'd30,
					 S_ERASE6_HOLD			= 6'd31,
					 S_ERASE7				= 6'd32,
					 S_ERASE7_HOLD			= 6'd33,
					 S_ERASE8				= 6'd34,
					 S_ERASE8_HOLD			= 6'd35,


					 S_ERASE_SS				= 6'd36,


					 S_WAIT_FRAME			= 6'd37,
					 S_MOVE					= 6'd38,
					 S_MOVE_HOLD			= 6'd39,
					 S_RESET_FRAME			= 6'd40,
					 S_DRAW_BACK			= 6'd41,
					 S_CHECK_COLLIDE		= 6'd42,
					 S_CHECK_HOLD			= 6'd43,
					 S_ERASE_HEART			= 6'd44,
					 S_ERASE_HEART_HOLD	= 6'd45,
					 S_CHECK_FIRED			= 6'd46,
					 S_DRAW_BEAM			= 6'd47,
					 S_CHECK_BEAM			= 6'd48,
					 S_ERASE_BEAM			= 6'd49,
					 S_ERASE_BEAM_HOLD	= 6'd50,
					 S_DRAW_BAR				= 6'd51,
					 S_DRAW_BAR_HOLD		= 6'd52,
					 S_ERASE_BAR 			= 6'd53,
					 S_ERASE_BAR_HOLD 	= 6'd54,
					 S_DRAW_END				= 6'd55;


	   // Next state logic aka our state table for plotting
    always@(*)
    begin: state_table
            case (current_state)
					 S_DRAW_END: next_state = S_DRAW_END;
					 S_DRAW_BACK: next_state = done ? S_START : S_DRAW_BACK;


                S_START: next_state = go ? S_START_WAIT : S_START;
                S_START_WAIT: next_state = go ? S_START_WAIT : S_RESET_FRAME;

					 S_RESET_FRAME: next_state = end_game ? S_DRAW_END : S_DRAW1; // Resets the frame counter


                S_DRAW1: next_state = done ? S_DRAW1_HOLD : S_DRAW1; // Draw ast1
					 S_DRAW1_HOLD : next_state = S_DRAW2;

					 S_DRAW2: next_state = done ? S_DRAW2_HOLD : S_DRAW2; // Draw ast2
					 S_DRAW2_HOLD : next_state = S_DRAW3;

					 S_DRAW3: next_state = done ? S_DRAW3_HOLD : S_DRAW3; // Draw ast3
					 S_DRAW3_HOLD: next_state = S_DRAW4;

					 S_DRAW4: next_state = done ? S_DRAW4_HOLD : S_DRAW4; // Draw ast4
					 S_DRAW4_HOLD: next_state = S_DRAW5;

					 S_DRAW5: next_state = done ? S_DRAW5_HOLD : S_DRAW5; // Draw ast5
					 S_DRAW5_HOLD: next_state = S_DRAW6;

					 S_DRAW6: next_state = done ? S_DRAW6_HOLD : S_DRAW6; // Draw ast6
					 S_DRAW6_HOLD: next_state = S_DRAW7;

					 S_DRAW7: next_state = done ? S_DRAW7_HOLD : S_DRAW7; // Draw ast7
					 S_DRAW7_HOLD: next_state = S_DRAW8;

					 S_DRAW8: next_state = done ? S_DRAW8_HOLD : S_DRAW8; // Draw ast8
					 S_DRAW8_HOLD: next_state = S_DRAW_SS;


					 S_DRAW_SS: next_state = done ? S_DRAW_BAR : S_DRAW_SS; // Draw spaceship, constantly, can't be seen


					 // SKIPPED FOR NOW
					 S_DRAW_BAR: next_state = done ? S_DRAW_BAR_HOLD : S_DRAW_BAR;
					 S_DRAW_BAR_HOLD: next_state = S_CHECK_FIRED;


					 S_CHECK_FIRED: next_state = fired ? S_DRAW_BEAM : S_WAIT_FRAME; // If fired then proceed to draw beam
					 S_DRAW_BEAM: next_state = done ? S_WAIT_FRAME : S_DRAW_BEAM;  // Draws beam and proceeds with the rest of the drawing


					 S_WAIT_FRAME: next_state = wait_frame ? S_ERASE1 : S_WAIT_FRAME; // Wait for some frames


                S_ERASE1: next_state = done ? S_ERASE1_HOLD : S_ERASE1; // Erase ast1
					 S_ERASE1_HOLD : next_state = S_ERASE2;

					 S_ERASE2: next_state = done ? S_ERASE2_HOLD : S_ERASE2; // Erase ast2
					 S_ERASE2_HOLD : next_state = S_ERASE3;

					 S_ERASE3: next_state = done ? S_ERASE3_HOLD : S_ERASE3;// Erase ast3
					 S_ERASE3_HOLD : next_state = S_ERASE4;

					 S_ERASE4: next_state = done ? S_ERASE4_HOLD : S_ERASE4;// Erase ast4
					 S_ERASE4_HOLD : next_state = S_ERASE5;

					 S_ERASE5: next_state = done ? S_ERASE5_HOLD : S_ERASE5;// Erase ast5
					 S_ERASE5_HOLD : next_state = S_ERASE6;

					 S_ERASE6: next_state = done ? S_ERASE6_HOLD : S_ERASE6;// Erase ast6
					 S_ERASE6_HOLD : next_state = S_ERASE7;

					 S_ERASE7: next_state = done ? S_ERASE7_HOLD : S_ERASE7;// Erase ast7
					 S_ERASE7_HOLD : next_state = S_ERASE8;

					 S_ERASE8: next_state = done ? S_ERASE8_HOLD : S_ERASE8;// Erase ast8
					 S_ERASE8_HOLD : next_state = S_ERASE_BAR;

					 S_ERASE_BAR: next_state = done ? S_ERASE_BAR_HOLD : S_ERASE_BAR; // Erase bar
					 S_ERASE_BAR_HOLD: next_state = S_ERASE_SS;


					 S_ERASE_SS: next_state = done ? S_CHECK_BEAM : S_ERASE_SS;   // Erase SS if needed

					 S_CHECK_BEAM: next_state = drawn_beam ? S_ERASE_BEAM : S_CHECK_COLLIDE; // Checks if beam was drawn

					 S_ERASE_BEAM: next_state = done ? S_ERASE_BEAM_HOLD : S_ERASE_BEAM; // Erases beam if it was drawn

					 S_ERASE_BEAM_HOLD: next_state = S_CHECK_COLLIDE;


					 S_CHECK_COLLIDE: next_state = collided_detected ? S_ERASE_HEART : S_MOVE; // Checks if collision occurred, if it did move to erase a heart

					 S_ERASE_HEART: next_state = done ? S_ERASE_HEART_HOLD : S_ERASE_HEART; // Erases a heart if collided
					 S_ERASE_HEART_HOLD: next_state = S_MOVE;

					 S_MOVE: next_state = S_MOVE_HOLD; // Updates the new position of the asteroids and spaceship
					 S_MOVE_HOLD: next_state = S_RESET_FRAME; // Loops back

            default:     next_state = S_START;
        endcase
    end // state_table



    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
	     select = 4'd0;
	     start = 1'd0;
	     move = 1'd0;
		  plot = 1'd0;
		  no_colour = 1'd0;
		  ld_colour = 1'd0;
		  reset_ast = 1'd0;
		  move_heart = 1'd0;
			move_bar = 1'd0;
		  // Internal reg
		  reset_frame = 1'd0;
		  case (current_state)
				S_DRAW_END:
				begin
					start = 1'd1;
					select = 4'd14;
					plot = 1'd1;
				end
				
				S_DRAW_BACK:
				begin
					start = 1'd1;
					select = 4'd10;
					plot = 1'd1;
				end
				S_RESET_FRAME:
				begin
					 reset_frame = 1'd1;
					 ld_colour = 1'd1;
				end

				S_DRAW_BEAM:
				begin
					start = 1'd1;
					select = 4'd12;
					plot = 1'd1;
				end
            S_DRAW1: // Draw ast1
				begin // Plot (x, y)
                start = 1'd1;
					 select = 4'd1;
					 plot = 1'd1;
            end
				S_DRAW1_HOLD: // Resets
				begin
					  start = 1'd0;
				end


            S_DRAW2: // Draw ast2
				begin // Plot (x, y)
                start = 1'd1;
					 select = 4'd2;
					 plot = 1'd1;
            end
				S_DRAW2_HOLD: // Resets
				begin
					  start = 1'd0;
				end


            S_DRAW3: // Draw ast3
				begin // Plot (x, y)
                start = 1'd1;
					 select = 4'd3;
					 plot = 1'd1;
            end
				S_DRAW3_HOLD: // Resets
				begin
					  start = 1'd0;
				end


            S_DRAW4: // Draw ast4
				begin // Plot (x, y)
                start = 1'd1;
					 select = 4'd4;
					 plot = 1'd1;
            end
				S_DRAW4_HOLD: // Resets
				begin
					  start = 1'd0;
				end


            S_DRAW5: // Draw ast5
				begin // Plot (x, y)
                start = 1'd1;
					 select = 4'd5;
					 plot = 1'd1;
            end
				S_DRAW5_HOLD: // Resets
				begin
					  start = 1'd0;
				end


            S_DRAW6: // Draw ast6
				begin // Plot (x, y)
                start = 1'd1;
					 select = 4'd6;
					 plot = 1'd1;
            end
				S_DRAW6_HOLD: // Resets
				begin
					  start = 1'd0;
				end


            S_DRAW7: // Draw ast7
				begin // Plot (x, y)
                start = 1'd1;
					 select = 4'd7;
					 plot = 1'd1;
            end
				S_DRAW7_HOLD: // Resets
				begin
					  start = 1'd0;
				end


            S_DRAW8: // Draw ast8
				begin // Plot (x, y)
                start = 1'd1;
					 select = 4'd8;
					 plot = 1'd1;
            end
				S_DRAW8_HOLD: // Resets
				begin
					  start = 1'd0;
				end


				S_DRAW_SS:
				begin
					  start = 1'd1;
					  select = 4'd9;
					  plot = 1'd1;
				end

				S_DRAW_BAR:
				begin
					  start = 1'd1;
					  select = 4'd13;
					  plot = 1'd1;
				end
				S_DRAW_BAR_HOLD:
				begin
					start = 1'd0;
				end
				
				S_WAIT_FRAME:
				begin
					start = 1'd0;
					no_colour = 1'd1;
					ld_colour = 1'd1;
				end


            S_ERASE1:
				begin // Erases ast1
                start = 1'd1;
					 select = 4'd1;
					 plot = 1'd1;
            end
				S_ERASE1_HOLD: // Resets
				begin
					 start = 1'd0;
				end


            S_ERASE2:
				begin // Erases ast2
                start = 1'd1;
					 select = 4'd2;
					 plot = 1'd1;
            end
				S_ERASE2_HOLD: // Resets
				begin
					 start = 1'd0;
				end


            S_ERASE3:
				begin // Erases ast3
                start = 1'd1;
					 select = 4'd3;
					 plot = 1'd1;
            end
				S_ERASE3_HOLD: // Resets
				begin
					 start = 1'd0;
				end


            S_ERASE4:
				begin // Erases ast4
                start = 1'd1;
					 select = 4'd4;
					 plot = 1'd1;
            end
				S_ERASE4_HOLD: // Resets
				begin
					 start = 1'd0;
				end


            S_ERASE5:
				begin // Erases ast5
                start = 1'd1;
					 select = 4'd5;
					 plot = 1'd1;
            end
				S_ERASE5_HOLD: // Resets
				begin
					 start = 1'd0;
				end


            S_ERASE6:
				begin // Erases ast6
                start = 1'd1;
					 select = 4'd6;
					 plot = 1'd1;
            end
				S_ERASE6_HOLD: // Resets
				begin
					 start = 1'd0;
				end


            S_ERASE7:
				begin // Erases ast7
                start = 1'd1;
					 select = 4'd7;
					 plot = 1'd1;
            end
				S_ERASE7_HOLD: // Resets
				begin
					 start = 1'd0;
				end


            S_ERASE8:
				begin // Erases ast8
                start = 1'd1;
					 select = 4'd8;
					 plot = 1'd1;
            end
				S_ERASE8_HOLD: // Resets
				begin
					 start = 1'd0;
				end
				
				S_ERASE_BAR:
				begin // Erases bar
					start = 1'd1;
					select = 4'd13;
					plot = 1'd1;
				end
				
				S_ERASE_BAR_HOLD:
				begin
					start = 1'd0;
				end

				S_ERASE_SS:
				begin
					  start = 1'd1;
					  select = 4'd9;
					  plot = 1'd1;
				end

				S_ERASE_BEAM:
				begin
					  start = 1'd1;
					  select = 4'd12;
					  plot = 1'd1;
				end

				S_ERASE_BEAM_HOLD:
				begin
					 reset_ast = 1'd1;
				end
				S_ERASE_HEART:
				begin
					  start = 1'd1;
					  select = 4'd11;
					  plot = 1'd1;
				end
				S_ERASE_HEART_HOLD:
				begin
					  move_heart = 1'd1;
				end

				S_MOVE:
				begin
					 move = 1'd1;
				end
			default: reset_frame = 1'd0;
			endcase
    end

	 always@(posedge clk)
    begin: rate_divider
        if(!resetn | reset_frame)
		  begin
            rate_counter <= 20'd0;
				frame_counter <= 4'd0;
		  end
		  else if (rate_counter == 20'd85_0000)
		  begin
				rate_counter <= 20'd0;
				frame_counter <= frame_counter + 1'd1;
		  end
        else
		  begin
            rate_counter <= rate_counter + 1'd1;
		  end
    end // rate_divider

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
		  begin
            current_state <= S_DRAW_BACK;
		  end
        else
		  begin
				current_state <= next_state;
		  end
    end // state_FFS


	 // Collider registers
    always@(posedge clk)
    begin: collider_holder
        if(!resetn)
		  begin
            collided_detected <= 1'd0;
		  end
		  else if (collided)
		  begin
				collided_detected <= 1'd1;
		  end
        else if (current_state == S_ERASE_HEART_HOLD)
		  begin
				collided_detected <= 1'd0;
		  end
    end // Collider


	 // Fire registers
    always@(posedge clk)
    begin: fire_holder
        if(!resetn)
		  begin
            fired <= 1'd0;
				drawn_beam <= 1'd0;
				cooldown <= 8'd0;
		  end
		  else if (fire & cooldown == 8'd0)
		  begin
				fired <= 1'd1;
				cooldown <= 8'd46;
		  end
		  else if (current_state == S_DRAW_BEAM)
		  begin
				drawn_beam <= 1'd1;
		  end
        else if (current_state == S_ERASE_BEAM_HOLD)
		  begin
				drawn_beam <= 1'd0;
				fired <= 1'd0;
		  end
		  else if (current_state == S_RESET_FRAME & cooldown != 8'd0)
		  begin
				cooldown <= cooldown - 1'd1;
		  end
    end // fire table

endmodule

module datapath(
	input clk,
	input resetn,
	input [3:0] select,
	input start,
	input move,
	input left,
	input right,
	input ld_colour,
	input no_colour,
	input reset_ast,
	input move_heart,
	input move_bar,
	input [7:0] cooldown,
	input fire,

	output reg [7:0] x,
	output reg [6:0] y,
	output reg [2:0] c_out,
	output reg done,
	output reg collided,
	output reg end_game);

	wire [7:0] x_out1, x_out2, x_out3, x_out4, x_out5, x_out6, x_out7, x_out8, x_out_ss, x_out_back, x_out_heart, x_out_beam, x_out_bar, x_out_end;
	wire [6:0] y_out1, y_out2, y_out3, y_out4, y_out5, y_out6, y_out7, y_out8, y_out_ss, y_out_back, y_out_heart, y_out_beam, y_out_bar, y_out_end;
	wire [2:0] c_out1, c_out2, c_out3, c_out4, c_out5, c_out6, c_out7, c_out8, c_out_ss, c_out_back, c_out_heart, c_out_beam, c_out_bar, c_out_end;
	wire done1, done2, done3, done4, done5, done6, done7, done8, done_ss, done_back, done_heart, done_beam, done_bar, done_end;
	wire [3:0] which;


	wire reset_ast1 = which == 4'd1;
	wire reset_ast2 = which == 4'd2;
	wire reset_ast3 = which == 4'd3;
	wire reset_ast4 = which == 4'd4;
	wire reset_ast5 = which == 4'd5;
	wire reset_ast6 = which == 4'd6;
	wire reset_ast7 = which == 4'd7;
	wire reset_ast8 = which == 4'd8;

	wire start_astss 	= select > 4'd0 & select < 4'd10;
	wire start_back	= select == 4'd10;
	wire start_heart 	= select == 4'd11;
	wire start_beam 	= select == 4'd12;
	wire start_bar 	= select == 4'd13;
	wire start_end		= select == 4'd14;




	  // Load the output properly with respective input logic
    always@(*)
    begin: select_table
            case (select)
					 4'd0:
							begin
								x = 8'd0;
								y = 7'd0;
								c_out = 3'd0;
								done = 1'd0;
							end
                4'd1:
							begin
								x = x_out1;
								y = y_out1;
								c_out = c_out1;
								done = done1;
							end
                4'd2:
							begin
								x = x_out2;
								y = y_out2;
								c_out = c_out2;
								done = done2;
							end
                4'd3:
							begin
								x = x_out3;
								y = y_out3;
								c_out = c_out3;
								done = done3;
							end
					 4'd4:
							begin
								x = x_out4;
								y = y_out4;
								c_out = c_out4;
								done = done4;
							end
					 4'd5:
							begin
								x = x_out5;
								y = y_out5;
								c_out = c_out5;
								done = done5;
							end
					 4'd6:
							begin
								x = x_out6;
								y = y_out6;
								c_out = c_out6;
								done = done6;
							end
					 4'd7:
							begin
								x = x_out7;
								y = y_out7;
								c_out = c_out7;
								done = done7;
							end
					 4'd8:
							begin
								x = x_out8;
								y = y_out8;
								c_out = c_out8;
								done = done8;
							end
					 4'd9:
							begin
								x = x_out_ss;
								y = y_out_ss;
								c_out = c_out_ss;
								done = done_ss;
							end
					 4'd10:
							begin
								x = x_out_back;
								y = y_out_back;
								c_out = c_out_back;
								done = done_back;
							end
					 4'd11:
							begin
								x = x_out_heart;
								y = y_out_heart;
								c_out = c_out_heart;
								done = done_heart;
							end
					 4'd12:
							begin
								x = x_out_beam;
								y = y_out_beam;
								c_out = c_out_beam;
								done = done_beam;
							end
					 4'd13:
							begin
								x = x_out_bar;
								y = y_out_bar;
								c_out = c_out_bar;
								done = done_bar;
							end
					4'd14:
							begin
								x = x_out_end;
								y = y_out_end;
								c_out = c_out_end;
								done = done_end;
							end
            default:
						begin
							x = 8'd0;
							y = 7'd0;
							c_out = 3'd0;
							done = 1'd0;
						end
        endcase
    end // select table




	 asteroid a1(
		 .clk(clk),
		 .resetn(resetn),
		 .reset_ast(reset_ast1),
		 .start(start_astss),
		 .move(move),
		 .no_colour(no_colour),
		 .ld_colour(ld_colour),
		 .rand_initial(6'd52),
		 .x_start(8'd0),

		 .x(x_out1),
		 .y(y_out1),
		 .c_out(c_out1),
		 .done(done1));

	 asteroid a2(
		 .clk(clk),
		 .resetn(resetn),
		 .reset_ast(reset_ast2),
		 .start(start_astss),
		 .move(move),
		 .no_colour(no_colour),
		 .ld_colour(ld_colour),
		 .rand_initial(6'd42),
		 .x_start(8'd15),

		 .x(x_out2),
		 .y(y_out2),
		 .c_out(c_out2),
		 .done(done2));

	 asteroid a3(
		 .clk(clk),
		 .resetn(resetn),
		 .reset_ast(reset_ast3),
		 .start(start_astss),
		 .move(move),
		 .no_colour(no_colour),
		 .ld_colour(ld_colour),
		 .rand_initial(6'd32),
		 .x_start(8'd30),

		 .x(x_out3),
		 .y(y_out3),
		 .c_out(c_out3),
		 .done(done3));

	 asteroid a4(
		 .clk(clk),
		 .resetn(resetn),
		 .reset_ast(reset_ast4),
		 .start(start_astss),
		 .move(move),
		 .no_colour(no_colour),
		 .ld_colour(ld_colour),
		 .rand_initial(6'd25),
		 .x_start(8'd45),

		 .x(x_out4),
		 .y(y_out4),
		 .c_out(c_out4),
		 .done(done4));

	 asteroid a5(
		 .clk(clk),
		 .resetn(resetn),
		 .reset_ast(reset_ast5),
		 .start(start_astss),
		 .move(move),
		 .no_colour(no_colour),
		 .ld_colour(ld_colour),
		 .rand_initial(6'd19),
		 .x_start(8'd60),

		 .x(x_out5),
		 .y(y_out5),
		 .c_out(c_out5),
		 .done(done5));

	 asteroid a6(
		 .clk(clk),
		 .resetn(resetn),
		 .reset_ast(reset_ast6),
		 .start(start_astss),
		 .move(move),
		 .no_colour(no_colour),
		 .ld_colour(ld_colour),
		 .rand_initial(6'd39),
		 .x_start(8'd75),

		 .x(x_out6),
		 .y(y_out6),
		 .c_out(c_out6),
		 .done(done6));

	 asteroid a7(
		 .clk(clk),
		 .resetn(resetn),
		 .reset_ast(reset_ast7),
		 .start(start_astss),
		 .move(move),
		 .no_colour(no_colour),
		 .ld_colour(ld_colour),
		 .rand_initial(6'd43),
		 .x_start(8'd90),

		 .x(x_out7),
		 .y(y_out7),
		 .c_out(c_out7),
		 .done(done7));

	 asteroid a8(
		 .clk(clk),
		 .resetn(resetn),
		 .reset_ast(reset_ast8),
		 .start(start_astss),
		 .move(move),
		 .no_colour(no_colour),
		 .ld_colour(ld_colour),
		 .rand_initial(5'd15),
		 .x_start(8'd105),

		 .x(x_out8),
		 .y(y_out8),
		 .c_out(c_out8),
		 .done(done8));





	 // Draw spaceship module
	 spaceship s1(
			 .clk(clk),
			 .resetn(resetn),
			 .start(start_astss),
			 .move(move),
			 .left(left),
			 .right(right),
			 .no_colour(no_colour),
			 .ld_colour(ld_colour),

			 .x(x_out_ss),
			 .y(y_out_ss),
			 .c_out(c_out_ss),
			 .done(done_ss));


	 // Draw bar
	 bar bar0(
			 .clk(clk),
			 .resetn(resetn),
			 .start(start_bar),
			 .fire(fire),
			 .move(move),
			 .cooldown(cooldown),
			 .no_colour(no_colour),
			 .ld_colour(ld_colour),

			 .x(x_out_bar),
			 .y(y_out_bar),
			 .c_out(c_out_bar),
			 .done(done_bar));


		// Draw Heart module

		heart heart0(
			 .clk(clk),
			 .resetn(resetn),
			 .start(start_heart),
			 .move(move_heart),

			 .x(x_out_heart),
			 .y(y_out_heart),
			 .c_out(c_out_heart),
			 .done(done_heart));


		// Draw background module
		bg_rom b0(
			 .clk(clk),
			 .resetn(resetn),
			 .start(start_back),

			 .x(x_out_back),
			 .y(y_out_back),
			 .c_out(c_out_back),
			 .done(done_back));
		
		bg_rom2 end0(
			 .clk(clk),
			 .resetn(resetn),
			 .start(start_end),

			 .x(x_out_end),
			 .y(y_out_end),
			 .c_out(c_out_end),
			 .done(done_end));

		// Draw / Erase Beam module
		beam beam0(
			.clk(clk),
			.resetn(resetn),
			.no_colour(no_colour),
			.ld_colour(ld_colour),
			.start(start_beam),
			.x_ss(x_out_ss),

			.x(x_out_beam),
			.y(y_out_beam),
			.c_out(c_out_beam),
			.done(done_beam));





		// Bullet Module
		bullet bullet0(
			.clk(clk),
			.resetn(resetn),
			.fire(reset_ast),
			.ss_x(x_out_ss),
			.ast1_x(x_out1),
			.ast2_x(x_out2),
			.ast3_x(x_out3),
			.ast4_x(x_out4),
			.ast5_x(x_out5),
			.ast6_x(x_out6),
			.ast7_x(x_out7),
			.ast8_x(x_out8),

			.which(which));



		// Collision detection


		wire collide = (y_check1 | y_check2 | y_check3 | y_check4 | y_check5 | y_check6 | y_check7 | y_check8);
		wire y_check1 = ((y_out1 >= 7'd115 & x_out1 < (x_out_ss + 2'd3)) & x_out1 >= (x_out_ss - 2'd3));
		wire y_check2 = ((y_out2 >= 7'd115 & x_out2 < (x_out_ss + 2'd3)) & x_out2 >= (x_out_ss - 2'd3));
		wire y_check3 = ((y_out3 >= 7'd115 & x_out3 < (x_out_ss + 2'd3)) & x_out3 >= (x_out_ss - 2'd3));
		wire y_check4 = ((y_out4 >= 7'd115 & x_out4 < (x_out_ss + 2'd3)) & x_out4 >= (x_out_ss - 2'd3));
		wire y_check5 = ((y_out5 >= 7'd115 & x_out5 < (x_out_ss + 2'd3)) & x_out5 >= (x_out_ss - 2'd3));
		wire y_check6 = ((y_out6 >= 7'd115 & x_out6 < (x_out_ss + 2'd3)) & x_out6 >= (x_out_ss - 2'd3));
		wire y_check7 = ((y_out7 >= 7'd115 & x_out7 < (x_out_ss + 2'd3)) & x_out7 >= (x_out_ss - 2'd3));
		wire y_check8 = ((y_out8 >= 7'd115 & x_out8 < (x_out_ss + 2'd3)) & x_out8 >= (x_out_ss - 2'd3));

		// Max collisions is 5
		reg [2:0] collisions;
		// Invincibility duration (about 1 frame)
		reg [23:0] reset_collide_hold;

		always @(posedge clk)
		begin
		  if (!resetn)
		  begin
			 collisions = 3'b000;
			 end_game = 1'b0;
			 reset_collide_hold = 23'd0;
			 collided = 1'd0;
		  end
		  else if (collide & (reset_collide_hold == 23'd0))
		  begin
			  collisions = collisions + 3'b001;
			  reset_collide_hold = 24'd15000000;
			  collided = 1'd1;
		  end
		  else if (collisions == 3'b101)
		  begin
			  end_game = 1'b1;
		  end
		  else if (reset_collide_hold != 23'd0)
		  begin
			  reset_collide_hold = reset_collide_hold - 1'b1;
			  collided = 1'd0;
		  end
		end


endmodule





// Single asteroid module that draws and outputs when start signal is provided and sends a done signal
// when its finished.


// Single asteroid module that draws and outputs when start signal is provided and sends a done signal
// when its finished.

module asteroid(
	 input clk,
	 input resetn,
	 input reset_ast,
	 input start,
	 input move,
	 input no_colour,
	 input ld_colour,
	 input [5:0] rand_initial,
	 input [7:0] x_start,

	 output [7:0] x,
	 output [6:0] y,
	 output [2:0] c_out,
	 output done);

	 wire ld_all, enable;


	 //Instantiate control
	 control_ast c0(
	 .clk(clk),
    .resetn(resetn),
	 .reset_ast(reset_ast),
	 .start(start),

    .ld_all(ld_all),
	 .enable(enable),
	 .done(done));

	 //Instantiate datapth
	 datapath_ast d0(
    .clk(clk),
    .resetn(resetn),
	 .reset_ast(reset_ast),
    .ld_all(ld_all),
	 .enable(enable),
	 .move(move),
	 .no_colour(no_colour),
	 .ld_colour(ld_colour),
	 .rand_initial(rand_initial),
	 .x_start(x_start),

    .x(x),
	 .y(y),
	 .c_out(c_out));


endmodule





module datapath_ast(
    input clk,
    input resetn,
	 input reset_ast,
    input ld_all,
	 input enable,
	 input move,
	 input no_colour,
	 input ld_colour,
	 input [5:0] rand_initial,
	 input [7:0] x_start,

    output reg [7:0] x,
	 output reg [6:0] y,
	 output reg [2:0] c_out);

	 reg [3:0] increment;
	 reg [7:0] x_hold;
	 reg [6:0] y_hold;
	 reg [2:0] c_hold;

	 wire [5:0] rand_value;

	 reg [4:0] x_offset;
	 reg [2:0] y_offset, moveby;

    // Registers x, y, c with respective input logic
    always @ (posedge clk) begin
        if (!resetn | reset_ast)
		  begin
            x <= 8'd0;
            y <= 7'd0;
            c_out <= 3'd0;
        end
		  else if (enable)
		  begin
				x <= x_hold + increment[1:0];
				y <= y_hold + increment[3:2];
				if (increment == 4'd0 | increment == 4'd3 | increment == 4'd12 | increment == 4'd15)
				begin
					c_out <= 3'd0;
				end
				else
				begin
					c_out <= c_hold;
				end
		  end
    end

	 // Registers x_hold, y_hold, c_hold with respective input logic
    always @ (posedge clk) begin
        if (!resetn | reset_ast)
		  begin
            x_hold <= 8'd0;
            y_hold <= 7'd0;
				c_hold <= 3'd0;
        end
		  else if (ld_all)
		  begin
				x_hold <= x_start;
				y_hold <= 7'd0;
				y_offset <= moveby;
				c_hold <= 3'd7;
		  end
		  else if (move)
		  begin
				if (y_hold >= 7'd124)
				begin
					x_hold <= x_start + x_offset; // Changes the x position when asteroid reaches the bottom
					y_hold <= 7'd0; // Reset the y position to the top of the screen
					y_offset <= moveby; // Creates a new speed that the asteroid will move by
				end
				else
				begin
					y_hold <= y_hold + y_offset; // Moves the asteroid down to the bottom of the screen
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

	 always@(posedge clk)
    begin: increment_counter
        if(!resetn | !enable | reset_ast)
		  begin
            increment <= 4'd0;
		  end
        else if (enable)
		  begin
            increment <= increment + 1'd1;
		  end
    end // increment


	 LFSR_6 lfsr0(
		.clk(clk),
		.resetn(resetn),
		.rand_num(rand_initial),

		.q(rand_value));

	 // Produces a random x_offset
	 always@(*)
	 begin: x_offset_table
		case(rand_value[3:0])
			4'd0:x_offset = 4'd0;
			4'd1:x_offset = 4'd1;
			4'd2:x_offset = 4'd2;
			4'd3:x_offset = 4'd3;
			4'd4:x_offset = 4'd4;

			4'd5:x_offset = 4'd5;
			4'd6:x_offset = 4'd6;
			4'd7:x_offset = 4'd7;
			4'd8:x_offset = 4'd8;

			4'd9:x_offset = 4'd9;
			4'd10:x_offset = 4'd10;
			4'd11:x_offset = 4'd11;

			4'd12:x_offset = 4'd1;
			4'd13:x_offset = 4'd4;
			4'd14:x_offset = 4'd7;
			4'd15:x_offset = 4'd10;
		endcase
	 end


	 // Produces a random moveby
	 always@(*)
	 begin: moveby_table
		case(rand_value[5:4])
			2'd0:moveby = 3'd1;
			2'd1:moveby = 3'd2;
			2'd2:moveby = 3'd3;
			2'd3:moveby = 3'd4;
		endcase
	 end

endmodule


module control_ast(
    input clk,
    input resetn,
	 input reset_ast,
	 input start,

    output reg ld_all,
	 output reg enable,
	 output reg done);

    reg [4:0] current_state, next_state;
	 reg [4:0] counter;

	 wire wait_plot = (counter > 5'd15);

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
        if(!resetn | !enable | reset_ast)
		  begin
            counter <= 5'd0;
		  end
        else
		  begin
            counter <= counter + 1'd1;
		  end
    end // counter

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn | reset_ast)
		  begin
            current_state <= S_INITIAL;
		  end
        else
		  begin
				current_state <= next_state;
		  end
    end // state_FFS
endmodule

module LFSR_6(
	 input clk,
	 input resetn,
	 input [5:0] rand_num,

	 output reg [5:0] q);

	 wire newbit = (q[5] ^ q[4]) ^ q[0];


	 always@(posedge clk) begin
	     if (!resetn)
		  begin
            q <= rand_num;
        end
		  else
		  begin
				q <= {newbit, q[5:1]};
		  end
    end
endmodule



module spaceship(
	 input clk,
	 input resetn,
	 input start,
	 input move,
	 input left,
	 input right,
	 input no_colour,
	 input ld_colour,

	 output [7:0] x,
	 output [6:0] y,
	 output [2:0] c_out,
	 output done);

	 wire ld_all, enable;

	 datapath_ss d0(
			.clk(clk),
			.resetn(resetn),
			.ld_all(ld_all),
			.enable(enable),
			.move(move),
			.left(left),
			.right(right),
			.no_colour(no_colour),
			.ld_colour(ld_colour),

			.x(x),
			.y(y),
			.c_out(c_out));

	 control_ast c1(
			 .clk(clk),
			 .resetn(resetn),
			 .start(start),

			 .ld_all(ld_all),
			 .enable(enable),
			 .done(done));


endmodule

module datapath_ss(
    input clk,
    input resetn,
    input ld_all,
	 input enable,
	 input move,
	 input left,
	 input right,
	 input no_colour,
	 input ld_colour,

    output reg [7:0] x,
	 output reg [6:0] y,
	 output reg [2:0] c_out);

	 reg [3:0] increment;
	 reg [7:0] x_hold;
	 reg [6:0] y_hold;
	 reg [2:0] c_hold;

	 reg move_left, move_right;

	 wire black = increment == 4'd1 | increment == 4'd2 | increment == 4'd4 | increment == 4'd7 | increment == 4'd8 | increment == 4'd11 | increment == 4'd13 | increment == 4'd14;
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
				x <= x_hold + increment[1:0];
				y <= y_hold + increment[3:2];
				if (black)
				begin
					c_out <= 3'd0;
				end
				else
				begin
					c_out <= c_hold;
				end
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
				x_hold <= 8'd56;
				y_hold <= 7'd116;
				c_hold <= 3'd3;
		  end
		  else if (move)
		  begin
				if (move_right && x_hold != 8'd116)
				begin
					x_hold <= (x_hold + 1'd1); // Move right
				end
				else if (move_left && x_hold != 8'd1)
				begin
					x_hold <= (x_hold - 1'd1); // Move left
				end
		  end
		  if (ld_colour)
		  begin
			  if (no_colour)
					c_hold <= 3'd0;
			  else
					c_hold <= 3'd6;
		  end
    end

	 always@(posedge clk)
    begin: increment_counter
        if(!resetn | !enable)
		  begin
            increment <= 4'd0;
		  end
        else if (enable)
		  begin
            increment <= increment + 1'd1;
		  end
    end // increment


	 always@(posedge clk)
    begin: move_movement
        if(!resetn | move_right == 1'd1 | move_left == 1'd1)
		  begin
            move_right <= 1'd0;
				move_left <= 1'd0;
		  end
		  if (right)
				move_right <= 1'd1;
		  else if (left)
				move_left <= 1'd1;
    end // movement


endmodule
