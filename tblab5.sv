`timescale 1ns / 1ps

module tb_mcu_system;

    
    logic Clock;
    logic Resetn;
    logic Run;
    logic [8:0] LEDs;

    mcu_system dut (
        .Clock(Clock),
        .Resetn(Resetn),
        .Run(Run),
        .LEDs(LEDs)
    );

    // tao xung clock 50mhz
    initial begin
        Clock = 0;
        forever #10 Clock = ~Clock; // 20ns period
    end

    
    // trinh tu kiem tra
    initial begin
        // ini
        $display("============================================================");
        $display("Starting Simulation...");
        $display("============================================================");
        
        Resetn = 0;
        Run = 0;
        
        //xung reset
        repeat(5) @(posedge Clock);
        Resetn = 1;
        
        // thuc thi
        @(posedge Clock);
        Run = 1;
        $display("[%0t] Processor Reset Released. RUN signal asserted.", $time);

        
        // chay mo phong 5000ns (idk why this works its just a random tip)
        repeat(500) @(posedge Clock);

        //end
        $display("============================================================");
        $display("Simulation Finished.");
        $display("Final LED State: %b (Hex: 0x%h)", LEDs, LEDs);
        $display("============================================================");
        $stop;
    end

    //giam sat register r0 to r7
    initial begin
        $timeformat(-9, 0, " ns", 8);
        
        // wait for reset
        @(posedge Resetn);
        
        forever begin
            @(posedge Clock);
            // kiem tra trang thai t1 (tstepq ==2)
            // (trang thai giaai ma, truoc do da lay lenh tu t4), pc on dinh cho lenh hien tai 
            if (dut.cpu.fsm_wrapper.Tstep_Q == 4'd2) begin 
                 $display("Time:%t | PC:%3d | IR:%h | R0:%h R1:%h R2:%h R3:%h R4:%h R5:%h R6:%h R7:%h | LED:%h", 
                          $time, 
                          dut.cpu.R7,        // PC 
                          dut.cpu.IR,        // Instruction Register
                          dut.cpu.R0,        
                          dut.cpu.R1,        
                          dut.cpu.R2,        
                          dut.cpu.R3,        
                          dut.cpu.R4,        
                          dut.cpu.R5,        
                          dut.cpu.R6,        
                          dut.cpu.R7,        
                          LEDs);             // led
            end
        end
    end

    // check led thay doi 
    always @(LEDs) begin
        if (Resetn) begin
            $display(">> [%t] *** LED UPDATE *** New Value: %b (0x%h)", $time, LEDs, LEDs);
        end
    end

endmodule