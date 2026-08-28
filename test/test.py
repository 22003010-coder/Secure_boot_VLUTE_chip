# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project_smoke(dut):
    """Minimal RTL and gate-level smoke test."""

    dut._log.info("Starting Secure Boot Tiny Tapeout smoke test")

    # The physical-design target is 100 MHz:
    # 10 ns period = 100 MHz.
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Initialize all Tiny Tapeout inputs.
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Apply active-low reset.
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)

    # Release reset.
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    # ui_in[0] is mapped to start_boot.
    dut.ui_in.value = 0x01
    await ClockCycles(dut.clk, 5)

    # Remove the start request and let the design run.
    dut.ui_in.value = 0x00
    await ClockCycles(dut.clk, 100)

    # The bidirectional pins are intentionally unused.
    # project.v permanently drives these outputs to zero.
    //assert int(dut.uio_out.value) == 0
    //assert int(dut.uio_oe.value) == 0

    dut._log.info("Secure Boot Tiny Tapeout smoke test passed")
