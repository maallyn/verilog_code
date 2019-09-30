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


// Start of insert of stub file
// End of insert of stub file


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

// How far is the lowest part of sine wave from beginning of wand
SINE_WAVE_BASE = 10,

// Size of each of the color states (descend, flat, and ascend)
// This is TOTAL_CYCLE_SIZE / 2, which in this case is 30
COLOR_STATE_SIZE = 30;


localparam STRING_SIZE = 47;
localparam NUMBER_STRINGS = 47;
localparam WAND_SINE_SIZE = 40;
localparam WAND_SINE_BASE = 3;

localparam MAX_COLOR_VALUE = 200;

localparam CREATE_COLOR_TOP = 0,
  CREATE_COLOR_MIDDLE = 1,
  CREATE_COLOR_BOTTOM = 2;

wire[7:0] color_sin[TOTAL_CYCLE_SIZE-1:0];
wire[7:0] wand_position_sin[WAND_SINE_SIZE-1:0];


reg[7:0] string_iteration_count = 0;
reg[7:0] create_string_count = 0;
reg[7:0] wand_sine_count = 0;
reg[7:0] blue_out = 0;
reg[7:0] green_out = 0;
reg[7:0] red_out = 0;
reg[7:0] blue_working = 0;
reg[7:0] green_working = 0;
reg[7:0] red_working = 0;
reg[7:0] middle_point = 0;

reg[7:0] top_blue;
reg[7:0] top_green;
reg[7:0] top_red;

reg[7:0] middle_blue;
reg[7:0] middle_green;
reg[7:0] middle_red;

reg[7:0] bottom_blue;
reg[7:0] bottom_green;
reg[7:0] bottom_red;

reg led_start = 0;
reg one_cycle = 0;
reg[1:0] input_type = INPUT_TYPE_START;
wire doled_busy;

assign led1 = mosi;
assign led2 = dostring_clk;

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

// Following is the wand position lookup table for placement
// of the white sine wave on the wand for each iteration

assign wand_position_sin[0] = 20;
assign wand_position_sin[1] = 23;
assign wand_position_sin[2] = 26;
assign wand_position_sin[3] = 29;
assign wand_position_sin[4] = 31;
assign wand_position_sin[5] = 34;
assign wand_position_sin[6] = 36;
assign wand_position_sin[7] = 37;
assign wand_position_sin[8] = 39;
assign wand_position_sin[9] = 39;
assign wand_position_sin[10] = 40;
assign wand_position_sin[11] = 39;
assign wand_position_sin[12] = 39;
assign wand_position_sin[13] = 37;
assign wand_position_sin[14] = 36;
assign wand_position_sin[15] = 34;
assign wand_position_sin[16] = 31;
assign wand_position_sin[17] = 29;
assign wand_position_sin[18] = 26;
assign wand_position_sin[19] = 23;
assign wand_position_sin[20] = 20;
assign wand_position_sin[21] = 16;
assign wand_position_sin[22] = 13;
assign wand_position_sin[23] = 10;
assign wand_position_sin[24] = 8;
assign wand_position_sin[25] = 5;
assign wand_position_sin[26] = 3;
assign wand_position_sin[27] = 2;
assign wand_position_sin[28] = 0;
assign wand_position_sin[29] = 0;
assign wand_position_sin[30] = 0;
assign wand_position_sin[31] = 0;
assign wand_position_sin[32] = 0;
assign wand_position_sin[33] = 2;
assign wand_position_sin[34] = 3;
assign wand_position_sin[35] = 5;
assign wand_position_sin[36] = 8;
assign wand_position_sin[37] = 10;
assign wand_position_sin[38] = 13;
assign wand_position_sin[39] = 16;

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
    color_stage_count <= 0;
    string_state <= STRING_START;
    led_send_state <= STR_WAIT_FOR_LED;
    blue_top_sine_state <= COLOR_DESCEND_SINE;
    red_top_sine_state <= COLOR_ON_ZERO;
    green_top_sine_state <= COLOR_ASCEND_SINE;
    green_bottom_sine_state <= COLOR_DESCEND_SINE;
    blue_bottom_sine_state <= COLOR_ON_ZERO;
    red_bottom_sine_state <= COLOR_ASCEND_SINE;
    string_color_state <= STRING_COLOR_TOP;
    string_iteration_count <= 0;
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
            case (string_color_state)
              // Fourth level nesting state is color sine wave states to determine
              // individual red/green/blue intensity values for this particular LED
              STRING_COLOR_TOP: // Between handle and white sine wave
                begin
                case (blue_top_sine_state)
                  // Fifth level nesting state is each individual color sine value
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
                  endcase
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
                    red_out <= 0;
                    end
                  endcase
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
                  endcase
                end
              STRING_COLOR_BOTTOM:
                begin
                case (blue_bottom_sine_state)
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
                  endcase
                case (green_bottom_sine_state)
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
                    red_out <= 0;
                    end
                  endcase
                case (red_bottom_sine_state)
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
                  endcase
                end
              STRING_COLOR_MIDDLE:
                // On the sine wave, all is white
                begin
                red_out <= 150;
                blue_out <= 150;
                green_out <= 150;
                end
              default:
                begin
                red_out <= 0;
                blue_out <= 0;
                green_out <= 0;
                end
              endcase
            end    
          default:
            begin
            input_type <= INPUT_TYPE_END;
            blue_out <= 8'hff;
            green_out <= 8'hff;
            red_out <= 8'hff;
            end
          endcase
        end 
            
      endcase
    end
  end
endmodule
