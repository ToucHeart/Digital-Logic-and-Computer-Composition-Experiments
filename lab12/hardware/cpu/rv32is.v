module rv32is(
	input 	clock,
	input 	reset,
	output [31:0] imemaddr,
	input  [31:0] imemdataout,
	output 	imemclk,
	output [31:0] dmemaddr,
	input  [31:0] dmemdataout,
	output [31:0] dmemdatain,
	output 	dmemrdclk,
	output	dmemwrclk,
	output [2:0] dmemop,
	output	dmemwe,
	output   awe,
	output   keyread,
	output [31:0] dbgdata);
//add your code here
 // ALU
  wire [31:0] dataa;
  wire [31:0] datab;
  wire [31:0] aluresult;
  wire less;
  wire zero;

  //Reg
  wire [31:0] busW;
  wire [31:0] busA;
  wire [31:0] busB;
  
  //Conctr
  wire [2:0] ExtOP;
  wire RegWr;
  wire [2:0] Branch;
  wire MemtoReg;
  wire ALUAsrc;
  wire [1:0] ALUBsrc;
  wire [3:0] ALUctr;
  wire dwe;
  
  //ImmGen
  wire [31:0] imm;
  
  //BranchCond
  wire PCAsrc;
  wire PCBsrc;
  
  //PC
  reg [31:0] pc;
  wire [31:0] nextpc;
  
  assign imemaddr = (reset)? 0: nextpc;
  assign imemclk = ~clock;
  assign dmemaddr = aluresult;
  assign dmemdatain = busB;
  assign dmemrdclk = clock;
  assign dmemwrclk = ~clock;
  assign dmemwe = (dmemaddr[31:20] == 12'h001)? dwe : 1'b0;
  assign awe = (dmemaddr[31:20] == 12'h002)? 1: 1'b0;
  assign keyread=((dmemaddr[31:20] == 12'h003)? 1: 1'b0);
  assign dbgdata = pc;
  
  always@(negedge clock)
  begin
	  if(reset)
	     pc<= 0;
	   else
		 pc<=nextpc;
  end
  
  ALU myALU(dataa, datab, ALUctr, less, zero, aluresult);
  regfile myregfile(~clock, RegWr, busW, imemdataout[19:15], imemdataout[24:20],
  imemdataout[11:7], busA, busB);
  ContrGen myContrGen(imemdataout[6:0], imemdataout[14:12], imemdataout[31:25],
  ExtOP, RegWr, ALUAsrc, ALUBsrc, ALUctr, Branch, MemtoReg, dwe, dmemop);
  ImmGen myImmGen(imemdataout, ExtOP, imm);
  BranchCond myBranchCond(Branch, less, zero, PCAsrc, PCBsrc);
  PC myPC(pc, PCAsrc, PCBsrc, imm, busA, nextpc);
  muxA mymuxA(pc, busA, ALUAsrc, dataa);
  muxB mymuxB(imm, busB, ALUBsrc, datab);
  muxC mymuxC(aluresult, dmemdataout, MemtoReg, busW);

endmodule

module ALU (
  input [31:0] dataa,
  input [31:0] datab,
  input [3:0]  ALUctr,
  output reg less,
  output reg zero,
  output reg [31:0] aluresult
);
  reg t_add_cin;
  reg [31:0] rs;
  reg of;
  reg lr;
  reg al;
  wire [31:0] sr;

  barrel a(dataa, datab[4:0], lr, al, sr);

  always @(*) 
    casez (ALUctr)
      4'b0000:
	   begin
	     aluresult = dataa + datab;
	     zero = ~(| aluresult);
	   end
      4'b1000:
	   begin
	     aluresult = dataa - datab;
	     zero = ~(| aluresult);
	   end
      4'bz001:
      begin
	     lr = 1;
	     aluresult = sr;
	     zero = ~(| aluresult);
	   end
      4'b0010:
	   begin
	     t_add_cin = ~datab[31];
	     rs = dataa - datab;
	     of = (dataa[31] == t_add_cin) && (rs[31] != dataa[31]);
	     less = of ? ~rs[31] : rs[31];
	     aluresult = less;
	     zero = (| rs) ? 0 : 1;//~less;
	   end
      4'b1010:
      begin
	     rs = dataa - datab;
	     //less = (dataa[31] ^ rs[31]) ? rs[31] : 0;
		  less = dataa < datab ? 1 : 0; 
	     aluresult = less;
	     zero = (| rs) ? 0 : 1;
	   end
      4'bz011: 
	   begin
	     aluresult = datab;
	     zero = ~(| aluresult);
	   end
      4'bz100: 
	   begin
	     aluresult = dataa ^ datab;
	     zero = ~(| aluresult);
	   end
      4'b0101: 
	   begin
	     lr = 0;
	     al = 0;
	     aluresult = sr;
	     zero = ~(| aluresult);
	   end
      4'b1101:
	   begin
	     lr = 0;
	     al = 1;
	     aluresult = sr;
	     zero = ~(| aluresult);
	   end
      4'bz110: 
	   begin
	     aluresult = dataa | datab;
	     zero = ~(| aluresult);
	   end
      4'bz111:
      begin
	     aluresult = dataa & datab;
	     zero = ~(| aluresult);
      end
    endcase

endmodule

module barrel (
  input [31:0] indata,
  input [4:0] shamt,
  input lr,
  input al,
  output [31:0] outdata
);

  wire [31:0] out1;
  wire [31:0] out2;
  wire [31:0] out3;
  wire [31:0] out4;
  mux #(1) a(indata,lr,al,shamt[0],out1);
  mux #(2) b(out1,lr,al,shamt[1],out2);
  mux #(4) c(out2,lr,al,shamt[2],out3);
  mux #(8) d(out3,lr,al,shamt[3],out4);
  mux #(16) e(out4,lr,al,shamt[4],outdata);
endmodule

module mux# ( parameter unit = 1) (
  input [31:0] indata,
  input lr,//s1
  input al,
  input oz,//s0
  output reg [31:0] dout
);
  always@(*)
	 case({lr,oz})
	   2'b00: dout = indata;
	   2'b01: dout = al ? {{unit{indata[31]}},indata[31:unit]} : {{unit{1'b0}},indata[31:unit]};
	   2'b10: dout = indata;
	   2'b11: dout = {indata[31-unit:0],{unit{1'b0}}};
	 endcase
