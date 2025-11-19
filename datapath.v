module datapath(input  clk, reset,
                input  [1:0]  ResultSrc, 
                input  PCSrc, ALUSrc,
                input  RegWrite,
                input  [1:0]  ImmSrc, 
                input  [2:0]  ALUControl,
                input  StallF, StallD,
                input  FlushD, FlushE,
                input  [1:0]  ForwardAE, ForwardBE,
                output Zero,
                output [31:0] PC,
                input  [31:0] Instr,
                output [31:0] ALUResult, WriteData, 
                input  [31:0] ReadData,
                output [31:0] InstrD,
                output [4:0] Rs1D, Rs2D,
                output [4:0] Rs1E, Rs2E,
                output [4:0] RdE, RdM, RdW);

  localparam WIDTH = 32;

  wire [31:0] PCNext, PCPlus4F, PCTargetE; 
  wire [31:0] ImmExtD, ImmExtE; 
  wire [31:0] RD1D, RD2D; 
  wire [31:0] RD1E, RD2E; 
  wire [31:0] PCE, PCPlus4E;
  wire [31:0] SrcAE, SrcBE, SrcB; 
  wire [31:0] ResultW; 
  wire [31:0] PCF;
  wire [31:0] ALUResultE;

  // next PC logic
  flopenr #(WIDTH) pcreg(
    .clk(clk), 
    .reset(reset), 
    .en(~StallF),
    .d(PCNext), 
    .q(PCF)
  ); 
  assign PC = PCF;

  adder pcadd4(
    .a(PCF), 
    .b(32'd4), 
    .y(PCPlus4F)
  ); 

  adder pcaddbranch(
    .a(PCE), 
    .b(ImmExtE), 
    .y(PCTargetE)
  ); 

  mux2 #(WIDTH) pcmux(
    .d0(PCPlus4F), 
    .d1(PCTargetE), 
    .s(PCSrc), 
    .y(PCNext)
  ); 
 
  // register file logic
  regfile rf(
    .clk(clk), 
    .we3(RegWrite), 
    .a1(Rs1D), 
    .a2(Rs2D), 
    .a3(RdW), 
    .wd3(ResultW), 
    .rd1(RD1D), 
    .rd2(RD2D)
  ); 

  extend ext(
    .instr(InstrD[31:7]), 
    .immsrc(ImmSrc), 
    .immext(ImmExtD)
  ); 

  // ALU logic
  mux3 #(WIDTH) forwarda(
    .d0(RD1E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardAE),
    .y(SrcAE)
  );

  mux3 #(WIDTH) forwardb(
    .d0(RD2E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardBE),
    .y(SrcBE)
  );

  mux2 #(WIDTH) srcbmux(
    .d0(SrcBE),
    .d1(ImmExtE),

    .s(ALUSrc), 
    .y(SrcB)
  ); 

  alu alu(
    .a(SrcAE), 
    .b(SrcB), 
    .alucontrol(ALUControl), 
    .result(ALUResultE), 
    .zero(Zero)
  ); 

  mux3 #(WIDTH) resultmux(
    .d0(ALUResultW), 
    .d1(ReadDataW), 
    .d2(PCPlus4W), 
    .s(ResultSrc), 
    .y(ResultW)
  );

  // IF/ID pipeline registers
  wire [31:0] InstrF = Instr;
  wire [31:0] PCPlus4D, PCD;

  flopenrc #(32) instrd_reg(
    .clk(clk),
    .reset(reset),
    .en(~StallD),
    .clear(FlushD),
    .d(InstrF),
    .q(InstrD)
  );

  flopenrc #(32) pcplus4d_reg(
    .clk(clk),
    .reset(reset),
    .en(~StallD),
    .clear(FlushD),
    .d(PCPlus4F),
    .q(PCPlus4D)
  );


  flopenrc #(32) pcd_reg(
    .clk(clk),
    .reset(reset),
    .en(~StallD),
    .clear(FlushD),
    .d(PCF),
    .q(PCD)
  );

  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];
  wire [4:0] RdD = InstrD[11:7];

  // ID/EX pipeline registers
  flopenrc #(32) rd1e_reg(.clk(clk), .reset(reset), .en(1'b1), .clear(FlushE), .d(RD1D), .q(RD1E));
  flopenrc #(32) rd2e_reg(.clk(clk), .reset(reset), .en(1'b1), .clear(FlushE), .d(RD2D), .q(RD2E));
  flopenrc #(32) pce_reg(.clk(clk), .reset(reset), .en(1'b1), .clear(FlushE), .d(PCD), .q(PCE));
  flopenrc #(5) rde_reg(.clk(clk), .reset(reset), .en(1'b1), .clear(FlushE), .d(RdD), .q(RdE));
  flopenrc #(5) rs1e_pipe(.clk(clk), .reset(reset), .en(1'b1), .clear(FlushE), .d(Rs1D), .q(Rs1E));
  flopenrc #(5) rs2e_pipe(.clk(clk), .reset(reset), .en(1'b1), .clear(FlushE), .d(Rs2D), .q(Rs2E));
  flopenrc #(32) immexte(.clk(clk), .reset(reset), .en(1'b1), .clear(FlushE), .d(ImmExtD), .q(ImmExtE));
  flopenrc #(32) pcplus4e(.clk(clk), .reset(reset), .en(1'b1), .clear(FlushE), .d(PCPlus4D), .q(PCPlus4E));

  // EX/MEM pipeline registers
  wire [31:0] ALUResultM, WriteDataM, PCPlus4M;
  flopr #(32) aluresultm(.clk(clk), .reset(reset), .d(ALUResultE), .q(ALUResultM));
  flopr #(32) writedatam(.clk(clk), .reset(reset), .d(SrcBE), .q(WriteDataM));
  flopr #(5) rdm(.clk(clk), .reset(reset), .d(RdE), .q(RdM));
  flopr #(32) pcplus4m(.clk(clk), .reset(reset), .d(PCPlus4E), .q(PCPlus4M));

  assign ALUResult = ALUResultM;
  assign WriteData = WriteDataM;

  // MEM/WB pipeline registers
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
  flopr #(32) aluresultw(.clk(clk), .reset(reset), .d(ALUResultM), .q(ALUResultW));
  flopr #(32) readdataw(.clk(clk), .reset(reset), .d(ReadData), .q(ReadDataW));
  flopr #(5) rdw(.clk(clk), .reset(reset), .d(RdM), .q(RdW));
  flopr #(32) pcplus4w(.clk(clk), .reset(reset), .d(PCPlus4M), .q(PCPlus4W));
  

endmodule