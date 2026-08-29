/*
UpDownCounter Testbench
*/

// timescale <time_unit> / <time_precision>
`timescale 1ns/1ps

module tb;
  // set this param in the tb to drive the DUT and the bit widths
  localparam WIDTH = 4;
  
  reg clk, rst, enable, direction;
  reg [WIDTH-1:0] load;
  wire flag;

  // initialize DUT and connect IO
  UpDownCounter #(.WIDTH(WIDTH)) DUT (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .load(load),
    .direction(direction),
    .flag(flag)
  );

  // ----Defining the tasks----
  // Creating a signal clearer for transition differentiation
  task signal_clear(input integer num_clocks);
    begin
      rst = 0;
      enable = 0;
      direction = 0;
      load = 0;
      repeat (num_clocks) @ (posedge clk);
    end
  endtask
  
  // Creating a DUT reset for up counting
  task up_reset(input [WIDTH-1:0] test_load,
                input integer num_clocks);
    begin
      rst       = 1;
      enable    = 0;
      direction = 1;
      load      = test_load;
      repeat (num_clocks) @ (posedge clk);
      rst       = 0;
    end
  endtask

  // Creating a DUT reset for down counting
  task down_reset(input [WIDTH-1:0] test_load,
                  input integer num_clocks);
    begin
      rst       = 1;
      enable    = 0;
      direction = 0;
      load      = test_load;
      repeat (num_clocks) @ (posedge clk);
      rst       = 0;
    end 
  endtask
    
  // Creating an up count
  task up_count(input [WIDTH-1:0] test_load,
                input integer num_clocks);
    begin
      @(posedge clk);  // Wait for the edge
      #0.1;            // Nudge slightly past the edge
      enable    = 1;
      direction = 1;
      repeat (num_clocks) @ (posedge clk);
      #0.1;
      enable    = 0;
    end
  endtask
  
  // Creating a down count
  task down_count(input [WIDTH-1:0] test_load,
                  input integer num_clocks);
    begin
      @(posedge clk);  // Wait for the edge
      #0.1;            // Nudge slightly past the edge
      enable    = 1;
      direction = 0;
      repeat (num_clocks) @ (posedge clk);
      #0.1;
      enable    = 0;
    end
  endtask
    
  // creating the clock signal
  initial begin
    // dump waves
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
    
    // oscillating the clock
    forever begin
      #1;
      clk = ~clk;
    end
  end

  // driving stimulus
  initial begin
    // initialize inputs
    clk       = 0;
    rst       = 0;
    enable    = 0;
    load      = 0;
    direction = 0;
    repeat (3) @ (posedge clk);
    // reset with direction set to up and then count up
    up_reset(4, 12);
    up_count(4, 12);
    // clear out the signals to cleanly see the next test
    signal_clear(4);
    // reset with direction set to down and then count down
    down_reset(3, 12);
    down_count(3, 12);
    // clear out the signals to cleanly see the next test
    signal_clear(4);
    // count up and then down
    up_reset(5, 2);
    up_count(5, 2);
    down_reset(5, 2);
    down_count(5, 2);

    // specify a duration 
    #100; // wait for 100 time units
    $finish;
  end

  // monitoring the signals and printing them to console if they change
  initial begin
    $display("Time\t Rst\t En\t Dir\t Count\t Flag");
    $monitor("%0t\t %b\t %b\t %b\t %d\t %b", 
             $time, rst, enable, direction, DUT.count, flag);
  end
  
endmodule
