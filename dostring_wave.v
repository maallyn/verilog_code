
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

// Start point for ascend in sine wave and descend in sine wave
localparam
  SINE_ASCEND_START_INDEX = 30,
  SINE_DESCEND_START_INDEX = 0;

// Each string needs special data at the beginning and the end, otherwise
// data is tri-color data for each led in the string
localparam
  STRING_START = 0,
  STRING_INSIDE = 1,
  STRING_END = 2;

// Overall state of string operation. We have to wait for the SPI data processing
// out to the wand itself. This is slower than the main clock of 100 mhz. 
// All operations are governed by this state table. This is the 'outer' state table
// and all others are nested inside this one.
localparam
  STR_WAIT_FOR_LED = 0,
  STR_LOAD_COLORS = 1,
  STR_SEND_COLORS = 2,
  STR_CHECK_COUNTERS = 3,
  STR_CLEAR_START = 4,
  STR_INCREMENT_WAND_COUNTERS = 5,
  STR_SET_MIDPOINT_AND_COLORS = 6;

// This is the state of each color in the sine wave. It can ascend via sine,
// descend via sine, or stay at zero. For example, at the violet end of the 
// rainbow, green is staying flat, blue is ascending, and red is descending;
// blue in rainbow is red staying flat, blue at peak and staring to descend
// and green is starting to ascend from staying flat at zero,
// then we start to move into cyan with blue descending, red staying flat at zero,
// and green ascending;
// and so on throughout the rainbow until we get to red (red at full; green starts
// flatline at zero, and blue starts to ascend while red starts to descend, which
// means we are starting the rainbow at violet once again
localparam
  COLOR_ON_ZERO = 0,
  COLOR_ASCEND_SINE = 1,
  COLOR_DESCEND_SINE = 2;

// Where are we in the current stage (each stage is 30 steps)
reg[7:0] color_stage_count;

// Begin and end are special data; inside is normal tri color data
reg[1:0] string_state;

// LED SPI data rate is low, we need to wait, then load data, then start send
reg[2:0] led_send_state;

// Following three are for the sine wave color state for each respective
// primary color for color above sine wave
reg[1:0] blue_top_sine_state;
reg[1:0] green_top_sine_state;
reg[1:0] red_top_sine_state; 

// This is for the led output module. There are three data types:
// First of string is a special start string data set,
// Then each LED is a tri-color data set, then
// End of string is a special data set.
localparam
  INPUT_TYPE_START = 0,
  INPUT_TYPE_LED = 1,
  INPUT_TYPE_END = 2;

// Total length of color sine wave
localparam TOTAL_CYCLE_SIZE = 60,

// Size of each of the color states (descend, flat, and ascend)
// This is TOTAL_CYCLE_SIZE / 2, which in this case is 30
COLOR_STATE_SIZE = 30;


localparam STRING_SIZE = 47;
localparam NUMBER_STRINGS = 47;
localparam WAND_SINE_SIZE = 40; // Length of sine wave in iterations
localparam WAND_SINE_BASE = 3; // Distance from bottome of sine wave to handle

localparam MAX_COLOR_VALUE = 200;

wire[7:0] color_sin[TOTAL_CYCLE_SIZE-1:0];

// What String are we on
reg[7:0] string_iteration_count = 0;

// Where in the string are we? This will repeat for each scan of the
// wand. Zero is at the joint between the wand and the handle.
// This is important because we need to send special data at the
// start of the wand and at the end of the wand, while sending normal
// led data for inside the wand
// This value is also checked to determine whether we are above, on, or
// below the sine wave on the wand
reg[7:0] create_string_count = 0;

// These three out values are the color elements that are fed to the
// wand's SPI output driver module
reg[7:0] blue_out = 0;
reg[7:0] green_out = 0;
reg[7:0] red_out = 0;

// This register is connected to the wand's SPI driver module. It tells
// the SPI driver to start sending the values to the wand.
reg led_start = 0;

// This tells the wand SPI driver what type of data, start, end, or LED
reg[1:0] input_type = INPUT_TYPE_START;

// This comes from the wand SPI driver. It indicates that the SPI driver
// is busy and that no data going to it should be changed, especially the
// red, blue, or green out registers.
wire doled_busy;

assign led1 = mosi;
assign led2 = sck;

// This is the color sine wave lookup table
// Range is from 0 to full led level of 200
// This is not used for position on the wand

