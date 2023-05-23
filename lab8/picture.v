module picture
(
    input clk,
    input reset,
    output vga_clk,//25MHz 时钟
    output hs,// 行同步和列同步信号
    output vs,
    output valid, //VGA 消隐信号（低有效）VGA_BLANK_N,当valid==1时不消隐
    output [3:0] R,// 红绿蓝颜色信号
    output [3:0] G,
    output [3:0] B
);

    wire [11:0] vga_data;
    wire [9:0] h_addr, v_addr;
	 
    ram1port myram({h_addr,v_addr[8:0]},clk,12'b0,1'b0,vga_data);
		
	 vga_ctrl ctrl(vga_clk,reset,reldata,h_addr,v_addr, hs,vs,valid,R,G,B);
	 
    clkgen #(25000000) vgaclk(clk,reset,1'b1,vga_clk);//该模块生成25MHz 时钟,传入vga_ctrl,并驱动VGA_CLK
	
		reg [11:0] reldata;
	   always@(posedge clk)
		begin
			reldata<=vga_data;
		end
		
endmodule