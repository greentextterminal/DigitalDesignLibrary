/*
----------------UpCounter----------------

- This block counts up to N
- N is loaded into the counter
- Can be set to count up to and hold value until reset or overflow and keep counting in a loop

About the block:
- This is a loadable counter which counts up from load_val to (target_val-1)
- If load is asserted, the counter will load its internal count register with 0
- Can be set to count up and hold value at load_val or keep loading and counting up in a loop
- Both the load and target values are bound by WIDTH, therefore set WIDTH to accomodate the largest of the two

Use cases:
- Standard up counter
- Timer
*/

module UpCounter #(
    parameter WIDTH = 8
)(
    input  clk                      // clock
    input  rst,                     // synchronous reset
    input  count_en,                // enable signal to run counter
    input  load_en                  // if asserted, load the count register with load_val
    input  [WIDTH-1:0] load_val,    // value with which to load the counter (starting value; may be non-0 in some cases)
    input  [WIDTH-1:0] target_val,  // value that we are counting up to (target value)
    input  hold_or_loop,            // hold the counter at 0 until reset or keep loading and counting down in a loop (0 : hold, 1 : loop)
    output reg [WIDTH-1:0] count,   // exposing count register
    output reg count_reached        // flag to indicate that counter has reached load_val
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

    // wires
    wire hit;
    
    // regs
    reg [WIDTH-1:0] count;

    // count hit detection
    assign hit = (count == (N-1)) ? 1 : 0;

    // always block to count up
    always @ (posedge clk) begin
        // reset the count back down to 0
        if (rst) begin
            count <= load_val;
        end
        // if hit detection logic
        else if (hit) begin
            // hold case
            if (~hold_or_overflow) begin
                // while count is being held, so if the count_reached flag
                count <= count;
            end
            // overflow case
            else if (hold_or_overflow) begin
                // reset the count back down to load_val to loop count
                count <= load_val;
            end
        end
        // increment the count if enable is asserted
        else if (count_en) begin 
            count <= count + 1;
        end
        // hold the count (enable deasserted)
        else begin
            count <= count;
        end
    end

    // drive output with hit wire
    assign count_reached = hit;
    
endmodule
