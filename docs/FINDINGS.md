# Findings

## Konami's hidden mark is here

Behind the filler at the end of the ROM, Konami hid in many cartridges its
catalogue number and the title in katakana. The find is not ours: **Manuel
Pazos** ([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) uncovered it and
explained the format. In Hyper Rally the last eleven bytes, from 0x7FF5, are the
title reversed, its length (8), the **18** of RC-718 in BCD, and the 0xAA that
closes the mark. `tools/marca_konami.py` reads it.

## The whole game is one interrupt

INIT falls into a dead `jr` at 0x404F and never returns. Every frame the
interrupt reads the state at 0xE000 and jumps through the nine-handler table at
0x40AA; inside each handler the sub-state at 0xE001 drives a `djnz` chain. It is
a compact way to run a sequence of screens and phases with two bytes of state.

## The road is a lookup, not geometry

0x68D0 turns the curvature at 0xE074 into an index into the shape table at
0x767C. The stripes move by scrolling a buffer (0x707A) at the speed's pace, and
the depth scaling of roadside objects comes from the tables at 0x6CD5. No
multiplies, no divides: everything the road needs is precomputed in tables.

## Twelve stages from eight composers

0xE060 (1..0x0C) selects, through the table at 0x481A, the routine that composes
a stage's background — and several share one, so eight routines cover the
twelve. 0xE061 (table at 0x4372) is not a terrain code but a **bit field** of
what each stage does differently: bit 1 makes the car skid and softens the wheel
(0x65C7 and 0x6658, the snow), 0x01 is the tunnel, 0x10 the storm, 0x08 the
night. The two tables agree exactly — same composer, same 0xE061 — and that
agreement is what proves the reading:

| Stage | Composer | 0xE061 | What you see |
|---|---|---|---|
| 1, 6 | 0x51B8 | 0x00 | day: cyan sky, green hills |
| 2, 10 | 0x586C | 0x01 | tunnel: black, lights along both walls |
| 3, 9 | 0x5A44 | 0x02 | snow: white ground, mountains behind |
| 4 | 0x5B22 | 0x06 | snow under a banded red sky |
| 5 | 0x5B68 | 0x08 | night: black sky, magenta stars |
| 7 | 0x5D5B | 0x10 | storm: grey sky **and a grey border** |
| 8 | 0x51B8 | 0x40 | stage 1 plus a snowy mountain range |
| 11 | 0x5D86 | 0x20 | desert: ochre ground, pale sky |
| 12 | 0x5E94 | 0x08 | night: dark blue sky, white stars |

0x51B8 is the generic composer: inside it, at 0x51DA, it tests for 0x40 and only
then adds the mountains, which is how stage 8 can share it. And stage 12's
composer calls stage 5's — the other night stage.

## There is no water stage: it is a starfield

An earlier version of this page said that 0xE061 = 8 meant the stage was run on
water. It does not, and Hyper Rally has no water stage;
[theNestruo](https://github.com/theNestruo) pointed it out. 0xE061 = 8 marks the
two **night** stages, 5 and 12, and 0x71AC does not animate a surface — it
scrolls the sky.

The routine writes into sixteen cells of the name table (0x3884 to 0x3930, rows
4 to 9, the strip of sky), listed at 0x7229 next to their two counters. Tiles
0xF3 to 0xFA are a **single pixel** walking the bottom row of the character
(0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01) and 0xFB erases it: eight
sub-positions inside one cell, so each star scrolls at pixel precision, and when
the cycle closes the cell itself steps one column. The delay between steps comes
from the car's speed (table at 0x7215, index = speed >> 5): seventeen frames
stopped, ten flat out. Bit 2 of 0xE075 flips the direction.

## The storm stage throws lightning

0x724B runs only when 0xE061 is 0x10 — stage 7, the one with the grey sky and,
because 0x418E writes 0xEE into VDP register 7, a grey border as well. After a
random wait (0x18, 0x38, 0x58 or 0x78 frames: half a second to two and a half)
it picks one of the four scripts at 0x72D2 — three distinct shapes — drops it
into row 2 of the name table, plays sound 0x43, flashes the border to 0xEF at
0x7276 and puts it back to 0xEE about a tenth of a second later. It is a
lightning bolt, not the fireworks at the finish line this page used to claim.

## It shares the sound player, little else

Measured with the sixteen-bit operands zeroed, Hyper Rally shares the Konami
three-channel sound player and the VDP helpers with the house's other MSX
cartridges, but it is its own program: the state machine, the road engine and
the collisions were read here, from this ROM.
