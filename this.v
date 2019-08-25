`timescale 1ns / 1ps

module doled (

input wire[7:0] blue_input,
input wire[7:0] green_input,
input wire[7:0] red_input,
input wire[1:0] type_input,
input wire doled_start,
output reg doled_busy = 0,
output wire mosi,
output wire sck,
input wire doled_clk
);

localparam
  INPUT_TYPE_START = 0,
  INPUT_TYPE_LED = 1,
  INPUT_TYPE_END = 2;

localparam
  LED_IDLE = 0,
  LED_START = 1,
  LED_WAIT_INIT = 2,
  LED_LOAD_INIT = 3,
  LED_WAIT_BLUE = 4,
  LED_LOAD_BLUE = 5,
  LED_WAIT_GREEN = 6,
  LED_LOAD_GREEN = 7,
  LED_WAIT_RED = 8,
  LED_LOAD_RED = 9,
  LED_WAIT_END = 10;

reg[7:0] blue_buf = 0;
reg[7:0] init_buf = 0;
reg[7:0] green_buf = 0;
reg[7:0] holding_buf = 0;
reg[7:0] red_buf = 0;
reg[3:0] led_state = LED_IDLE;
reg spi_start = 0;

spi spi1(
  .spi_clk(doled_clk),
  .spi_output_data(mosi),
  .spi_output_clock(sck),
  .spi_start(spi_start),
  .spi_data_in(blue_buf),
  .spi_busy(spi_busy)
  );

always @ (posedge doled_clk)
  begin
  case (led_state)
    begin
    endcase
  end

endmodule
