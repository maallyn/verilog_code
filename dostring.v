`timescale 10ns / 10ps

module top (
  output wire led0,
  output wire led1,
  output wire led2,
  output wire led3,
  output wire mosi,
  output wire sck,
  input wire CLK
);

assign led0 = sck;
assign led1 = mosi;
assign led2 = 1;
assign led3 = dostring_clk;

localparam
  INPUT_TYPE_START = 0,
  INPUT_TYPE_LED = 1,
  INPUT_TYPE_END = 2;

localparam STRING_SIZE = 30;

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
  CREATE_STRING_LOAD = 2,
  CREATE_STRING_LOAD_ITERATION = 3,
  CREATE_STRING_SEND = 4,
  CREATE_STRING_WAIT_BUSY = 5,
  CREATE_STRING_WAIT = 6,
  CREATE_STRING_DONE = 7;

reg dostring_clk;
reg[7:0] create_string_count;
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


reg led_start = 0;
reg[1:0] input_type = INPUT_TYPE_START;
wire doled_busy;
reg[3:0] string_send_state = STRING_WAIT_FOR_CURRENT_STRING;
reg[3:0] string_create_state = CREATE_STRING_START;
reg[7:0] string_out_count = 0;
reg[7:0] string_process_count = 0;
reg[7:0] string_move_count = 0;
reg[16:0] clk_count = 0;

always @ (posedge CLK)
  begin
  if (clk_count == 100000)
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
      if (current_string_ready)
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
    case(string_create_state)
      CREATE_STRING_START:
        begin
        string_create_state <= CREATE_STRING_WAIT_FOR_STRING_READY_FOR_WRITE;
        end
      CREATE_STRING_WAIT_FOR_STRING_READY_FOR_WRITE:
        begin
        if (current_string_available_for_write == 1)
          begin
          create_string_count <= 0;
          current_string_ready <= 0;
          string_create_state <= CREATE_STRING_LOAD;
          end
        else
          begin
          string_create_state <= CREATE_STRING_WAIT_FOR_STRING_READY_FOR_WRITE;
          end
        end
      CREATE_STRING_LOAD:
        begin
        current_string[create_string_count] = create_string_count + 50;
        current_string[create_string_count + 1] = create_string_count + 100;
        current_string[create_string_count + 2] = create_string_count + 150;
        string_create_state <= CREATE_STRING_LOAD_ITERATION;
        end
      CREATE_STRING_LOAD_ITERATION:
        begin
        if (create_string_count < STRING_SIZE * 3)
          begin
          create_string_count <= create_string_count + 1;
          string_create_state <= CREATE_STRING_LOAD;
          end
        else
          begin
          create_string_count <= 0;
          string_create_state <= CREATE_STRING_SEND;
          end 
        end
      CREATE_STRING_SEND:
        begin
        current_string_ready <= 1;
        string_create_state <= CREATE_STRING_WAIT_BUSY;
        end
      CREATE_STRING_WAIT_BUSY:
        begin
        if (current_string_available_for_write == 0)
          begin
          current_string_ready <= 0;
          string_create_state <= CREATE_STRING_WAIT;
          end
        else
          begin
          string_create_state <= CREATE_STRING_WAIT_BUSY;
          end
        end
      CREATE_STRING_WAIT:
        begin
        if (current_string_available_for_write == 1)
          begin
          string_create_state <= CREATE_STRING_DONE;
          end
        else
          begin
          string_create_state <= CREATE_STRING_WAIT;
          end
        end
      CREATE_STRING_DONE:
        begin
        current_string_ready <= 0;
        string_create_state <= CREATE_STRING_START;
        end
      default:
        begin
        current_string_ready <= 0;
        string_create_state <= CREATE_STRING_START;
        end
      endcase
  end
endmodule
