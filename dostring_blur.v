
module top (
  output wire led0,
  output wire led1,
  output wire led2,
  output wire mosi,
  output wire sck,
  input wire CLK
);

localparam
  INPUT_TYPE_START = 0,
  INPUT_TYPE_LED = 1,
  INPUT_TYPE_END = 2;

localparam STRING_SIZE = 46;

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
  CREATE_STRING_LOAD = 3,
  CREATE_STRING_LOAD_ITERATION = 4,
  CREATE_STRING_SEND = 5,
  CREATE_STRING_WAIT_BUSY = 6;

localparam MOVE_STRING_START = 0,
  MOVE_STRING_SET_RESPONSE_TO_READIES = 1,
  MOVE_STRING_LOAD = 2,
  MOVE_STRING_LOAD_ITERATION = 3,
  MOVE_CURRENT_STRING_SEND = 4,
  MOVE_STRING_WAIT_CURRENT_STRING_BUSY = 5,
  MOVE_STRING_WAIT_WORKING_STRING_BUSY = 6;
  
localparam STRING_COLOR_DELAY = 10000000;

reg dostring_clk = 0;

reg[7:0] create_string_count = 0;
reg[7:0] blue_out = 0;
reg[7:0] green_out = 0;
reg[7:0] red_out = 0;
reg[7:0] current_string[STRING_SIZE * 3:0];
reg[7:0] working_string[STRING_SIZE * 3:0];
reg[7:0] blue_working = 0;
reg[7:0] green_working = 0;
reg[7:0] red_working = 0;
reg current_string_ready = 0;
reg current_string_available_for_write = 1;
reg working_string_ready = 0;
reg working_string_available_for_write = 1;


reg led_start = 0;
reg[1:0] input_type = INPUT_TYPE_START;
wire doled_busy;
reg[3:0] string_send_state = STRING_WAIT_FOR_CURRENT_STRING;
reg[3:0] string_create_state = CREATE_STRING_START;
reg[3:0] string_move_state = MOVE_STRING_START;
reg[7:0] string_out_count = 0;
reg[7:0] string_process_count = 0;
reg[7:0] string_move_count = 0;
reg[16:0] clk_count = 0;
reg[3:0] string_color = 0;
reg[31:0] string_color_wait = 0;
reg go_ahead_move_from_working = 0;
reg go_ahead_move_to_current = 0;

assign led0 = sck;
assign led1 = mosi;
assign led2 = dostring_clk;

wire go_ahead_with_move;

assign go_ahead_with_move = go_ahead_move_from_working && go_ahead_move_to_current;

always @ (posedge CLK)
  begin
  if (clk_count == 5)
    begin
    clk_count <= 0;
    dostring_clk <= ~dostring_clk;
    end
  else
    begin
    clk_count <= clk_count + 1;
    end  
  end

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

always @ (posedge dostring_clk)
  begin
    case(string_create_state)
      CREATE_STRING_START:
        begin
        string_create_state <= CREATE_STRING_WAIT_FOR_STRING_READY_FOR_WRITE;
        end
      CREATE_STRING_WAIT_FOR_STRING_READY_FOR_WRITE:
        begin
        if (working_string_available_for_write == 1)
          begin
          create_string_count <= 0;
          working_string_ready <= 0;
          string_create_state <= CREATE_STRING_DELAY_WAIT;
          end
        else
          begin
          string_create_state <= CREATE_STRING_WAIT_FOR_STRING_READY_FOR_WRITE;
          string_color_wait <= 0;
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
          string_create_state <= CREATE_STRING_LOAD;
          end
        end
      CREATE_STRING_LOAD:
        begin
        string_create_state <= CREATE_STRING_LOAD_ITERATION;
        if (string_color == 0)
          begin
          working_string[create_string_count] <= 8'h3f;
          working_string[create_string_count + 1] <= 8'h00;
          working_string[create_string_count + 2] <= 8'h00;
          end
        else if (string_color == 1)
          begin
          working_string[create_string_count] <= 8'h00;
          working_string[create_string_count + 1] <= 8'h3f;
          working_string[create_string_count + 2] <= 8'h00;
          end
        else if (string_color == 2)
          begin
          working_string[create_string_count] <= 8'h00;
          working_string[create_string_count + 1] <= 8'h00;
          working_string[create_string_count + 2] <= 8'h3f;
          end
        else if (string_color == 3)
          begin
          working_string[create_string_count] <= 8'h3f;
          working_string[create_string_count + 1] <= 8'h3f;
          working_string[create_string_count + 2] <= 8'h00;
          end
        else if (string_color == 4)
          begin
          working_string[create_string_count] <= 8'h3f;
          working_string[create_string_count + 1] <= 8'h00;
          working_string[create_string_count + 2] <= 8'h3f;
          end
        else if (string_color == 5)
          begin
          working_string[create_string_count] <= 8'h00;
          working_string[create_string_count + 1] <= 8'h3f;
          working_string[create_string_count + 2] <= 8'h3f;
          end
        else
          begin
          working_string[create_string_count] <= 8'h3f;
          working_string[create_string_count + 1] <= 8'h3f;
          working_string[create_string_count + 2] <= 8'h3f;
          end

        end
      CREATE_STRING_LOAD_ITERATION:
        begin
        if (create_string_count < STRING_SIZE * 3)
          begin
          create_string_count <= create_string_count + 3;
          string_create_state <= CREATE_STRING_LOAD;
          end
        else
          begin
          create_string_count <= 0;
          if (string_color == 6)
            begin
            string_color <= 0;
            end
          else
            begin
            string_color <= string_color + 1;
            end
          string_create_state <= CREATE_STRING_SEND;
          end 
        end
      CREATE_STRING_SEND:
        begin
        working_string_ready <= 1;
        string_create_state <= CREATE_STRING_WAIT_BUSY;
        end
      CREATE_STRING_WAIT_BUSY:
        begin
        if (working_string_available_for_write == 0)
          begin
          working_string_ready <= 0;
          string_create_state <= CREATE_STRING_START;
          end
        else
          begin
          string_create_state <= CREATE_STRING_WAIT_BUSY;
          end
        end
      endcase
  end
endmodule
