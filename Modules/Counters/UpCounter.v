/*
UpCounter

- This block counts up to N
- N is loaded into the counter
- Can be set to count up to and hold value until reset or overflow and keep counting in a loop
*/

module UpCounter #(
    parameter N                = 1; // default value is a count of at least 1
    parameter hold_or_overflow = 0, // hold to keep the counter at N until reset, otherwise overflow and loop (0 for hold and 1 for overflow)
)(
    input  clk                      // clock
    input  rst,                     // synchronous reset
    input  en,                      // enable
    output count_reached            // flag to indicate that counter has reached N
);
    /*
        CC   |  count
        -----|----------
        1    |  0
        2    |  1
        3    |  2
        ...  |  ...
        N    |  N - 1
    */

    // count register
    reg [($clog2(N) - 1) : 0] count;

    // count hit detection
    wire hit;
    assign hit = (count == (N-1)) ? 1 : 0;

    // always block to count up
    always @ (posedge clk) begin
        if (rst) begin
            count <= 0; // reset the count back down to 0
        end
        else if (~hold_or_overflow) begin // hold case
            if (hit) begin
                count <= count; // while count is being held, so if the count_reached flag
            end
        end
        else if (hold_or_overflow) begin // overflow case
            if (hit) begin
                count <= 0; // reset the count back down to 0 to loop count
            end
        end
        else if (en) begin 
            count <= count + 1; // increment the count if enable is asserted
        end
        else begin
            count <= count; // hold the count (enable deasserted)
        end
    end

    // drive output with hit wire
    assign count_reached = hit;
    
endmodule
