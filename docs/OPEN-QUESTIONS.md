# Open questions

What the binary does not settle on its own:

- **A drawing routine with no caller.** 0x4DCC draws nineteen rows of sixteen
  bytes from 0x518E, decodes cleanly to its `ret` at 0x4DE9, and yet no
  instruction in the ROM references it. It is disassembled as code, with the
  note that it may be leftover.
- **The exact meaning of each of the nine main states.** They are named by what
  their code does (start of stage, countdown, race, results); tying each number
  to the screen it paints would take a play-through with 0xE000 watched.
- **The melodies are not broken down.** The sound data at 0x61C5 is a table of
  melody pointers followed by the melodies; the player is understood, but each
  tune's notes are not transcribed here.
- **Full-screen rendering.** The website draws the font and the road tiles from
  the ROM; composing a whole stage screen would need the two-layer script
  interpreter (0x44B0) and the road renderer ported to Python too.
- **Code or data at 0x68BE?** On its way back from drawing the odometer, the
  game returns to an address it pushed itself: 0x68BE by day and 0x68C7 by night.
  There are eighteen bytes there that, read raw, look like two nine-byte rows of
  data (`2F 30 34 32 2F 2F 2B 2C 0F` and `30 30 34 31 2F 2F 2B 2D 0F`), and the
  trace lists them as code. Read as code they do odd things: `ld (2F2Fh),a`, at
  0x68C1, writes to the BIOS ROM, which takes no writes. Either it is code that
  depends on the carry the drawing routine returns with, or it is data the trace
  has swallowed. Settling it means checking in the emulator whether the CPU
  really goes through 0x68C1.
