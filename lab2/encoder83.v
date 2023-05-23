
module encoder83(
	input [7:0]		x,
	input en,
	output    valid,            //输入有效提示位
	output    reg [3:0] out,   //编码结果输出
	output    [6:0]	  HEX
);

	assign valid = en & (|x);//8 个开关全 0 时指示位为 0，在en有效时有任何一个开关为 1 时指示位为 1
	
	always @(*) 
	begin
		if (en)
		    begin
            	    casez(x)
							 8'b00000001:out = 4'b0000;
							 8'b0000001z:out = 4'b0001;
							 8'b000001zz:out = 4'b0010;
							 8'b00001zzz:out = 4'b0011;
							 8'b0001zzzz:out = 4'b0100;
							 8'b001zzzzz:out = 4'b0101;
							 8'b01zzzzzz:out = 4'b0110;
							 8'b1zzzzzzz:out = 4'b0111;
							 default:	 out = 4'b1111;
            	    endcase
        	    end
		else
		    out = 4'b1111;
	end
	
	bcd7seg bcd(out, HEX);
	
endmodule


module bcd7seg(
	 input  [3:0] b,
	 output reg [6:0] h
	 );
	 
	 always @(*) begin
		case (b)
			4'b0000: h = 7'b1000000;
			4'b0001: h = 7'b1111001;
			4'b0010: h = 7'b0100100;
			4'b0011: h = 7'b0110000;
			4'b0100: h = 7'b0011001;
			4'b0101: h = 7'b0010010;
			4'b0110: h = 7'b0000010;
			4'b0111: h = 7'b1111000;
			4'b1000: h = 7'b0000000;
			4'b1001: h = 7'b0010000;
			default: h = 7'b1111111;
		endcase
	end
	
endmodule



