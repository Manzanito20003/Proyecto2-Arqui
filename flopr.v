module flopr (input  clk, reset, enable,
               input  [WIDTH-1:0] d, 
               output [WIDTH-1:0] q);

  parameter WIDTH = 8;

  reg [WIDTH-1:0] q; 

  always @(posedge clk or posedge reset or posedge enable) begin 
    if (reset) q <= 0; 
    else if (enable) q <= d;
    else q <= d;
  end
endmodule