module controller(input  clk, reset,
                  input  FlushE,
                  input  [6:0] op,
                  input  [2:0] funct3,
                  input        funct7b5,
                  input        Zero,

                  output [1:0] ResultSrc,
                  output       MemWrite,
                  output       PCSrc, ALUSrc,
                  output       RegWrite, Jump,
                  output [1:0] ImmSrc, 
                  output [2:0] ALUControl,
                  output       RegWriteM,
                  output       ResultSrcE0);
  
  wire [1:0] ALUOp; 
  wire       BranchD; 
  wire       RegWriteD, RegWriteE; 
  wire       MemWriteD, MemWriteE; 
  wire       JumpD, JumpE; 
  wire       BranchE; 
  wire [1:0] ResultSrcD, ResultSrcE, ResultSrcM, ResultSrcW; 
  wire [2:0] ALUControlD, ALUControlE; 
  wire       ALUSrcD, ALUSrcE; 
  wire       MemWriteM; 
  wire       RegWriteW; 
  
  maindec md(
    .op(op), 
    .ResultSrc(ResultSrcD), 
    .MemWrite(MemWriteD), 
    .Branch(BranchD),
    .ALUSrc(ALUSrcD), 
    .RegWrite(RegWriteD), 
    .Jump(JumpD), 
    .ImmSrc(ImmSrc), 
    .ALUOp(ALUOp)
  ); 

  aludec ad(
    .opb5(op[5]), 
    .funct3(funct3), 
    .funct7b5(funct7b5), 
    .ALUOp(ALUOp), 
    .ALUControl(ALUControlD)
  ); 

  flopE fe(
    .clk(clk), 
    .reset(reset), 
    .FlushE(FlushE),
    .RegWriteD(RegWriteD), 
    .ResultSrcD(ResultSrcD), 
    .MemWriteD(MemWriteD), 
    .JumpD(JumpD), 
    .BranchD(BranchD), 
    .ALUControlD(ALUControlD), 
    .ALUSrcD(ALUSrcD), 
    .RegWriteE(RegWriteE), 
    .ResultSrcE(ResultSrcE), 
    .MemWriteE(MemWriteE), 
    .JumpE(JumpE), 
    .BranchE(BranchE), 
    .ALUControlE(ALUControlE), 
    .ALUSrcE(ALUSrcE)
  );

  flopM fm(
    .clk(clk),
    .reset(reset),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    .MemWriteM(MemWriteM)
  );

  flopW fw(
    .clk(clk),
    .reset(reset),
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    .RegWriteW(RegWriteW),
    .ResultSrcW(ResultSrcW)
  );

  assign PCSrc = (BranchE & Zero) | JumpE; 
  assign RegWrite = RegWriteW;
  assign ResultSrc = ResultSrcW;
  assign MemWrite = MemWriteM;
  assign ALUSrc = ALUSrcE;
  assign Jump = JumpE;
  assign ALUControl = ALUControlE;
  assign ResultSrcE0 = ResultSrcE[0];
endmodule