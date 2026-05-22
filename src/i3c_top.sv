`timescale 1ns/1ps

module i3c_top;

// =====================================================
// INTERNAL STIMULUS REGISTERS
// =====================================================
reg clk;
reg rst_n;

reg start_daa;
reg start_tx;
reg [7:0] target_addr;
reg [7:0] tx_data_in;

wire daa_complete;
wire tx_complete;
wire [7:0] last_rx_data;

// PAD BUS 
wire scl;
wire sda;

// PAD INTERFACE SIGNALS
wire scl_o, scl_oe, scl_i;
wire sda_o, sda_oe, sda_i;


// =====================================================
// SIMPLE CLOCK + RESET GENERATION
// =====================================================
initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 100 MHz simulation clock
end

initial begin
    rst_n = 0;
    start_daa = 0;
    start_tx  = 0;
    target_addr = 8'h52;
    tx_data_in  = 8'hA5;

    #100 rst_n = 1;

    // Example transaction trigger
    #50  start_tx = 1;
    #10  start_tx = 0;
end


// =====================================================
// PAD WRAPPER
// =====================================================
i3c_pad_wrapper pads(
 .scl_o(scl_o),
 .scl_oe(scl_oe),
 .scl_i(scl_i),
 .scl(scl),

 .sda_o(sda_o),
 .sda_oe(sda_oe),
 .sda_i(sda_i),
 .sda(sda)
);


// =====================================================
// CONTROLLER
// =====================================================
i3c_controller ctrl(
 .clk(clk),
 .rst_n(rst_n),
 .start_daa(start_daa),
 .start_tx(start_tx),
 .target_addr(target_addr),
 .tx_data_in(tx_data_in),
 .daa_complete(daa_complete),
 .tx_complete(tx_complete),
 .last_rx_data(last_rx_data),
 .scl_o(scl_o),
 .scl_oe(scl_oe),
 .scl_i(scl_i),
 .sda_o(sda_o),
 .sda_oe(sda_oe),
 .sda_i(sda_i)
);

endmodule
