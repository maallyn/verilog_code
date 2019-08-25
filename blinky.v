`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/24/2019 12:25:44 PM
// Design Name: 
// Module Name: blinky
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input wire CLK,
    output wire [3:0] led,
    input wire [3:0] sw,
    output wire [7:0] ja
    
    );

reg [31:0] ctr1 = 32'b0;

assign led[0] = ctr1[16];
assign led[1] = ctr1[17];
assign led[2] = ctr1[18];
assign ja[0] = ctr1[18];
assign ja[1] = ctr1[19];
assign ja[2] = ctr1[20];

always @ (posedge CLK) begin
  ctr1 <= ctr1 + 1;
  end

endmodule
