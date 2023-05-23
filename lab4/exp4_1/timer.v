module timer(
			input clk,	 //其中 clk 是系统时钟,对应CLOCK_50
			input start, //对应SW[0]
			input pause, //对应SW[1]
			input reset, //对应SW[2]
			output over, //对应LEDR[0]
			output [6:0] lowbit, //对应HEX[0]
			output [6:0] highbit //对应HEX[1]
			);
			
			reg isover;
			assign over=isover;
			reg [3:0] low;
			reg [3:0] high;
			
			wire clk_1s;
			divider Div(clk,clk_1s);
			
			initial
			begin
        			isover=0;
        			low=0;
        			high=0;
			end
			
			always@(posedge clk_1s)
				begin
					if(reset==1)
						begin
							low<=0;
							high<=0;
						end
					else if(pause==1)
						begin
							low<=low;
							high<=high;
						end
					else if(start==1)
						begin
							if(high==9&&low==9)
								begin
									high<=4'b0000;
									low<=4'b0000;
									isover<=1;
								end
							else if(low==9&&high!=9)
								begin
									high<=high+4'b0001;
									low<=0;
									isover<=0;
								end
							else
								begin
									low<=low+4'b0001;
									high<=high;
									isover<=0;
								end
						end
				end
        bcd7seg bcd7seg1(low,lowbit);
		  bcd7seg bcd7seg2(high,highbit);
endmodule 