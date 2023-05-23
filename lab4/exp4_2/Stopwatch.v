module  Stopwatch(
        input clk,
        input pause,//SW[2]
        input reset,//,SW[3]
        output [5:0] h,m,s
);
		  
		  reg [5:0] hour,min,sec;
        initial
        begin
            hour=0;
            min=0;
            sec=0;
        end
			
		  assign h=hour;
		  assign m=min;
		  assign s=sec;
		  
        wire clk_1s;
        divider div(clk,clk_1s);

        always @ (posedge clk_1s) 
        begin
            if (reset==1) 
                begin
                    hour<= 0;
                    min <= 0;
                    sec <= 0;
                end
            else if(pause==1)
                begin
                    hour <= hour;
                    min <= min;
                    sec <= sec;
                end
            else
                begin
                    if (sec == 59) 
                        begin
                            sec <= 0;
                            if (min == 59) 
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