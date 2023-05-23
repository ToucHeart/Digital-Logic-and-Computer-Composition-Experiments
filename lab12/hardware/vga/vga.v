module vga(
  input clk,
  input [9:0] h_addr,
  input [9:0] v_addr,
  output reg [23:0] dataout,
  input [31:0]dmemdatain,
  input [31:0]dmemaddr,
  input dmemwrclk,
  input awe,
  output [5:0]lnum
  );
  wire [11:0] addr_ascii;
  wire [7:0] ascii;
  wire [11:0] addr_font;
  wire [11:0] vga_font;
  
  assign lnum=lineNum;
  reg [5:0] lineNum;//行号
  
  initial 
  begin
		lineNum=0;
  end
  
  assign  addr_ascii = h_addr / 9 + (v_addr/16) * 70+lineNum * 70;
  assign  addr_font = {ascii[7:0],v_addr[3:0]};//在字模中的位置
  
  always@(posedge clk)
  begin
    if (h_addr >= 630) 
    begin
      dataout = 24'b0;
    end
    else 
    begin
      dataout = {24{vga_font[h_addr % 9]}};//vga_data
    end
	 if(dmemaddr[31:20]==12'h005)
	 begin
		lineNum=dmemdatain[5:0];
	 end
  end

  asciistorage asciimem(dmemdatain[7:0],addr_ascii,clk,dmemaddr[11:0],dmemwrclk,awe,ascii);

  font fontmem(addr_font,clk,0,0,vga_font);

endmodule