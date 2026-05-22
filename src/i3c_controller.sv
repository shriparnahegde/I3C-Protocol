module i3c_controller(
 input wire clk,
 input wire rst_n,

 input wire start_daa,
 input wire start_tx,
 input wire [7:0] target_addr,
 input wire [7:0] tx_data_in,

 output reg daa_complete,
 output reg tx_complete,
 output reg [7:0] last_rx_data,

 // -------- PAD INTERFACE (NO INOUT HERE) --------
 output wire scl_o,
 output wire scl_oe,
 input  wire scl_i,

 output wire sda_o,
 output wire sda_oe,
 input  wire sda_i
);

localparam IDLE=0,DAA1=1,DAA2=2,DAA3=3,DAA4=4,SDR1=5,SDR2=6,SDR3=7;

reg [3:0] state;

// -------- PHY INTERFACE --------
reg phy_start;
reg [7:0] phy_tx_data;
reg phy_is_read;
reg phy_stop;
reg phy_restart;
reg phy_mode_pp;
reg phy_ack_val;

wire phy_done;

wire scl_out_int,scl_oe_int;
wire sda_out_int,sda_oe_int;

// ===============================================
// PHY INSTANCE
// ===============================================
i3c_master_phy phy_inst(
 .clk(clk),.rst_n(rst_n),
 .start_transfer(phy_start),
 .tx_data(phy_tx_data),
 .is_read(phy_is_read),
 .stop_condition(phy_stop),
 .restart(phy_restart),
 .mode_pp(phy_mode_pp),
 .ack_value(phy_ack_val),
 .tx_done(phy_done),
 .rx_data(),
 .ack_error(),
 .arbitration_lost(),
 .ibi_detect(),
 .scl_out(scl_out_int),
 .scl_oe(scl_oe_int),
 .scl_in(scl_i),
 .sda_out(sda_out_int),
 .sda_oe(sda_oe_int),
 .sda_in(sda_i)
);

// CONNECT TO PAD LAYER
assign scl_o  = scl_out_int;
assign scl_oe = scl_oe_int;
assign sda_o  = sda_out_int;
assign sda_oe = sda_oe_int;

// =====================================================
// CONTROLLER FSM
// =====================================================
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin
  state<=IDLE;
  phy_start<=0;
  phy_tx_data<=0;
  phy_is_read<=0;
  phy_stop<=0;
  phy_restart<=0;
  phy_mode_pp<=0;
  phy_ack_val<=0;
  daa_complete<=0;
  tx_complete<=0;
 end else begin

  phy_start<=0;
  phy_stop<=0;
  phy_restart<=0;
  phy_is_read<=0;

  case(state)

   IDLE: begin
    daa_complete<=0;
    tx_complete<=0;
    phy_mode_pp<=0;
    if(start_daa) state<=DAA1;
    else if(start_tx) state<=SDR1;
   end

   DAA1: begin phy_tx_data<=8'h7E; phy_start<=1; state<=DAA2; end

   DAA2: if(phy_done) begin
     phy_tx_data<=8'h07;
     phy_start<=1;
     state<=DAA3;
   end

   DAA3: if(phy_done) begin
     phy_tx_data<=8'h08;
     phy_stop<=1;
     phy_start<=1;
     state<=DAA4;
   end

   DAA4: if(phy_done) begin
     daa_complete<=1;
     state<=IDLE;
   end

   SDR1: begin
     phy_mode_pp<=1;
     phy_tx_data<={target_addr[6:0],1'b0};
     phy_start<=1;
     state<=SDR2;
   end

   SDR2: if(phy_done) begin
     phy_tx_data<=tx_data_in;
     phy_stop<=1;
     phy_start<=1;
     state<=SDR3;
   end

   SDR3: if(phy_done) begin
     tx_complete<=1;
     state<=IDLE;
   end

  endcase
 end
end

endmodule


