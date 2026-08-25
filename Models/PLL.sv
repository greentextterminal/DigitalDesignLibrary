/*
--------PLL Model--------

High Level Block Model
   __________________
->|ref_clk  pll_lock|->
->|clk0_en      clk0|->
->|clk1_en      clk1|->
->|clk2_en      clk2|->
->|clk3_en      clk3|->
->|clk4_en      clk4|->
->|clk5_en      clk5|->
  |_________________|


Clock Period from Frequency Calculation
____________________________________________________________________
| These waveforms are meant to illustrate why we need to           |
| toggle the clock at half the calculated given some frequency     |
|                                                                  |
| Waveforms example (@ frequency = 1GHz -> period = 1ns            |
|              _____       _____                                   |
| clk_out:    |     |_____|     |_____|                            |
| period (T): |<---1ns--->|                                        |
| clk signal: |<-1->|<-0->|                                        |
|                   ^_______toggle clock here every T/2 time units | 
|__________________________________________________________________|

Assumptions:
- Primary global clock (clk0) is 50MHz and is the default frequency for the PLL model
- All other clock outputs (clk1-clk5) will default to 0 if not specified
- All frequency parameters are specified in MHz (uses a real data type to accept decimal values
- The input ref_clk is an external reference clock that will be used for the internal logic of this module
- Timescale is 1 ns / 1 ps (ps precision is needed for half periods that are decimals i.e. F = 40MHz, 1/2T = 12.5ns)
- A lost reference clock will stay low (expect the ref clock to be stuck low if lost or disabled)
- 1 missed positive edge of the reference clock will be considered a lost reference clock

*/

