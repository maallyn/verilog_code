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
  output wire led0,
  output wire led1,
  output wire led2,
  output wire mosi,
  output wire sck,
  input wire dostring_clk
);

localparam
  INPUT_TYPE_START = 0,
  INPUT_TYPE_LED = 1,
  INPUT_TYPE_END = 2;

localparam STRING_SIZE = 47;
localparam NUMBER_STRINGS = 47;
localparam MAX_COLOR_VALUE = 100;

localparam STRING_WAIT_FOR_CURRENT_STRING = 0,
  STRING_WAIT_START = 1,
  STRING_LOAD_START = 2,
  STRING_SEND_START = 3,
  STRING_WAIT_START_BUSY = 4, 
  STRING_WAIT_LED_PIXEL = 5,
  STRING_LOAD_LED_PIXEL = 6,
  STRING_SEND_LED_PIXEL = 7,
  STRING_WAIT_LED_PIXEL_BUSY = 8, 
  STRING_INCREMENT_PIXEL_COUNT_AND_CHECK = 9,
  STRING_WAIT_FINISH = 10,
  STRING_LOAD_FINISH = 11,
  STRING_SEND_FINISH = 12,
  STRING_WAIT_FINISH_BUSY = 13,
  STRING_WAIT_FOR_DONE = 14;

localparam CREATE_STRING_START = 0,
  CREATE_STRING_WAIT_FOR_STRING_READY_FOR_WRITE = 1,
  CREATE_STRING_DELAY_WAIT = 2,
  CREATE_STRING_PRE_LOAD = 3,
  CREATE_STRING_LOAD = 4,
  CREATE_STRING_LOAD_ITERATION = 5,
  CREATE_STRING_SEND = 6,
  CREATE_STRING_WAIT_BUSY = 7,
  CREATE_STRING_ADVANCE_COLOR = 8;

localparam CREATE_COLOR_TOP = 0,
  CREATE_COLOR_MIDDLE = 1,
  CREATE_COLOR_BOTTOM = 2;

localparam INCREMENT_TOP_BLUE = 3,
  INCREMENT_TOP_GREEN = 2,
  INCREMENT_TOP_RED = 1,
  INCREMENT_MIDDLE_GREEN = 1,
  INCREMENT_MIDDLE_BLUE = 2,
  INCREMENT_MIDDLE_RED = 3,
  INCREMENT_BOTTOM_GREEN = 2,
  INCREMENT_BOTTOM_BLUE = 1,
  INCREMENT_BOTTOM_RED = 2,
  START_TOP_GREEN = 0,
  START_TOP_BLUE = 10,
  START_TOP_RED = 20,
  START_MIDDLE_GREEN = 30,
  START_MIDDLE_BLUE = 50,
  START_MIDDLE_RED = 70,
  START_BOTTOM_GREEN =40,
  START_BOTTOM_BLUE = 30,
  START_BOTTOM_RED = 0;

localparam MOVE_STRING_START = 0,
  MOVE_STRING_SET_RESPONSE_TO_READIES = 1,
  MOVE_STRING_LOAD = 2,
  MOVE_STRING_LOAD_ITERATION = 3,
  MOVE_CURRENT_STRING_SEND = 4,
  MOVE_STRING_WAIT_CURRENT_STRING_BUSY = 5,
  MOVE_STRING_WAIT_WORKING_STRING_BUSY = 6;
  
localparam STRING_COLOR_DELAY = 5;

wire[7:0] mysine[89:0];

reg[7:0] count_devide_three = 0;
reg[7:0] string_iteration_count = 0;
reg[7:0] create_string_count = 0;
reg[7:0] blue_out = 0;
reg[7:0] green_out = 0;
reg[7:0] red_out = 0;
reg[7:0] current_string[STRING_SIZE * 3:0];
reg[7:0] working_string[STRING_SIZE * 3:0];
reg[7:0] blue_working = 0;
reg[7:0] green_working = 0;
reg[7:0] red_working = 0;
reg[7:0] middle_point = 0;

