module dmem    //数据存储器
(
	input  [31:0] addr,//读写地址
	input  [31:0] datain,//存储器写入的数据
	input  rdclk,//读取时钟,上升沿
	input  wrclk,//写入时钟,上升沿
	input [2:0] memop,// 内存操作控制位
	input we,//写使能，高电平有效
	output [31:0] dataout//存储器读取结果
	);

	reg [31:0] outdata;
	assign dataout=outdata;

	reg [31:0] tempout;
	wire [31:0] tempin;
	reg [7:0] ram [4095:0];

	integer i;
	initial
	begin
		tempout=0;
		for(i=0;i<=4095;++i)
			ram[i]=0;
		outdata=0;
	end
	always@(posedge rdclk)
	begin
		if(we)
			tempout<={ram[addr+3],ram[addr+2],ram[addr+1],ram[addr]};
		else
		begin
			case(memop)
			3'b000:
				outdata<={{24{ram[addr][7]}},ram[addr]};
			3'b001:
				outdata<={{16{ram[addr+1][7]}},ram[addr+1],ram[addr]};
			3'b010:
				outdata<={ram[addr+3],ram[addr+2],ram[addr+1],ram[addr]};
			3'b100:
				outdata<={24'b0,ram[addr]};
			3'b101:
				outdata<={16'b0,ram[addr+1],ram[addr]};
			endcase
		end
	end

	assign tempin[7:0] = (~memop[2])?datain[7:0]:tempout[7:0];//byte
 	assign tempin[15:8] = (~memop[2]&&(|memop[1:0]))?datain[15:8]:tempout[15:8];//word
 	assign tempin[31:16] = (~memop[2]&&memop[1]&&~memop[0])?datain[31:16]: tempout[31:16];//double-word

	//tempout是该位置原来的数据
	//datain是新数据

	always@(posedge wrclk)
 	begin
 		if(we)
 		begin
 			{ram[addr+3],ram[addr+2],ram[addr+1],ram[addr]}<=tempin;
 		end
	end

endmodule