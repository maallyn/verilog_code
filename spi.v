// This writes a byte to the LED strip. It uses a
// modified SPI output from master to slave. We
// are master and se send data. Nothing is required
// to be received by the slave.

module spi (
    input wire spi_clk,
    output reg spi_output_data = 0,
    output reg spi_output_clock = 0,
    input wire spi_start,
    input wire[7:0] spi_data_in,
    output reg spi_busy = 0
  );
 
localparam 
  STATE_IDLE = 0,
  STATE_ACCEPT = 1,
  STATE_SET_BIT = 2,
  STATE_WAIT_CLOCK_SET = 3,
  STATE_SET_CLOCK = 4,
  STATE_WAIT_CLOCK_CLEAR = 5,
  STATE_CLEAR_CLOCK = 6,
  STATE_SHIFT_DATA_HOLDING = 7;

localparam
  CLOCK_DELAY_TIME = 5;
  
reg[2:0] bit_counter = 0;
reg[3:0] spi_state = STATE_IDLE;
reg[7:0] spi_data_holding = 0;
reg[3:0] clock_delay = 0;

always @ (posedge spi_clk)
  begin
  case(spi_state)
    STATE_IDLE:
      begin
      if (spi_start == 1)
        begin
        spi_busy <= 1;
        spi_state <= STATE_ACCEPT;
        end
      else
        begin
        spi_busy <= 0;
        spi_state <= STATE_IDLE;
        end
      end
    STATE_ACCEPT:
      begin
      spi_data_holding <= spi_data_in;
      spi_state <= STATE_SET_BIT;
      end
    STATE_SET_BIT:
      begin
      spi_output_data <= spi_data_holding[7:7];
      spi_state <= STATE_WAIT_CLOCK_SET;
      clock_delay <= 0;
      end
    STATE_WAIT_CLOCK_SET:
      begin
      if (clock_delay < CLOCK_DELAY_TIME)
        begin
        clock_delay <= clock_delay + 1;
        spi_state <= STATE_WAIT_CLOCK_SET;
        end
      else
        begin
        clock_delay <= 0;
        spi_state <= STATE_SET_CLOCK;
        end
      end
    STATE_SET_CLOCK:
      begin
      spi_output_clock <= 1;
      spi_state <= STATE_WAIT_CLOCK_CLEAR;
      end
    STATE_WAIT_CLOCK_CLEAR:
      begin
      if (clock_delay < CLOCK_DELAY_TIME)
        begin
        clock_delay <= clock_delay + 1;
        spi_state <= STATE_WAIT_CLOCK_CLEAR;
        end
      else
        begin
        clock_delay <= 0;
        spi_state <= STATE_CLEAR_CLOCK;
        end
      end
    STATE_CLEAR_CLOCK:
      begin
      spi_output_clock <= 0;
      spi_state <= STATE_SHIFT_DATA_HOLDING;
      end
    STATE_SHIFT_DATA_HOLDING:
      begin
      if (bit_counter == 7)
        begin
        bit_counter <= 0;
        spi_output_data <= 0;
        spi_busy <= 0;
        spi_state <= STATE_IDLE;
        end
      else
        begin
        bit_counter <= bit_counter + 1;
        spi_data_holding <= spi_data_holding << 1;
        spi_state <= STATE_SET_BIT;
        end
      end
    default:
      begin
      spi_output_data <= 0;
      spi_output_clock <= 0;
      spi_busy <= 0;
      bit_counter <= 0;
      spi_state <= STATE_IDLE;
      spi_data_holding <= 0;
      end
    endcase
  end

endmodule
