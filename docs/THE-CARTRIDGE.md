# The cartridge

16 KB in page 1 (0x4000–0x7FFF), with no bank switching. The "AB" header
declares only **INIT** (0x4010); STATEMENT, DEVICE and TEXT are zero.

## What INIT does

INIT sets interrupt mode 1, writes a `jp` into the H.KEYI hook (0xFD9A) pointing
at **0x4051**, puts the stack at 0xE800, clears the work RAM 0xE000–0xE7FF, sets
up the VDP and the first screen, and then falls into a `jr` to itself at 0x404F.
From that point on the main program does nothing: the interrupt, once per frame,
runs the whole game.

## The screen

SCREEN 2. The name table is at 0x3800 and the sprite attribute table at 0x3B00.
The cartridge does not store whole screens: it stores compressed scripts that a
decompressor (0x446D, with its `out (c),a` core relocated to 0xE310) unpacks
into VRAM.

## The RAM map

Everything the game touches lives from 0xE000 up, under the stack:

- **0xE000** main state (0..8), the index into the jump table at 0x40AA
- **0xE001** sub-state, split by the `djnz` chains inside each handler
- **0xE004** a frame delay the handlers load and wait out
- **0xE010–0xE03A** the three sound channels, fourteen bytes each
- **0xE055–0xE058** the score and best in BCD
- **0xE060** the stage number (1..0x0C); **0xE061** its terrain parameter
- **0xE074** the road's curvature; **0xE085** the speed
- **0xE120..** the car and rival sprite records
