/*
 * Copyright (c) 2026 Nguyen Minh Nhut VLUTE
 * SPDX-License-Identifier: Apache-2.0
 */
`timescale 1ns / 1ps

`default_nettype none

module tt_um_secure_boot (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire soc_reset_n;
  wire boot_active_led;
  wire boot_done_led;
  wire boot_fail_led;

  chip top_chip (
    .clk              (clk),
    .rst_n            (rst_n),
    .start_boot       (ui_in[0]),
    .soc_reset_n      (soc_reset_n),
    .boot_active_led  (boot_active_led),
    .boot_done_led    (boot_done_led),
    .boot_fail_led    (boot_fail_led)
  );

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[0]   = soc_reset_n;
  assign uo_out[1]   = boot_active_led;
  assign uo_out[2]   = boot_done_led;
  assign uo_out[3]   = boot_fail_led;
  assign uo_out[7:4] = 4'b0000;

  assign uio_out = 8'b00000000;
  assign uio_oe  = 8'b00000000;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0};

endmodule