endmodule

module regfile (
  input wrclk,
  input RegWr,
  input [31:0] busW,
  input [4:0] Ra,
  input [4:0] Rb,
  input [4:0] Rw,
  output [31:0] busA,
  output [31:0] busB
);

  reg [31:0] regs [31:0];

  initial
  begin
    regs[0] = 0;
  end
  
  always@(posedge wrclk)
	 if (Rw != 0)
	   if (RegWr)
	     regs[Rw] <= busW;

  assign busA = regs[Ra];
  assign busB = regs[Rb];

endmodule

module ContrGen (
  input [6:0] op,
  input [2:0] func3,
  input [6:0] func7,
  output reg [2:0] ExtOP,
  output reg RegWr,
  output reg ALUAsrc,
  output reg [1:0] ALUBsrc,
  output reg [3:0] ALUctr,
  output reg [2:0] Branch,
  output reg MemtoReg,
  output reg MemWr,
  output reg [2:0] MemOP
);
  always@(*)
    casez({op[6:2],func3,func7[5]})
      9'b01101zzzz: //LUI 
      begin
        ExtOP = 3'b001;   // get imm
	     RegWr = 1'b1;     // write to rd
	     Branch = 3'b000;  // no jump
	     MemtoReg = 1'b0;  // select alu as output
	     MemWr = 1'b0;     // no data write
	    //MemOP = x;
	    //ALUAsrc = x;
	    ALUBsrc = 2'b01;  // input imm
	    ALUctr = 4'b0011; // get aluresult
      end
      9'b00101zzzz: //AUIPC 
      begin
        ExtOP = 3'b001;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b1;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0000;
      end
      9'b00100000z: //ADDI 
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0000;
      end
      9'b00100010z: //SLTI 
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0010;
      end
      9'b00100011z: //SLTIU
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b1010;
      end
      9'b00100100z: //XORI 
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0100;
      end
      9'b00100110z: //ORI 
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0110;
      end
      9'b00100111z: //ANDI 
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0111;
      end
      9'b001000010: //SLLI 
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0001;
      end
      9'b001001010: //SRLI 
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0101;
      end
      9'b001001011: //SRAI 
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b1101;
      end
      9'b011000000: //ADD 
      begin
        //ExtOP = x;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0000;
      end
      9'b011000001: //SUB
      begin
        //ExtOP = x;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b1000;
      end
      9'b011000010: //SLL 
      begin
        //ExtOP = x;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0001;
      end
      9'b011000100: //SLT 
      begin
        //ExtOP = x;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0010;
      end
      9'b011000110: //SLTU
      begin
        //ExtOP = x;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b1010;
      end
      9'b011001000: //XOR
      begin
        //ExtOP = x;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0100;
      end
      9'b011001010: //SRL
      begin
        //ExtOP = x;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0101;
      end
      9'b011001011: //SRA 
      begin
        //ExtOP = x;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b1101;
      end
      9'b011001100: //OR
      begin
        //ExtOP = x;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0110;
      end
      9'b011001110: //AND
      begin
        //ExtOP = x;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0111;
      end
      9'b11011zzzz: //JAL
      begin
        ExtOP = 3'b100;
	     RegWr = 1'b1;
	     Branch = 3'b001;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b1;
	     ALUBsrc = 2'b10;
	     ALUctr = 4'b0000;
      end
      9'b11001000z: //JALR
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b010;
	     MemtoReg = 1'b0;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b1;
	     ALUBsrc = 2'b10;
	     ALUctr = 4'b0000;
      end
      9'b11000000z: //BEQ
      begin
        ExtOP = 3'b011;
	     RegWr = 1'b0;
	     Branch = 3'b100;
	     //MemtoReg = x;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0010;
      end
      9'b11000001z: //BNE
      begin
        ExtOP = 3'b011;
	     RegWr = 1'b0;
	     Branch = 3'b101;
	     //MemtoReg = x;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0010;
      end
      9'b11000100z: //BLT
      begin
        ExtOP = 3'b011;
	     RegWr = 1'b0;
	     Branch = 3'b110;
	     //MemtoReg = x;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0010;
      end
      9'b11000101z: //BGE
      begin
        ExtOP = 3'b011;
	     RegWr = 1'b0;
	     Branch = 3'b111;
	     //MemtoReg = x;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b0010;
      end
      9'b11000110z: //BLTU
      begin
        ExtOP = 3'b011;
	     RegWr = 1'b0;
	     Branch = 3'b110;
	     //MemtoReg = x;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b1010;
      end
      9'b11000111z: //BGEU
      begin
        ExtOP = 3'b011;
	     RegWr = 1'b0;
	     Branch = 3'b111;
	     //MemtoReg = x;
	     MemWr = 1'b0;
	     //MemOP = x;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b00;
	     ALUctr = 4'b1010;
      end
      9'b00000000z: //LB
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b1;
	     MemWr = 1'b0;
	     MemOP = 3'b000;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0000;
      end
      9'b00000001z: //LH
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b1;
	     MemWr = 1'b0;
	     MemOP = 3'b001;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0000;
      end
      9'b00000010z: //LW
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
        MemtoReg = 1'b1;
	     MemWr = 1'b0;
	     MemOP = 3'b010;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0000;
      end
      9'b00000100z: //LBU
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b1;
	     MemWr = 1'b0;
	     MemOP = 3'b100;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0000;
      end
      9'b00000101z: //LHU
      begin
        ExtOP = 3'b000;
	     RegWr = 1'b1;
	     Branch = 3'b000;
	     MemtoReg = 1'b1;
	     MemWr = 1'b0;
	     MemOP = 3'b101;
	     ALUAsrc = 1'b0;
	     ALUBsrc = 2'b01;
	     ALUctr = 4'b0000;
      end
      9'b01000000z: //SB
      begin
       ExtOP = 3'b010;
	    RegWr = 1'b0;
	    Branch = 3'b000;
	    //MemtoReg = x;
	    MemWr = 1'b1;
	    MemOP = 3'b000;
	    ALUAsrc = 1'b0;
	    ALUBsrc = 2'b01;
	    ALUctr = 4'b0000;
     end
     9'b01000001z: //SH
     begin
       ExtOP = 3'b010;
	    RegWr = 1'b0;
	    Branch = 3'b000;
	    //MemtoReg = x;
	    MemWr = 1'b1;
	    MemOP = 3'b001;
	    ALUAsrc = 1'b0;
	    ALUBsrc = 2'b01;
	    ALUctr = 4'b0000;
     end
     9'b01000010z: //SW
     begin
       ExtOP = 3'b010;
	    RegWr = 1'b0;
	    Branch = 3'b000;
	    //MemtoReg = x;
	    MemWr = 1'b1;
	    MemOP = 3'b010;
	    ALUAsrc = 1'b0;
	    ALUBsrc = 2'b01;
	    ALUctr = 4'b0000;
     end
   endcase

