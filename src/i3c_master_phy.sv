`timescale 1ns/1ps

module i3c_master_phy #(
    parameter CLK_FREQ_MHZ = 100,
    parameter I2C_FREQ_KHZ = 400,
    parameter I3C_FREQ_MHZ = 12
)(
    input  wire clk,
    input  wire rst_n,

    // Control Interface
    input  wire start_transfer,
    input  wire [7:0] tx_data,
    input  wire is_read,
    input  wire stop_condition,
    input  wire restart,
    input  wire mode_pp,
    input  wire ack_value,

    // Status Interface
    output reg  tx_done,
    output reg  [7:0] rx_data,
    output reg  ack_error,
    output reg  arbitration_lost,
    output wire ibi_detect,

    // Bus Interface
    output reg  scl_out,
    output wire scl_oe,
    input  wire scl_in,
    output reg  sda_out,
    output reg  sda_oe,
    input  wire sda_in
);

    // --- State Definitions ---
    localparam IDLE       = 3'd0, 
               START_SEQ  = 3'd1, 
               BIT_TX     = 3'd2, 
               BIT_RX     = 3'd3,
               ACK_RX     = 3'd4, 
               ACK_TX     = 3'd5, 
               STOP_SEQ   = 3'd6;

    reg [2:0] state;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg sda_drive_reg;

    // --- Clock Divider Logic ---
    localparam DIV_OD = (CLK_FREQ_MHZ * 1000) / (I2C_FREQ_KHZ * 4);
    localparam DIV_PP = (CLK_FREQ_MHZ) / (I3C_FREQ_MHZ * 4);

    reg [15:0] div_cnt;
    reg [1:0]  quarter_state;
    wire [15:0] current_div = mode_pp ? DIV_PP : DIV_OD;

    // FIX: Clock stretching ONLY allowed in Open-Drain (I2C/DAA) mode
    // This prevents simulation deadlocks in Push-Pull mode
    wire is_stretching = (scl_out == 1'b1 && scl_in == 1'b0 && !mode_pp);
    wire pulse_quarter = (div_cnt == 0 && !is_stretching);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            div_cnt <= 0;
            quarter_state <= 0;
        end else if(state != IDLE) begin
            if(!is_stretching) begin
                if(div_cnt >= current_div - 1) begin
                    div_cnt <= 0;
                    quarter_state <= quarter_state + 1;
                end else begin
                    div_cnt <= div_cnt + 1;
                end
            end
        end else begin
            div_cnt <= 0;
            quarter_state <= 0;
        end
    end

    // --- Arbitration Logic ---
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            arbitration_lost <= 0;
        end else if(state == BIT_TX && sda_oe && sda_out && !sda_in && !mode_pp) begin
            arbitration_lost <= 1;
        end else if(state == IDLE) begin
            arbitration_lost <= 0;
        end
    end

    // --- Main FSM ---
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            bit_cnt <= 0;
            shift_reg <= 0;
            ack_error <= 0;
            tx_done <= 0;
            rx_data <= 0;
            sda_drive_reg <= 1;
        end else begin
            tx_done <= 0;
            
            if(arbitration_lost) begin
                state <= IDLE;
            end else begin
                case(state)
                    IDLE: begin
                        if(start_transfer) begin
                            shift_reg <= tx_data;
                            bit_cnt <= 7;
                            state <= START_SEQ;
                        end
                    end

                    START_SEQ: begin
                        if(pulse_quarter && quarter_state == 3)
                            state <= is_read ? BIT_RX : BIT_TX;
                    end

                    BIT_TX: begin
                        if(pulse_quarter) begin
                            if(quarter_state == 0) sda_drive_reg <= shift_reg[bit_cnt];
                            if(quarter_state == 3) begin
                                if(bit_cnt == 0) state <= ACK_RX;
                                else bit_cnt <= bit_cnt - 1;
                            end
                        end
                    end

                    BIT_RX: begin
                        if(pulse_quarter) begin
                            if(quarter_state == 2) rx_data[bit_cnt] <= sda_in;
                            if(quarter_state == 3) begin
                                if(bit_cnt == 0) state <= ACK_TX;
                                else bit_cnt <= bit_cnt - 1;
                            end
                        end
                    end

                    ACK_RX: begin
                        if(pulse_quarter) begin
                            if(quarter_state == 2) ack_error <= sda_in;
                            if(quarter_state == 3) begin
                                tx_done <= 1;
                                state <= stop_condition ? STOP_SEQ : IDLE;
                            end
                        end
                    end

                    ACK_TX: begin
                        if(pulse_quarter) begin
                            if(quarter_state == 0) sda_drive_reg <= ack_value;
                            if(quarter_state == 3) begin
                                tx_done <= 1;
                                state <= stop_condition ? STOP_SEQ : IDLE;
                            end
                        end
                    end

                    STOP_SEQ: begin
                        if(pulse_quarter && quarter_state == 3) begin
                            tx_done <= 1;
                            state <= IDLE;
                        end
                    end

                    default: state <= IDLE;
                endcase
            end
        end
    end

    // --- Output Drive Logic ---
    // SCL Control
    always @(*) begin
        if(state == IDLE) scl_out = 1'b1;
        else if(state == START_SEQ || state == STOP_SEQ) scl_out = 1'b1;
        else scl_out = (quarter_state >= 2);
    end

    assign scl_oe = mode_pp ? 1'b1 : (scl_out == 0);

    // SDA Control
    always @(*) begin
        sda_oe = 0;
        sda_out = 0;
        case(state)
            START_SEQ: begin
                sda_oe = 1'b1;
                sda_out = (quarter_state == 0);
            end
            STOP_SEQ: begin
                sda_oe = 1'b1;
                sda_out = (quarter_state >= 2);
            end
            BIT_TX: begin
                // In Push-Pull, Master always drives SDA
                sda_oe = mode_pp ? 1'b1 : (sda_drive_reg == 0);
                sda_out = mode_pp ? sda_drive_reg : 1'b0;
            end
            ACK_TX: begin
                sda_oe = 1'b1;
                sda_out = sda_drive_reg;
            end
            default: begin
                sda_oe = 0;
                sda_out = 0;
            end
        endcase
    end

    assign ibi_detect = (state == IDLE) && (scl_in == 1) && (sda_in == 0) && (!start_transfer);

endmodule
