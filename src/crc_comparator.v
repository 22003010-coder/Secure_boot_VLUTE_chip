`timescale 1ns / 1ps
// =============================================================================
// crc_comparator.v
// So sanh CRC tinh duoc voi CRC mong doi.
// =============================================================================
module crc_comparator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        compare_start,
    input  wire [31:0] calculated_crc,
    input  wire [31:0] expected_crc,

    output reg         crc_match,
    output reg         compare_done
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_match    <= 1'b0;
            compare_done <= 1'b0;
        end
        else begin
            compare_done <= 1'b0;

            if (compare_start) begin
                crc_match    <= (calculated_crc == expected_crc);
                compare_done <= 1'b1;
            end
        end
    end

endmodule
