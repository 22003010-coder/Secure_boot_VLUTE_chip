# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# Các hàm trợ giúp (Helper Functions) để thao tác bit an toàn
def set_bit(value: int, bit_index: int, bit_val: int) -> int:
    """Gán giá trị bit_val (0 hoặc 1) vào vị trí bit_index của value."""
    if bit_val:
        return value | (1 << bit_index)
    else:
        return value & ~(1 << bit_index)

def toggle_bit(value: int, bit_index: int) -> int:
    """Đảo giá trị bit ở vị trí bit_index của value."""
    return value ^ (1 << bit_index)


@cocotb.test()
async def test_project_smoke(dut):
    cmd = 0xEB
    addr = 0

    """Minimal RTL and gate-level smoke test."""

    dut._log.info("Starting Secure Boot Tiny Tapeout smoke test")

    # Physical-design target: 100 MHz (10 ns period)
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Initialize all Tiny Tapeout inputs.
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Apply active-low reset.
    dut._log.info("Resetting DUT")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)

    # Release reset.
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    # Booting: Bat bit ui_in[0] = 1
    dut._log.info("Booting...")
    dut.ui_in.value = set_bit(int(dut.ui_in.value), 0, 1)
    await ClockCycles(dut.clk, 5)

    # Tat bit ui_in[0] = 0
    dut.ui_in.value = set_bit(int(dut.ui_in.value), 0, 0)
    await ClockCycles(dut.clk, 95)

    # Wait for Master to turn on: Bat bit ui_in[2] = 1
    dut._log.info("Boot Done.")
    dut.ui_in.value = set_bit(int(dut.ui_in.value), 2, 1)
    await ClockCycles(dut.clk, 5)

    # Prepare for transmit data: ui_in[2] = 0, ui_in[1] = 1
    ui_val = int(dut.ui_in.value)
    ui_val = set_bit(ui_val, 2, 0)
    ui_val = set_bit(ui_val, 1, 1)
    dut.ui_in.value = ui_val

    # Waiting for command (8 bits MSB first)
    dut._log.info("Waiting for command...")
    for i in range(8):
        # Dao bit ui_in[1]
        dut.ui_in.value = toggle_bit(int(dut.ui_in.value), 1)

        # Gan bit uio_in[1] theo cmd
        bit_val = (cmd >> (7 - i)) & 1
        dut.uio_in.value = set_bit(int(dut.uio_in.value), 1, bit_val)

        await ClockCycles(dut.clk, 5)

    # Waiting for address (6 bits)
    dut._log.info("Waiting for address...")
    for i in range(6):
        dut.ui_in.value = toggle_bit(int(dut.ui_in.value), 1)
        
        # Gan giu nguyen va cap nhat addr
        dut.uio_in.value = addr
        await ClockCycles(dut.clk, 5)

    # Send data out (20 cycles)
    dut._log.info("Sending data...")
    for i in range(20):
        dut.ui_in.value = toggle_bit(int(dut.ui_in.value), 1)
        await ClockCycles(dut.clk, 5)

    # Done sending data: Bat bit ui_in[2] = 1
    dut._log.info("Done!")
    dut.ui_in.value = set_bit(int(dut.ui_in.value), 2, 1)

    dut._log.info("Secure Boot Tiny Tapeout smoke test passed")
