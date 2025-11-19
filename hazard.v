module hazard(Rs1D,Rs2D,Rs1E,Rs2E,RdE,RdM,RdW,RegWriteM,RegWriteW,ResultSrcE0,PCSrcE,StallF, StallD,FlushE,FlushD,ForwardAE, ForwardBE);
  input [4:0] Rs1D, Rs2D;
  input [4:0] Rs1E, Rs2E, RdE;
  input [4:0] RdM;
  input [4:0] RdW;
  
  input  RegWriteM, RegWriteW;
  input  ResultSrcE0;
  input  PCSrcE;

  output StallF, StallD;
  output FlushE,FlushD;
  output reg [1:0] ForwardAE, ForwardBE;

  //logic hardz unit: Reenviar para resolver riesgos de datos cuando sea necesario
  always @(*) begin
    if ((Rs1E == RdM) && RegWriteM && (Rs1E != 5'b0))
      ForwardAE = 2'b10;
    else if ((Rs1E == RdW) && RegWriteW && (Rs1E != 5'b0))
      ForwardAE = 2'b01;
    else
      ForwardAE = 2'b00;
  end

  always @(*) begin
    if ((Rs2E == RdM) && RegWriteM && (Rs2E != 5'b0))
      ForwardBE = 2'b10;
    else if ((Rs2E == RdW) && RegWriteW && (Rs2E != 5'b0))
      ForwardBE = 2'b01;
    else
      ForwardBE = 2'b00;
  end
  
  wire lwStall;
  assign lwStall = (ResultSrcE0 && (RdE != 5'b0) && ((Rs1D == RdE) || (Rs2D == RdE)));
  assign StallF = lwStall;
  assign StallD = lwStall;
  assign FlushD = PCSrcE;
  assign FlushE = lwStall | PCSrcE;

endmodule