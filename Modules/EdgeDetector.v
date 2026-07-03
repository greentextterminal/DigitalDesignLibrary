/*
This edge detector module is meant to precisely detect when a signal transitions.
It can be configured in 3 different ways.

"RE" : rising edge  0 -> 1
"FE" : falling edge 1 -> 0
"AE" : any edge     0 -> 1 or 1 -> 0

Set the edge type parameter as follows for different configurations:
0 : "RE"
1 : "FE"
2 : "AE"

It should be noted that if signal is 1 while coming out of reset, 
the circuit will erroneously flag an edge detected in the case of RE or AE (the RE portion).
To prevent this, the first clock cycle after rst goes low should be suppressed. This can be 
done by registering the rst and creating a 1 clock cycle delayed rst signal whose inverse will be ANDed
with the cases that are affected by coming out of rst (RE and AE).
The reason that the RE and AE edge cases can exhibit these behavior is due to the signal_dly signal being driven 
low while the rst is asserted. Since signal_dly is a register, when rst goes low, signal_dly will still be 0
for the clock cycle after rst goes low, which when combined with signal already being driven with a 1 can create
a condition where RE or AE incorrectly flag an edge. However, this is wrong since the signal_dly was driven with a 0
by rst being high, rather than naturally setling to 0 by sampling the signal input. Therefore, in this situation,
the clock cycle after rst goes low is an invalid window and should be igored/suppressed.
*/

module edge_detector #(
  parameter EDGE_TYPE = 0 // default is RE
)(
  input  clk,
  input  rst,
  input  signal,
  output edge_detected
);

  // reg declarations
  reg rst_dly;
  reg signal_dly;

  // creating a rst delay to prevent erroneous coming out of reset edge detections (RE and AE cases)
  always @ (posedge clk) begin
    if (rst)
      rst_dly <= 1'b1;
    else
      rst_dly <= 1'b0;
  end

  // creating a signal delay to create edge detection
  always @ (posedge clk) begin
    if (rst)
      signal_dly <= 0;
    else 
      signal_dly <= signal;
  end

  // equivalent to a conditional generate block to synthesize a specific edge detector configuration
  // since the parameter is known during elaboration time, the synthesizer prunes the "unreachable" logic
  // and leaves only the case item logic corresponding to the EDGE_TYPE case
  always @ (*) begin
    case (EDGE_TYPE)
      0 :      edge_detected = (signal & ~signal_dly) & ~rst_dly; // rising edge case
      1 :      edge_detected = (~signal & signal_dly);            // falling edge case
      2 :      edge_detected = (signal ^ signal_dly) & ~rst_dly;  // any edge case
      default: edge_detected = 1'b0;                              // default case (prevent latching if illegal value entered for EDGE_TYPE)
    endcase
  end
  
endmodule
