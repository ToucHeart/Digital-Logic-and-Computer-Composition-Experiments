module rom
   (
   input [7:0] addr,
	input capison,
   output reg [7:0] dout
   );

   reg [7:0] normcode[255:0];
	reg [7:0] data;
   initial 
   begin
      dout = 8'b0;
      $readmemh("E:/Digital_Design/exp9/transfcode.txt", normcode, 0, 255);
   end
      
   always @ (*) 
   begin
		data=normcode[addr];//scancode to ascii
		if(capison&&data>=8'd97&&data<=8'd122)
			dout = normcode[addr]-8'd32;
		else
			dout = normcode[addr];
   end
   
endmodule