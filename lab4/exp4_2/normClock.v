module normClock(
        input clk,
        input [3:0] modifytime,
        output [5:0] h,m,s
);
	
		  reg [5:0] hour,min,sec;
        initial
        begin
               hour=0;
               min=5;
               sec=20;
        end
		  
		  assign h=hour;
		  assign m=min;
		  assign s=sec;
	
        wire clk_1s;
        divider div(clk,clk_1s);
        always @ (posedge clk_1s) 
        begin
                if (~ modifytime [3]) 
                        begin
                        if (~ modifytime[2]) 
                                hour <= ( hour + 1) % 24;
                        if (~ modifytime[1]) 
                                min <= ( min + 1) % 60;
                        if (~ modifytime[0]) 
                                sec <= ( sec + 1) % 60;
                        end
                else
                begin
                if (sec == 59) 
                        begin
                        sec <= 0;
                        if (min >= 59) 
                                begin
                                min <= 0;
                                if(hour== 23)
                                        hour <=0;
                                else
                                        hour<=hour+1;
                                end
                        else
                                min <= min + 1;
                        end
                else
                        begin
                        sec <= sec + 1;
                        end
                end 
        end
endmodule 