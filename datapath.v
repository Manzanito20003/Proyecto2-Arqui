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
                input  [31:0] ReadData
                
                input enableStallF,
                input enableStallD,
                input resetFlushE,
                input [1:0] ForwardAE,
                input [1:0] ForwardBE,
                
                output [3:0] Rs1D,
                output [3:0] Rs2D,
                output [3:0] RdEO
                );
  
  localparam WIDTH = 32; // Define a local parameter for bus width

  wire [31:0] PCNext, PCPlus4, PCTarget; 
  wire [31:0] ImmExt; 
  wire [31:0] SrcA, SrcB; 
  wire [31:0] Result; 
  wire [31:0] ALUResultE;
  wire [31:0] WriteDataD;

  // next PC logic
  flopr #(WIDTH) pcreg(
    .clk(clk), 
    .reset(reset), 
    .enable(enableStallF)
    .d(PCNext), 
    .q(PC)
  ); 

  adder       pcadd4(
    .a(PC), 
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4)
  ); 

  adder       pcaddbranch(
    .a(PCE), 
    .b(ImmExtE), 
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
    .a3(RdW), // check
    .wd3(Result), 
    .rd1(SrcA), 
    .rd2(WriteDataD)
  ); 

  extend      ext(
    .instr(InstrD[31:7]), // check
    .immsrc(ImmSrc), 
    .immext(ImmExt)
  ); 

  // ALU logic
  mux2 #(WIDTH)  srcbmux(
    .d0(RMuxE), // check
    .d1(ImmExtE), // check
    .s(ALUSrc), 
    .y(SrcB)
  ); 

  alu         alu(
    .a(SrcAE), // check
    .b(SrcB), 
    .alucontrol(ALUControl), 
    .result(ALUResultE), 
    .zero(Zero)
  ); 

  mux3 #(WIDTH)  resultmux(
    .d0(ALUResultM), // check 
    .d1(ReadDataW), // check
    .d2(PCPlus4W), // check 
    .s(ResultSrc), 
    .y(Result)
  );

  // datapath with reg
  wire [31:0] InstrD, PCPlus4D, PCD;
  flopr #(32) instrd(.clk(clk), .reset(reset), enable(enableStallD), .d(Instr), .q(InstrD));
  flopr #(32) pcplus4d(.clk(clk), .reset(reset), enable(enableStallD), .d(PCPlus4), .q(PCPlus4D));
  flopr #(32) pcd_reg(.clk(clk), .reset(reset), enable(enableStallD), .d(PC), .q(PCD));


  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  wire [3:0] RdE;
  flopr #(32) rd1e(.clk(clk), .reset(resetFlushE), enable(1'b0), .d(SrcA), .q(RD1E));
  flopr #(32) rd2e(.clk(clk), .reset(resetFlushE), enable(1'b0), .d(WriteDataD), .q(RD2E));
  flopr #(32) pce_reg(.clk(clk), .reset(resetFlushE), enable(1'b0), .d(PCD), .q(PCE));
  flopr #(4) rde(.clk(clk), .reset(resetFlushE), enable(1'b0), .d(InstrD[11:7]) , .q(RdE));
  flopr #(32) immexte(.clk(clk), .reset(resetFlushE), enable(1'b0), .d(ImmExt), .q(ImmExtE));
  flopr #(32) pcplus4e(.clk(clk), .reset(resetFlushE), enable(1'b0), .d(PCPlus4D), .q(PCPlus4E));

  // mux for hazar unit
  wire [31:0] SrcAE;
  mux3 #(32) mux3sra(RD1E, Result, ALUResultM, ForwardAE, SrcAE);
  mux3 #(32) mux3sra(RD2E, Result, ALUResultM, ForwardBE, RMuxE);

  wire [31:0] ALUResultM, WriteDataM, PCPlus4M;
  wire [3:0] RdM;
  flopr #(32) aluresultm(.clk(clk), .reset(reset), enable(1'b0), .d(ALUResultE), .q(ALUResultM));
  assign ALUResult = ALUResultW;
  flopr #(32) writedatam(.clk(clk), .reset(reset), enable(1'b0), .d(RD2E), .q(WriteDataM));
  assign WriteData = WriteDataM;
  flopr #(4) rdm(.clk(clk), .reset(reset), enable(1'b0), .d(RdE), .q(RdM));
  flopr #(32) pcplus4m(.clk(clk), .reset(reset), enable(1'b0), .d(PCPlus4E), .q(PCPlus4M));


  wire [31:0] ALUResultW, ReadDataW;
  wire [3:0] RdW;
  flopr #(32) aluresultw(.clk(clk), .reset(reset), enable(1'b0), .d(ALUResultM), .q(ALUResultW));
  flopr #(32) readdataw(.clk(clk), .reset(reset), enable(1'b0), .d(ReadData), .q(ReadDataW));
  flopr #(4) rdw(.clk(clk), .reset(reset), enable(1'b0), .d(RdM), .q(RdW));
  flopr #(32) pcplus4w(.clk(clk), .reset(reset), enable(1'b0), .d(PCPlus4M), .q(PCPlus4W));
  
  // reg for hazar unit
  flopr #(4) rs1d(clk, resetFlushE, 1'b0, InstrD[19:15], Rs1E);
  flopr #(4) rs2d(clk, resetFlushE, 1'b0, InstrD[24:20], Rs2E);
  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];
  assign RdEO = RdE;
endmodule