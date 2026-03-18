module full_adder (
 input logic A,
 input logic B,
 input logic Cin,
 output logic Sum,
 output logic Cout 
 );
 assign Sum = A ^ B ^ Cin;
 assign Cout = (A & B) | (B & Cin) | (A & Cin);
endmodule

module dff9bit (
 input logic clk,rst,
 input logic [8:0] D,
 output logic [8:0] Q
 );
 
 always_ff @(posedge clk or negedge rst) begin 
	if(!rst)
		Q <= 9'b0;
	else 
		Q <= D;
	end
 endmodule

module blockfa(
	input logic [8:0] A,B,
	input logic c,
	output logic [8:0] Sum,
	output logic cout 
	);
	
	logic [8:0] carry;
	
	full_adder fa0 ( .A(A[0]), .B(B[0]^c), .Cin(c),        .Sum(Sum[0]), .Cout(carry[0]) );
    
    // Bits 1-8: Cin comes from previous carry
    full_adder fa1 ( .A(A[1]), .B(B[1]^c), .Cin(carry[0]), .Sum(Sum[1]), .Cout(carry[1]) );
    full_adder fa2 ( .A(A[2]), .B(B[2]^c), .Cin(carry[1]), .Sum(Sum[2]), .Cout(carry[2]) );
    full_adder fa3 ( .A(A[3]), .B(B[3]^c), .Cin(carry[2]), .Sum(Sum[3]), .Cout(carry[3]) );
    full_adder fa4 ( .A(A[4]), .B(B[4]^c), .Cin(carry[3]), .Sum(Sum[4]), .Cout(carry[4]) );
    full_adder fa5 ( .A(A[5]), .B(B[5]^c), .Cin(carry[4]), .Sum(Sum[5]), .Cout(carry[5]) );
    full_adder fa6 ( .A(A[6]), .B(B[6]^c), .Cin(carry[5]), .Sum(Sum[6]), .Cout(carry[6]) );
    full_adder fa7 ( .A(A[7]), .B(B[7]^c), .Cin(carry[6]), .Sum(Sum[7]), .Cout(carry[7]) );
    full_adder fa8 ( .A(A[8]), .B(B[8]^c), .Cin(carry[7]), .Sum(Sum[8]), .Cout(carry[8]) );

    assign cout = carry[8];

endmodule

	
module dff_9bit (
    input logic clk, rst,
    input logic [8:0] D,
    output logic [8:0] Q
);
    
    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            Q <= 9'b0;
        else
            Q <= D;
    end
endmodule

module wanbeetreg (
    input logic clk,
    input logic D,
    output logic Q
);
    
    // Updates Q with the value of D on every rising edge of the clock
    always_ff @(posedge clk) begin
        Q <= D;
    end

endmodule




module counter ( 
    input logic clk, rst, Done, en,
    input logic [8:0] D,
    output logic [8:0] Q 
);
    logic [8:0] current_count;
    logic [8:0] next_count;
    logic [8:0] incremented_count;

    assign incremented_count = current_count + 9'b1;

    assign next_count = (en) ? D : ( (Done) ? incremented_count : current_count );

    dff_9bit state_reg (
        .clk(clk),
        .rst(rst),
        .D(next_count),
        .Q(current_count)
    );

    assign Q = current_count;

endmodule



