`timescale 10ns / 10ps

module testbench;
  reg clk = 0;
  wire mosi;
  wire sck;

  top mytop1(
    .mosi(mosi),
    .sck(sck),
    .CLK(clk)
  );

integer mycount = 0;

initial begin
  clk = 0;
  for (mycount = 0; mycount < 200000; mycount=mycount+1)
    begin
    #1;
    clk = !clk;
    end
  end

endmodule
