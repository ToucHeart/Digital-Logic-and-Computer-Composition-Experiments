module divider(
			input clk,
			output clk_1sec
			);
			
	reg clk_1s;
	reg[27:0] count_clk;
	
	assign clk_1sec=clk_1s;
	initial
	begin
		clk_1s=0;
		count_clk=0;
	end
	
	always@(posedge clk)
	begin
		begin
			if(count_clk==24999999)
				begin
					count_clk<=0;
					clk_1s <= ~clk_1s;
				end
			else
				count_clk<=count_clk+28'b1;
		end
	end
endmodule
