`timescale 1ns/1ps

module testbench;

    reg clk;
    reg reset;

    // Instancia del procesador (top-level)
    top dut(
        .clk(clk),
        .reset(reset)
    );

    // ----------------------------------
    // GENERADOR DE RELOJ
    // ----------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // periodo 10ns
    end

    // ----------------------------------
    // RESET INICIAL
    // ----------------------------------
    initial begin
        reset = 1;
        #20;
        reset = 0;
    end

    // ----------------------------------
    // SEGUIMIENTO DEL PIPELINE
    // (AJUSTA LOS NOMBRES SI TUS SEÑALES CAMBIAN)
    // ----------------------------------
    integer cycle;
    initial begin
        cycle = 0;

        // PARA GENERAR ARCHIVO DE ONDAS
        $dumpfile("wave.vcd");
        $dumpvars(0, testbench);

        $display("Iniciando simulación...");

        repeat(300) begin
            @(posedge clk);
            cycle = cycle + 1;

            // Estas rutas deben existir en tu datapath.
            // AJÚSTALAS si tus nombres son diferentes.

            $display("CICLO %0d | PCF=%h | InstrD=%h | RegWriteW=%b | RdW=%0d",
                cycle,
                dut.dp.PCF,         // PC en IF
                dut.dp.InstrD,      // instrucción en Decode
                dut.dp.RegWriteW,   // escribe en registro?
                dut.dp.RdW          // destino en Writeback
            );
        end

        $display("FIN DE SIMULACION");
        $stop;
    end

endmodule
