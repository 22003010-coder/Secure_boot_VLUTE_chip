<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a digital secure boot demonstration.

When `ui_in[0]` is asserted, the design starts a boot sequence. The internal
controller reads firmware data from a small internal ROM, sends the data to a
CRC-32 calculation block, and compares the calculated result with a predefined
CRC value.

The design contains the following RTL blocks:

- Boot controller
- Firmware reader
- Internal firmware ROM
- CRC-32 engine
- CRC comparator

The dedicated output pins indicate the current boot status.

## How to test

The project uses the standard Tiny Tapeout clock and active-low reset inputs.

1. Set `ena` high.
2. Drive `rst_n` low for several clock cycles.
3. Release `rst_n`.
4. Pulse `ui_in[0]` high to start the boot sequence.
5. Return `ui_in[0]` low.
6. Observe the status outputs.

Pin mapping:

| Tiny Tapeout pin | Function |
| --- | --- |
| `ui_in[0]` | Start boot request |
| `uo_out[0]` | SoC reset status |
| `uo_out[1]` | Boot active status |
| `uo_out[2]` | Boot completed status |
| `uo_out[3]` | Boot failure status |

The remaining dedicated inputs and outputs are unused.

All bidirectional pins are configured as inputs by setting `uio_oe` to zero.

## External hardware

No external hardware is required.