reg[7:0] top_blue = START_TOP_BLUE;
reg[7:0] top_green = START_TOP_GREEN;
reg[7:0] top_red = START_TOP_RED;

reg[7:0] middle_blue = START_MIDDLE_BLUE;
reg[7:0] middle_green = START_MIDDLE_GREEN;
reg[7:0] middle_red = START_MIDDLE_RED;

reg[7:0] bottom_blue = START_BOTTOM_BLUE;
reg[7:0] bottom_green = START_BOTTOM_GREEN;
reg[7:0] bottom_red = START_BOTTOM_RED;

reg current_string_ready = 0;
reg current_string_available_for_write = 1;
reg working_string_ready = 0;
reg working_string_available_for_write = 1;


reg led_start = 0;
reg one_cycle = 0;
reg[1:0] input_type = INPUT_TYPE_START;
wire doled_busy;
reg[3:0] string_send_state = STRING_WAIT_FOR_CURRENT_STRING;
reg[3:0] string_create_state = CREATE_STRING_START;
reg[3:0] string_move_state = MOVE_STRING_START;
reg[7:0] string_out_count = 0;
reg[7:0] string_process_count = 0;
reg[7:0] string_move_count = 0;
reg[16:0] clk_count = 0;
reg[3:0] string_color_state = 0;
reg[31:0] string_color_wait = 0;
reg go_ahead_move_from_working = 0;
reg go_ahead_move_to_current = 0;
wire go_ahead_with_move;

assign led0 = one_cycle;
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

assign go_ahead_with_move = go_ahead_move_from_working && go_ahead_move_to_current;

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
.doled_clk(dostring_clk)
);

// This is the state machine to take the current string and send it
// to the doled module which sends the values to the strip via the spi module

always @ (posedge dostring_clk)
  begin
  case (string_send_state)
    STRING_WAIT_FOR_CURRENT_STRING:
      begin
      if (current_string_ready == 1)
        begin
        current_string_available_for_write <= 0;
        string_send_state <= STRING_WAIT_START;
        string_out_count <= 0;
        end
      else
        begin
        current_string_available_for_write <= 1;
        string_send_state <= STRING_WAIT_FOR_CURRENT_STRING;
        end
      end
    STRING_WAIT_START:
      begin
      if (doled_busy == 0)
        begin
        string_send_state <= STRING_LOAD_START;
        end
      else
        begin
        string_send_state <= STRING_WAIT_START;
        end
      end
    STRING_LOAD_START:
      begin
      input_type <= INPUT_TYPE_START;
      string_send_state <= STRING_SEND_START;
      end
    STRING_SEND_START:
      begin
      led_start <= 1;
      string_send_state <= STRING_WAIT_START_BUSY;
      end
    STRING_WAIT_START_BUSY:
      begin
      if (doled_busy == 1)
        begin
        led_start <= 0;
        string_send_state <= STRING_WAIT_LED_PIXEL;
        end
      else
        begin
        string_send_state <= STRING_WAIT_START_BUSY;
        end
      end
    STRING_WAIT_LED_PIXEL: 
      begin
      if (doled_busy == 0)
        begin
        string_send_state <= STRING_LOAD_LED_PIXEL;
        end
      else
        begin
        string_send_state <= STRING_WAIT_LED_PIXEL;
        end
      end
    STRING_LOAD_LED_PIXEL:
      begin
      input_type <= INPUT_TYPE_LED;
      blue_out <= current_string[string_out_count];
      green_out <= current_string[string_out_count + 1];
      red_out <= current_string[string_out_count + 2];
      string_send_state <= STRING_SEND_LED_PIXEL;
      end
    STRING_SEND_LED_PIXEL:
      begin
      led_start <= 1;
      string_send_state <= STRING_WAIT_LED_PIXEL_BUSY;
      end
    STRING_WAIT_LED_PIXEL_BUSY:
      begin
      if (doled_busy == 1)
        begin
        led_start <= 0;
        string_send_state <= STRING_INCREMENT_PIXEL_COUNT_AND_CHECK;
        end
      else
        begin
        string_send_state <= STRING_WAIT_LED_PIXEL_BUSY;
        end
      end
    STRING_INCREMENT_PIXEL_COUNT_AND_CHECK:
      begin
      if (string_out_count < (STRING_SIZE - 1) * 3)
        begin
        string_out_count <= string_out_count + 3;
        string_send_state <= STRING_WAIT_LED_PIXEL;
        end
      else
        begin
        string_send_state <= STRING_WAIT_FINISH;
        string_out_count <= 0;
        end
      end
    STRING_WAIT_FINISH:
      begin
      if (doled_busy == 0)
        begin
        string_send_state <= STRING_LOAD_FINISH;
        end
      else
        begin
        string_send_state <= STRING_WAIT_FINISH;
        end
      end
    STRING_LOAD_FINISH:
      begin
      input_type <= INPUT_TYPE_END;
      string_send_state <= STRING_SEND_FINISH;
      end
    STRING_SEND_FINISH:
      begin
      led_start <= 1;
      string_send_state <= STRING_WAIT_FINISH_BUSY;
      end
    STRING_WAIT_FINISH_BUSY:
      begin
      if (doled_busy == 1)
        begin
        led_start <= 0;
        string_send_state <= STRING_WAIT_FOR_DONE;
        end
      else
        begin
        string_send_state <= STRING_WAIT_FINISH_BUSY;
        end
      end
    STRING_WAIT_FOR_DONE:
      begin
      if (doled_busy == 0)
        begin
        current_string_available_for_write <= 1;
        string_send_state <= STRING_WAIT_FOR_CURRENT_STRING;
        end
      else
        begin
        current_string_available_for_write <= 0;
        string_send_state <= STRING_WAIT_FOR_DONE;
        end
      end
    default:
      begin
      string_send_state <= STRING_WAIT_FOR_CURRENT_STRING;
      current_string_available_for_write <= 1;
      led_start <= 0;
      end
    endcase
  end

