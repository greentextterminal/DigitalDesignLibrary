/*
This counter can be set to count up or count down
If the counter is set to count up then it counts up from 0 to load
If the counter is set to count down then it counts down from load to 0
The WIDTH parameter is used to set the register width for storing the count
When enable is asserted the counter counts up or down
When enable is deasserted the counter is paused

This counter counts 'load' number of times
Ex: @ load = 4, direction = 1
flag:  0    0    0    1    0
count: 0 -> 1 -> 2 -> 3 -> 0 -> ...
       ^    ^    ^    ^
      CC1  CC2  CC3  CC4 }-> total of 4 CC's == (load = 4)
*/

module UpDownCounter #(
  parameter WIDTH = 8
) 
(
  input  clk,
  input  rst,
  input  enable,
  input  [WIDTH - 1:0] load, 
  input  direction, // 1 up, 0 down
  output reg flag
); 

  // internal reg
  reg [WIDTH - 1:0] count;

  // sync reset clears or resets the load value based on the direction
  always @ (posedge clk) begin
    // default flag value
    flag <= 0;
    // reset block
    if (rst) begin
      if (direction) begin 
        count <= 0; // reset count with 0
      end
      else if (!direction) begin
        count <= (load - 1); // reset count with (load - 1)
      end
    end
    // enabled count block
    else if (enable) begin
      // increment the counter if direction is up
      if (direction) begin
        // reset count to 0 if (load-1) is reached
        if (count == (load - 1)) begin
          count <= 0;
        end
        else begin
          count <= count + 1;
          // count look ahead to raise the flag during the same clock edge as count == (load - 1)
          if (count == (load - 2)) begin
                 flag <= 1; // when the count matches the conditional the logic will trigger (during same CC)
          end
        end
      end
      // decrement the counter if direction is down
      else if (!direction) begin
        // reset count to (load - 1) if 0 is reached
        if (count == 0) begin
          count <= (load - 1);
        end
        else begin
          count <= count - 1;
          // count look ahead to raise the flag during the same clock edge as count == 0
          if (count == (0 + 1)) begin
            flag <= 1; // when the count matches the conditional the logic will trigger (during same CC)
          end
        end
      end
    end // end of if (enable) block
    // hold the count if not enabled
    else if (!enable) begin
      count <= count; 
    end 
  end
endmodule
