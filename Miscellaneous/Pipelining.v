/* 
1) Pipelining
In piplining you break an operation up into stages. By doing so you stagger the logic
in a way that you can perform incremental logical computations such that all the logic
necessary for the greater logical operation will be ready and correcly calculated. This
technique allows you to increase throughput by doing multiple operations in a single clock
cycle. This is done by staging. Each stage performs one or a set of specific operations and 
allows multiple digital "threads" to take place back to back.

This can be depicted simply using a math operation in the form of an equation: 
a + b - c * d = e
This equation has 4 variables (a, b, c, d) and 3 operations (+, -, *).
Mathematically, the order of operations is:  (c * d) and (a + b), ((a + b) - (c * d))
We can already start to see a natural order: |-----stage 1-----|  |-----stage 2-----|

Our pipeline should be staged in the same way such that each stage is a smaller part
of the greater operation. Each stage should be assigned to a register which is effectively a delay.
Large and complex operations can be performed combinatorially, but due to the nature of
propagation delay there will be moments of incorrect/unknown outputs as the values settle. To avoid
this we used clock based methodologies with memory elements such as registers that allow for the scheduling
or sequencing of logical operations which guarantee values up to a certain point in time (clock cycle) 
within the greater circuit.
*/

/*
Assuming the variables we are operating on are 4 bit wide the block diagram for the math operation is as follows:
The largest number that can be represented by 4 bits is 15
To prevent overflow the bit widths of the add and multiply blocks are adjusted based on the input bit widths and the operation.

               stage 1                       stage 2
             |         |                  |capture     |
             | capture |                  |parallelized|
             | inputs  |                  |ADD and MULT|
             |         |                  |outputs     |
             |         |                  |            |
          4  | _______ | 4   _______      |            |
[3:0] a---/--|-|a reg|-|-/---|ADDER|   5  | __________ |  5    
             | |_____| |     |BLOCK|---/--|-|ADD reg |-|--/---
          4  | _______ | 4   |(a+b)|      | |________| |     |   _____________
[3:0] b---/--|-|b reg|-|-/---|_____|      |            |     |___|SUBTRACT   |   9   ________   9
             | |_____| |                  |            |         |BLOCK      |---/---|e reg |---/---
          4  | _______ | 4   _______      |            |     ----|(a+b)-(c*d)|       |______|
[3:0] c---/--|-|c reg|-|-/---|MULTI|   8  | __________ |  8  |   |___________| 
             | |_____| |     |BLOCK|---/--|-|MULT reg|-|--/---
          4  | _______ | 4   |(c*d)|      | |________| |
[3:0] d---/--|-|d reg|-|-/---|_____|      |            |
             | |_____| |                  |            |
             |         |                  |            |

*/


// Creating a 2 stage pipeline
wire rst;                                          // reset input
wire [3:0] a, b, c, d;                             // input variables
reg  [3:0] a_stage1, b_stage1, c_stage1, d_stage1; // stage 1
reg  [4:0] adder_stage2;                           // stage 2
reg  [7:0] multiplier_stage2;                      // stage 2
reg  [8:0] e;                                      // solution

// sequential block
always @ (posedge clk) begin
  if (rst) begin // clearing all registers (including pipeline)
    a_stage1          <= 4'b0;
    b_stage1          <= 4'b0;
    c_stage1          <= 4'b0;
    d_stage1          <= 4'b0;
    adder_stage2      <= 5'b0;
    multiplier_stage2 <= 8'b0;
    e                 <= 9'b0;
  end
  else begin
    // stage 1
    a_stage1 <= a;
    b_stage1 <= b;
    c_stage1 <= c;
    d_stage1 <= d;
    // stage 2
    adder_stage2      <= (a_stage1 + b_stage1);
    multiplier_stage2 <= (c_stage1 * d_stage1);
    // e
    e <= (adder_stage2 - multiplier_stage2); 
  end
end



