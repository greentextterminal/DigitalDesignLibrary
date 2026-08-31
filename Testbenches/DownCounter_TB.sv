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
    localparam     START_VAL_2                 = WIDTH'(5);
    localparam     TARGET_VAL                  = WIDTH'(0);
    
    // signal declaration
    logic clk;
    logic rst;
    logic count_en;
    logic load_en;
    logic [WIDTH-1:0] load_val;
    logic [WIDTH-1:0] target_val;
    logic hold_or_loop;
    logic [WIDTH-1:0] count;
    logic count_reached;

    // DUT instantiation
    DownCounter #(
        .WIDTH(WIDTH)) DUT
    (
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

    // ---------------------------Value Initialization Block--------------------------
    initial begin
        clk          = 0;
        rst          = 1;           // asserted
        count_en     = 0;
        load_en      = 0;
        load_val     = START_VAL;   // starting value
        target_val   = TARGET_VAL;  // target value
        hold_or_loop = 0;           // hold selected
    end

    // --------------------------------Clock Generator--------------------------------
    initial begin
        // toggling every 10ns -> T = 20ns -> F = 50MHz
        forever begin
            #10 clk = ~clk;
        end
    end
                                                
    // -------------------------------------Tasks-------------------------------------
    // This task creates delays based on a parameterized number of clock counts
    task automatic clock_edge_delay(
        input int clock_edge_count
    );
        repeat (clock_edge_count) begin
            @(posedge clk);
        end
    endtask

    // -------------------------------Stimulus Generator------------------------------
    initial begin
        // holding reset before release
        clock_edge_delay(CLK_EDGES_UNTIL_RST_RELEASE);
        rst <= 0;
        
        // enable the counter
        count_en <= 1;

        // wait until flag goes high;
        wait(count_reached);

        // wait for 5 clock edges before assertnng reset to test flags ability to hold state
        clock_edge_delay(5);
        rst <= 1;
        
        // holding reset before release
        clock_edge_delay(CLK_EDGES_UNTIL_RST_RELEASE);
        rst <= 0;
       
        // disable the counter
        count_en <= 0;

        // set the counter to loop
        hold_or_loop <= 1;

        // load new value to test loop capability
        load_en <= 1;
        load_val <= START_VAL_2;

        // wait for 1 cc
        clock_edge_delay(1);

        // deassert load en
        load_en <= 0;

        // enable the counter
        count_en <= 1;
        
        // end the simulation
        #800
        $finish;
    end

    // --------------------------------Waveform Dumping-------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, DownCounter_TB);
    end

endmodule
