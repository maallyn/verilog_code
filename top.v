module top (
  output wire led0,
  output wire led1,
  output wire led2,
  output wire mosi,
  output wire sck,
  input wire Clk
);

dostring_wave dostring_wave1 (
  .led0(led0),
  .led1(led1),
  .led2(led2),
  .mosi(mosi),
  .sci(sck),
  .CLK(CLK)
);
