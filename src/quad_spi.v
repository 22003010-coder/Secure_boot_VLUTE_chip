`timescale 1ns / 1ps
// ==============================================================================================
// quad_spi.v - Module Quad-SPI Dual-Clock (An toan CDC + SoC Reset)
// doc rom va xuat du lieu theo chuan Quad_SPI
// chi hoat dong sau khi soc_reset_n kich hoat
// viec xuat nhap du lieu yeu cau mot xung nhip khac (sclk)
// he thong toi uu nhat doi voi nguon xung (clk - sclk) dong bo 100MHz
// he thong van hoat dong voi 2 xung bat dong bo (clk - sclk)
// tuy nhien hoat dong che do khong dong bo yeu cau xung sclk < 50MHz
// Standard Read: tan so xung sclk khi dung khuyen nghi la 10MHz tro xuong
// Fast Read: tan so xung sclk khong dong bo khuyen nghi la 50MHz tro xuong
// Quad Output Fast Read: tan so xung sclk khong dong bo khuyen nghi la 50MHz tro xuong
// Fast Read Quad I/0: tan so xung sclk khong dong bo khuyen nghi la 50MHz tro xuong
// ==============================================================================================

module quad_spi #(
    parameter integer ADDR_WIDTH = 4
)(
    // --- Mien xung SCLK (Ngoai) ---
    input  wire                  sclk,          // Xung SCLK tu Master
    input  wire                  cs_n,          // Chip Select (Active Low)
    input  wire [3:0]            data_in,       // Ngo vao Bus Quad-SPI
    output reg  [3:0]            data_out,      // Ngo ra Bus Quad-SPI
    output reg  [3:0]            oe,

    // --- Mien xung CLK Noi (100MHz) ---
    input  wire                  clk,           // System Clock 100MHz
    input  wire                  soc_reset_n,   // Reset he thong tu SoC (Active Low)
    output reg                   mem_req,       // Yeu cau doc ROM
    output reg  [ADDR_WIDTH-1:0] mem_addr,      // Dia chi gui ROM
    input  wire [7:0]            mem_rdata,     // Du lieu tu ROM tra ve
    input  wire                  mem_rvalid     // ROM du lieu ready
);

// =============================================================================
// FRONTEND: MIEN XUNG SCLK (Reset bat dong bo theo CS_N)
// =============================================================================
    reg [7:0]   cnt;
    reg [7:0]   cmd;
    reg [23:0]  shift_addr;
    reg [7:0]   sclk_mem_buf;

    reg                  req_toggle_sclk;
    reg [ADDR_WIDTH-1:0] addr_latched_sclk;

    // Tín hiệu trung gian để xử lý part-select đúng chuẩn Verilog
    wire [23:0] next_shift_addr_1bit = {shift_addr[22:0], data_in[0]};
    wire [23:0] next_shift_addr_4bit = {shift_addr[19:0], data_in[3:0]};

    always @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            cnt               <= 8'b00000000;
            cmd               <= 8'b00000000;
            oe                <= 4'b0000;
            shift_addr        <= 24'd0;
            data_out          <= 4'b0000;
            req_toggle_sclk   <= 1'b0;
            addr_latched_sclk <= {ADDR_WIDTH{1'b0}};
        end else begin
            cnt <= cnt + 1'b1;

            if (cnt < 8) begin
                oe  <= 4'b0000;
                cmd <= {cmd[6:0], data_in[0]};
            end else begin
                case (cmd)
                    // ==============================================================================================================================
                    // Standard Read
                    // ==============================================================================================================================
                    8'h03: begin
                        if (cnt >= 8 && cnt < 32) begin
                            oe <= 4'b0000;
                            shift_addr <= next_shift_addr_1bit;
                            if (cnt == 31) begin
                                addr_latched_sclk <= next_shift_addr_1bit[ADDR_WIDTH-1:0];
                                req_toggle_sclk   <= ~req_toggle_sclk; 
                            end
                        end else begin
                            oe <= 4'b1111;
                            data_out <= {2'b00, sclk_mem_buf[7 - ((cnt - 32) % 8)], 1'b0};
                        end
                    end

                    // ==============================================================================================================================
                    // Fast Read
                    // ==============================================================================================================================
                    8'h0B: begin
                        if (cnt >= 8 && cnt < 32) begin
                            oe <= 4'b0000;
                            shift_addr <= next_shift_addr_1bit;
                            if (cnt == 31) begin
                                addr_latched_sclk <= next_shift_addr_1bit[ADDR_WIDTH-1:0];
                                req_toggle_sclk   <= ~req_toggle_sclk; 
                            end
                        end else if (cnt >= 32 && cnt < 40) begin
                            oe <= 4'b0000;
                        end else begin
                            oe <= 4'b1111;
                            data_out <= {2'b00, sclk_mem_buf[7 - ((cnt - 32) % 8)], 1'b0};
                        end
                    end

                    // ==============================================================================================================================
                    // Quad Output Fast Read
                    // ==============================================================================================================================
                    8'h6B: begin
                        if (cnt >= 8 && cnt < 32) begin
                            oe <= 4'b0000;
                            shift_addr <= next_shift_addr_1bit;
                            if (cnt == 31) begin
                                addr_latched_sclk <= next_shift_addr_1bit[ADDR_WIDTH-1:0];
                                req_toggle_sclk   <= ~req_toggle_sclk; 
                            end
                        end else if (cnt >= 32 && cnt < 40) begin
                            oe <= 4'b0000;
                        end else begin
                            oe <= 4'b1111;
                            if ((cnt - 40) & 1'b1)
                                data_out <= sclk_mem_buf[3:0];
                            else
                                data_out <= sclk_mem_buf[7:4];
                        end
                    end

                    // ==============================================================================================================================
                    // Fast Read Quad I/O
                    // ==============================================================================================================================
                    8'hEB: begin
                        if (cnt >= 8 && cnt < 14) begin
                            oe <= 4'b0000;
                            shift_addr <= next_shift_addr_4bit;
                            if (cnt == 13) begin
                                addr_latched_sclk <= next_shift_addr_4bit[ADDR_WIDTH-1:0];
                                req_toggle_sclk   <= ~req_toggle_sclk; 
                            end
                        end 
                        else if (cnt >= 14 && cnt < 22) begin
                            oe <= 4'b0000;
                        end 
                        else begin
                            oe <= 4'b1111;
                            if ((cnt - 22) & 1'b1)
                                data_out <= sclk_mem_buf[3:0];
                            else
                                data_out <= sclk_mem_buf[7:4];
                        end
                    end
                    default: oe <= 4'b0000;
                endcase
            end
        end
    end

// =============================================================================
// BACKEND: MIEN XUNG CLK 100MHz (Reset bang soc_reset_n)
// =============================================================================
    reg [2:0] req_sync_clk;
    reg       state;
    localparam IDLE = 1'b0;
    localparam REQ  = 1'b1;

    always @(posedge clk or negedge soc_reset_n) begin
        if (!soc_reset_n) begin
            req_sync_clk <= 3'b000;
            mem_req      <= 1'b0;
            mem_addr     <= {ADDR_WIDTH{1'b0}};
            state        <= IDLE;
        end else begin
            req_sync_clk <= {req_sync_clk[1:0], req_toggle_sclk};

            case (state)
                IDLE: begin
                    mem_req <= 1'b0;
                    if (req_sync_clk[2] ^ req_sync_clk[1]) begin
                        mem_req  <= 1'b1;
                        mem_addr <= addr_latched_sclk;
                        state    <= REQ;
                    end
                end

                REQ: begin
                    if (mem_rvalid) begin
                        mem_req <= 1'b0;
                        state   <= IDLE;
                    end else begin
                        mem_req <= 1'b1;
                    end
                end
            endcase
        end
    end

// =============================================================================
// CDC DU LIEU TRA VE: Tu CLK -> SCLK (Reset bang soc_reset_n va cs_n)
// =============================================================================
    reg [7:0] clk_mem_latched;
    reg       ack_toggle_clk;

    always @(posedge clk or negedge soc_reset_n) begin
        if (!soc_reset_n) begin
            clk_mem_latched <= 8'h00;
            ack_toggle_clk  <= 1'b0;
        end else if (mem_rvalid) begin
            clk_mem_latched <= mem_rdata;
            ack_toggle_clk  <= ~ack_toggle_clk; 
        end
    end

    reg [2:0] ack_sync_sclk;

    always @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            ack_sync_sclk <= 3'b000;
            sclk_mem_buf  <= 8'h00;
        end else begin
            ack_sync_sclk <= {ack_sync_sclk[1:0], ack_toggle_clk};

            if (ack_sync_sclk[2] ^ ack_sync_sclk[1]) begin
                sclk_mem_buf <= clk_mem_latched;
            end
        end
    end

endmodule