`timescale 1 ns / 1 ps

module PLLSimModel #(
    parameter real clk0_freq_mhz = 50.0,    // Default to 50MHz for clk0; reserved for global clock
    parameter real clk1_freq_mhz = 0.0,     // Clocks 1-5 are general purpose (any other clock interface)
    parameter real clk2_freq_mhz = 0.0,     // ...
    parameter real clk3_freq_mhz = 0.0,     // ...
    parameter real clk4_freq_mhz = 0.0,     // ...
    parameter real clk5_freq_mhz = 0.0      // ...
)(
    input      ref_clk,                     // input reference clock for the PLL
    input      clk0_en,                     // enable signal for clk0
    input      clk1_en,                     // enable signal for clk1
    input      clk2_en,                     // enable signal for clk2
    input      clk3_en,                     // enable signal for clk3
    input      clk4_en,                     // enable signal for clk4
    input      clk5_en,                     // enable signal for clk5
    output     pll_lock                     // is high when PLL is locked
    output reg clk0,                        // clk0 generator
    output reg clk1,                        // clk1 generator
    output reg clk2,                        // clk2 generator
    output reg clk3,                        // clk3 generator
    output reg clk4,                        // clk4 generator
    output reg clk5                         // clk5 generator
);
    
    // Declaring internal variables
    reg pll_lock_internal;                  // PLL lock acts as our internal global enable signal for the clock generators
    reg message_printed = 0;                // message control flag (prevent repeat prints)

    // local parameters
    localparam int CYCLES_UNTIL_LOCK = 5;   // Number of ref clk posedges until PLL locks
    localparam int REF_CLK_PERIOD_NS = 20;  // 50MHz reference clock in ns

    // connecint internal regs to output wires
    assign pll_lock = pll_lock_internal;

    // --------------------Main Simulation Logic---------------------
    /* This section describes the main sim flow
       NOTE: All edge/level sensitive behavior operates directly on the module signals inside always blocks.
            Task arguments in SystemVerilog are copied by value at call time 
    */

    // ----------------------Initialize Outputs----------------------
    initial begin
        pll_lock_internal = 0;
        clk0              = 0;
        clk1              = 0;
        clk2              = 0;
        clk3              = 0;
        clk4              = 0;
        clk5              = 0;
    end

    // -----------------------Wait for PLL lock----------------------
    // count ref_clk edges; assert pll_lock after CYCLES_UNTIL_LOCK
    integer lock_tick_count = 0;
    //
    always @ (posedge ref_clk) begin
        if (lock_tick_count == CYCLES_UNTIL_LOCK) begin
            pll_lock_internal <= 1;
            message_printed   <= 0; // reset the message print flag once pll locks
        end
        else if (~pll_lock_internal) begin
            if (lock_tick_count < CYCLES_UNTIL_LOCK) begin
                lock_tick_count <= lock_tick_count + 1;
                $display("Waiting for PLL lock...Cycle %0d/%0d", lock_tick_count + 1, CYCLES_UNTIL_LOCK);
            end
        end
        else begin
            pll_lock_internal <= 1;
        end
    end
   
    // ---------------Clock Period Calculation Function--------------
    // Function to calculate period from frequency (MHz to ns)
    function real calculate_period (
        real frequency_mhz
    );
        return 1000.0 / frequency_mhz;
    endfunction

    // --------Generate clocks Based on Specific Frequencies--------
    /* This automatic task describes the clock generation operation
       It is called from always blocks so it re-executes continuously
       - automatic: each concurrent caller gets its own local storage
       - pll_lock_internal is referenced directly as a module signal (not a task arguments) so the task always sees the current value
       - clk_out is inout (current value is copied in, toggled, copied out)
       - frequency is an input (a parameter constant, safe to copy once)
    */
    task automatic clk_gen (
        input real frequency,
        inout reg  clk_out
    );
        if (~pll_lock_internal || frequency == 0.0) begin
            clk_out = 0;
            @(posedge ref_clk);
        end
        else begin
            @(calculate_period(frequency) / 2.0);
            clk_out = ~clk_out;
        end
    endtask
    
    // -------------------Reference Clock Monitor--------------------
    /* Missing pulse watchdog: at each negedge, race the real next posedge against a one period timeout. Which occurs first wins
       - posedge wins -> clock is healthy, timeout branch is disabled
       - negedge wins -> no posedge arrived within a full period -> lost reference clock
       
                                     |<-expext a posedge here
                                     |
              _____       _____      |
        _____|     |_____|     |_____|_____|_____|_____|_____|
       0ns  10ns  20ns  30ns  40ns  50ns  60ns  70ns  80ns  90ns
                               |<--------->|
                                           ^end of watchdog
    */
    always @ (negedge ref_clk) begin
        // capture immediately
        static realtime negedge_time = $realtime;
        if (pll_lock_internal) begin
            fork : ref_clk_watchdog
                // healthy path: next posedge arrives well before timeout
                begin
                    @(posedge ref_clk);
                end
                // timeout path: a full period passed, no posedge seen
                begin
                    #(REF_CLK_PERIOD_NS);
                    if (~message_printed) begin
                        // time when ref clk was lost
                        $display("Ref clk was lost @ time=%.1f ns", negedge_time);
                        // time when pll was unlocked
                        $display("PLL unlocked @ time=%.1f ns", $realtime);
                        message_printed = 1; // blocking so flag takes effect immediately
                    end
                    // unlock the PLL
                    pll_lock_internal <= 0;
                end
            join_any // stop the other branch when one completes
            disable ref_clk_watchdog
        end
    end
    //
    // Reset the pll lock tick counter the moment pll_lock_internal is deasserted (fires on falling edge)
    always @ (negedge pll_lock_internal) begin
        lock_tick_count <= 0;
    end

    // --------Clock Generator Task Calles with Enable Gating--------
    // clk0_gen
    always begin
        if (~clk0_en | ~pll_lock_internal) begin
            clk0 = 0;
            wait(clk0_en & pll_lock_internal)
        end
        else begin
            clk_gen(clk0_freq_mhz, clk0);
        end
    end
    // clk1_gen
    always begin
        if (~clk1_en | ~pll_lock_internal) begin
            clk1 = 0;
            wait(clk1_en & pll_lock_internal)
        end
        else begin
            clk_gen(clk1_freq_mhz, clk1);
        end
    end
    // clk2_gen
    always begin
        if (~clk2_en | ~pll_lock_internal) begin
            clk2 = 0;
            wait(clk2_en & pll_lock_internal)
        end
        else begin
            clk_gen(clk2_freq_mhz, clk2);
        end
    end
    // clk3_gen
    always begin
        if (~clk3_en | ~pll_lock_internal) begin
            clk3 = 0;
            wait(clk3_en & pll_lock_internal)
        end
        else begin
            clk_gen(clk3_freq_mhz, clk3);
        end
    end
    // clk4_gen
    always begin
        if (~clk4_en | ~pll_lock_internal) begin
            clk4 = 0;
            wait(clk4_en & pll_lock_internal)
        end
        else begin
            clk_gen(clk4_freq_mhz, clk4);
        end
    end
    // clk5_gen
    always begin
        if (~clk5_en | ~pll_lock_internal) begin
            clk5 = 0;
            wait(clk5_en & pll_lock_internal)
        end
        else begin
            clk_gen(clk5_freq_mhz, clk5);
        end
    end

endmodule
