`timescale 1ns / 1ps
// =============================================================================
// crc32_engine.v
// CRC-32/ISO-HDLC (cach tinh reflected):
//   Init       = 32'hFFFFFFFF
//   Poly ref   = 32'hEDB88320
//   Final XOR  = 32'hFFFFFFFF
//   Xu ly LSB-first
// =============================================================================
module crc32_engine (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,

    input  wire [7:0]  data_in,
    input  wire        data_valid,
    input  wire        data_last,

    output reg  [31:0] crc_out,
    output reg         crc_done
);

    localparam [31:0] CRC_INIT      = 32'hFFFFFFFF;
    localparam [31:0] CRC_POLY_REF  = 32'hEDB88320;
    localparam [31:0] CRC_FINAL_XOR = 32'hFFFFFFFF;

    reg  [31:0] crc_reg;
    reg         busy;
    wire [31:0] crc_after_byte;

    function [31:0] next_crc32_byte;
        input [31:0] crc_in;
        input [7:0]  byte_in;
        integer k;
        reg [31:0] c;
        begin
            c = crc_in ^ {24'h000000, byte_in};

            for (k = 0; k < 8; k = k + 1) begin
                if (c[0])
                    c = (c >> 1) ^ CRC_POLY_REF;
                else
                    c = c >> 1;
            end

            next_crc32_byte = c;
        end
    endfunction

    assign crc_after_byte = next_crc32_byte(crc_reg, data_in);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg  <= CRC_INIT;
            crc_out  <= 32'h00000000;
            crc_done <= 1'b0;
            busy     <= 1'b0;
        end
        else begin
            crc_done <= 1'b0;

            if (start && !busy) begin
                crc_reg <= CRC_INIT;
                crc_out <= 32'h00000000;
                busy    <= 1'b1;
            end
            else if (busy && data_valid) begin
                crc_reg <= crc_after_byte;

                if (data_last) begin
                    crc_out  <= crc_after_byte ^ CRC_FINAL_XOR;
                    crc_done <= 1'b1;
                    busy     <= 1'b0;
                end
            end
        end
    end

endmodule
