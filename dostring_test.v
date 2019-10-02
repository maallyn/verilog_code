
// This is the workhorse for creating the colorful sine waves.
// I am attempting to do everything on the fly, which would
// eliminate the need for multiple buffers.

// Each iteration of the wand will be created on the fly using
// an artistic sine wave approach. Colors will be based on sinasuidal
// rotation of values of the primary colors. Each of red, green, and blue
// will rotate based on ascend, then descend, then flat, then ascend and so on.

// As wand moves by, you would see via persistance of vision a sine wave. Above
// of sine wave would be one set of changing colors; sine wave itself would be
// white. Then below the sine wave would be another set of changing colors.

module dostring_wave (
  output wire led1,
  output wire led2,
  output wire mosi,
  output wire sck,
  input wire dostring_reset,
  input wire dostring_clk
);

localparam
  STR_WAIT_FOR_LED = 0,
  STR_LOAD_COLORS = 1,
  STR_SEND_COLORS = 2,
  STR_CHECK_COUNTERS = 3,
  STR_CLEAR_START = 4,
  STR_INCREMENT_WAND_COUNTERS = 5,
  STR_SET_MIDPOINT_AND_COLORS = 6;

assign led1 = sck;
assign led2 = send_pulse;

reg[2:0] led_send_state;
reg[7:0] led_counter;
reg[8:0] time_counter;

localparam
  INPUT_TYPE_START = 0,
  INPUT_TYPE_LED = 1,
  INPUT_TYPE_END = 2;

// Total length of color sine wave
localparam TOTAL_CYCLE_SIZE = 3,

COLOR_CYCLE_SIZE = 30;

reg[7:0] blue_out = 0;
reg[7:0] green_out = 0;
reg[7:0] red_out = 0;
reg[1:0] input_type = 0;
reg[1:0] string_out_state = 0;
reg send_pulse = 0;

// This register is connected to the wand's SPI driver module. It tells
// the SPI driver to start sending the values to the wand.
reg led_start = 0;

// This comes from the wand SPI driver. It indicates that the SPI driver
// is busy and that no data going to it should be changed, especially the
// red, blue, or green out registers.
wire doled_busy;

// Instantiation of the doled module

doled doled_1 (
.blue_input(blue_out),
.green_input(green_out),
.red_input(red_out),
.type_input(input_type),
.doled_busy(doled_busy),
.doled_start(led_start),
.mosi(mosi),
.sck(sck),
.doled_reset(dostring_reset),
.doled_clk(dostring_clk)
);

always @ (posedge dostring_clk)
  begin
  if (dostring_reset)
    begin
    time_counter <= 0;
    led_send_state <= 0;
    blue_out <= 0;
    green_out <= 0;
    red_out <= 0;
    input_type <= 0;
    led_start <= 0;
    string_out_state <= 0;
    led_counter <= 0;
    send_pulse <= 0;
    end
  else
    begin
    case (led_send_state)
      0:
        begin
        send_pulse <= 0;
        if (~doled_busy)
          begin
          led_send_state <= 1;
          end
        end
      1:
        begin
        time_counter <= 1;
        case (string_out_state)
          0:
            begin
            input_type <= 0;
            string_out_state <= 1;
            led_counter <= 0;
            end
          1:
            begin
            input_type <= 1;
            if (blue_out >= 200)
              begin
              blue_out <= 10;
              end
            else
              begin
              blue_out <= blue_out + 5 + led_counter;
              end

            if (green_out >= 200)
              begin
              green_out <= 40;
              end
            else
              begin
              green_out <= green_out + 2 + led_counter;
              end

            if (red_out >= 200)
              begin
              red_out <= 00;
              end
            else
              begin
              red_out <= red_out + 10 + led_counter;
              end

            if (led_counter < 5)
              begin
              led_counter <= led_counter + 1;
              string_out_state <= 1;
              end
            else
              begin
              led_counter <= 0;
              string_out_state <= 2;
              end
            end
          2:
            begin
            input_type <= 2;
            string_out_state <= 0;
            end
          default:
            begin
            input_type <= 0;
            end
          endcase // string_out_state

        led_send_state <= 2;
        end
      2:
        if (time_counter < 200)
          begin
          time_counter <= time_counter + 1;
          led_send_state <= 2;
          end
        else
          begin
          time_counter <= 0;
          send_pulse <= 1;
          led_start <= 1;
          led_send_state <= 3;
        end
      3:
        begin
        led_send_state <= 4;
        end
      4:
        begin
        led_start <= 0;
        led_send_state <= 0;
        end
      endcase
    end
  end
endmodule
