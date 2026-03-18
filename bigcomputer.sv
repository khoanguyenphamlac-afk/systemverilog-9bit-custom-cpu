`timescale 1ns / 1ps

module mcu_system(
    input  logic Clock,
    input  logic Resetn,
    input  logic Run,
    output logic [8:0] LEDs
);

    logic [8:0] ADDR_Bus;  
    logic [8:0] DOUT_Bus;  
    logic [8:0] DIN_Bus;   
    logic W_Main; 
	 logic Done_Sig;
    
    logic Mem_Wr_En;//viet cho RAM
    logic LED_En;//viet cho LED
    
    

    processor cpu (
        .DIN(DIN_Bus),
        .Resetn(Resetn),
        .Clock(Clock),
        .Run(Run),
        .Done(Done_Sig),
        .BusWires(),      
        .W(W_Main),
        .ADDR(ADDR_Bus),
        .DOUT(DOUT_Bus)
    );

 

	 
	 
	// RAM hop le khi address =  00xxxxxxx (0-127)
	 assign Mem_Wr_En = W_Main & ~ADDR_Bus[8] & ~ADDR_Bus[7];		 

    assign LED_En    = W_Main &  ADDR_Bus[8] & ~ADDR_Bus[7];
	 //de output led, thuc hien lenh ST tren address 100000000 (256)

    RAM main_memory (
        .clock(Clock),
        .address(ADDR_Bus[6:0]), // Use lower 7 bits for 128 words
        .data(DOUT_Bus),
        .wren(Mem_Wr_En),
        .q(DIN_Bus)
    );

    ledreg9bit ledreg(
        .D(DOUT_Bus),
        .enable(LED_En),
        .clock(Clock),
        .Q(LEDs)
    );

endmodule