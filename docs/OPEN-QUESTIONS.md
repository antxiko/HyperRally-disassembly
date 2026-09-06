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
- **A second writer of byte 0 that never fired.** 0x7CFF writes byte 0 of an
  opponent's record with a value pulled from a nine-byte ring at 0xE0DF, walked
  by the pointer at 0xE0DE. It is behind `cp 0f0h / ret c` on byte 1, and byte 1
  was measured taking only the values 0, 1, 3 and 4 — so over 45 seconds of
  racing, with a write watchpoint on the record, **that write never happened
  once**. What sets byte 1 to 0xF0 or above, and what that ring holds, is not
  settled here.
