 //实现RV32I寄存器堆。
module regfile(
	input  [4:0]  ra,//读取口a地址，5位
	input  [4:0]  rb,///读取口b地址，5位
	input  [4:0]  rw,//写入地址，5位
	input  [31:0] wrdata,
	input  regwr,//write enable
	input  wrclk,//wr clk
	output [31:0] outa,
	output [31:0] outb
	);
	

	reg [31:0] regs[31:0];	
	assign outa=regs[ra];
	assign outb=regs[rb];
	initial
		regs[0]=32'b0;
		
	always@(negedge wrclk)
	begin
		if(regwr)
			regs[rw]=wrdata;
		regs[0]=32'b0;
	end
endmodule

/*
输入格式
input  [4:0]  ra, //读取口a地址，5位
input  [4:0]  rb, //读取口b地址，5位
input  [4:0]  rw, //写入地址，5位
input  [31:0] wrdata, //写入数据，32位
input  regwr, //写入使能，1位高电平有效
input  wrclk, //写入时钟，上升沿触发

输出格式
output [31:0] outa,  //输出读取数据a
output [31:0] outb  //输出读取数据b
读取不受时钟控制，只要地址改变立即输出新数据。
写入地址由rw决定，写入数据由32位wrdata决定。

*/