/*
--------------------------------UpCounter--------------------------------

- This block counts up to N
- N is loaded into the counter
- Can be set to count up to and hold value until reset or loop and keep counting in a loop

About the block:
- This is a loadable counter which counts up from load_val to (target_val-1)
- If load is asserted, the counter will load its internal count register with 0
- Can be set to count up and hold value at load_val or keep loading and counting up in a loop
- Both the load and target values are bound by WIDTH, therefore set WIDTH to accomodate the largest of the two

Use cases:
- Standard up counter
- Timer

--------------------------------Waveform example--------------------------------
Assumptions: 
- count started from 0 coming out of reset 
- target value N is 5 (count the edges or clock cycles)

Create a lookahead flag so that the outut can sample and cleanly register this output as a registered flag
target_hit is asserted when the counts value is N - 1 and is used for controlling the count logic
target_look_ahead asserts when count is N - 2 and is used for sampling purposes by the count_reached register
count_reached is a register which samples the lookeahead to cleanly register the data
If the counter is configured to hold, then the count_reached will remain asserted until reset
If the counter is configured to loop, then the count_reached will remain asserted for 1 clock cycle then reload a start value
                             ___     ___     ___     ___     ___     ___
clk                      ___|   |___|   |___|   |___|   |___|   |___|   |___

clk cycle                   1       2       3       4       5       6    ...

count                       0       1       2       3       4      ...   ...
                                                     _______
lookahead                ___________________________|       |_______________
                                                             _______
target_hit (loop)        ___________________________________|       |_______
                                                             _______
count_reached (loop)     ___________________________________|       |_______
                                                             _______________
target_hit (hold)        ___________________________________|       
                                                             _______________ 
count_reached (hold)     ___________________________________|               


Relationship between clock cycle (CC) and count:
CC   |  count
-----|----------
1    |  0
2    |  1
3    |  2
...  |  ...
N    |  N - 1

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
    // wires
    wire target_hit;
    wire target_look_ahead;

    // count hit detection
    assign target_hit = (count == (target_val - 1)) ? 1 : 0;

    // count hit lookahead detection
    assign target_look_ahead = (count == (target_val - 2)) ? 1 : 0;

    // always block to count up
    always @ (posedge clk) begin
        // reset the count back down to 0
        if (rst) begin
            count <= load_val;
        end
        // if hit detection logic
        else if (target_hit) begin
            // hold case
            if (~hold_or_loop) begin
                // while count is being held, so if the count_reached flag
                count <= count;
            end
            // loop case
            else if (hold_or_loop) begin
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

    // count_reached register logic
    always @ (posedge clk) begin
        // clear the flag
        if (rst) begin
            count_reached <= 0;
        end
        // if lookahead flag is high then count reached asserts in the next cycle
        else if (target_look_ahead) begin
            count_reached <= 1;
        end
        // if count hits target then count_reached behavior is determined based on hold or loop config
        else if (target_hit) begin
            // hold (only clears during a reset)
            if (~hold_or_loop) begin
                count_reached <= 1;
            end
            // loop (assert count reahced flag for 1 cc then clear)
            else if (hold_or_loop) begin
                count_reached <= 0;
            end
        end
        // default
        else begin
            count_reached <= 0;
        end
    end
    
endmodule
