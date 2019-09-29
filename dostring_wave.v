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

// How much to devide the sine value to place location of sine wave on wand
// This is done by shift right; devide by 2 is shift right of 1
SINE_WAVE_DIVISION = 1,

// Size of each of the color states (descend, flat, and ascend)
// This is TOTAL_CYCLE_SIZE / 3, which in this case is 20
COLOR_STATE_SIZE = 20;

localparam STRING_SIZE = 47;
localparam NUMBER_STRINGS = 47;
localparam MAX_COLOR_VALUE = 100;

localparam CREATE_COLOR_TOP = 0,
  CREATE_COLOR_MIDDLE = 1,
  CREATE_COLOR_BOTTOM = 2;

wire[7:0] mysine[TOTAL_CYCLE_SIZE-1:0];

reg[7:0] string_iteration_count = 0;
reg[7:0] create_string_count = 0;
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

// This is the sine wave lookup table

assign sin[0] = 100;
assign sin[1] = 99;
assign sin[2] = 98;
assign sin[3] = 97;
assign sin[4] = 95;
assign sin[5] = 93;
assign sin[6] = 90;
assign sin[7] = 87;
assign sin[8] = 83;
assign sin[9] = 79;
assign sin[10] = 75;
assign sin[11] = 70;
assign sin[12] = 65;
assign sin[13] = 60;
assign sin[14] = 55;
assign sin[15] = 50;
assign sin[16] = 44;
assign sin[17] = 39;
assign sin[18] = 34;
assign sin[19] = 29;
assign sin[20] = 24;
assign sin[21] = 20;
assign sin[22] = 16;
assign sin[23] = 12;
assign sin[24] = 9;
assign sin[25] = 6;
assign sin[26] = 4;
assign sin[27] = 2;
assign sin[28] = 1;
assign sin[29] = 0;
assign sin[30] = 0;
assign sin[31] = 0;
assign sin[32] = 1;
assign sin[33] = 2;
assign sin[34] = 4;
assign sin[35] = 6;
assign sin[36] = 9;
assign sin[37] = 12;
assign sin[38] = 16;
assign sin[39] = 20;
assign sin[40] = 24;
assign sin[41] = 29;
assign sin[42] = 34;
assign sin[43] = 39;
assign sin[44] = 44;
assign sin[45] = 50;
assign sin[46] = 55;
assign sin[47] = 60;
assign sin[48] = 65;
assign sin[49] = 70;
assign sin[50] = 75;
assign sin[51] = 79;
assign sin[52] = 83;
assign sin[53] = 87;
assign sin[54] = 90;
assign sin[55] = 93;
assign sin[56] = 95;
assign sin[57] = 97;
assign sin[58] = 98;
assign sin[59] = 99;

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
    string_count <= 0;
    string_size <= 47;
    end
  else
    begin
    case (led_send_state)
      STR_WAIT_FOR_LED:
        begin
        if (~doled_busy)
          begin
          led_send_state <= STR_CHECK_COLOR_STATE;
          end
        end
endmodule
