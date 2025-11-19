module controller(input  clk, reset,
                  input  [6:0] op,
                  input  [2:0] funct3,
                  input   funct7b5,
                  input        Zero,

                  output [1:0] ResultSrc,
                  output Branch, 
                  output MemWrite,
                  output PCSrc, ALUSrc,
                  output RegWrite, Jump,
                  output [1:0] ImmSrc, 
                  output [2:0] ALUControl);
  
  wire [1:0] ALUOp; 
  wire       Branch; 
  
  maindec md(
    .op(op), 
    .ResultSrc(ResultSrc), 
    .MemWrite(MemWrite), 
    .Branch(Branch),
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite), 
    .Jump(Jump), 
    .ImmSrc(ImmSrc), 
    .ALUOp(ALUOp)
  ); 

  aludec  ad(
    .opb5(op[5]), 
    .funct3(funct3), 
    .funct7b5(funct7b5), 
    .ALUOp(ALUOp), 
    .ALUControl(ALUControl)
  ); 
  assign PCSrc = Branch & Zero | Jump; 

    // Execute 
  wire RegWriteE, MemWriteE, ALUSrcE, JumpE,BranchE;
  wire [1:0] ResultSrcE;
  wire [2:0] ALUControlE;

  // Memory
  wire RegWriteM, MemWriteM;
  wire [1:0] ResultSrcM;

  // Writeback
  wire RegWriteW;
  wire [1:0] ResultSrcW;

  //flop E
  flopE fe(
    .clk(clk), 
    .reset(reset), 
    .RegWriteD(RegWrite), 
    .ResultSrcD(ResultSrc), 
    .MemWriteD(MemWrite), 
    .JumpD(Jump), 
    .BranchD(Branch), 
    .ALUControlD(ALUControl), 
    .ALUSrcD(ALUSrc), 

    .RegWriteE(RegWriteE), 
    .ResultSrcE(ResultSrcE), 
    .MemWriteE(MemWriteE), 
    .JumpE(JumpE), 
    .BranchE(BranchE), 
    .ALUControlE(ALUControlE), 
    .ALUSrcE(ALUSrcE)
  );

  //flop M
  flopM fm(
    .clk(clk),
    .reset(reset),
    .RegWriteE(RegWriteE)
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),

    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    .MemWriteM(MemWriteM)
  );
  //flop W
  flopW fw(
    .clk(clk),
    .reset(reset),
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),

    .RegWriteW(RegWriteW),
    .ResultSrcW(ResultSrcW)
  );

  // assing
  assign RegWrite = RegWriteW;
  assign ResultSrc = ResultSrcW;
  assign MemWrite = MemWriteM;
  assign ALUSrc = ALUSrcE;
  assign Jump = JumpE;
  assign ALUControl = ALUControlE;

  

endmodule