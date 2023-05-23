 module select(
	input [1:0] X0,
	input [1:0] X1,
	input [1:0] X2,
	input [1:0] X3,
	input [1:0] Y,
	output reg [1:0] F
	);
	
	always @ (*)
		case(Y)
			2'd0: F = X0;
			2'd1: F = X1;
			2'd2: F = X2;
			2'd3: F = X3;
			default: F = 2'b00;
		endcase

endmodule