assign color_sin[0] = 200;
assign color_sin[1] = 199;
assign color_sin[2] = 197;
assign color_sin[3] = 195;
assign color_sin[4] = 191;
assign color_sin[5] = 186;
assign color_sin[6] = 180;
assign color_sin[7] = 174;
assign color_sin[8] = 166;
assign color_sin[9] = 158;
assign color_sin[10] = 150;
assign color_sin[11] = 140;
assign color_sin[12] = 130;
assign color_sin[13] = 120;
assign color_sin[14] = 110;
assign color_sin[15] = 100;
assign color_sin[16] = 89;
assign color_sin[17] = 79;
assign color_sin[18] = 69;
assign color_sin[19] = 59;
assign color_sin[20] = 49;
assign color_sin[21] = 41;
assign color_sin[22] = 33;
assign color_sin[23] = 25;
assign color_sin[24] = 19;
assign color_sin[25] = 13;
assign color_sin[26] = 8;
assign color_sin[27] = 4;
assign color_sin[28] = 2;
assign color_sin[29] = 0;
assign color_sin[30] = 0;
assign color_sin[31] = 0;
assign color_sin[32] = 2;
assign color_sin[33] = 4;
assign color_sin[34] = 8;
assign color_sin[35] = 13;
assign color_sin[36] = 19;
assign color_sin[37] = 25;
assign color_sin[38] = 33;
assign color_sin[39] = 41;
assign color_sin[40] = 49;
assign color_sin[41] = 59;
assign color_sin[42] = 69;
assign color_sin[43] = 79;
assign color_sin[44] = 89;
assign color_sin[45] = 100;
assign color_sin[46] = 110;
assign color_sin[47] = 120;
assign color_sin[48] = 130;
assign color_sin[49] = 140;
assign color_sin[50] = 150;
assign color_sin[51] = 158;
assign color_sin[52] = 166;
assign color_sin[53] = 174;
assign color_sin[54] = 180;
assign color_sin[55] = 186;
assign color_sin[56] = 191;
assign color_sin[57] = 195;
assign color_sin[58] = 197;
assign color_sin[59] = 199;

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

