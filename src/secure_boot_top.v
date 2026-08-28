`timescale 1ns / 1ps
// =============================================================================
// secure_boot_top.v
// Tich hop controller, reader, ROM, CRC engine va comparator.
// =============================================================================
module secure_boot_top #(
    parameter integer FIRMWARE_SIZE = 16,
    parameter integer ADDR_WIDTH    = 4,
    parameter [31:0]  EXPECTED_CRC  = 32'hA782E9E1
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start_boot,
    
    input  wire       sclk,
    input  wire       cs_n,
    input  wire [3:0] data_in,
    output wire [3:0] data_out,
    output wire [3:0] oe,

    output wire       soc_reset_n,
    output wire       boot_active,
    output wire       boot_done,
    output wire       boot_fail

);

    wire reader_start;
    wire crc_start;
    wire compare_start;

    wire                  reader_req;
    wire [ADDR_WIDTH-1:0] reader_addr;
    wire                  spi_req;
    wire [ADDR_WIDTH-1:0] spi_addr;

    wire                  mem_req;
    wire [ADDR_WIDTH-1:0] mem_addr;
    wire [7:0]            mem_rdata;
    wire                  mem_rvalid;

    wire [7:0] firmware_data;
    wire       firmware_valid;
    wire       firmware_last;

    wire [31:0] calculated_crc;
    wire        crc_done;

    wire crc_match;
    wire compare_done;

    assign boot_fail = boot_done & ~soc_reset_n;

    assign mem_req  = soc_reset_n? spi_req  : reader_req;
    assign mem_addr = soc_reset_n? spi_addr : reader_addr;

    boot_controller u_boot_controller (
        .clk           (clk),
        .rst_n         (rst_n),
        .start_boot    (start_boot),
        .crc_done      (crc_done),
        .compare_done  (compare_done),
        .crc_match     (crc_match),
        .reader_start  (reader_start),
        .crc_start     (crc_start),
        .compare_start (compare_start),
        .soc_reset_n   (soc_reset_n),
        .boot_active   (boot_active),
        .boot_done     (boot_done)
    );

    firmware_reader #(
        .FIRMWARE_SIZE (FIRMWARE_SIZE),
        .ADDR_WIDTH    (ADDR_WIDTH)
    ) u_firmware_reader (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (reader_start),
        .mem_req    (reader_req),
        .mem_addr   (reader_addr),
        .mem_rdata  (mem_rdata),
        .mem_rvalid (mem_rvalid),
        .data_out   (firmware_data),
        .data_valid (firmware_valid),
        .data_last  (firmware_last)
    );

    firmware_rom #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_firmware_rom (
        .clk        (clk),
        .rst_n      (rst_n),
        .mem_req    (mem_req),
        .mem_addr   (mem_addr),
        .mem_rdata  (mem_rdata),
        .mem_rvalid (mem_rvalid)
    );

    crc32_engine u_crc32_engine (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (crc_start),
        .data_in    (firmware_data),
        .data_valid (firmware_valid),
        .data_last  (firmware_last),
        .crc_out    (calculated_crc),
        .crc_done   (crc_done)
    );

    crc_comparator u_crc_comparator (
        .clk            (clk),
        .rst_n          (rst_n),
        .compare_start  (compare_start),
        .calculated_crc (calculated_crc),
        .expected_crc   (EXPECTED_CRC),
        .crc_match      (crc_match),
        .compare_done   (compare_done)
    );

    quad_spi u_quad_spi(
        .sclk           (sclk),
        .cs_n           (cs_n),
        .data_in        (data_in),
        .data_out       (data_out),
        .oe             (oe),
        .clk            (clk),
        .soc_reset_n    (soc_reset_n),
        .mem_req        (spi_req),
        .mem_addr       (spi_addr),
        .mem_rdata      (mem_rdata),
        .mem_rvalid     (mem_rvalid)
);

endmodule
