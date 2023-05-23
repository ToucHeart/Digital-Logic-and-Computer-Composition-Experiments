module  rv32is(
	input 	clock,
	input 	reset,
	output [31:0] imemaddr,
	input  [31:0] imemdataout,//取出的指令
	output 	imemclk,
	output [31:0] dmemaddr,
	input  [31:0] dmemdataout,
	output [31:0] dmemdatain,
	output 	dmemrdclk,
	output	dmemwrclk,
	output [2:0] dmemop,
	output	dmemwe,//write enable
	output [31:0] dbgdata
	);
	//指令分解 begin
	wire [6:0] op;
	wire [4:0] rs1,rs2,rd;
	wire [2:0] func3;
	wire [6:0] func7;

	assign op = imemdataout[6:0];  
	assign rs1 = imemdataout[19:15]; 
	assign rs2 = imemdataout[24:20]; 
	assign rd =imemdataout[11:7]; 
	assign func3 = imemdataout[14:12]; 
	assign func7 = imemdataout[31:25];
	//end

	reg [31:0] PC;
	assign dbgdata=PC;    
    assign dmemrdclk=clock;//上升沿读取
    assign dmemwrclk=~clock;//下降沿写入
    assign imemclk=~clock;//下降沿读取

	wire regwr;	
	wire aluasrc;
	wire [1:0]alubsrc;
	wire [3:0] aluctr;
	wire mem2reg;
	wire [31:0] busA,busB;
	wire zero,less;
	wire [2:0] branch;
	wire [2:0] extop;
	wire [31:0] imm;
    reg [31:0] regsWrdata;
    reg [31:0] dmemin;
    initial
    begin
        dmemin=32'b0;
        regsWrdata=32'b0;
        PC=32'b0;
    end
    assign dmemdatain=dmemin;

	assign imemaddr=reset?0:pc_;
	
	wire [31:0] pc_;
    
	nextPc nextpc(reset,zero,less,PC,branch,imm,busA,pc_);

	instr2imm immGen(imemdataout,extop,imm);
	
	controller control(op[6:2],func3,func7[5],extop,regwr,aluasrc,alubsrc,aluctr,branch,mem2reg,dmemwe,dmemop);

	regfile myregfile(rs1,rs2,rd,regsWrdata,regwr,clock,busA,busB);

	wire [31:0] aluresult;
	wire [31:0] alusrca;
    wire [31:0] alusrcb;

    assign alusrca=(aluasrc?PC:busA);

    assign alusrcb=(alubsrc[1]?32'd4:(alubsrc[0]?imm:busB));

    alu myalu(alusrca,alusrcb,aluctr,less,zero,aluresult);

	assign dmemaddr=aluresult;

	always@(negedge clock)
	begin
		PC<=pc_;
		if(reset)
			PC<=32'b0;
	end	

    always@(*)
    begin
        if(mem2reg==1)
		begin
            case(dmemop)
            3'b000:
            regsWrdata={{24{dmemdataout[7]}}, dmemdataout[7:0]};
            3'b001:
            regsWrdata={{16{dmemdataout[15]}},dmemdataout[15:0]};
            3'b010:
            regsWrdata=dmemdataout;
            3'b100:
            regsWrdata={24'b0,dmemdataout[7:0]};
            3'b101:
            regsWrdata={16'b0,dmemdataout[15:0]};
            endcase
        end

		else
        begin
			regsWrdata=aluresult;
        end
        
        if(dmemwe==1)
        begin
            case(dmemop)
            3'b000:
            dmemin={{24{busB[7]}},busB[7:0]};
            3'b001:
            dmemin={{16{busB[15]}},busB[15:0]};
            3'b010:
            dmemin=busB;
            endcase
        end
    end

endmodule

module regfile(
	input  [4:0]  ra,//读取口a地址，5位
	input  [4:0]  rb,///读取口b地址，5位
	input  [4:0]  rw,//写入地址，5位
	input  [31:0] wrdata,
	input  regwr,//write enable
	input  wrclk,//wr clk
	output [31:0] outa,
	output [31:0] outb
	);
	

	reg [31:0] regs[31:0];	
	assign outa=regs[ra];
	assign outb=regs[rb];

    integer i;
	initial
    begin
		for(i=0;i<32;i=i+1)
        begin
            regs[i]=32'b0;
        end
	end

	always@(negedge wrclk)
	begin
		if(regwr)   
        begin
			regs[rw]<=wrdata;
        end
		regs[0]<=32'b0;
	end

endmodule


//pc 和寄存器堆立即输出,
//指令存储器和数据存储器用时钟
module nextPc
(
    input reset,
    input zero,
    input less,
    input [31:0] pc,
    input [2:0] branch,
    input [31:0] imm,
    input [31:0] rs1,
    output reg [31:0] nextpc
);

    wire [31:0] seqpc=pc+32'd4;
    wire [31:0] jalpc=pc+imm;
    wire [31:0] jalrpc=rs1+imm;
    always@(*)
    begin
        if(reset)
			nextpc=32'b0;
        else
        begin
            case(branch)
            3'b000:nextpc=seqpc;
            3'b001:nextpc=jalpc;
            3'b010:nextpc=jalrpc;
            3'b100:
            begin
                if(zero==0)
                    nextpc=seqpc;
                else
                    nextpc=jalpc;
            end
            3'b101:
            begin
                if(zero==0)
                    nextpc=jalpc;
                else
                    nextpc=seqpc;
            end
            3'b110:
            begin
                if(less==0)
                    nextpc=seqpc;
                else
                    nextpc=jalpc;
            end
            3'b111:
            begin
                if(less==0)
                    nextpc=jalpc;
                else
                    nextpc=seqpc;
            end
        endcase
        end
    end
endmodule

module instr2imm
(
    input [31:0] instr,
    input [2:0] extop,
    output reg [31:0] imm
);
 	wire [31:0] immI,immU,immS,immB,immJ;
	 
	assign immI = {{20{instr[31]}}, instr[31:20]};
    assign immU = {instr[31:12], 12'b0};
    assign immS = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    assign immB = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    assign immJ = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
    
    initial
    begin
        imm=32'b0;
    end
    
    always@(*)
    begin
        case(extop)
        3'd0:imm=immI;
        3'd1:imm=immU;
        3'd2:imm=immS;
        3'd3:imm=immB;
        3'd4:imm=immJ;
        endcase
    end

endmodule

module controller
(
    input [4:0] opcode,//opcode高5位
    input [2:0] func3,
    input func7,//func7次高位
    output [2:0] ExtOp,
    output RegWr,
    output ALUAsrc,
    output [1:0]ALUBsrc,
    output [3:0] ALUctr,
    output [2:0] Branch,
    output Mem2Reg,
    output MemWr,
    output [2:0]MemOp
);
    assign ExtOp[2]=(opcode==5'b11011)?1'b1:1'b0;
    assign ExtOp[1]=(opcode[3:0]==4'b1000)?1'b1:1'b0;
    assign ExtOp[0]=(opcode[2:0]==3'b101)||(opcode==5'b11000);

    assign RegWr=(opcode[3:0]==4'b1000)?1'b0:1'b1;
    assign Branch[0]=(opcode==5'b11011)||(opcode==5'b11000&&func3[0]);
    assign Branch[1]=(opcode==5'b11001)||(opcode==5'b11000&&func3[2]);
    assign Branch[2]=(opcode==5'b11000);

    assign Mem2Reg=((opcode==5'b00000)?1'b1:1'b0);

    assign MemWr=(opcode==5'b01000)?1'b1:1'b0;

    assign ALUAsrc=(opcode==5'b00101||opcode==5'b11011||opcode==5'b11001);

    assign ALUBsrc[0]=(opcode==5'b00100||opcode==5'b00101||opcode==5'b01101||opcode==5'b00000||opcode==5'b01000);
    assign ALUBsrc[1]=(opcode==5'b11011||opcode==5'b11001);
   assign MemOp=(~opcode[4]&~opcode[2]&~opcode[1]&~opcode[0])?func3:3'b000;
    
    reg [3:0] ctrl;
    assign ALUctr=ctrl;
    initial
    begin
        ctrl=4'b0000;
    end
    always@(*)
    begin
        case (opcode)
        5'b00000,5'b01000:
        begin
            ctrl=4'b0000;
        end
        5'b11000:
        begin
            case (func3)
            3'b110,3'b111:
            ctrl=4'b1010;
            default:ctrl=4'b0010; 
            endcase
        end
        5'b11001,5'b11011:
        ctrl=4'b0000;
        5'b01100:
        begin
            case (func3)
            3'b000:
            begin
                if(func7==1)
                    ctrl=4'b1000;
                else
                    ctrl=4'b0000;
            end
            3'b001:
            ctrl=4'b0001;
            3'b010:
            ctrl=4'b0010;
            3'b011:
            ctrl=4'b1010;
            3'b100:
            ctrl=4'b0100;
            3'b101:
            begin
                if(func7==1)
                    ctrl=4'b1101;
                else
                    ctrl=4'b0101;
            end
            3'b110:
            ctrl=4'b0110;
            3'b111:
            ctrl=4'b0111;
            endcase
        end
        5'b00100:
        begin
            case (func3)
            3'b101:
            begin
                if(func7==1)
                    ctrl=4'b1101;
                else
                    ctrl=4'b0101;
            end
            3'b000:
            ctrl=4'b0000;
            3'b010:
            ctrl=4'b0010;
            3'b011:
            ctrl=4'b1010;
            3'b100:
            ctrl=4'b0100;
            3'b110:
            ctrl=4'b0110;
            3'b111:
            ctrl=4'b0111;
            3'b001:
            ctrl=4'b0001;
            endcase
        end
        5'b00101:
        ctrl=4'b0000;
        5'b01101:
        ctrl=4'b0011;
        endcase
    end

endmodule



module alu( 
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
    reg lr,al;

    initial
    begin
        less=0;
        zero=0;
        lr=0;
        al=0;
    end

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

    if(ALUctr==4'b0010)//带符号小于
    begin
        less=(OF!=f[31]);//of!=sign 小于
        aluresult=less;
        zero=(ZERO==1);
    end
    else if(ALUctr==4'b1010)//无符号比较
    begin
        less=CF;//cf == 1小于
        aluresult=less;
        zero=(ZERO==1);
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

//input lr, //为1时左移，为0时右移
// input al, //为1时算术移位，为0时逻辑移位

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
	assign zero = ~(| F[31:0]);//全部是0时,zero为1

endmodule
 