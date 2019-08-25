`timescale 1ns / 1ps

module top (

output wire mosi,
output wire sck,
input wire CLK,
input wire myreset
);

localparam DO_RESET = 0,
  WAIT_TO_SEND_STRING_END = 1,
  SET_LEDSTART = 2,
  CLEAR_LEDSTART = 3,
  WAIT_TO_SEND_LED = 4,
  SET_LEDSTART_LED = 5,
  CLEAR_LEDSTART_LED = 6,
  CHECK_FINISH = 7;

reg top_rst;

reg[7:0] clk_countdown;
reg[1:0] slowresetcount;
reg slowclk;
reg[3:0] color;
reg[7:0] blue_buf;
reg[7:0] green_buf;
reg[7:0] red_buf;
reg[7:0] my_green;
reg[7:0] my_blue;
reg[7:0] my_red;
reg[7:0] led_count;
reg advance_color;
reg has_advance_color_reset;

reg ledstart;
reg stringend;
reg[4:0] resetcount;
wire doledbusy;

reg[4:0] colorstate;
reg slowreset;

doled doled1 (.clk(CLK), .red(red_buf), .blue(blue_buf), .green(green_buf), .mosi(mosi),
    .sck(sck), .ledstart(ledstart), .stringend(stringend), 
    .doled_rst(top_rst), .doledbusy(doledbusy));

always @ (posedge CLK)
  begin
  if (myreset == 1)
    begin
    has_advance_color_reset <= 1;
    slowresetcount <= 0;
    slowreset <= 1;
    top_rst <= 1;
    slowclk <= 0;
    clk_countdown <= 0;
    my_green <= 0;
    my_blue <= 20;
    my_red <= 100;
    end
  else
    begin
    top_rst <= 0;

    if (clk_countdown == 8'b00000010)
      begin
      clk_countdown <= 0;
      slowclk <= ~slowclk;
      if (slowreset == 1)
        begin
        if (slowresetcount == 3)
          begin
          slowreset <= 0;
          end
        else
          begin
          slowresetcount = slowresetcount + 1;
          end
        end
      end
    else
      begin
      clk_countdown <= clk_countdown + 1;
      end

    if ((advance_color == 1) && (has_advance_color_reset == 1))
      begin
      has_advance_color_reset <= 0;
      if (my_green > 150)
        begin 
        my_green = 0;
        end
      else
        begin
        my_green = my_green + 1;
        end

      if (my_blue > 150)
        begin 
        my_blue = 0;
        end
      else
        begin
        my_blue = my_blue + 1;
        end
  
      if (my_red > 150)
        begin 
        my_red = 0;
        end
      else
        begin
        my_red = my_red + 1;
        end
      end
    if (advance_color == 0)
      begin
      has_advance_color_reset <= 1;
      end
    end
  end
    
always @ (posedge slowclk)
  begin
  if (slowreset == 1)
    begin
    colorstate <= DO_RESET;
    end
  case (colorstate)
    DO_RESET:
      begin
      led_count <= 0;
      blue_buf <= 0;
      green_buf <= 0;
      red_buf <=0;
      ledstart <= 0;
      advance_color <= 0;
      if (slowreset == 0)
        begin
        colorstate <= WAIT_TO_SEND_STRING_END;
        end
      end
    WAIT_TO_SEND_STRING_END:
      begin
      if (doledbusy == 0)
        begin
        stringend <= 1;
        colorstate <= SET_LEDSTART;
        end
      end
    SET_LEDSTART:
      begin
      ledstart <= 1;
      colorstate <= CLEAR_LEDSTART;
      end
    CLEAR_LEDSTART:
      begin
      colorstate <= WAIT_TO_SEND_LED;
      ledstart <= 0;
      end
    WAIT_TO_SEND_LED:
      begin
      stringend <= 0;
      if (doledbusy == 0)
        begin
        blue_buf <= my_blue;
        green_buf <= my_green;
        red_buf <= my_red;
        if (led_count == 20)
          begin
          advance_color <= 1;
          end
        colorstate <= SET_LEDSTART_LED;
        end
      end
    SET_LEDSTART_LED:
      begin
      ledstart <= 1;
      advance_color <= 1;
      colorstate <= CLEAR_LEDSTART_LED;
      end
    CLEAR_LEDSTART_LED:
      begin
      colorstate <= CHECK_FINISH;
      ledstart <= 0;
      end
    CHECK_FINISH:
      begin
      if (led_count == 20)
        begin
        led_count <= 0;
        advance_color <= 1;
        colorstate <= WAIT_TO_SEND_STRING_END;
        end
      else
        begin
        led_count = led_count + 1;
        colorstate <= WAIT_TO_SEND_LED;
        end
      end
  endcase
  end

endmodule
