`timescale 1ns/1ps

module i3c_pad_wrapper(

 input wire scl_o,
 input wire scl_oe,
 output wire scl_i,
 inout wire scl,

 input wire sda_o,
 input wire sda_oe,
 output wire sda_i,
 inout wire sda
);

// Open-drain / push-pull modeling
assign scl = (scl_oe) ? scl_o : 1'bz;
assign sda = (sda_oe) ? sda_o : 1'bz;

assign scl_i = scl;
assign sda_i = sda;

endmodule


