`timescale 1ns / 1ps
// =============================================================================
// firmware_rom.v
// ROM firmware tong hop duoc boi Xilinx XST / ISE 14.7.
// Firmware 16 byte:
// 10 21 32 43 54 65 76 87 98 A9 BA CB DC ED FE 8F
// CRC32 chuan: 32'hA782E9E1
// =============================================================================
module firmware_rom #(
    parameter integer ADDR_WIDTH = 4
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  mem_req,
    input  wire [ADDR_WIDTH-1:0] mem_addr,

    output reg  [7:0]            mem_rdata,
    output reg                   mem_rvalid
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_rdata  <= 8'h00;
            mem_rvalid <= 1'b0;
        end
        else begin
            mem_rvalid <= 1'b0;

            if (mem_req) begin
                mem_rvalid <= 1'b1;

                case (mem_addr)
                    0:  mem_rdata <= 8'h10;
                    1:  mem_rdata <= 8'h21;
                    2:  mem_rdata <= 8'h32;
                    3:  mem_rdata <= 8'h43;
                    4:  mem_rdata <= 8'h54;
                    5:  mem_rdata <= 8'h65;
                    6:  mem_rdata <= 8'h76;
                    7:  mem_rdata <= 8'h87;
                    8:  mem_rdata <= 8'h98;
                    9:  mem_rdata <= 8'hA9;
                    10: mem_rdata <= 8'hBA;
                    11: mem_rdata <= 8'hCB;
                    12: mem_rdata <= 8'hDC;
                    13: mem_rdata <= 8'hED;
                    14: mem_rdata <= 8'hFE;
                    15: mem_rdata <= 8'h8F;
                    default: mem_rdata <= 8'h00;
                endcase
            end
        end
    end

endmodule
