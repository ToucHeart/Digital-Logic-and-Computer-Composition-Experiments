module mykey
    (
    input clk, clrn, ps2_clk, ps2_data,
    output reg [6:0] keycount_high, keycount_low, ascii_high, ascii_low, scancode_high, scancode_low,
	  output cap_on,
    output reg [7:0] dis_data
    );
    
    wire [7:0] data;
    wire ready, overflow;
    reg nextdata_n;
	 
    ps2_keyboard inst
    (
      .clk(clk),
      .clrn(clrn),
      .ps2_clk(ps2_clk),
      .ps2_data(ps2_data),
	  .nextdata_n(nextdata_n),
      .data(data),
      .ready(ready),
      .overflow(overflow)
    );
    
    reg [7:0] keycount;//记录数目
    reg counted;
	
    wire [7:0] ascii;
	 
	 reg capon;
	 
    rom arom(dis_data,capon,ascii);
		
    bcd7seg out1(0,dis_data[3:0],scancode_low);
    bcd7seg out2(0,dis_data[7:4],scancode_high);
    bcd7seg out3(0,ascii[3:0],ascii_low);
    bcd7seg out4(0,ascii[7:4],ascii_high);
    bcd7seg out5(0,keycount[3:0],keycount_low);
    bcd7seg out6(0,keycount[7:4],keycount_high);
	

	 assign cap_on=capon;
	 reg [7:0] prevkey;
    initial
    begin
      nextdata_n = 1;
      counted = 0;
      keycount = 0;
		dis_data=8'b0;
		capon=0;
      prevkey=8'b0;
    end
	  

    always @(negedge clk)
    begin
      if(clrn==0) 
        begin
            nextdata_n = 1;
            counted = 0;
            keycount = 0;
			dis_data=8'b0;
            prevkey=8'b0;
        end
      else
        begin
            if(ready)//读数据
            begin
                if(data!=8'hF0)//按下去,或者松开之后的下一个
                begin
                    if(prevkey!=8'hF0)//不是松开
                    begin
								dis_data=data;
                        if(data==8'h58)//press cap
                        begin						      
									if(capon==1)
										capon<=0;
									else
										capon<=1;
                        end
                        if(counted==0)
                        begin
                          keycount<=keycount+1;
                          counted=1;
                        end
                    end
                    else if(prevkey==8'hF0)
                    begin
                        dis_data<=8'b0;
                        prevkey=8'b0;
                    end
                end
                else//松开
                begin
                    prevkey=8'hF0;
                    dis_data=8'b0;
                    counted=0;
                end
                nextdata_n <= 0;
            end
            else
                nextdata_n <= 1;
        end
    end

endmodule 