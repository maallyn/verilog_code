
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
  STR_SET_THE_SEGMENT_TO_START_SEGMENT = 6;

// Which color segment are we on?
// Goes from 0 for purple to COLOR_SEGMENT_NUMBER for red
reg[7:0] color_segment_count;

// Where in color segment are we?
// Goes from 0 to COLOR_SEGMENT_SIZE
reg[7:0] color_segment_position;

// Where in the segment shall we start this string
reg[7:0] start_in_segment;

// Which segment to start in
reg[7:0] which_segment_to_start;

// Begin and end are special data; inside is normal tri color data
reg[1:0] string_state;

// LED SPI data rate is low, we need to wait, then load data, then start send
reg[2:0] led_send_state;

// This is for the led output module. There are three data types:
// First of string is a special start string data set,
// Then each LED is a tri-color data set, then
// End of string is a special data set.
localparam
  INPUT_TYPE_START = 0,
  INPUT_TYPE_LED = 1,
  INPUT_TYPE_END = 2;

localparam STRING_SIZE = 47;

localparam
  COLOR_FULL_BRITE = 8'hf0,
  COLOR_QUARTER_BRITE = 8'h40,
  COLOR_HALF_BRITE = 8'h80,
  COLOR_MIN_BRITE = 9'h02,
  COLOR_THREE_QUARTER_BRITE = 8'hc0,
  COLOR_SEGMENT_SIZE = 10,
  COLOR_SEGMENT_NUMBER = 7;

localparam MAX_COLOR_VALUE = 200;

wire[7:0] blue_seg[COLOR_SEGMENT_NUMBER-1:0];
wire[7:0] green_seg[COLOR_SEGMENT_NUMBER-1:0];
wire[7:0] red_seg[COLOR_SEGMENT_NUMBER-1:0];

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

// Rainbow color values for color arrays
// purple
assign blue_seg[0] = COLOR_HALF_BRITE;
assign green_seg[0] = COLOR_MIN_BRITE;
assign red_seg[0] = COLOR_HALF_BRITE;

// blue
assign blue_seg[0] = COLOR_FULL_BRITE;
assign green_seg[0] = COLOR_MIN_BRITE;
assign red_seg[0] = COLOR_MIN_BRITE;

// cyan
assign blue_seg[0] = COLOR_HALF_BRITE;
assign green_seg[0] = COLOR_HALF_BRITE;
assign red_seg[0] = COLOR_MIN_BRITE;

// green
assign blue_seg[0] = COLOR_MIN_BRITE;
assign green_seg[0] = COLOR_FULL_BRITE;
assign red_seg[0] = COLOR_MIN_BRITE;

// yellow
assign blue_seg[0] = COLOR_MIN_BRITE;
assign green_seg[0] = COLOR_HALF_BRITE;
assign red_seg[0] = COLOR_FULL_BRITE;

// orange
assign blue_seg[0] = COLOR_MIN_BRITE;
assign green_seg[0] = COLOR_QUARTER_BRITE;
assign red_seg[0] = COLOR_THREE_QUARTER_BRITE;

// red
assign blue_seg[0] = COLOR_MIN_BRITE;
assign green_seg[0] = COLOR_MIN_BRITE;
assign red_seg[0] = COLOR_FULL_BRITE;

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
    string_state <= STRING_START;
    led_send_state <= STR_WAIT_FOR_LED;
    color_segment_count <= 0;
    color_segment_position <= 0;
    start_in_segment <= 0;
    which_segment_to_start <= 0;
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
            // Where we are in a segment and which segment we are in determine the
            // color values
 
            // set the color values
            blue_out <= blue_seg[color_segment_count];
            green_out <= green_seg[color_segment_count];
            red_out <= red_seg[color_segment_count];

            // Bump up color_segment_position
            color_segment_position <= color_segment_position + 1;

            // This is the input type
            input_type <= INPUT_TYPE_LED;
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
          // and while we are still inside the string, check the segment position
          // and bump up segment if we are at the end of the segment
          if (color_segment_position >= COLOR_SEGMENT_SIZE)
            begin
            // Are we at the last segment? If so, go back to the start of the rainbow
            if (color_segment_count >= COLOR_SEGMENT_NUMBER)
              begin
              color_segment_count <= 0;
              end
            else
              begin
              color_segment_count <= color_segment_count + 1;
              end
            color_segment_position <= 0;
            end
          else
            begin
            color_segment_position <= color_segment_position + 1;
            end
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
          // At end of string, set the next string start segment and position
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
        // Now determine the new segment start position and which segment
        if (start_in_segment >= COLOR_SEGMENT_SIZE)
          begin
          // Switch segment to start in
          if (which_segment_to_start >= COLOR_SEGMENT_NUMBER)
            begin
            // Go back to beginning of rainbow
            which_segment_to_start <= 0;
            end
          else
            begin
            which_segment_to_start <= which_segment_to_start + 1;
            end
          start_in_segment <= 0;
          end
        else
          begin
          start_in_segment <= start_in_segment + 1;
          end
        led_send_state <= STR_SET_THE_SEGMENT_TO_START_SEGMENT;
        end

      STR_SET_THE_SEGMENT_TO_START_SEGMENT:
        begin
        color_segment_position <= start_in_segment;
        color_segment_count <= which_segment_to_start;
        led_send_state <= STR_WAIT_FOR_LED;
        end  

      endcase // led_send_state
    end
  end
endmodule