endmodule

module ImmGen (
  input [31:0] instr,
  input [2:0] ExtOP,
  output reg [31:0] imm
);

  always@(*)
    case(ExtOP)
      3'b000: imm = {{20{instr[31]}}, instr[31:20]};
      3'b001: imm = {instr[31:12], 12'b0};
      3'b010: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      3'b011: imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
      3'b100: imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
    endcase
endmodule

module BranchCond (
  input [2:0] Branch,
  input less,
  input zero,
  output reg PCAsrc,
  output reg PCBsrc
);

  always@(*)
    casez({Branch,zero,less})
	   5'b000zz: 
		begin
		  PCAsrc = 0;
		  PCBsrc = 0;
		end
		5'b001zz:
		begin
		  PCAsrc = 1;
		  PCBsrc = 0;
		end
		5'b010zz:
		begin
		  PCAsrc = 1;
		  PCBsrc = 1;
		end
      5'b1000z:
		begin
		  PCAsrc = 0;
		  PCBsrc = 0;
		end
		5'b1001z:
		begin
		  PCAsrc = 1;
		  PCBsrc = 0;
		end
		5'b1010z:
		begin
		  PCAsrc = 1;
		  PCBsrc = 0;
		end
		5'b1011z:
		begin
		  PCAsrc = 0;
		  PCBsrc = 0;
		end
		5'b110z0:
		begin
		  PCAsrc = 0;
		  PCBsrc = 0;
		end
		5'b110z1:
		begin
		  PCAsrc = 1;
		  PCBsrc = 0;
		end
		5'b111z0:
		begin
		  PCAsrc = 1;
		  PCBsrc = 0;
		end
		5'b111z1:
		begin
		  PCAsrc = 0;
		  PCBsrc = 0;
		end
	 endcase
