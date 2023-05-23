module alu(    //top module
	input [31:0] dataa,
	input [31:0] datab,
	input [3:0]  ALUctr,
	output reg less,
	output reg zero,
	output reg [31:0] aluresult
	);

	wire [31:0] f;
    wire [31:0] shiftresult;
	wire CF,ZERO,OF;
    reg lr=0,al=0;

	adder add(dataa,datab,|ALUctr,f,CF,ZERO,OF);
    barrel shift(dataa,datab[4:0],lr,al,shiftresult);
    
always@(*)
begin
    if(ALUctr==4'b0000||ALUctr==4'b1000)
        aluresult=f;
    else if(ALUctr[2:0]==3'b011)
        aluresult=datab;
    else if(ALUctr[2:0]==3'b100)
        aluresult=datab^dataa;
    else if(ALUctr[2:0]==3'b110)
        aluresult=datab|dataa;
    else if(ALUctr[2:0]==3'b111)
        aluresult=datab&dataa;
    else if(ALUctr[2:0]==3'b001)
    begin
        lr=1;
        aluresult=shiftresult;
    end
    else if(ALUctr==4'b0101)
    begin
        lr=0;
        al=0;
        aluresult=shiftresult;
    end
    else if(ALUctr==4'b1101)
    begin
        lr=0;
        al=1;
        aluresult=shiftresult;
    end
    zero=~(| aluresult[31:0]);

    if(ALUctr==4'b0010)
    begin
        less=(OF!=f[31]);
        aluresult=less;
        zero=(dataa==datab);
    end
    else if(ALUctr==4'b1010)//无符号比较
    begin
        less=CF;
        aluresult=less;
        zero=(dataa==datab);
    end
end

endmodule


module barrel(  //移位器
    input [31:0] indata,
	input [4:0] shamt,
	input lr,
	input al,
	output reg [31:0] outdata
);
always@(*)
begin
    outdata=indata;
    if(lr==1)//left shift
    begin
        if(shamt[0]==1)
            outdata={outdata[30:0],1'b0};
        if(shamt[1]==1)
            outdata={outdata[29:0],2'b00};
        if(shamt[2]==1)
            outdata={outdata[27:0],4'b0000};
        if(shamt[3]==1)
            outdata={outdata[23:0],8'b0};
        if(shamt[4]==1)
            outdata={outdata[15:0],16'b0};
    end
    else//right shift
    begin
        if(al==0)//logical shift
        begin
            if(shamt[0]==1)
                outdata={1'b0,outdata[31:1]};
            if(shamt[1]==1)
                outdata={2'b0,outdata[31:2]};
            if(shamt[2]==1)
                outdata={4'b0,outdata[31:4]};
            if(shamt[3]==1)
                outdata={8'b0,outdata[31:8]};
            if(shamt[4]==1)
                outdata={16'b0,outdata[31:16]};
        end
        else//arithmetical shift
        begin
            if(shamt[0]==1)
                outdata={outdata[31],outdata[31:1]};
            if(shamt[1]==1)
                outdata={{2{outdata[31]}},outdata[31:2]};
            if(shamt[2]==1)
                outdata={{4{outdata[31]}},outdata[31:4]};
            if(shamt[3]==1)
                outdata={{8{outdata[31]}},outdata[31:8]};
            if(shamt[4]==1)
                outdata={{16{outdata[31]}},outdata[31:16]};
        end
    end
end
endmodule

module adder //加法器
(
	input  [31:0] A,
	input  [31:0] B,
	input  addsub,
	output [31:0] F,
	output cf,
	output zero,
	output of
);

	wire temp;
	wire [31:0] t_no_Cin= {32{addsub}} ^ B;
	assign {temp,F[31:0]} = A + t_no_Cin + addsub;
	assign cf=temp^addsub;
	assign of = (A[31] == t_no_Cin[31])&& (A[31] != F[31]); 
	assign zero = ~(| F[31:0]);

endmodule