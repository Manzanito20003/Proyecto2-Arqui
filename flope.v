module flopE (input  clk, reset,
               input  RegWriteD,
               input  [1:0]ResultSrcD,
               input  MemWriteD,
               input  JumpD,
               input  BranchD,
               input   [2:0]ALUControlD,
               input   ALUSrcD,

               output  RegWriteE,
               output  [1:0]ResultSrcE,
               output  MemWriteE,
               output  JumpE,
               output  BranchE,
               output   [2:0]ALUControlE,
               output   ALUSrcE
               );
  always @(posedge clk or posedge reset) 
  begin 
    if (reset) 
    begin 
        RegWriteE <= 0; 
        ResultSrcE <= 2'b00; 
        MemWriteE <= 0; 
        JumpE <= 0; 
        BranchE <= 0; 
        ALUControlE <= 3'b000; 
        ALUSrcE <= 0;
    end 
    else
    begin 
        RegWriteE <= RegWriteD; 
        ResultSrcE <= ResultSrcD; 
        MemWriteE <= MemWriteD; 
        JumpE <= JumpD; 
        BranchE <= BranchD; 
        ALUControlE <= ALUControlD; 
        ALUSrcE <= ALUSrcD;
    end 
  end
endmodule