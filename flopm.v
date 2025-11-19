module flopM (input  clk, reset,
              input  RegWriteE,
              input  [1:0] ResultSrcE,
              input  MemWriteE,
              output reg RegWriteM,
              output reg [1:0] ResultSrcM,
              output reg MemWriteM);

  always @(posedge clk or posedge reset) begin 
    if (reset) begin 
      RegWriteM <= 1'b0; 
      ResultSrcM <= 2'b00; 
      MemWriteM <= 1'b0; 
    end else begin 
      RegWriteM <= RegWriteE; 
      ResultSrcM <= ResultSrcE; 
      MemWriteM <= MemWriteE;
    end 
  end
endmodule