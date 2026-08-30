/*
DownCounter Testbench
*/

// timescale <time_unit> / <time_precision>
`timescale 1 ns / 1 ns

// testbench shell
module DownCounter_TB;
    // ---------------Parameter/Signal Declaration and DUT Instantiation--------------
    // parameters
    localparam int WIDTH                       = 8;
    localparam int CLK_EDGES_UNTIL_RST_RELEASE = 5;
    // width casting params based on WIDTH param
    localparam     START_VAL                   = WIDTH'(10);
    localparam     TARGET_VAL                  = WIDTH'(0);
    
    // signal declaration
    logic clk,
    logic rst,
    logic count_en,
    logic load_en,
    logic load_val,
    logic target_val,
    logic hold_or_loop,
    logic count,
    logic count_reached

    // DUT instantiation
    DownCounter dut #(
        .WIDTH(WIDTH)
    )(
        .clk(clk),
        .rst(rst),
        .count_en(count_en),
        .load_en(load_en),
        .load_val(load_val),
        .target_val(target_val),
        .hold_or_loop(hold_or_loop),
        .count(count),
        .count_reached(count_reached)
    );

    // -------------------Clock Edge Counter to Control Reset Release-----------------
    integer clock_posedge_cnt = 0;
    always @ (posedge clk) begin
        if (clock_posedge_cnt == CLK_EDGES_UNTIL_RST_RELEASE) begin
            clock_posedge_cnt = clock_posedge_cnt;
            rst               = 1;
        end
        else begin
            clock_posedge_cnt = clock_posedge_cnt + 1;
        end
    end
    //
    // --------Reset the count when reset is asserted again (event controlled)--------
    always @ (posedge rst) begin
        clock_posedge_cnt = 0;
    end

    // ---------------------------Value Initialization Block--------------------------
    initial begin
        clk          = 0;
        rst          = 1;     // asserted
        count_en     = 0;
        load_en      = 0;
        load_val     = 8'd10; // starting value
        target_val   = 8'd0;  // target value
        hold_or_loop = 0;     // hold selected
    end

    // --------------------------------Clock Generator--------------------------------
    initial begin
        // toggling every 1ns -> T = 2ns -> F = 500MHz
        forever begin
            #1 clk = ~clk;
        end
    end

    // -------------------------------Stimulus Generator------------------------------
    initial begin
        // wait until reset is released to proceed with driving the stimulus
        wait(~rst)
        $display("Reset deasserted @ time %0t", $realtime);

        // begin decrementing
        count_en = 1;
    end

    // ---------------------------Monitor and Display block---------------------------
    initial begin
        // monitor count
        $monitor("count is %d @ time=%t is ", count, $realtime);
        // monitor count_reached
        $monitor("count_reached @ time=%t ", $realtime);
    end

endmodule