// this is the state machine that copies the working string to the current string.
// It needs to wait for the current string to be available for writing as well as
// the working string to be available for reading.

always @ (posedge dostring_clk)
  begin
    case(string_move_state)
      MOVE_STRING_START:
        begin
        go_ahead_move_from_working <= 0;
        go_ahead_move_to_current <= 0;
        string_move_state <= MOVE_STRING_SET_RESPONSE_TO_READIES;;
        end
      MOVE_STRING_SET_RESPONSE_TO_READIES:
        begin
        if ((working_string_ready == 1) && (go_ahead_move_from_working == 0))
          begin
          working_string_available_for_write <= 0;
          go_ahead_move_from_working <= 1;
          string_move_count <= 0;
          end
        if ((current_string_available_for_write == 1) && (go_ahead_move_to_current == 0))
          begin
          go_ahead_move_to_current <= 1;
          current_string_ready <= 0;
          end
        if (go_ahead_with_move == 1)
          begin
          string_move_state <= MOVE_STRING_LOAD;
          end
        else
          begin
          string_move_state <= MOVE_STRING_SET_RESPONSE_TO_READIES;
          end
        end
      MOVE_STRING_LOAD:
        begin
        current_string[string_move_count] <= working_string[string_move_count];
        string_move_state <= MOVE_STRING_LOAD_ITERATION;
        end
      MOVE_STRING_LOAD_ITERATION:
        begin
        if (string_move_count < STRING_SIZE * 3)
          begin
          string_move_count <= string_move_count + 1;
          string_move_state <= MOVE_STRING_LOAD;
          end
        else
          begin
          string_move_state <= MOVE_CURRENT_STRING_SEND;
          end
        end
      MOVE_CURRENT_STRING_SEND:
        begin
        current_string_ready <= 1;
        working_string_available_for_write <= 1;
        string_move_state <= MOVE_STRING_WAIT_CURRENT_STRING_BUSY;
        end
      MOVE_STRING_WAIT_CURRENT_STRING_BUSY:
        begin
        if (current_string_available_for_write == 0)
          begin
          string_move_state <= MOVE_STRING_WAIT_WORKING_STRING_BUSY;
          end
        else
          begin
          string_move_state <= MOVE_STRING_WAIT_CURRENT_STRING_BUSY;
          end
        end
      MOVE_STRING_WAIT_WORKING_STRING_BUSY:
        begin
        if (working_string_ready == 0)
          begin
          string_move_state <= MOVE_STRING_START;
          end
        else
          begin
          string_move_state <= MOVE_STRING_WAIT_WORKING_STRING_BUSY;
          end
        end
      default:
        begin
        string_move_state <= MOVE_STRING_START;
        current_string_ready <= 0;
        working_string_available_for_write <= 1;
        end
      endcase
  end

