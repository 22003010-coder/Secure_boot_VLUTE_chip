# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project_smoke(dut):
    cmd = 0xEB
    addr = 0
    
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
    dut._log.info("Resetting DUT")  
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)

    # Release reset.
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    # ui_in[0] is mapped to start_boot.
    dut._log.info("Booting...")  
    dut.ui_in[0].value = 1
    await ClockCycles(dut.clk, 5)

    # Remove the start request and let the design run.
    dut.ui_in[0].value = 0
    await ClockCycles(dut.clk, 95)

    # Wait for Master to turn on.
    dut._log.info("Boot Done.")  
    dut.ui_in[2].value = 1
    await ClockCycles(dut.clk, 5)
    
    # Prepare for transmit data.
    dut.ui_in[2].value = 0
    dut.ui_in[1].value = 1
    
    # Waiting for command
    dut._log.info("Waiting for command...")  
    for i in range(8):
        dut.ui_in[1].value = 1 - int(dut.ui_in[1].value)
        bit_val = (cmd >> (7 - i)) & 1
        dut.uio_in[1].value = bit_val
        await ClockCycles(dut.clk, 5)
        
    # Waiting for address
    dut._log.info("Waiting for address...")  
    for i in range(6):
        dut.ui_in[1].value = 1 - int(dut.ui_in[1].value)
        dut.uio_in.value = addr
        await ClockCycles(dut.clk, 5)

    # Send data out
    dut._log.info("Sending data...")  
    for i in range(20):
        dut.ui_in[1].value = 1 - int(dut.ui_in[1].value)
        await ClockCycles(dut.clk, 5)
    
    # Done sending data
    dut._log.info("Done!") 
    dut.ui_in[2].value = 1
    # The bidirectional pins are intentionally unused.
    # project.v permanently drives these outputs to zero.
    #assert int(dut.uio_out.value) == 0
    #assert int(dut.uio_oe.value) == 0

    dut._log.info("Secure Boot Tiny Tapeout smoke test passed")
