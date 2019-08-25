`timescale 1ns / 1ps

module testbench;
  reg clk = 0;
  reg reset = 0;
  wire mosi;
  wire sck;

  top mytop1(
    .mosi(mosi),
    .sck(sck),
    .CLK(clk),
    .myreset(reset)
  );

integer mycount = 0;

initial begin
  clk = 0;
  reset = 0;
  for (mycount = 0; mycount < 3000; mycount=mycount+1)
    begin
    #1;
    clk = !clk;
    if (mycount == 3)
      reset = 1;
    if (mycount == 10)
      reset = 0;
    end
  end

endmodule
