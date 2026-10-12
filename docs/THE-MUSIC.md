# The music

Everything you hear here comes from running the cartridge's own sound engine (`ACTUALIZA_SONIDO`, 0x5FB7, and `ARRANCA_SONIDO`, 0x5ED9, which hands it the channels; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- tune 0x94, whole, 254 frames;
- tune 0x9A, whole, 386 frames, just as the game asks for it;
- tune 0x97, its first 401 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`ARRANCA_SONIDO` takes the number in A: the low six bits pick the channel and the priority. Low numbers are effects and from 0x8D up there is music of up to three voices. The voices take 14 bytes each from 0xE010 and 0xE03A holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`; 0x8D, 0x8E and 0x8F, several minutes long without repeating, are left out.

## The tunes

**The state 6 tune** (0x94)

Asked for by `ESTADO_6`; lasts 4.2 s.

<audio controls preload="none" src="audio/musica_94.mp3?v=d89fef3f"></audio>

**The state 8 tune** (0x97)

Asked for by `EST8_SUB2`; lasts 28.0 s.

<audio controls preload="none" src="audio/musica_97.mp3?v=dd379ca1"></audio>

**The state 4 tune** (0x9A)

Asked for by `EST4_SUB6`; lasts 6.4 s.

<audio controls preload="none" src="audio/musica_9A.mp3?v=79b7b004"></audio>

**Table track 0x90** (0x90)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 20.4 s.

<audio controls preload="none" src="audio/musica_90.mp3?v=c944641f"></audio>

**Table track 0x91** (0x91)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.4 s.

<audio controls preload="none" src="audio/musica_91.mp3?v=914d1ab7"></audio>

**Table track 0x92** (0x92)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.4 s.

<audio controls preload="none" src="audio/musica_92.mp3?v=5a09caea"></audio>

**Table track 0x93** (0x93)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.4 s.

<audio controls preload="none" src="audio/musica_93.mp3?v=7ead4fcf"></audio>

**Table track 0x95** (0x95)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 16.4 s and starts again at second 16.0.

<audio controls preload="none" src="audio/musica_95.mp3?v=6c12835b"></audio>

**Table track 0x96** (0x96)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 28.0 s.

<audio controls preload="none" src="audio/musica_96.mp3?v=b68d1be9"></audio>

**Table track 0x98** (0x98)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.8 s and starts again at second 6.4.

<audio controls preload="none" src="audio/musica_98.mp3?v=18e4139a"></audio>

**Table track 0x99** (0x99)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.8 s and starts again at second 6.4.

<audio controls preload="none" src="audio/musica_99.mp3?v=757fad9d"></audio>

**Table track 0x9B** (0x9B)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.4 s.

<audio controls preload="none" src="audio/musica_9B.mp3?v=73554b22"></audio>

**Table track 0x9C** (0x9C)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.4 s.

<audio controls preload="none" src="audio/musica_9C.mp3?v=65d04f14"></audio>