endmodule

module PC (
  input [31:0] pc,
  input PCAsrc,
  input PCBsrc,
  input [31:0] imm,
  input [31:0] rs1,
  output reg [31:0] nextpc
);
initial nextpc = 0;

  always@(*)
    case({PCAsrc,PCBsrc})
	   2'b00: nextpc = pc + 4;
		//2'b01: nextpc = pc + imm;
		2'b10: nextpc = pc + imm;
      2'b11: nextpc = rs1 + imm;
	 endcase 
endmodule

module muxA (
  input [31:0] pc,
  input [31:0] bus,
  input ALUAsrc,
  output reg [31:0] datain
);

  always@(*)
    case(ALUAsrc)
	   0: datain = bus;
		1: datain = pc;
	 endcase
	 
endmodule

module muxB (
  input [31:0] imm,
  input [31:0] bus,
  input [1:0] ALUBsrc,
  output reg [31:0] datain
);

  always@(*)
    case(ALUBsrc)
	   0: datain = bus;
		1: datain = imm;
		2: datain = 4;
	 endcase
	 
endmodule

module muxC (
  input [31:0] aluresult,
  input [31:0] dmemdataout,
  input MemtoReg,
  output reg [31:0] busw
);

  always@(*)
    case(MemtoReg)
	   0: busw = aluresult;
		1: busw = dmemdataout;
	 endcase
	 
endmodule