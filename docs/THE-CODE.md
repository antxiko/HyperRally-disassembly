# The code

## The state machine

The interrupt (0x4051) calls 0x4089 every frame. It reads the word at 0xE000:
the low byte is the **main state**, 0 to 8, and with it a jump through the table
at 0x40AA reaches one of nine handlers; the high byte is the **sub-state**, and
each handler splits it with `djnz` chains. Changing state is a write to 0xE000;
advancing a sub-state is `inc (0xE001)`. There are no other threads: everything
is this one interrupt.

## Drawing from scripts

Nothing on screen is a stored bitmap. Three interpreters build the VRAM:

- **0x446D** unpacks run-length scripts (a count byte, then either a literal run
  or a repeated byte) into the name or pattern table.
- **0x45EC** copies blocks: `[destination][count][bytes]` until a 0xFF.
- **0x455A** draws the big labels, and is copied to RAM (0xE1C0) to run there.

The font and the road tiles are one such script, at 0x4DEA; the website's
pictures are drawn by running that same decompressor in Python.

## The road

There is no perspective math. 0x68D0 reads the curvature at 0xE074 and indexes
the table of road shapes at 0x767C to pick what to draw; 0x707A scrolls the
stripes toward the player; the roadside objects are scaled by depth from the
tables at 0x6CD5.

## The sound

0x5FB7 is the per-frame player: three fourteen-byte channel records at 0xE010,
each reading its melody with a small command interpreter and writing the PSG
through the BIOS. 0x5ED9 starts a melody or effect by number, checking priority
first. It is the framework Konami reused across its MSX cartridges.
