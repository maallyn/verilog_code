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

wire[7:0] mysine[89:0];

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

assign mysine[0] = 50;
assign mysine[1] = 56;
assign mysine[2] = 62;
assign mysine[3] = 68;
assign mysine[4] = 75;
assign mysine[5] = 80;
assign mysine[6] = 85;
assign mysine[7] = 89;
assign mysine[8] = 93;
assign mysine[9] = 96;
assign mysine[10] = 98;
assign mysine[11] = 99;
assign mysine[12] = 99;
assign mysine[13] = 99;
assign mysine[14] = 97;
assign mysine[15] = 95;
assign mysine[16] = 92;
assign mysine[17] = 88;
assign mysine[18] = 84;
assign mysine[19] = 78;
assign mysine[20] = 72;
assign mysine[21] = 67;
assign mysine[22] = 60;
assign mysine[23] = 53;
assign mysine[24] = 47;
assign mysine[25] = 40;
assign mysine[26] = 33;
assign mysine[27] = 28;
assign mysine[28] = 22;
assign mysine[29] = 16;
assign mysine[30] = 12;
assign mysine[31] = 8;
assign mysine[32] = 4;
assign mysine[33] = 2;
assign mysine[34] = 0;
assign mysine[35] = 0;
assign mysine[36] = 0;
assign mysine[37] = 1;
assign mysine[38] = 3;
assign mysine[39] = 5;
assign mysine[40] = 9;
assign mysine[41] = 14;
assign mysine[42] = 18;
assign mysine[43] = 24;
assign mysine[44] = 30;
assign mysine[45] = 36;
assign mysine[46] = 43;

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
    string_output_state <= OUTPUT_IDLE;
    string_iteration_count <= 0;
    string_count <= 0;
    string_size <= 47/2;
    end
endmodule