always @ (posedge dostring_clk or posedge dostring_reset)
  begin
  if (dostring_reset)
    begin
    input_type <= INPUT_TYPE_START;
    blue_out <= 0;
    red_out <= 0;
    green_out <= 0;
    led_start <= 0;
    color_stage_count <= 0;
    string_state <= STRING_START;
    led_send_state <= STR_WAIT_FOR_LED;
    blue_top_sine_state <= COLOR_DESCEND_SINE;
    red_top_sine_state <= COLOR_ON_ZERO;
    green_top_sine_state <= COLOR_ASCEND_SINE;
    create_string_count <= 0;
    end
  else
    begin
    // Outermost state machine; one that handles the SPI to the wand.
    // All others must nest on this as this one is driven by the SPI
    // signaling which is slower than the main system clock.
    case (led_send_state)
      STR_WAIT_FOR_LED:
        // We cannot do much but sit and wait for the SPI to the wand 
        begin
        if (~doled_busy)
          begin
          led_send_state <= STR_LOAD_COLORS;
          end
        end

      STR_LOAD_COLORS:
        begin
        // SPI is done with previous LED. We are now free to load the color values 
        // This is the 2nd level nesting of state machine. This state machine is driven
        // by whether we are at the start, end, or anywhere in the middle of the string
        // sent to the wand. Beginning and ending data sets are special. Those in between
        // are RGB LED values
        case (string_state)
          // Are we at begin, end, or middle of string?
          STRING_START:
            begin
            input_type <= INPUT_TYPE_START;
            blue_out <= 0;
            green_out <= 0;
            red_out <= 0;
            end

          STRING_END:
            begin
            input_type <= INPUT_TYPE_END;
            blue_out <= 8'hff;
            green_out <= 8'hff;
            red_out <= 8'hff; 
            end

          STRING_INSIDE:
            begin
            // This is the workhorse. Individual LED colors are set here
            // The 3rd level nesting of state machine. This is driven by where
            // we are on the wand; ie; how far are we from the beginning of the wand
            // Where the handle is glued to the wand itself.
            // Above the sine wave is between the handle and the white sine wave pattern
            // On the sine wave is on the white sine wave
            // Below the sine wave is between the white sine wave and the free end of
            // the wand.
            // Where we are in the overall color rainbow also determines what we send
            // to the led. The color rainbow position is the same for the entire string;
            // it changes only between strings.
            input_type <= INPUT_TYPE_LED;

            case (blue_top_sine_state)
              COLOR_ON_ZERO:
                begin
                blue_out <= 0;
                end

              COLOR_ASCEND_SINE:
                begin
                blue_out <= color_sin[SINE_ASCEND_START_INDEX + color_stage_count];
                end

              COLOR_DESCEND_SINE:
                begin
                blue_out <= color_sin[SINE_DESCEND_START_INDEX + color_stage_count];
                end

              default:
                begin
                blue_out <= 0;
                end

              endcase // blue_top_sine_state

            case (green_top_sine_state)
              COLOR_ON_ZERO:
                begin
                green_out <= 0;
                end

              COLOR_ASCEND_SINE:
                begin
                green_out <= color_sin[SINE_ASCEND_START_INDEX + color_stage_count];
                end

              COLOR_DESCEND_SINE:
                begin
                green_out <= color_sin[SINE_DESCEND_START_INDEX + color_stage_count];
                end

              default:
                begin
                green_out <= 0;
                end

              endcase // green_top_sine_state

            case (red_top_sine_state)
              COLOR_ON_ZERO:
                begin
                red_out <= 0;
                end

              COLOR_ASCEND_SINE:
                begin
                red_out <= color_sin[SINE_ASCEND_START_INDEX + color_stage_count];
                end

              COLOR_DESCEND_SINE:
                begin
                red_out <= color_sin[SINE_DESCEND_START_INDEX + color_stage_count];
                end

              default:
                begin
                red_out <= 0;
                end

              endcase // red_top_sine_state

            end

          default:
            begin
            input_type <= INPUT_TYPE_END;
            blue_out <= 8'hff;
            green_out <= 8'hff;
            red_out <= 8'hff;
            end
          
          endcase // string_state

        led_send_state <= STR_SEND_COLORS;
        end // Done with loading the colors to the SPI

      STR_SEND_COLORS:
        begin
        led_start <= 1; // Tell SPI to do it's thing
        // While we are at it, we can increment the create_string_count.
        // We do not increment the color_stage_count 
        // because it stays for the entire duration of the string;
        // it is incremented and checked only at the end of the entire string
        if (create_string_count < STRING_SIZE)
          begin
          create_string_count <= create_string_count + 1;
          end
        else
          begin
          create_string_count <= 0;
          end

        // We will do checking and state machine adjustment at the next
        // clock cycle
        led_send_state <= STR_CHECK_COUNTERS;
        end

      STR_CHECK_COUNTERS:
        begin
        // First check the state of the string (begin, inside for LED, end)
        if (create_string_count == 0)
          begin
          string_state <= STRING_START;
          end
        else if (create_string_count < STRING_SIZE)
          begin
          string_state <= STRING_INSIDE;
          end
        else
          begin
          string_state <= STRING_END;
          end
          
        led_send_state <= STR_CLEAR_START;
        end

      STR_CLEAR_START:
        // Now that we are two clock from starting the SPI, let's clear the
        // led_start signal so that it won't repeat this LED when it is done
        // with it
        begin
        led_start <= 0;
        if (string_state == STRING_END)
          // At end of string, rotate colors, and set the new middle point,
          // otherwise wait for SPI to finish and then output the next LED
          begin
          led_send_state <= STR_INCREMENT_WAND_COUNTERS;
          end
        else
          begin
          led_send_state <= STR_WAIT_FOR_LED;
          end
        end

      STR_INCREMENT_WAND_COUNTERS:
        begin
        color_stage_count <= color_stage_count + 1;
        led_send_state <= STR_SET_MIDPOINT_AND_COLORS;
        end

      STR_SET_MIDPOINT_AND_COLORS:
        begin
        // Now the challenging part, update color sequence states if at
        // the end of a color segment
        if (color_stage_count >= COLOR_STATE_SIZE)
          begin
          // first, clear the counter
          color_stage_count <= 0;

          // do top states first

          // blue
          if (blue_top_sine_state == COLOR_ON_ZERO)
            begin
            blue_top_sine_state <= COLOR_ASCEND_SINE;
            end
          else if (blue_top_sine_state == COLOR_ASCEND_SINE)
            begin
            blue_top_sine_state <= COLOR_DESCEND_SINE;
            end
          else
            begin
            blue_top_sine_state <= COLOR_ON_ZERO;
            end
          
          // green
          if (green_top_sine_state == COLOR_ON_ZERO)
            begin
            green_top_sine_state <= COLOR_ASCEND_SINE;
            end
          else if (green_top_sine_state == COLOR_ASCEND_SINE)
            begin
            green_top_sine_state <= COLOR_DESCEND_SINE;
            end
          else
            begin
            green_top_sine_state <= COLOR_ON_ZERO;
            end
          
          // red
          if (red_top_sine_state == COLOR_ON_ZERO)
            begin
            red_top_sine_state <= COLOR_ASCEND_SINE;
            end
          else if (red_top_sine_state == COLOR_ASCEND_SINE)
            begin
            red_top_sine_state <= COLOR_DESCEND_SINE;
            end
          else
            begin
            red_top_sine_state <= COLOR_ON_ZERO;
            end
  
          end
        led_send_state <= STR_WAIT_FOR_LED;
        end  

      endcase // led_send_state
    end
  end
endmodule
