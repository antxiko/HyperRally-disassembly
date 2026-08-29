# In the emulator

The listing and every number on this site come from the binary and are
reproducible with `make`. Nothing here was measured by eye.

## Running it

    openmsx -machine Philips_VG_8020 -cart hyperrally.rom

An MSX1 machine is enough; the cartridge maps into page 1 and drives everything
from the frame interrupt.

## What can be measured

To confirm a state or a timing, put a breakpoint and watch the RAM the notes
name: 0xE000 is the main state, 0xE060 the stage, 0xE085 the speed. The
per-frame cost of a routine is the difference of `machine_info time` between a
breakpoint at its entry and one at its `ret`, times 3579545 for Z80 cycles.

Output paths in any Tcl script must be Windows paths, never `/tmp`.
