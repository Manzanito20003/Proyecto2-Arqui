module hazard();
  input [3:0]Rs1D, Rs2D;
  input [3:0]Rs1E, Rs2E,RdE;
  input [3:0]RdM;
  input [3:0]RdW;
  
  input  RegWriteM, RegWriteW;
  input  ResultSrcE,
  input  PCSrcE;

  output StallF, StallD;
  output FlushE,FlushD;
  output [1:0] ForwardAE, ForwardBE;

  //logic hardz unit: Reenviar para resolver riesgos de datos cuando sea necesario
  always @(*)
  begin
    if ( (Rs1E == RdM) & RegWriteM & (Rs1E != 0) ) 
      ForwardAE = 2'b10; 
    else if ( (Rs1E == RdW) & RegWriteW & (Rs1E != 0) ) 
      ForwardAE = 2'b01; 
    else 
      ForwardAE = 2'b00;
  end

  always @(*)
  begin
    if ( (Rs2E == RdM) & RegWriteM & (Rs2E != 0) ) 
      ForwardBE = 2'b10; 
    else if ( (Rs2E == RdW) & RegWriteW & (Rs2E != 0) ) 
      ForwardBE = 2'b01; 
    else 
      ForwardBE = 2'b00;
  end 
  //stall logic:Detenerse cuando ocurre un riesgo de carga
  assign StallD = ( ( (Rs1D == RdE) | (Rs2D == RdE) ) & RegWriteE & (ResultSrcE == 0) ) ? 1 : 0;
  assign StallF =StallD;
  //flush : Vacíe cuando se tome una rama o una carga introduzca una burbuja:
  assign FlushE =StallD | PCSrcE;
  assign FlushD =StallD;

endmodule