module alu (
    input  wire [8:0] A,
    input  wire [8:0] B,
    input  wire       AddSub,
    output wire [8:0] Sum,
    output wire       Zero
);

    wire c1, c2, c3, c4, c5, c6, c7, c8, c9;
    wire [8:0] B_logic;

    assign B_logic[0] = B[0] ^ AddSub;
    assign B_logic[1] = B[1] ^ AddSub;
    assign B_logic[2] = B[2] ^ AddSub;
    assign B_logic[3] = B[3] ^ AddSub;
    assign B_logic[4] = B[4] ^ AddSub;
    assign B_logic[5] = B[5] ^ AddSub;
    assign B_logic[6] = B[6] ^ AddSub;
    assign B_logic[7] = B[7] ^ AddSub;
    assign B_logic[8] = B[8] ^ AddSub;
    
    full_adder fa0 ( .A(A[0]), .B(B_logic[0]), .Cin(AddSub), .Sum(Sum[0]), .Cout(c1) );
    full_adder fa1 ( .A(A[1]), .B(B_logic[1]), .Cin(c1),     .Sum(Sum[1]), .Cout(c2) );
    full_adder fa2 ( .A(A[2]), .B(B_logic[2]), .Cin(c2),     .Sum(Sum[2]), .Cout(c3) );
    full_adder fa3 ( .A(A[3]), .B(B_logic[3]), .Cin(c3),     .Sum(Sum[3]), .Cout(c4) );
    full_adder fa4 ( .A(A[4]), .B(B_logic[4]), .Cin(c4),     .Sum(Sum[4]), .Cout(c5) );
    full_adder fa5 ( .A(A[5]), .B(B_logic[5]), .Cin(c5),     .Sum(Sum[5]), .Cout(c6) );
    full_adder fa6 ( .A(A[6]), .B(B_logic[6]), .Cin(c6),     .Sum(Sum[6]), .Cout(c7) );
    full_adder fa7 ( .A(A[7]), .B(B_logic[7]), .Cin(c7),     .Sum(Sum[7]), .Cout(c8) );
    full_adder fa8 ( .A(A[8]), .B(B_logic[8]), .Cin(c8),     .Sum(Sum[8]), .Cout(c9) );

    assign Zero = ~(Sum[0] | Sum[1] | Sum[2] | Sum[3] | Sum[4] | Sum[5] | Sum[6] | Sum[7] | Sum[8]);

endmodule



module register (
    input logic [8:0] D,
    input logic En, Clock, Resetn, 
    output logic [8:0] Q
);
    always_ff @(posedge Clock or negedge Resetn) begin
        if (!Resetn)
            Q <= 9'b0;      
        else if (En) 
            Q <= D;
    end
endmodule

module dec3to8(
    input logic [2:0] In,
    input logic En,
    output logic [7:0] Out
);
    always_comb begin
        if (En)
            case(In)
                3'b000: Out = 8'b00000001;
                3'b001: Out = 8'b00000010;
                3'b010: Out = 8'b00000100;
                3'b011: Out = 8'b00001000;
                3'b100: Out = 8'b00010000;
                3'b101: Out = 8'b00100000;
                3'b110: Out = 8'b01000000;
                3'b111: Out = 8'b10000000;
                default: Out = 8'b00000000;
            endcase
        else
            Out = 8'b00000000;
    end
endmodule



module bus_multiplexer(
    input logic [8:0] R0, R1, R2, R3, R4, R5, R6, R7, 
    input logic [8:0] G, DIN,
    input logic [7:0] Rout, 
    input logic Gout, DINout,
    output logic [8:0] BusWires
);
    always_comb begin
        BusWires = 9'b0;
        if (Rout[0]) BusWires = R0;
        else if (Rout[1]) BusWires = R1;
        else if (Rout[2]) BusWires = R2;
        else if (Rout[3]) BusWires = R3;
        else if (Rout[4]) BusWires = R4;
        else if (Rout[5]) BusWires = R5;
        else if (Rout[6]) BusWires = R6;
        else if (Rout[7]) BusWires = R7;
        else if (Gout)    BusWires = G;
        else if (DINout)  BusWires = DIN;
    end
endmodule


module ledreg9bit(
    input logic [8:0] D,
    input logic clock,
    input logic enable,
    output logic [8:0] Q
    );

    always_ff @(posedge clock) begin
        if (enable) begin
            Q <= D;
        end
    end
endmodule

module pc_logic(
    input  logic [8:0] R7,
    input  logic [8:0] BusWires,
    input  logic       Sel,      
    output logic [8:0] R7_next
);
    assign R7_next = Sel ? BusWires : (R7 + 9'b1);
endmodule

module fflop(
    input  logic D,
    input  logic En,
    input  logic Clock,
    input  logic Resetn,
    output logic Q
);
    always_ff @(posedge Clock or negedge Resetn) begin
        if (!Resetn) 
            Q <= 1'b0;
        else if (En) 
            Q <= D;
    end
endmodule