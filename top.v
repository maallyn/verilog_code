module top (
  output wire led0,
  output wire led1,
  output wire led2,
  output wire mosi,
  output wire sck,
  input wire CLK,
  input wire my_reset
);

assign led0 = my_reset;

reg[7:0] counter1 = 0;
reg local_clock = 0;

always @ (posedge CLK)
  begin
  if (counter1 > 3)
    begin
    local_clock <= ~local_clock;
    counter1 <= 0;
    end
  else
    begin
    // local_clock <= ~local_clock; // Debugging
    counter1 <= counter1 + 1;
    end
  end
    

//clk_wiz_0 my_main_clock
  //(
   //Clock out ports  
  //.clk_out1(clk_out1),
  // Status and control signals               
  //.reset(my_reset), 
  //.locked(my_locked),
 // Clock in ports
  //.clk_in1(CLK)
 //);

dostring_wave dostring_wave1 (
  .led1(led1),
  .led2(led2),
  .mosi(mosi),
  .sck(sck),
  .dostring_reset(my_reset),
  .dostring_clk(local_clock)
);
endmodule
