`timescale 1ns / 1ps
// ==============================================================================================
// quad_spi.v - Module Quad-SPI Dual-Clock (An toan CDC + SoC Reset)
// doc rom va xuat du lieu theo chuan Quad_SPI
// chi hoat dong sau khi soc_reset_n kich hoat
// viec xuat nhap du lieu yeu cau mot xung nhip khac (sclk)
// he thong van hoat dong voi 2 xung bat dong bo (clk - sclk)
// tuy nhien hoat dong che do khong dong bo yeu cau xung sclk duoi 25 MHz
// Fast Read (Burst Read): tan so xung sclk khong dong bo khuyen nghi la 25MHz tro xuong
// Quad Output Fast Read (Burst Read): tan so xung sclk khong dong bo khuyen nghi la 25MHz tro xuong
// Fast Read Quad I/0 (Burst Read): tan so xung sclk khong dong bo khuyen nghi la 25MHz tro xuong
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
    reg [16:0]   cnt;
    reg [7:0]   cmd;
    reg [23:0]  shift_addr;
    reg [7:0]   sclk_mem_buf;
    reg [7:0]   preload_mem;

    reg                  req_toggle_sclk;
    reg [ADDR_WIDTH-1:0] addr_latched_sclk;

    // Tín hiệu trung gian để xử lý part-select đúng chuẩn Verilog
    wire [23:0] next_shift_addr_1bit = {shift_addr[22:0], data_in[0]};
    wire [23:0] next_shift_addr_4bit = {shift_addr[19:0], data_in[3:0]};

    always @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            cnt               <= 16'd0;
            cmd               <= 8'b00000000;
            oe                <= 4'b0000;
            preload_mem       <= 8'b00000000;
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
                    // Fast Read
                    // ==============================================================================================================================
                    8'h0B: begin
                        if (cnt >= 8 && cnt < 32) begin                // Phase Address (24 nhip)
                            oe <= 4'b0000;
                            shift_addr <= next_shift_addr_1bit;
                            if (cnt == 31) begin
                                addr_latched_sclk <= next_shift_addr_1bit[ADDR_WIDTH-1:0];
                                req_toggle_sclk   <= ~req_toggle_sclk; 
                            end
                        end else if (cnt >= 32 && cnt < 40) begin      // Phase Dummy (8 nhip)
                            oe <= 4'b0000;
                            if (cnt == 36) begin
                                sclk_mem_buf <= preload_mem;
                            end
                        end else begin                                 // Phase Data (8 nhip moi Byte)
                            oe <= 4'b1111;
                            data_out <= {2'b00, sclk_mem_buf[7 - ((cnt - 32) % 8)], 1'b0};
                            if (((cnt - 32) % 8) == 0) begin
                                addr_latched_sclk <= addr_latched_sclk + 1;
                                req_toggle_sclk   <= ~req_toggle_sclk;
                            end
                            if (((cnt - 32) % 8) == 7) begin
                                sclk_mem_buf <= preload_mem;
                            end
                        end
                    end

                    // ==============================================================================================================================
                    // Quad Output Fast Read
                    // ==============================================================================================================================
                    8'h6B: begin
                        if (cnt >= 8 && cnt < 32) begin                // Phase Address (24 nhip)
                            oe <= 4'b0000;
                            shift_addr <= next_shift_addr_1bit;
                            if (cnt == 31) begin
                                addr_latched_sclk <= next_shift_addr_1bit[ADDR_WIDTH-1:0];
                                req_toggle_sclk   <= ~req_toggle_sclk; 
                            end
                        end else if (cnt >= 32 && cnt < 40) begin      // Phase Dummy (8 nhip)
                            oe <= 4'b0000;
                            if (cnt == 36) begin
                                sclk_mem_buf <= preload_mem;
                                addr_latched_sclk <= addr_latched_sclk + 1;
                                req_toggle_sclk   <= ~req_toggle_sclk;
                            end
                        end else begin                                 // Phase Data (2 nhip moi Byte)
                            oe <= 4'b1111;
                            if ((cnt - 40) & 1'b1) begin
                                data_out <= sclk_mem_buf[3:0];
                                sclk_mem_buf <= preload_mem;
                            end
                            else begin
                                data_out <= sclk_mem_buf[7:4];
                                addr_latched_sclk <= addr_latched_sclk + 1;
                                req_toggle_sclk   <= ~req_toggle_sclk;
                            end
                        end
                    end

                    // ==============================================================================================================================
                    // Fast Read Quad I/O
                    // ==============================================================================================================================
                    8'hEB: begin
                        if (cnt >= 8 && cnt < 14) begin         // Phase Address (6 nhip)
                            oe <= 4'b0000;
                            shift_addr <= next_shift_addr_4bit;
                            if (cnt == 13) begin
                                addr_latched_sclk <= next_shift_addr_4bit[ADDR_WIDTH-1:0];
                                req_toggle_sclk   <= ~req_toggle_sclk; 
                            end
                        end 
                        
                        else if (cnt >= 14 && cnt < 22) begin   // Phase Dummy (8 nhip)
                            oe <= 4'b0000;                            
                            if (cnt == 18) begin
                                sclk_mem_buf <= preload_mem;
                                addr_latched_sclk <= addr_latched_sclk + 1;
                                req_toggle_sclk   <= ~req_toggle_sclk;
                            end
                        end
                        
                        else begin                              // Phase Data (2 nhip moi Byte)
                            oe <= 4'b1111;
                            if ((cnt - 22) & 1'b1) begin
                                data_out <= sclk_mem_buf [3:0];
                                sclk_mem_buf <= preload_mem;
                            end
                            else begin
                                data_out <= sclk_mem_buf [7:4];
                                addr_latched_sclk <= addr_latched_sclk + 1;
                                req_toggle_sclk   <= ~req_toggle_sclk;
                            end
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
            req_sync_clk <= {req_sync_clk[0], req_toggle_sclk};

            case (state)
                IDLE: begin
                    mem_req <= 1'b0;
                    if (req_sync_clk[1] ^ req_sync_clk[0]) begin
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
    reg       mem_rvalid_d; // Thanh ghi de bat suon len của mem_rvalid

    // Tạo tín hiệu Posedge (chỉ active đúng 1 chu kỳ clk duy nhất)
    wire mem_rvalid_posedge = mem_rvalid && !mem_rvalid_d;

    always @(posedge clk or negedge soc_reset_n) begin
        if (!soc_reset_n) begin
            clk_mem_latched <= 8'h00;
            ack_toggle_clk  <= 1'b0;
            mem_rvalid_d    <= 1'b0;
        end else begin
            mem_rvalid_d <= mem_rvalid; // Luu lai gia tri chu ky truoc

            // Chi dao trang thai ack DUNG 1 LAN khi mem_rvalid vua bat len 1
            if (mem_rvalid_posedge) begin
                clk_mem_latched <= mem_rdata;
                ack_toggle_clk  <= ~ack_toggle_clk; 
            end
        end
    end

    reg [2:0] ack_sync_sclk;

    always @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            ack_sync_sclk <= 3'b000;
            sclk_mem_buf  <= 8'h00;
        end else begin
            ack_sync_sclk <= {ack_sync_sclk[1:0], ack_toggle_clk};
            if (ack_sync_sclk[1] ^ ack_sync_sclk[0]) begin
                preload_mem <= clk_mem_latched;
            end
        end
    end

endmodule
