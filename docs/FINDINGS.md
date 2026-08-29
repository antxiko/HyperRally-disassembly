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
a stage's background — and several stages share one. The terrain parameter
0xE061 (from 0x4372) decides the surface: when it is 8 the stage is on water and
0x71AC animates the surface apart.

## It shares the sound player, little else

Measured with the sixteen-bit operands zeroed, Hyper Rally shares the Konami
three-channel sound player and the VDP helpers with the house's other MSX
cartridges, but it is its own program: the state machine, the road engine and
the collisions were read here, from this ROM.
