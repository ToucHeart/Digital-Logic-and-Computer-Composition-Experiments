module char_display(
		input clk, 
		input clrn,
		input no_input,//1:无输入,0:有输入
		input [2:0] command,
		input [7:0] char_ascii,
		input [9:0] h_addr, 
		input [9:0] v_addr, 
		output reg [11:0] vga_data
//		output reg loc_sig
//      output reg char
		);
	
		reg [7:0] displayram[0:29][0:69];//30行,70列,每个8位显存
		reg [11:0] font[4095:0];//存储字模,每行12bit,每个16行*256个=4096行
				
		wire [3:0] curr_loc;//当前像素点
		wire [9:0] x_loc;//当前扫描点所在字符的x坐标
		wire [9:0] y_loc;//当前扫描点所在字符的y坐标
		//以左上角为原点建立字符坐标,y向下,x向右
		assign x_loc=h_addr/9;
		assign y_loc=v_addr>>4;	
		assign curr_loc=h_addr%9;
		
		//根据x_loc和y_loc来在显存中读取
		//displayram[y_loc][x_loc]
		
		wire [7:0] curr_ascii;
		wire [11:0] fontloc;//当前ASCII的字模行在font中的位置==ASCII*16+v_addr%16;
		wire [11:0] curr_line;//当前要显示的字模的一行

		
		assign curr_ascii=h_addr< 10'd630 ? displayram[y_loc][x_loc]: 8'b0;//读取当前位置的ASCII码
		assign fontloc={curr_ascii[7:0],v_addr[3:0]};//在字模中的位置
		assign curr_line=font[fontloc];//字模的一行

		reg [6:0] write_pointer_x;//显存写入指针,指示将要写入的位置
		reg [6:0] write_pointer_y;

		integer i,j;
		initial 
		begin
			write_pointer_y=0;
			write_pointer_x=0;
			for (i = 0; i < 30; i = i+1)
			begin
				for (j = 0; j < 70; j = j+1)
				begin
					displayram[i][j] = 8'b0;//全部初始化成0
				end
			end
			$readmemh("E:/Digital_Design/exp9/font_matrix.txt", font, 0, 4095);
		end

		always@(posedge clk)
		begin
			if(clrn)
			begin
				vga_data<=12'b0;
			end
			else
			begin
				vga_data<=curr_line[curr_loc[3:0]]?12'h1FF:12'h302;//无字符显示紫色,字符显示蓝绿色
			end													 
		end
		//如果当前像素点为1,则输出FFF,最终颜色为F0F0F0,否则输出000,最终颜色为000000;
		//2090d0:蓝色,209010,绿色,10f0f0:蓝绿色,300020:终端默认紫色
		
		
		clkgen #(6.5) printclk(clk,clrn,1'b1,print_clk);
		wire print_clk;
		
		always@(posedge print_clk)
		begin
		
			if(clrn)
			begin
				for (i = 0; i < 30; i = i+1)
				begin
					for (j = 0; j < 70; j = j+1)
					begin
						displayram[i][j] = 8'b0;//全部初始化成0
					end
				end
				write_pointer_y=0;
				write_pointer_x=0;
			end
			
			else if(no_input)//无输入
			begin
				write_pointer_x<=write_pointer_x;
				write_pointer_y<=write_pointer_y;
			end
			
			else if(command!=3'b0)// 有特殊输入
			begin
				case(command)
				3'd1://enter 
				begin
					if(write_pointer_y>=29)
					begin
						for (i = 0; i < 30; i = i+1)
						begin
							for (j = 0; j < 70; j = j+1)
							begin
								displayram[i][j] = 8'b0;//全部初始化成0
							end
						end
						write_pointer_y<=0;
						write_pointer_x<=0;
					end
					else
					begin
						write_pointer_x<=0;
						write_pointer_y<=write_pointer_y+1;
					end
				end
				3'd2://backspace
				begin
					if(write_pointer_x==0)
					begin
					
						if(write_pointer_y==0)
						begin
							write_pointer_x<=write_pointer_x;
							write_pointer_y<=write_pointer_y;
							displayram[write_pointer_y][write_pointer_x]<=8'b0;
						end
						
						else 
						begin
							write_pointer_y<=write_pointer_y-1;
							write_pointer_x<=69;//回到上一行最末尾的位置
							displayram[write_pointer_y][write_pointer_x]<=8'b0;
						end
						
					end
					
					else
					begin
						write_pointer_x<=write_pointer_x-1;
						displayram[write_pointer_y][write_pointer_x]<=8'b0;
					end
					
				end
				endcase
			end
			
			else                  //字符输入
			begin
				if(write_pointer_x==69)
				begin
				
					if(write_pointer_y==29)
					begin
						displayram[write_pointer_y][write_pointer_x]<=char_ascii;
						write_pointer_y<=write_pointer_y+1;
					end
					
					else if(write_pointer_y==30)
					begin
						for (i = 0; i < 30; i = i+1)
						begin
							for (j = 0; j < 70; j = j+1)
							begin
								displayram[i][j] = 8'b0;//全部初始化成0
							end
						end						
						write_pointer_y<=0;
						write_pointer_x<=0;
						displayram[write_pointer_y][write_pointer_x]<=char_ascii;
					end
					
					else
					begin
						displayram[write_pointer_y][write_pointer_x]<=char_ascii;
						write_pointer_y<=write_pointer_y+1;
						write_pointer_x<=0;
					end
				end
				
				else
				begin
					displayram[write_pointer_y][write_pointer_x]<=char_ascii;
					write_pointer_x<=write_pointer_x+1;
				end
			end
		end
endmodule 