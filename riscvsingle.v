module riscvsingle(input  clk, reset,
                   output [31:0] PC,
                   input  [31:0] Instr,
                   output MemWrite,
                   output [31:0] DataAdr, 
                   output [31:0] WriteData,
                   input  [31:0] ReadData);
  
  wire [31:0] ALUResult; 
  wire [31:0] InstrD;
  wire       ALUSrc, RegWrite, Jump, Zero; 
  wire [1:0] ResultSrc, ImmSrc; 
  wire [2:0] ALUControl; 
  wire       PCSrcE; 
  wire       StallF, StallD, FlushD, FlushE;
  wire [1:0] ForwardAE, ForwardBE;
  wire       RegWriteM;
  wire       ResultSrcE0;
  wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;

  assign DataAdr = ALUResult;

  controller c(
    .clk(clk),
    .reset(reset),
    .FlushE(FlushE),
    .op(InstrD[6:0]), 
    .funct3(InstrD[14:12]), 
    .funct7b5(InstrD[30]), 
    .Zero(Zero),
    .ResultSrc(ResultSrc), 
    .MemWrite(MemWrite), 
    .PCSrc(PCSrcE),
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite), 
    .Jump(Jump),
    .ImmSrc(ImmSrc), 
    .ALUControl(ALUControl),
    .RegWriteM(RegWriteM),
    .ResultSrcE0(ResultSrcE0)
  ); 
  
  datapath dp(
    .clk(clk), 
    .reset(reset), 
    .ResultSrc(ResultSrc), 
    .PCSrc(PCSrcE),
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite),
    .ImmSrc(ImmSrc), 
    .ALUControl(ALUControl),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .Zero(Zero), 
    .PC(PC), 
    .Instr(Instr),
    .ALUResult(ALUResult), 
    .WriteData(WriteData), 
    .ReadData(ReadData),
    .InstrD(InstrD),
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .RdM(RdM),
    .RdW(RdW)
  ); 
  
  hazard hd(
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .RdM(RdM),
    .RdW(RdW),
    .RegWriteM(RegWriteM),
    .RegWriteW(RegWrite),
    .ResultSrcE0(ResultSrcE0),
    .PCSrcE(PCSrcE),
    .StallF(StallF),
    .StallD(StallD),
    .FlushE(FlushE),
    .FlushD(FlushD),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE)
  );
  
endmodule