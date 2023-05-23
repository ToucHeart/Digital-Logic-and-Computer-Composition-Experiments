module alu_s( input [3:0] A,
			  input [3:0] B,
			  input [2:0] ALUctr,
			  output reg [3:0] F,
			  output reg cf,
			  output reg zero,
			  output reg of
);

	wire [3:0]f;
	wire CF,ZERO,OF;

	adder add(A,B,|ALUctr,f,CF,ZERO,OF);
	
	always @ (*)
	begin
		if(ALUctr>=2)
			begin
				of=0;
				cf=0;
			end
		else
			begin
				cf=CF;
				of=OF;
			end
		case (ALUctr)
			3'd2 :F=~A;
			3'd3 :F=A & B;
			3'd4 :F=A | B;
			3'd5 :F=A ^ B;  
			3'd6 :F=(A[3] == B[3] && A[2:0] > B[2:0])|| (A[3] == 0) && (B[3] == 1);  
			3'd7 :F=(A == B);
			default:F=f;
		endcase
		zero=~(| F[3:0]);
	end
endmodule



module adder(
	input  [3:0] A,
	input  [3:0] B,
	input  addsub,
	output [3:0] F,
	output cf,
	output zero,
	output of
	);
	wire temp;
	wire [3:0]t_no_Cin= {4{addsub}} ^ B;
	assign {temp,F[3:0]} = A + t_no_Cin + addsub;
	assign cf=temp^addsub;
	assign of = (A[3] == t_no_Cin[3])&& (A[3] != F[3]); 
	assign zero = ~(| F[3:0]);
endmodule

