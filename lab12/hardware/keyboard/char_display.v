module char_display(
		    input clk, clrn,
			input no_input,//1:无输入,0:有输入
			input [2:0] command,
			input [7:0] char_ascii,
			input cpuclk,//CPU时钟12.5M
			input [3:0]dmemaddr,
			input cpuread,
			output reg[7:0] data2cpu,
			//	output [3:0]keyw,//for debug
			//	output [7:0]ascii
			output [7:0]key0,
			output [7:0]key1,
			output [7:0]key2
		);
		
		reg [7:0] keyin[15:0];
		reg [3:0] keycount;//记录数目
		integer i;
		initial
		begin
			keycount=4'b0;
			for(i=0;i<16;i=i+1)
				keyin[i]=8'b0;
		end
		
		assign key0=keyin[0];
		assign key1=keyin[1];
		assign key2=keyin[2];
		
		clkgen #(6) printclk(clk,clrn,1'b1,print_clk);
		wire print_clk;
		
		always@(posedge cpuclk)
		begin
			if(cpuread)
			begin
				if(dmemaddr==keycount)
					data2cpu=8'b0;
				else
				begin
					data2cpu=keyin[dmemaddr];
				end
			end
		end
		
		always@(posedge print_clk)
		begin
			if(no_input)//无输入
			begin
				keycount=keycount;
			end
			else                  //字符输入
			begin
				keyin[keycount]=char_ascii;
				keycount=keycount+1;
			end
		end
endmodule 