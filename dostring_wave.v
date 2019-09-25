// This is the workhorse for creating the colorful sine waves.
// It uses a crude pipeline of two buffers in attempt to reduce
// waiting times.
// This is also where I think I need the most help. I feel that I could
// have implimended this by using RAM and not registers if I knew how.
// There are three state machines.
// One is to feed the doled module with individual tricolor LEDs
// The second is to move the data from the working data array to the
// current data array (which is the one that is output to the LED strip
// The third state machine is the one that does the creating.
// I anticipate that the third state machine is the one that I would add
// features in the future such as accellerometer synchronization and other
// graphics beyond simple multi color sine waves.

module dostring_wave (
  output wire led1,
  output wire led2,
  output wire mosi,
  output wire sck,
  input wire dostring_reset,
  input wire dostring_clk
);

localparam
  INPUT_TYPE_START = 0,
  INPUT_TYPE_LED = 1,
  INPUT_TYPE_END = 2;

localparam STRING_SIZE = 47;
localparam NUMBER_STRINGS = 47;
localparam MAX_COLOR_VALUE = 100;

localparam CREATE_COLOR_TOP = 0,
  CREATE_COLOR_MIDDLE = 1,
  CREATE_COLOR_BOTTOM = 2;

wire[7:0] mysine[TOTAL_CYCLE_SIZE-1:0];

reg[4:0] string_output_state = STRING_OUTPUT_IDLE;
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
    string_output_state <= OUTPUT_IDLE;
    blue_top_sine_state <= COLOR_DESCEND_SINE;
    red_top_sine_state <= COLOR_ON_ZERO;
    green_top_sine_state <= COLOR_ASCEND_SINE;
    green_bottom_sine_state <= COLOR_DESCEND_SINE;
    blue_bottom_sine_state <= COLOR_ON_ZERO;
    red_bottom_sine_state <= COLOR_ASCEND_SINE;
    string_color_state <= STRING_COLOR_TOP;
    string_iteration_count <= 0;
    string_count <= 0;
    string_size <= 47/2;
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
