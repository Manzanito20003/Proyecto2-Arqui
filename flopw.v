module flopW (input  clk, reset,
              input  RegWriteM,
              input  [1:0] ResultSrcM,
              output reg RegWriteW,
              output reg [1:0] ResultSrcW);

  always @(posedge clk or posedge reset) begin 
    if (reset) begin 
      RegWriteW <= 1'b0; 
      ResultSrcW <= 2'b00; 
    end else begin 
      RegWriteW <= RegWriteM; 
      ResultSrcW <= ResultSrcM;
    end 
  end
endmodule