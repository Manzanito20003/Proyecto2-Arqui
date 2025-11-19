module flopE (input  clk, reset,
              input  FlushE,
              input  RegWriteD,
              input  [1:0] ResultSrcD,
              input  MemWriteD,
              input  JumpD,
              input  BranchD,
              input  [2:0] ALUControlD,
              input  ALUSrcD,

              output reg RegWriteE,
              output reg [1:0] ResultSrcE,
              output reg MemWriteE,
              output reg JumpE,
              output reg BranchE,
              output reg [2:0] ALUControlE,
              output reg ALUSrcE);

  always @(posedge clk or posedge reset) begin 
    if (reset || FlushE) begin 
      RegWriteE   <= 1'b0; 
      ResultSrcE  <= 2'b00; 
      MemWriteE   <= 1'b0; 
      JumpE       <= 1'b0; 
      BranchE     <= 1'b0; 
      ALUControlE <= 3'b000; 
      ALUSrcE     <= 1'b0;
    end else begin 
      RegWriteE   <= RegWriteD; 
      ResultSrcE  <= ResultSrcD; 
      MemWriteE   <= MemWriteD; 
      JumpE       <= JumpD; 
      BranchE     <= BranchD; 
      ALUControlE <= ALUControlD; 
      ALUSrcE     <= ALUSrcD;
    end 
  end
endmodule