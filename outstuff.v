module domysine (input wire[7:0] angle_input,
  output wire[7:0] sine_output);

wire[7:0] mysine[89:0];

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

assign sine_output = mysine[angle_input];
endmodule
