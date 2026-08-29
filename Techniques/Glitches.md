# Glitches
Glitches can occur in combinational logic. 
For instance unequal path delays could results in a signals arriving at different times.
Another example is multiple input changes which could result in momentary race conditions leading to incorrect logical states before settling.
To avoid the problem of corrupted data or injecting issues into your datapath a simple mitigation strategy is to register the output of the combinational logic prior to use.

```systemverilog

```
