`timescale 1ns / 1ps
// =============================================================================
// chip.v - Top-level cho NI Digital Electronics FPGA Board
// FPGA: Spartan-3E XC3S500E-FT256 speed grade -5
//
// Mac dinh UCF:
//   clk        -> GCLK0 50 MHz, pin B8
//   rst_n      -> SW0, pin J11 (OFF = reset, ON = chay)
//   start_boot -> SW1, pin J12 (gat OFF -> ON de bat dau)
//   LED0       -> soc_reset_n / PASS
//   LED1       -> boot_active
//   LED2       -> boot_done
//   LED3       -> boot_fail
// =============================================================================
module chip (
    input  wire clk,
    input  wire rst_n,
    input  wire start_boot,

    output wire soc_reset_n,
    output wire boot_active_led,
    output wire boot_done_led,
    output wire boot_fail_led
);

    // Reset vat ly duoc assert bat dong bo va deassert dong bo 2 chu ky.
    // Cach nay an toan hon khi SW0 co rung tiep diem luc nha reset.
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_sync_ff;
    wire core_rst_n;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_sync_ff <= 2'b00;
        else
            reset_sync_ff <= {reset_sync_ff[0], 1'b1};
    end

    assign core_rst_n = reset_sync_ff[1];

    secure_boot_top #(
        .FIRMWARE_SIZE (16),
        .ADDR_WIDTH    (4),
        .EXPECTED_CRC  (32'hA782E9E1)
    ) u_secure_boot_top (
        .clk         (clk),
        .rst_n       (core_rst_n),
        .start_boot  (start_boot),
        .soc_reset_n (soc_reset_n),
        .boot_active (boot_active_led),
        .boot_done   (boot_done_led),
        .boot_fail   (boot_fail_led)
    );

endmodule
