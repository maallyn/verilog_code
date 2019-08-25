`timescale 1ns / 1ps

module sinewave (input wire sinewave_rst);
    reg[7:0] sin [0:89];

    always @ (posedge sinewave_rst)
      begin
      sin[0] <= 100;
      sin[1] <= 106;
      sin[2] <= 113;
      sin[3] <= 120;
      sin[4] <= 127;
      sin[5] <= 134;
      sin[6] <= 140;
      sin[7] <= 146;
      sin[8] <= 152;
      sin[9] <= 158;
      sin[10] <= 164;
      sin[11] <= 169;
      sin[12] <= 174;
      sin[13] <= 178;
      sin[14] <= 182;
      sin[15] <= 186;
      sin[16] <= 189;
      sin[17] <= 192;
      sin[18] <= 195;
      sin[19] <= 197;
      sin[20] <= 198;
      sin[21] <= 199;
      sin[22] <= 199;
      sin[23] <= 199;
      sin[24] <= 199;
      sin[25] <= 198;
      sin[26] <= 197;
      sin[27] <= 195;
      sin[28] <= 192;
      sin[29] <= 189;
      sin[30] <= 186;
      sin[31] <= 182;
      sin[32] <= 178;
      sin[33] <= 174;
      sin[34] <= 169;
      sin[35] <= 164;
      sin[36] <= 158;
      sin[37] <= 152;
      sin[38] <= 146;
      sin[39] <= 140;
      sin[40] <= 134;
      sin[41] <= 127;
      sin[42] <= 120;
      sin[43] <= 113;
      sin[44] <= 106;
      sin[45] <= 100;
      sin[46] <= 93;
      sin[47] <= 86;
      sin[48] <= 79;
      sin[49] <= 72;
      sin[50] <= 65;
      sin[51] <= 59;
      sin[52] <= 53;
      sin[53] <= 47;
      sin[54] <= 41;
      sin[55] <= 35;
      sin[56] <= 30;
      sin[57] <= 25;
      sin[58] <= 21;
      sin[59] <= 17;
      sin[60] <= 13;
      sin[61] <= 10;
      sin[62] <= 7;
      sin[63] <= 4;
      sin[64] <= 2;
      sin[65] <= 1;
      sin[66] <= 0;
      sin[67] <= 0;
      sin[68] <= 0;
      sin[69] <= 0;
      sin[70] <= 1;
      sin[71] <= 2;
      sin[72] <= 4;
      sin[73] <= 7;
      sin[74] <= 10;
      sin[75] <= 13;
      sin[76] <= 17;
      sin[77] <= 21;
      sin[78] <= 25;
      sin[79] <= 30;
      sin[80] <= 35;
      sin[81] <= 41;
      sin[82] <= 47;
      sin[83] <= 53;
      sin[84] <= 59;
      sin[85] <= 65;
      sin[86] <= 72;
      sin[87] <= 79;
      sin[88] <= 86;
      sin[89] <= 93;
      end
endmodule



module spi #(parameter CLK_DIV = 4)(
    input clk,
    input spi_rst,
    output mosi,
    output sck,
    input start,
    input[7:0] data_in,
    output busy
  );
 
  localparam STATE_SIZE = 2;
  localparam IDLE = 2'd0,
    WAIT_HALF = 2'd1,
    TRANSFER = 2'd2;
 
  reg [STATE_SIZE-1:0] state_d, state_q;
 
  reg [7:0] data_d, data_q;
  reg [CLK_DIV-1:0] sck_d, sck_q;
  reg mosi_d, mosi_q;
  reg [2:0] ctr_d, ctr_q;
 
  assign mosi = mosi_q;
  assign sck = (sck_q[CLK_DIV-1]) & (state_q == TRANSFER);
  assign busy = state_q != IDLE;
 
  always @(*) begin
    sck_d = sck_q;
    data_d = data_q;
    mosi_d = mosi_q;
    ctr_d = ctr_q;
    state_d = state_q;
 
    case (state_q)
      IDLE: begin
        sck_d = 4'b0;              // reset clock counter
        ctr_d = 3'b0;              // reset bit counter
        if (start == 1'b1) begin   // if start command
          data_d = data_in;        // copy data to send
          state_d = WAIT_HALF;     // change state
        end
      end
      WAIT_HALF: begin
        sck_d = sck_q + 1'b1;                  // increment clock counter
        if (sck_q == {CLK_DIV-1{1'b1}}) begin  // if clock is half full (about to fall)
          sck_d = 1'b0;
          state_d = TRANSFER;                  // change state
        end
      end
      TRANSFER: begin
        sck_d = sck_q + 1'b1;                           // increment clock counter
        if (sck_q == 4'b0000) begin                        // if clock counter is 0
          mosi_d = data_q[7];                           // output the MSB of data
        end else if (sck_q == {CLK_DIV-1{1'b1}}) begin  // else if it's half full (about to fall)
          data_d = {data_q[6:0], 1'b0};
        end else if (sck_q == {CLK_DIV{1'b1}}) begin    // else if it's full (about to rise)
          ctr_d = ctr_q + 1'b1;                         // increment bit counter
          if (ctr_q == 3'b111) begin                    // if we are on the last bit
            state_d = IDLE;                             // change state
          end
        end
      end
    endcase
  end
 
  always @(posedge clk) begin
    if (spi_rst) begin
      ctr_q <= #5 3'b0;
      data_q <= #5 8'b0;
      sck_q <= #5 4'b0;
      mosi_q <= #5 1'b0;
      state_q <= #5 IDLE;
    end else begin
      ctr_q <= #5 ctr_d;
      data_q <= #5 data_d;
      sck_q <= #5 sck_d;
      mosi_q <= #5 mosi_d;
      state_q <= #5 state_d;
    end
  end
 
endmodule

module doled (
  input wire[7:0] red,
  input wire [7:0] blue,
  input wire [7:0] green,
  output wire mosi,
  output wire sck,
  input wire clk,
  input wire doled_rst,
  input wire ledstart,
  input wire stringend,
  output reg doledbusy
  );


wire spibusy;
reg[7:0] data_out;
reg dostringend;

reg[7:0] myinit; 
reg[7:0] myred;
reg[7:0] myblue;
reg[7:0] mygreen;
reg[3:0] mystate;
reg[1:0] delay_for_spi_to_clear_busy;
reg spistart;

spi spi1(.clk(clk), .spi_rst(doled_rst), .mosi(mosi), .sck(sck),
  .start(spistart), .data_in(data_out), .busy(spibusy));

localparam IDLE = 0,
  START = 1,
  WAIT_INIT = 2,
  LOAD_INIT = 3,
  SEND_INIT = 4,
  WAIT_RED = 5,
  LOAD_RED = 6,
  SEND_RED = 7,
  WAIT_BLUE = 8,
  LOAD_BLUE = 9,
  SEND_BLUE = 10,
  WAIT_GREEN = 11,
  LOAD_GREEN = 12,
  SEND_GREEN = 13;

always @ (posedge clk)

  begin
  if (doled_rst)
    begin
    mystate <= IDLE;
    myinit <= 0;
    myred <= 0;
    mygreen <= 0;
    myblue <= 0;
    data_out <= 0;
    doledbusy <= 0;
    dostringend <= 0;
    delay_for_spi_to_clear_busy <= 0;
    spistart <= 0;
    end
  else 
    begin
    case (mystate)
      IDLE:
        begin
        if (ledstart)
          begin
          mystate <= START;
          dostringend <= stringend;
          doledbusy <= 1;
          end
        end

      START:
        begin
        if (dostringend)
          begin
          myred <= 0;
          mygreen <= 0;
          myblue <= 0;
          myinit <= 0;
          end
        else
          begin
          myred <= red;
          myblue <= blue;
          mygreen <= green;
          myinit <= 8'b11100000;
          end
        mystate <= WAIT_INIT;
        end
      WAIT_INIT:
        begin
        if (~spibusy)
          begin
	  data_out <= myinit;
          mystate <= LOAD_INIT;
          end
        end
      LOAD_INIT:
        begin
        delay_for_spi_to_clear_busy <= 2'b00;
        spistart <= 1;
        mystate <= SEND_INIT;
        end
      SEND_INIT:
        begin
        if (delay_for_spi_to_clear_busy == 2'b11)
          begin
          spistart <= 0;
          mystate <= WAIT_RED;
          end
        else
          begin
          delay_for_spi_to_clear_busy <= delay_for_spi_to_clear_busy + 1;
          end
        end
      WAIT_RED:
        begin
        if (~spibusy)
          begin
	  data_out <= myred;
          mystate <= LOAD_RED;
          end
        end
      LOAD_RED:
        begin
        delay_for_spi_to_clear_busy <= 2'b00;
        spistart <= 1;
        mystate <= SEND_RED;
        end
      SEND_RED:
        begin
        if (delay_for_spi_to_clear_busy == 2'b11)
          begin
          spistart <= 0;
          mystate <= WAIT_BLUE;
          end
        else
          begin
          delay_for_spi_to_clear_busy <= delay_for_spi_to_clear_busy + 1;
          end
        end
      WAIT_BLUE:
        begin
        if (~spibusy)
          begin
	  data_out <= myblue;
          mystate <= LOAD_BLUE;
          end
        end
      LOAD_BLUE:
        begin
        delay_for_spi_to_clear_busy <= 2'b00;
        spistart <= 1;
        mystate <= SEND_BLUE;
        end
      SEND_BLUE:
        begin
        if (delay_for_spi_to_clear_busy == 2'b11)
          begin
          spistart <= 0;
          mystate <= WAIT_GREEN;
          end
        else
          begin
          delay_for_spi_to_clear_busy <= delay_for_spi_to_clear_busy + 1;
          end
        end
      WAIT_GREEN:
        begin
        if (~spibusy)
          begin
	  data_out <= mygreen;
          mystate <= LOAD_GREEN;
          end
        end
      LOAD_GREEN:
        begin
        delay_for_spi_to_clear_busy <= 2'b00;
        spistart <= 1;
        mystate <= SEND_GREEN;
        end
      SEND_GREEN:
        begin
        if (delay_for_spi_to_clear_busy == 2'b11)
          begin
          spistart <= 0;
          mystate <= IDLE;
          doledbusy <= 0;
          end
        else
          begin
          delay_for_spi_to_clear_busy <= delay_for_spi_to_clear_busy + 1;
          end
        end
    endcase
    end
  end
endmodule 
