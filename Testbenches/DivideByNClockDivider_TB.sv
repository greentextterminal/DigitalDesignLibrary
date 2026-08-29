module tb;  
  reg clk;
  reg rst;
  wire divided_clk;

  // DUT instantiation (Set N parameter to anything >=2)
  divide_clock_by_N #(.N(3)) dut (
    .clk(clk),
    .rst(rst),
    .divided_clk(divided_clk)
  );

  // creating the clock
  initial begin
    // dump waves
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
    
    // oscillate the clock
	clk = 0;
    forever begin
      #1;         // 1 time unit of delay
      clk = ~clk; // invert clk signal every 1 time unit
    end
  end
  
  // hold reset then release
  initial begin
  	rst = 1;
    #3;
    rst = 0;
  end
  
  // specify a duration 
  initial begin
    #50;// wait for 50 time units
    $finish;
  end

endmodule
