module processor(
    input  logic [8:0] DIN,
    input  logic Resetn, Clock, Run,
    output logic Done,
    output logic [8:0] BusWires,
    output logic W,              
    output logic [8:0] ADDR,     
    output logic [8:0] DOUT      
);

    logic [8:0] IR;
    logic [8:0] R0, R1, R2, R3, R4, R5, R6, R7;
    logic [8:0] A, G, Sum;
    logic IRin, Ain, Gin, Gout, DINout, AddSub;
    logic [7:0] Rin, Rout, Xreg, Yreg; 
    logic [2:0] I;         
    logic ALUz, ALU_Zero_Comb, pc_incr; 
    logic ADDR_en, DOUT_en; 

    assign I = IR[8:6]; 
    dec3to8 decX (IR[5:3], 1'b1, Xreg); 
    dec3to8 decY (IR[2:0], 1'b1, Yreg); 
  
    control_unit fsm_wrapper (
        .Clock(Clock), .Resetn(Resetn), .Run(Run),
        .I(I), .Xreg(Xreg), .Yreg(Yreg), .ALUz(ALUz), 
        .IRin(IRin), .Ain(Ain), .Gin(Gin),
        .Gout(Gout), .DINout(DINout), .AddSub(AddSub),
        .Rin(Rin), .Rout(Rout),
        .Done(Done), .pc_incr(pc_incr),      
        .W(W), .ADDR_en(ADDR_en), .DOUT_en(DOUT_en)
    );

    // thanh ghi
    register reg_IR (DIN, IRin, Clock, Resetn, IR);
    register reg_0 (BusWires, Rin[0], Clock, Resetn, R0);
    register reg_1 (BusWires, Rin[1], Clock, Resetn, R1);
    register reg_2 (BusWires, Rin[2], Clock, Resetn, R2);
    register reg_3 (BusWires, Rin[3], Clock, Resetn, R3);
    register reg_4 (BusWires, Rin[4], Clock, Resetn, R4);
    register reg_5 (BusWires, Rin[5], Clock, Resetn, R5);
    register reg_6 (BusWires, Rin[6], Clock, Resetn, R6);
    
    // xac dinh logic pc: pc = pc + 1 hoac nap dia chi moi tu bus 
	 //neu Rin[7] = 0 thi fsm ko ghi data moi vao PC bang mv,skip pc=pc+ 
	 //neu Rin[7] = 1 suy ra co ghi data vao R7,BusWires ghi truc tiep vao r7_next
    logic [8:0] R7_next;
    pc_logic pc_calc_inst (.R7(R7), .BusWires(BusWires), .Sel(Rin[7]), .R7_next(R7_next) );

    register reg_7(.D(R7_next), .En(Rin[7] | pc_incr), .Clock(Clock), .Resetn(Resetn), .Q(R7));

    register reg_A (BusWires, Ain, Clock, Resetn, A);
    register reg_G (Sum, Gin, Clock, Resetn, G);
    register ADDR_reg(.D(BusWires), .En(ADDR_en), .Clock(Clock), .Resetn(Resetn), .Q(ADDR));
    register DOUT_reg(.D(BusWires), .En(DOUT_en), .Clock(Clock), .Resetn(Resetn), .Q(DOUT));
    alu alu_inst(.A(A), .B(BusWires), .AddSub(AddSub), .Sum(Sum), .Zero(ALU_Zero_Comb));

    fflop alu_z_reg ( .D(ALU_Zero_Comb),  .En(Gin),  .Clock(Clock), .Resetn(Resetn), .Q(ALUz) );

    // mux
    bus_multiplexer bus_mux(
        .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7),
        .G(G), .DIN(DIN), .Rout(Rout), .Gout(Gout), .DINout(DINout),
        .BusWires(BusWires)
    );

endmodule

module control_unit(
    input logic Clock, Resetn, Run,
    input logic [2:0] I,         
    input logic [7:0] Xreg, Yreg,
    input logic ALUz,           
    output logic IRin, Ain, Gin,
    output logic Gout, DINout, AddSub,
    output logic [7:0] Rin, Rout,
    output logic Done, W, 
    output logic ADDR_en, DOUT_en, 
    output logic pc_incr 
);

    typedef enum logic [3:0] {
        T0, T0_Wait,  //state don lenh     
        T1, 			 //giai ma   
        T2, T2_Wait,  // thuc hien    
        T3, 					//ghi nguoc ket qua(add/sub) hay ghi bo nho st
        T4
    } state_t;			//chuan bi address cho lenh tiep theo
    
    state_t Tstep_Q, Tstep_D;

    parameter mv   = 3'b000;
    parameter movi = 3'b001;
    parameter add  = 3'b010;
    parameter sub  = 3'b011;
    parameter ld   = 3'b100;
    parameter st   = 3'b101;
    parameter mvnz = 3'b110;

    always_ff @(posedge Clock, negedge Resetn) begin
        if (!Resetn) Tstep_Q <= T4;
        else Tstep_Q <= Tstep_D;
    end
	
    always_comb begin 
        Tstep_D = Tstep_Q; 
        case(Tstep_Q)
            // chu ky don lenh 
            // t4 da nap addr. t0 cho phep addr on dinh tai dau ram
            // t0_wait cho phep ram xuat du lieu
            T0: begin
                if (!Run) Tstep_D = T0;
                else Tstep_D = T0_Wait; 
            end

            T0_Wait: Tstep_D = T1; // du lieu hop le, chot IR

            //chu ky giai ma 
            T1: begin
                case (I)
                    movi, ld: Tstep_D = T2; // can doc bo nho 
                    st, add, sub: Tstep_D = T2; // khong can doc bo nho 
                    default: Tstep_D = T4; // mv, mvnz (xong)
                endcase
            end

            // thuc thi/thiet lap dia chi 
            T2: begin
                case (I)
                    movi, ld: Tstep_D = T2_Wait; // doi du lieu tu ram
                    add, sub, st: Tstep_D = T3;
                    default: Tstep_D = T4; 
                endcase
            end

            // doi doc bo nho  
            T2_Wait: Tstep_D = T3; // du lieu tu bo nho hop le

            T3: Tstep_D = T4;

            T4: Tstep_D = T0;

            default: Tstep_D = T0;
        endcase
    end
    
    // logic dau ra
    always_comb begin 
	 //chong latch
        IRin = 0; Done = 0; Ain = 0; Gin = 0;
        Gout = 0; DINout = 0; AddSub = 0;
        W = 0; ADDR_en = 0; DOUT_en = 0;
        Rin = 8'b0; Rout = 8'b0;
        pc_incr = 0; 
        
        case(Tstep_Q)
            T0: ; // doi cho ADDR on dinh tren RAM address bus

            T0_Wait: begin 
                IRin = 1'b1;   // bat lenh tu RAM
                pc_incr = 1'b1; 
            end
            
            T1: case(I)
                mv: begin Rout = Yreg; Rin = Xreg; end//copy Y sang X
					 
                movi: begin Rout = 8'b10000000; ADDR_en = 1'b1; end // xuat PC ra bus, chuan bi doc byte tiep theo
					 
                add, sub: begin Rout = Xreg; Ain = 1'b1; end//load data tu thanh ghi x sang thanh ghi a cua ALU
					 
                ld, st: begin Rout = Yreg; ADDR_en = 1'b1; end      // chuan bi memory address tu thanh ghi Y
                mvnz: if (!ALUz) begin Rout = Yreg; Rin = Xreg; end
                default: ; 
            endcase 
            
            T2: case (I)
                //  thiet lap 
					 
                movi, ld: ; //cho ram doc data tu address set o T1
                
             
                add, sub: begin Rout = Yreg; Gin = 1'b1; AddSub = (I == sub); end
					 
					 
                st: begin Rout = Xreg; DOUT_en = 1'b1; end//data tu X sang RAM
					 
					 //
                default: ; 
            endcase

            T2_Wait: case(I)//da doc xong data 
                
                movi: begin
					 DINout = 1'b1; //doc immediate tu data bus vao thanh ghi X
					 Rin = Xreg; 
					 pc_incr = 1'b1;//pc = pc +1 de tranh doc address cua immediate
					 end
					 
                ld:   begin DINout = 1'b1; Rin = Xreg; end//doc memory data vao X
					 
                default: ;
            endcase

            T3: case (I)
                add, sub: begin Gout = 1'b1; Rin = Xreg; end
                st: begin W = 1'b1; end // ghi vao ram
                default: ; 
            endcase

            T4: begin
                Rout = 8'b10000000; // dua pc len bus cho lan don lenh ke tiep 
                ADDR_en = 1'b1;     
                Done = 1'b1; //xong instruction nay 
            end
            
            default: ;
        endcase
    end

endmodule



