`timescale 1ns / 1ns

module testbench;
  reg clk = 0;
  wire mosi;
  wire sck;
  wire led0;
  wire led1;
  wire led2;
  reg my_reset;

  top mytop1(
    .mosi(mosi),
    .sck(sck),
    .led0(led0),
    .led1(led1),
    .led2(led2),
    .my_reset(my_reset),
    .CLK(clk)
  );

integer mycount = 0;

initial begin
  clk = 0;
  for (mycount = 0; mycount < 200000; mycount=mycount+1)
    begin
    #1
    clk = ~clk;
    end
  end

initial begin
 #10
 my_reset = 1;
 #20
 my_reset = 0;
 end

endmodule
