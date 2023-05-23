module Ram(
			input clock,			//KEY[0],posedge
			input we,    			//KEY[1],
			input [1:0] din,		//SW[9:8],
			input [3:0] raddr,	//SW[7:4],
			input [3:0] waddr,	//SW[3:0],
			output [6:0]	low,	//HEX0,
			output [6:0]	high	//HEX1
			);
			
			reg [7:0] ram [15:0];
			
			initial
			begin
				$readmemh("E:/Digital_Design/exp5/mem1.txt", ram, 0, 15);
			end
			
			always@(posedge clock)
			begin
				if(!we)
					ram[waddr]<={6'b0,din};
			end
			
			bcd7seg bcd1(ram[raddr][3:0],low);
			bcd7seg bcd2(ram[raddr][7:4],high);
			
endmodule 