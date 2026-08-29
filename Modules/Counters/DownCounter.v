/*
----------------DownCounter----------------

About the block:
- This is a loadable counter which counts down from (load_val-1) to 0
- If load is asserted, the counter will load its internal count register with load_val
- Can be set to count down and hold value at 0 or keep loading and counting down in a loop
- Both the load and target values are bound by WIDTH, therefore set WIDTH to accomodate the largest of the two

Use cases:
- Watchdog timer
- Standard down counter

Block Model:
                            look ahead latch
 _________    _________    ____________________
 | adder |    | count |    | target-1 reached |
 |       |--->|  DFF  |--->|       DFF        |---> registered and clean (glitch free) flag
 |_______|    |_______|    |__________________|
 
*/

module DownCounter #(
    parameter WIDTH = 8
)(
    input  clk                      // clock
    input  rst,                     // synchronous reset
    input  count_en,                // enable signal to run counter
    input  load_en,                 // if asserted, load the count register with load_val
    input  [WIDTH-1:0] load_val,    // value with which to load the counter (starting value)
    input  [WIDTH-1:0] target_val,  // value that we are counting down to (target value; usually 0 unless set to non-0 value)
    input  hold_or_loop,            // hold the counter at 0 until reset or keep loading and counting down in a loop (0 : hold, 1 : loop)
    output reg [WIDTH-1:0] count,   // exposing the internal count register (can be used for monitoring, indexing, etc...)
    output count_reached            // flag to indicate that counter has reached target value
);
    // wires
    wire target_hit;
    wire target_look_ahead;

    // regs
    reg latched_look_ahead;

    // target value hit detection
    assign target_hit = (count == target_val) ? 1 : 0; // drive the wire if count hits target value

    // look ahead detaction (target_val + 1)
    assign target_look_ahead = (count == (target_val + 1)) ? 1 : 0;

    // down counter logic
    always @ (posedge clk) begin
        // reload the count with load_val during a reset
        if (rst) begin
            count <= load_val;
        end
        // load the count register with load_val (starting value)
        else if (load_en) begin
            count <= load_val;
        end
        // if target is reached (actions below take place on the next clock cycle)
        else if (target_hit) begin
            // if hold is selected, hold the count val once target value is hit
            if (~hold_or_loop) begin
                count <= count;
            end
            // if loop is selected, reload the count with load_val and count back down
            else if (hold_or_loop) begin
                count <= load_val;
            end
        end
        // if count is enabled decrement the count
        else if (count_en) begin
            count <= count - 1;
        end
        // hold the counter in its current state (enable deasserted)
        else begin
            count <= count;
        end
    end

    // look ahead latch to register a target hit with no potential for combinational glitches during target hit CC
    always @ (posedge clk) begin
        if (target_look_ahead) begin
            latched_look_ahead <= target_look_ahead;
        end
        else begin
            latched_look_ahead <= 0;
        end
    end
    
    // drive the outputs
    assign count_reached = latched_look_ahead;

endmodule
