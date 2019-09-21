// Doled is the module that presents an entire tricolor LED module to the
// strip. It hendles the master byte and the three color bytes.
// It also will send the start byte for the strip (all zeroes), if the
// type input variable is set to INPUT_TYPE_START value. It will send
// the end string if the input type variable is set to INPUT_TYPE_END. If
// that value is INPUT_TYPE_LED, it will send a properly formated tri
// color LED data string to the strip.

module doled (

input wire[7:0] blue_input,
input wire[7:0] green_input,
input wire[7:0] red_input,
input wire[1:0] type_input,
input wire doled_start,
output reg doled_busy = 0,
output wire mosi,
output wire sck,
input wire doled_reset,
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
  LED_SEND_INIT = 4,
  LED_WAIT_SPI_BUSY_SEND_INIT = 5,
  LED_WAIT_BLUE = 6,
  LED_LOAD_BLUE = 7,
  LED_SEND_BLUE = 8,
  LED_WAIT_SPI_BUSY_SEND_BLUE = 9,
  LED_WAIT_GREEN = 10,
  LED_LOAD_GREEN = 11,
  LED_SEND_GREEN = 12,
  LED_WAIT_SPI_BUSY_SEND_GREEN = 13,
  LED_WAIT_RED = 14,
  LED_LOAD_RED = 15,
  LED_SEND_RED = 16,
  LED_WAIT_SPI_BUSY_SEND_RED = 17,
  LED_WAIT_END = 18;

reg[7:0] blue_buf = 0;
reg[7:0] init_buf = 0;
reg[7:0] green_buf = 0;
reg[7:0] holding_buf = 0;
reg[7:0] red_buf = 0;
reg[4:0] led_state = LED_IDLE;
reg spi_start = 0;

spi spi1(
  .spi_reset(doled_reset),
  .spi_clk(doled_clk),
  .spi_output_data(mosi),
  .spi_output_clock(sck),
  .spi_start(spi_start),
  .spi_data_in(holding_buf),
  .spi_busy(spi_busy)
  );

always @ (posedge doled_clk or posedge doled_reset)
  begin
  if (doled_reset)
    begin
    led_state <= LED_IDLE;
    doled_busy <= 0;
    spi_start <= 0;
    holding_buf <= 0;
    end
  else
    begin
    case (led_state)
      LED_IDLE:
        begin
        if (doled_start == 1)
          begin
          doled_busy <= 1;
          led_state <= LED_START;
          end
        else
          begin
          doled_busy <= 0;
          led_state <= LED_IDLE;
          end
        end
      LED_START:
        begin
        case (type_input)
          INPUT_TYPE_START:
            begin
            init_buf <= 0;
            blue_buf <= 0;
            green_buf <= 0;
            red_buf <= 0;
            end
          INPUT_TYPE_LED:
            begin
            init_buf <= 8'b11111111;
            blue_buf <= blue_input;
            green_buf <= green_input;
            red_buf <= red_input;
            end
          INPUT_TYPE_END:
            begin
            init_buf <= 8'b11111111;
            blue_buf <= 8'b11111111;
            green_buf <= 8'b11111111;
            red_buf <= 8'b11111111;
            end
          default:
            begin
            init_buf <= 8'b11111111;
            blue_buf <= 8'b11111111;
            green_buf <= 8'b11111111;
            red_buf <= 8'b11111111;
            end
          endcase
        led_state <= LED_WAIT_INIT;
        end
      LED_WAIT_INIT:
        begin
        if (~spi_busy)
          begin
          led_state <= LED_LOAD_INIT;
          end
        else
          begin
          led_state <= LED_WAIT_INIT;
          end
        end
      LED_LOAD_INIT:
        begin
        holding_buf <= init_buf;
        led_state <= LED_SEND_INIT;
        end
      LED_SEND_INIT:
        begin
        spi_start <= 1;
        led_state <= LED_WAIT_SPI_BUSY_SEND_INIT;
        end
      LED_WAIT_SPI_BUSY_SEND_INIT:
        begin
        if (spi_busy == 1)
          begin
          spi_start <= 0;
          led_state <= LED_WAIT_BLUE;
          end
        else
          begin
          led_state <= LED_WAIT_SPI_BUSY_SEND_INIT;
          end
        end
      LED_WAIT_BLUE:
        begin
        if (~spi_busy)
          begin
          led_state <= LED_LOAD_BLUE;
          end
        else
          begin
          led_state <= LED_WAIT_BLUE;
          end
        end
      LED_LOAD_BLUE:
        begin
        holding_buf <= blue_buf;
        led_state <= LED_SEND_BLUE;
        end
      LED_SEND_BLUE:
        begin
        spi_start <= 1;
        led_state <= LED_WAIT_SPI_BUSY_SEND_BLUE;
        end
      LED_WAIT_SPI_BUSY_SEND_BLUE:
        begin
        if (spi_busy == 1)
          begin
          spi_start <= 0;
          led_state <= LED_WAIT_GREEN;
          end
        else
          begin
          led_state <= LED_WAIT_SPI_BUSY_SEND_BLUE;
          end
        end
      LED_WAIT_GREEN:
        begin
        if (~spi_busy)
          begin
          led_state <= LED_LOAD_GREEN;
          end
        else
          begin
          led_state <= LED_WAIT_GREEN;
          end
        end
      LED_LOAD_GREEN:
        begin
        holding_buf <= green_buf;
        led_state <= LED_SEND_GREEN;
        end
      LED_SEND_GREEN:
        begin
        spi_start <= 1;
        led_state <= LED_WAIT_SPI_BUSY_SEND_GREEN;
        end
      LED_WAIT_SPI_BUSY_SEND_GREEN:
        begin
        if (spi_busy == 1)
          begin
          spi_start <= 0;
          led_state <= LED_WAIT_RED;
          end
        else
          begin
          led_state <= LED_WAIT_SPI_BUSY_SEND_GREEN;
          end
        end
      LED_WAIT_RED:
        begin
        if (~spi_busy)
          begin
          led_state <= LED_LOAD_RED;
          end
        else
          begin
          led_state <= LED_WAIT_RED;
          end
        end
      LED_LOAD_RED:
        begin
        holding_buf <= red_buf;
        led_state <= LED_SEND_RED;
        end
      LED_SEND_RED:
        begin
        spi_start <= 1;
        led_state <= LED_WAIT_SPI_BUSY_SEND_RED;
        end
      LED_WAIT_SPI_BUSY_SEND_RED:
        begin
        if (spi_busy == 1)
          begin
          spi_start <= 0;
          led_state <= LED_WAIT_END;
          end
        else
          begin
          led_state <= LED_WAIT_SPI_BUSY_SEND_RED;
          end
        end
      LED_WAIT_END:
        begin
        if (~spi_busy)
          begin
          doled_busy <= 0;
          led_state <= LED_IDLE;
          end
        else
          begin
          led_state <= LED_WAIT_END;
          end
        end
      default:
        begin
        led_state <= LED_IDLE;
        doled_busy <= 0;
        end
      endcase
    end
  end

endmodule
