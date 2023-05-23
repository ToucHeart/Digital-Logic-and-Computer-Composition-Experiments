module  alarm(
        input clk,
        input [1:0] modifyen,
        input [2:0] modifytime,
		  input hit,//是否在响铃时间内
        output [5:0] h,m,s,
		  output ala
);
        
        reg [5:0] hour,min,sec;
		  reg ishit;
		  
        initial
        begin
            hour=5;
            min=5;
            ishit=0;
				sec=30;
        end
		  
		  assign ala=ishit;
		  assign h=hour;
        assign m=min;
        assign s=sec;
		  
        wire clk_1s;
        divider div(clk,clk_1s);
        always @ (posedge clk_1s) 
        begin
            if (modifyen==2'b10) 
                begin
                    if (~ modifytime[2]) 
                        hour <= ( hour + 1) % 24;
                    if (~ modifytime[1]) 
                        min <= ( min + 1) % 60;
                    if (~ modifytime[0]) 
                        sec <= ( sec + 1) % 60;
                end
				else if(hit==1)
					begin
						 if(ishit==1)
								ishit=0;
						 else
								ishit=1;
					end
				else
					 ishit=0;
        end
endmodule