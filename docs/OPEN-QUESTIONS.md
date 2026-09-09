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
