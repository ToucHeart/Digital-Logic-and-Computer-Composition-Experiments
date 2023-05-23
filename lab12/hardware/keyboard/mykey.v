module mykey
    (
    input clk, clrn, ps2_clk, ps2_data,
	 output cap_on,
    output [7:0] ascii,
	 output reg noinput,
	 output reg [2:0] command
    );
    
    wire [7:0] data;
    wire ready, overflow;
    reg nextdata_n;
	 reg [7:0] dis_data;
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
    
    reg [4:0] keycount;//记录数目
    reg counted;
	 
	 reg capon;
	 
    rom arom(dis_data,capon,ascii);
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
		noinput=1;
		command=3'b0;
    end
	  

    always @(negedge clk)
    begin
      if(clrn) 
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
							noinput=1; //否则按下cap会多出一个空格
							if(capon==1)
								capon<=0;
							else
								capon<=1;
                        end
								
						else if(data==8'h5A)
						begin
							noinput=0;
							command<=1;//enter
						end
						
						else if(data==8'h66)
						begin
							noinput=0;
							command<=2;//backspace
						end
						
						else
						begin
							noinput=0;
							command<=3'b0;//command==0,代表无特殊输入
						end
								
                        if(counted==0)
                        begin
                          keycount<=keycount+1;
                          counted=1;
                        end
								
                    end
                    else if(prevkey==8'hF0)//松开后的一个
                    begin
								noinput=1;
                        dis_data<=8'b0;
                        prevkey=8'b0;
                    end
                end
                else//松开
                begin
						  noinput=1;
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