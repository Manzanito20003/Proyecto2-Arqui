module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;
  
  // instantiate device to be tested
  top dut(
    .clk(clk), 
    .reset(reset), 
    .WriteData(WriteData), 
    .DataAdr(DataAdr), 
    .MemWrite(MemWrite)
  );

  // Acceso a señales internas del pipeline mediante jerarquía de nombres
  wire [31:0] PC = dut.rvsingle.PC;
  wire [31:0] Instr = dut.rvsingle.Instr;
  wire [31:0] InstrD = dut.rvsingle.InstrD;
  wire [31:0] ALUResult = dut.rvsingle.ALUResult;
  wire [31:0] ReadData = dut.rvsingle.ReadData;
  
  // Señales de control
  wire RegWrite = dut.rvsingle.RegWrite;
  wire RegWriteM = dut.rvsingle.RegWriteM;
  wire MemWrite_int = dut.rvsingle.MemWrite;
  wire PCSrcE = dut.rvsingle.PCSrcE;
  wire Zero = dut.rvsingle.Zero;
  wire StallF = dut.rvsingle.StallF;
  wire StallD = dut.rvsingle.StallD;
  wire FlushD = dut.rvsingle.FlushD;
  wire FlushE = dut.rvsingle.FlushE;
  wire [1:0] ForwardAE = dut.rvsingle.ForwardAE;
  wire [1:0] ForwardBE = dut.rvsingle.ForwardBE;
  
  // Registros del pipeline
  wire [4:0] Rs1D = dut.rvsingle.Rs1D;
  wire [4:0] Rs2D = dut.rvsingle.Rs2D;
  wire [4:0] Rs1E = dut.rvsingle.Rs1E;
  wire [4:0] Rs2E = dut.rvsingle.Rs2E;
  wire [4:0] RdE = dut.rvsingle.RdE;
  wire [4:0] RdM = dut.rvsingle.RdM;
  wire [4:0] RdW = dut.rvsingle.RdW;
  
  // Señales del datapath
  wire [31:0] RD1D = dut.rvsingle.dp.RD1D;
  wire [31:0] RD2D = dut.rvsingle.dp.RD2D;
  wire [31:0] RD1E = dut.rvsingle.dp.RD1E;
  wire [31:0] RD2E = dut.rvsingle.dp.RD2E;
  wire [31:0] SrcAE = dut.rvsingle.dp.SrcAE;
  wire [31:0] SrcBE = dut.rvsingle.dp.SrcBE;
  wire [31:0] ALUResultE = dut.rvsingle.dp.ALUResultE;
  wire [31:0] PCD = dut.rvsingle.dp.PCD;
  wire [31:0] PCE = dut.rvsingle.dp.PCE;
  wire [31:0] ImmExtE = dut.rvsingle.dp.ImmExtE;
  wire [31:0] ResultW = dut.rvsingle.dp.ResultW;
  wire [31:0] PCF = dut.rvsingle.dp.PCF;
  wire [31:0] PCPlus4F = dut.rvsingle.dp.PCPlus4F;
  wire [31:0] PCPlus4D = dut.rvsingle.dp.PCPlus4D;
  wire [31:0] PCPlus4E = dut.rvsingle.dp.PCPlus4E;
  wire [31:0] PCPlus4M = dut.rvsingle.dp.PCPlus4M;
  wire [31:0] PCPlus4W = dut.rvsingle.dp.PCPlus4W;
  wire [31:0] ALUResultM = dut.rvsingle.dp.ALUResultM;
  wire [31:0] WriteDataM = dut.rvsingle.dp.WriteDataM;
  
  // Señales adicionales
  wire ResultSrcE0 = dut.rvsingle.ResultSrcE0;
  wire RegWriteE_ctrl = dut.rvsingle.c.RegWriteE;
  wire RegWriteW_ctrl = dut.rvsingle.c.RegWriteW;
  // lwStall se calcula: (((Rs1D == RdE) | (Rs2D == RdE)) & ResultSrcE0 & (RdE != 0))
  wire lwStall = (((Rs1D == RdE) | (Rs2D == RdE)) & ResultSrcE0 & (RdE != 0));
  
  // Variables para almacenar instrucciones en cada etapa del pipeline
  reg [31:0] InstrF_pipe, InstrD_pipe, InstrE_pipe, InstrM_pipe, InstrW_pipe;
  reg [31:0] PCF_pipe, PCD_pipe, PCE_pipe, PCM_pipe, PCW_pipe;
  reg [4:0] RdE_pipe, RdM_pipe, RdW_pipe;
  reg [4:0] Rs1E_pipe, Rs2E_pipe;
  reg ResultSrcE0_pipe;
  reg [31:0] ALUResultE_pipe, ALUResultM_pipe;
  reg [31:0] WriteDataM_pipe;
  reg [31:0] ResultW_pipe;
  
  integer cycle_count = 0;
  
  // Variables para validación de etapas
  reg valid_if, valid_id, valid_ex, valid_mem, valid_wb;
  
  // Función para determinar qué etapas están activas
  function [79:0] get_stages;
    input valid_if, valid_id, valid_ex, valid_mem, valid_wb;
    begin
      if (valid_wb & valid_mem & valid_ex & valid_id & valid_if)
        get_stages = "IF → ID → EX → MEM → WB";
      else if (valid_mem & valid_ex & valid_id & valid_if)
        get_stages = "IF → ID → EX → MEM";
      else if (valid_ex & valid_id & valid_if)
        get_stages = "IF → ID → EX";
      else if (valid_id & valid_if)
        get_stages = "IF → ID";
      else if (valid_if)
        get_stages = "IF";
      else
        get_stages = "NONE";
    end
  endfunction
  
  // Función para decodificar tipo de instrucción
  function [79:0] decode_instr;
    input [31:0] instr;
    begin
      case(instr[6:0])
        7'b0110011: begin // R-type
          case({instr[30], instr[14:12]})
            4'b0000: decode_instr = "ADD     ";
            4'b1000: decode_instr = "SUB     ";
            4'b0110: decode_instr = "OR      ";
            4'b0111: decode_instr = "AND     ";
            default: decode_instr = "R-TYPE  ";
          endcase
        end
        7'b0010011: begin // I-type (ADDI, etc)
          case(instr[14:12])
            3'b000: decode_instr = "ADDI    ";
            3'b010: decode_instr = "SLTI    ";
            default: decode_instr = "I-TYPE  ";
          endcase
        end
        7'b0000011: decode_instr = "LW      "; // Load
        7'b0100011: decode_instr = "SW      "; // Store
        7'b1100011: begin // B-type
          case(instr[14:12])
            3'b000: decode_instr = "BEQ     ";
            3'b001: decode_instr = "BNE     ";
            default: decode_instr = "BRANCH  ";
          endcase
        end
        7'b1101111: decode_instr = "JAL     "; // Jump and Link
        7'b1100111: decode_instr = "JALR    "; // Jump and Link Register
        default: decode_instr = "UNKNOWN ";
      endcase
    end
  endfunction

  function [79:0] decode_or_nop;
    input [31:0] instr;
    begin
      if (instr === 32'h0 || instr === 32'hxxxxxxxx)
        decode_or_nop = "NOP/----";
      else
        decode_or_nop = decode_instr(instr);
    end
  endfunction

  // initialize test
  initial begin
    reset = 1; # 22;
    reset = 0;
    
    // Opcional: Generar archivo VCD para visualización en GTKWave
    // $dumpfile("pipeline_trace.vcd");
    // $dumpvars(0, testbench);
  end

  // generate clock to sequence tests
  always begin
    clk = 1;
    # 5; clk = 0; # 5;
  end

  // Capturar valores en el flanco positivo del reloj para rastrear el pipeline
  always @(posedge clk) begin
    if (!reset) begin
      // Incrementar contador primero
      cycle_count <= cycle_count + 1;
      
      // Propagación de instrucciones a través del pipeline (después del flanco)
      // Estas se actualizan después del flanco positivo, así que capturamos los valores nuevos
      InstrF_pipe <= Instr;                    // IF: Instrucción actual
      InstrD_pipe <= InstrD;                   // ID: Instrucción decodificada
      InstrE_pipe <= InstrD_pipe;              // EX: Instrucción que estaba en ID (valor anterior)
      InstrM_pipe <= InstrE_pipe;              // MEM: Instrucción que estaba en EX (valor anterior)
      InstrW_pipe <= InstrM_pipe;              // WB: Instrucción que estaba en MEM (valor anterior)
      
      // Propagación de PC a través del pipeline
      PCF_pipe <= PCF;
      PCD_pipe <= PCD;
      PCE_pipe <= PCE;
      PCM_pipe <= PCE_pipe;
      PCW_pipe <= PCM_pipe;
      
      // Propagación de registros
      RdE_pipe <= RdE;
      RdM_pipe <= RdM;
      RdW_pipe <= RdW;
      Rs1E_pipe <= Rs1E;
      Rs2E_pipe <= Rs2E;
      ResultSrcE0_pipe <= ResultSrcE0;
      
      // Valores de datos en cada etapa
      ALUResultE_pipe <= ALUResultE;
      ALUResultM_pipe <= ALUResult;
      WriteDataM_pipe <= WriteData;
      ResultW_pipe <= ResultW;
    end else begin
      // Reset de todas las señales
      InstrF_pipe <= 32'h0;
      InstrD_pipe <= 32'h0;
      InstrE_pipe <= 32'h0;
      InstrM_pipe <= 32'h0;
      InstrW_pipe <= 32'h0;
      cycle_count <= 0;
    end
  end

  // Mostrar información del pipeline en cada ciclo
  // Usamos negedge con un pequeño delay para asegurar que las señales se estabilicen
  always @(negedge clk) begin
    #1; // Pequeño delay para estabilización
    if (!reset && cycle_count > 0) begin
      // Determinar qué etapas están activas usando las copias del pipeline
      valid_if  = (InstrF_pipe !== 32'h0);
      valid_id  = (InstrD_pipe !== 32'h0 && !FlushD);
      valid_ex  = (InstrE_pipe !== 32'h0 && !FlushE);
      valid_mem = (InstrM_pipe !== 32'h0);
      valid_wb  = (InstrW_pipe !== 32'h0);

      $display("\n================================================================");
      $display("===== CICLO %0d =====   t=%0t ps", cycle_count, $time);
      $display("Etapas activas: %s", get_stages(valid_if, valid_id, valid_ex, valid_mem, valid_wb));
      $display("----------------------------------------------------------------");
      $display("InstrF=%8h (%s) | InstrD=%8h (%s)",
               InstrF_pipe, decode_or_nop(InstrF_pipe),
               InstrD_pipe, decode_or_nop(InstrD_pipe));
      $display("InstrE=%8h (%s) | InstrM=%8h (%s) | InstrW=%8h (%s)",
               InstrE_pipe, decode_or_nop(InstrE_pipe),
               InstrM_pipe, decode_or_nop(InstrM_pipe),
               InstrW_pipe, decode_or_nop(InstrW_pipe));
      $display("PC : F=%08h  D=%08h  E=%08h  M=%08h  W=%08h",
               PCF_pipe, PCD_pipe, PCE_pipe, PCM_pipe, PCW_pipe);
      $display("PC+4: F=%08h  D=%08h  E=%08h  M=%08h  W=%08h",
               PCPlus4F, PCPlus4D, PCPlus4E, PCPlus4M, PCPlus4W);
      $display("Regs: Rs1D=%0d  Rs2D=%0d  |  Rs1E=%0d  Rs2E=%0d",
               Rs1D, Rs2D, Rs1E_pipe, Rs2E_pipe);
      $display("Rds : RdE=%0d  RdM=%0d  RdW=%0d", RdE_pipe, RdM_pipe, RdW_pipe);
      $display("RegWrite: E=%0b  M=%0b  W=%0b", RegWriteE_ctrl, RegWriteM, RegWriteW_ctrl);
      $display("Forward: AE=%02b  BE=%02b", ForwardAE, ForwardBE);
      $display("Hazards: lwStall=%0b  ResultSrcE0=%0b  PCSrcE=%0b",
               lwStall, ResultSrcE0_pipe, PCSrcE);
      $display("Control: StallF=%0b  StallD=%0b  FlushE=%0b  FlushD=%0b",
               StallF, StallD, FlushE, FlushD);
      $display("ALU   : ResultE=%08h  ResultM=%08h  ResultW=%08h",
               ALUResultE_pipe, ALUResultM, ResultW_pipe);
      $display("Mem   : WriteDataM=%08h  DataAdr=%08h  MemWrite=%0b",
               WriteDataM, DataAdr, MemWrite);
      $display("----------------------------------------------------------------");

      // Detener después de un número razonable de ciclos para evitar loops infinitos
      if (cycle_count > 50) begin
        $display("\n*** SIMULATION STOPPED AFTER %0d CYCLES ***", cycle_count);
        $stop;
      end
    end
  end
endmodule