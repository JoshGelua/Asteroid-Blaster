module bullet(
		input clk,
		input resetn,
		input fire,
		input [7:0] ss_x,
		input [7:0] ast1_x,
		input [7:0] ast2_x,
		input [7:0] ast3_x,
		input [7:0] ast4_x,
		input [7:0] ast5_x,
		input [7:0] ast6_x,
		input [7:0] ast7_x,
		input [7:0] ast8_x,
		
		output reg [3:0] which);
		
		
		wire hit1, hit2, hit3, hit4, hit5, hit6, hit7, hit8;
		assign hit1 = (ast1_x < ss_x + 2'd3) & (ast1_x >= ss_x - 2'd3);
		assign hit2 = (ast2_x < ss_x + 2'd3) & (ast2_x >= ss_x - 2'd3);
		assign hit3 = (ast3_x < ss_x + 2'd3) & (ast3_x >= ss_x - 2'd3);
		assign hit4 = (ast4_x < ss_x + 2'd3) & (ast4_x >= ss_x - 2'd3);
		assign hit5 = (ast5_x < ss_x + 2'd3) & (ast5_x >= ss_x - 2'd3);
		assign hit6 = (ast6_x < ss_x + 2'd3) & (ast6_x >= ss_x - 2'd3);
		assign hit7 = (ast7_x < ss_x + 2'd3) & (ast7_x >= ss_x - 2'd3);
		assign hit8 = (ast8_x < ss_x + 2'd3) & (ast8_x >= ss_x - 2'd3);
		
		
		
		
		always@(posedge clk)
		begin: bullet_table
			if(!resetn | !fire)
			begin
				which <= 4'd0;
			end
			else if (fire)
			begin
				if (hit1)
				begin
					which <= 4'd1;
				end
				else if (hit2)
				begin
					which <= 4'd2;
				end
				else if (hit3)
				begin
					which <= 4'd3;
				end
				else if (hit4)
				begin
					which <= 4'd4;
				end
				else if (hit5)
				begin
					which <= 4'd5;
				end
				else if (hit6)
				begin
					which <= 4'd6;
				end
				else if (hit7)
				begin
					which <= 4'd7;
				end
				else if (hit8)
				begin
					which <= 4'd8;
				end
			end
		end // Bullet table
		
endmodule
		
		
		
		