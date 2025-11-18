module datapath(input  clk, reset,
                input  [1:0]  ResultSrc, 
                input  PCSrc, ALUSrc,
                input  RegWrite,
                input  [1:0]  ImmSrc, 
                input  [2:0]  ALUControl,
                output Zero,
                output [31:0] PC,
                input  [31:0] Instr,
                output [31:0] ALUResult, WriteData, 
                input  [31:0] ReadData);
  
  localparam WIDTH = 32; // Define a local parameter for bus width

  wire [31:0] PCNext, PCPlus4, PCTarget; 
  wire [31:0] ImmExt; 
  wire [31:0] SrcA, SrcB; 
  wire [31:0] Result; 

  // next PC logic
  flopr #(WIDTH) pcreg(
    .clk(clk), 
    .reset(reset), 
    .d(PCNext), 
    .q(PC)
  ); 

  adder       pcadd4(
    .a(PC), 
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4)
  ); 

  adder       pcaddbranch(
    .a(PC), 
    .b(ImmExt), 
    .y(PCTarget)
  ); 

  mux2 #(WIDTH)  pcmux(
    .d0(PCPlus4), 
    .d1(PCTarget), 
    .s(PCSrc), 
    .y(PCNext)
  ); 
 
  // register file logic
  regfile     rf(
    .clk(clk), 
    .we3(RegWrite), 
    .a1(InstrD[19:15]), // check
    .a2(InstrD[24:20]), // check
    .a3(Instr[11:7]), 
    .wd3(Result), 
    .rd1(SrcA), 
    .rd2(WriteData)
  ); 

  extend      ext(
    .instr(InstrD[31:7]), // check
    .immsrc(ImmSrc), 
    .immext(ImmExt)
  ); 

  // ALU logic
  mux2 #(WIDTH)  srcbmux(
    .d0(WriteData), 
    .d1(ImmExt), 
    .s(ALUSrc), 
    .y(SrcB)
  ); 

  alu         alu(
    .a(SrcA), 
    .b(SrcB), 
    .alucontrol(ALUControl), 
    .result(ALUResult), 
    .zero(Zero)
  ); 

  mux3 #(WIDTH)  resultmux(
    .d0(ALUResult), 
    .d1(ReadData), 
    .d2(PCPlus4), 
    .s(ResultSrc), 
    .y(Result)
  );

  // datapath with reg
  wire [31:0] InstrD, PCPlus4D, PCD;
  flopr #(32) instrd(clk, reset, Instr, InstrD);
  flopr #(32) pcplus4d(clk, reset, PCPlus4, PCPlus4D);
  flopr #(32) pcd(clk, reset, PC, PCD);

  flopr #() rd1e(clk, reset);

endmodule