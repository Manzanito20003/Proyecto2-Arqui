module flopE (input  clk, reset,
               input  RegWriteE,
               input  [1:0]ResultSrcE,
               input  MemWriteE,
               
               output  RegWriteM,
               output  [1:0]ResultSrcM,
               output  MemWriteM,
               );
  always @(posedge clk or posedge reset) 
  begin 
    if (reset) 
    begin 
        RegWriteM <= 0; 
        ResultSrcM <= 2'b00; 
        MemWriteM <= 0; 
    end
    else
    begin 
        RegWriteM <= RegWriteE; 
        ResultSrcM <= ResultSrcE; 
        MemWriteM <= MemWriteE;
    end 
  end
endmodule