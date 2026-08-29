/*
----------------DownCounter----------------

About the block:
- This is a loadable counter which counts down from (load_val-1) to 0
- If load is asserted, the counter will load its internal count register with load_val
- Can be set to count down and hold value at 0 or keep loading and counting down in a loop 

Use cases:
- Watchdog timer
- Standard down counter
*/

module DownCounter #(
    parameter WIDTH = 8
)(
    input  clk                      // clock
    input  rst,                     // synchronous reset
    input  count_en,                // enable signal to run counter
    input  load_en,                 // if asserted, load the count register with load_val
    input  [WIDTH-1:0] load_val,    // value with which to load the counter       
    input  hold_or_loop,            // hold the counter at 0 until reset or keep loading and counting down in a loop (0 : hold, 1 : loop)
    output count_reached            // flag to indicate that counter has reached 0
);
    // count register
    reg [WIDTH-1:0] count;

    // 0 hit detection
    wire zero_hit;
    assign zero_hit = (count == 0) ? 1 : 0; // drive the wire if count hits 0

    // down counter logic
    always @ (posedge clk) begin
        // reload the count with load_val during a reset
        if (rst) begin
            count <= load_val;
        end
        // load the count register with load_val
        else if (load_en) begin
            count <= load_val;
        end
        // if count is not enabled hold the counter in its current state
        else if (~count_en) begin
            count <= count;
        end
        // if hold is selected, hold the count val once 0 is hit
        else if (~hold_or_loop) begin
            if (zero_hit) begin
                count <= count;
            end
        end
        // if loop is selected, reload the count with load_val and count back down
        else if (hold_or_loop) begin
            if (zero_hit) begin
                count <= load_val;
            end
        end
        // decrement the count
        else begin
            count <= count - 1;
        end
    end

    // drive the output
    assign count_reached = hit;

endmodule