// This is the state machine that creates the multi colored sine waves on the
// working string. This is the one where the art takes place and the one that
// will be made more smart in the future.

always @ (posedge dostring_clk)
  begin
    case(string_create_state)
      CREATE_STRING_START:
        begin
        string_create_state <= CREATE_STRING_WAIT_FOR_STRING_READY_FOR_WRITE;
        end
      CREATE_STRING_WAIT_FOR_STRING_READY_FOR_WRITE:
        begin
        string_color_wait <= 0;
        if (working_string_available_for_write == 1)
          begin
          one_cycle <= ~one_cycle;
          count_devide_three = mysine[string_iteration_count] / 3;
          middle_point = (mysine[string_iteration_count - 1] / 3) + 5;
          create_string_count <= 0;
          working_string_ready <= 0;
          string_create_state <= CREATE_STRING_DELAY_WAIT;
          if (string_iteration_count < NUMBER_STRINGS)
            begin
            string_iteration_count <= string_iteration_count + 1;
            end
          else
            begin
            string_iteration_count <= 1;
            end
          end
        else
          begin
          string_create_state <= CREATE_STRING_WAIT_FOR_STRING_READY_FOR_WRITE;
          end
        end
      CREATE_STRING_DELAY_WAIT:
        begin
        if (string_color_wait < STRING_COLOR_DELAY)
          begin
          string_color_wait <= string_color_wait + 1;
          string_create_state <= CREATE_STRING_DELAY_WAIT;
          end
        else
          begin
          string_color_wait <= 0;
          string_create_state <= CREATE_STRING_PRE_LOAD;
          end
        end
      CREATE_STRING_PRE_LOAD:
        begin
        if (create_string_count / 3 < middle_point)
          begin
          string_color_state <= CREATE_COLOR_TOP;
          end
        else if (create_string_count / 3 == middle_point)
          begin
          string_color_state <= CREATE_COLOR_MIDDLE;
          end
        else
          begin
          string_color_state <= CREATE_COLOR_BOTTOM;
          end
        string_create_state <= CREATE_STRING_LOAD;
        end
      CREATE_STRING_LOAD:
        begin
        string_create_state <= CREATE_STRING_LOAD_ITERATION;
        if (string_color_state == CREATE_COLOR_TOP)
          begin
          working_string[create_string_count] <= mysine[top_blue];
          working_string[create_string_count + 1] <= mysine[top_green];
          working_string[create_string_count + 2] <= mysine[top_red];
          end
        else if (string_color_state == CREATE_COLOR_MIDDLE)
          begin
          working_string[create_string_count] <= mysine[middle_blue];
          working_string[create_string_count + 1] <= mysine[middle_green];
          working_string[create_string_count + 2] <= mysine[middle_red];
          end
        else
          begin
          working_string[create_string_count] <= mysine[bottom_blue];
          working_string[create_string_count + 1] <= mysine[bottom_green];
          working_string[create_string_count + 2] <= mysine[bottom_red];
          end
        end
      CREATE_STRING_LOAD_ITERATION:
        begin
        if (create_string_count < STRING_SIZE * 3)
          begin
          create_string_count <= create_string_count + 3;
          string_create_state <= CREATE_STRING_PRE_LOAD;
          end
        else
          begin
          string_create_state <= CREATE_STRING_SEND;
          end 
        end
      CREATE_STRING_SEND:
        begin
        working_string_ready <= 1;
        string_create_state <= CREATE_STRING_WAIT_BUSY;
        string_create_state <= CREATE_STRING_WAIT_BUSY;
        end
      CREATE_STRING_WAIT_BUSY:
        begin
        if (working_string_available_for_write == 0)
          begin
          working_string_ready <= 0;
          string_create_state <= CREATE_STRING_ADVANCE_COLOR;
          end
        else
          begin
          string_create_state <= CREATE_STRING_WAIT_BUSY;
          end
        end
      CREATE_STRING_ADVANCE_COLOR:
        begin
        if ((top_green + INCREMENT_TOP_GREEN) >= NUMBER_STRINGS)
          begin
          top_green = ((top_green + INCREMENT_TOP_GREEN) - NUMBER_STRINGS);
          end
        else
          begin
          top_green = top_green + INCREMENT_TOP_GREEN;
          end
        if ((top_blue + INCREMENT_TOP_BLUE) >= NUMBER_STRINGS)
          begin
          top_blue = ((top_blue + INCREMENT_TOP_BLUE) - NUMBER_STRINGS);
          end
        else
          begin
          top_blue = top_blue + INCREMENT_TOP_BLUE;
          end
        if ((top_red + INCREMENT_TOP_RED) >= NUMBER_STRINGS)
          begin
          top_red = ((top_red + INCREMENT_TOP_RED) - NUMBER_STRINGS);
          end
        else
          begin
          top_red = top_red + INCREMENT_TOP_RED;
          end
        if ((middle_green + INCREMENT_MIDDLE_GREEN) >= NUMBER_STRINGS)
          begin
          middle_green = ((middle_green + INCREMENT_MIDDLE_GREEN) - NUMBER_STRINGS);
          end
        else
          begin
          middle_green = middle_green + INCREMENT_MIDDLE_GREEN;
          end
        if ((middle_blue + INCREMENT_MIDDLE_BLUE) >= NUMBER_STRINGS)
          begin
          middle_blue = ((middle_blue + INCREMENT_MIDDLE_BLUE) - NUMBER_STRINGS);
          end
        else
          begin
          middle_blue = middle_blue + INCREMENT_MIDDLE_BLUE;
          end
        if ((middle_red + INCREMENT_MIDDLE_RED) >= NUMBER_STRINGS)
          begin
          middle_red = ((middle_red + INCREMENT_MIDDLE_RED) - NUMBER_STRINGS);
          end
        else
          begin
          middle_red = middle_red + INCREMENT_MIDDLE_RED;
          end
        if ((bottom_green + INCREMENT_BOTTOM_GREEN) >= NUMBER_STRINGS)
          begin
          bottom_green = ((bottom_green + INCREMENT_BOTTOM_GREEN) - NUMBER_STRINGS);
          end
        else
          begin
          bottom_green = bottom_green + INCREMENT_BOTTOM_GREEN;
          end
        if ((bottom_blue + INCREMENT_BOTTOM_BLUE) >= NUMBER_STRINGS)
          begin
          bottom_blue = ((bottom_blue + INCREMENT_BOTTOM_BLUE) - NUMBER_STRINGS);
          end
        else
          begin
          bottom_blue = bottom_blue + INCREMENT_BOTTOM_BLUE;
          end
        if ((bottom_red + INCREMENT_BOTTOM_RED) >= NUMBER_STRINGS)
          begin
          bottom_red = ((bottom_red + INCREMENT_BOTTOM_RED) - NUMBER_STRINGS);
          end
        else
          begin
          bottom_red = bottom_red + INCREMENT_BOTTOM_RED;
          end
        string_create_state <= CREATE_STRING_START;
        end
      endcase
  end
endmodule
