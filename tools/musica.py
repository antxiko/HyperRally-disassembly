#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `ARRANCA_SONIDO` (0x5ED9, A = numero) y corre
`ACTUALIZA_SONIDO` (0x5FB7), que la interrupcion llama cada cuadro. Tres voces
de 14 bytes desde 0xE010; la copia del registro 7 del PSG, en 0xE03A.
Uso:  musica.py registros 0x94 [cuadros] | mp3 0x94 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xBF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x94, "La pieza del estado 6", "The state 6 tune", "`ESTADO_6`"),
    P(0x97, "La pieza del estado 8", "The state 8 tune", "`EST8_SUB2`"),
    P(0x9A, "La pieza del estado 4", "The state 4 tune", "`EST4_SUB6`"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0x90, 0x91, 0x92, 0x93, 0x95, 0x96, 0x98, 0x99, 0x9B, 0x9C)]

PAGINA = motor_musica.pagina_basica(
    "`ACTUALIZA_SONIDO`, 0x5FB7, y `ARRANCA_SONIDO`, 0x5ED9, que le reparte "
    "los canales; lo llama la interrupción",
    "`ACTUALIZA_SONIDO`, 0x5FB7, and `ARRANCA_SONIDO`, 0x5ED9, which hands it "
    "the channels; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la pieza 0x94 entera, 254 cuadros",
      "tune 0x94, whole, 254 frames"),
     ("la pieza 0x9A entera, 386 cuadros, tal como el juego la pide",
      "tune 0x9A, whole, 386 frames, just as the game asks for it"),
     ("la pieza 0x97, sus primeros 401 cuadros",
      "tune 0x97, its first 401 frames")],
    [("Cómo se pide una pieza",
      "`ARRANCA_SONIDO` recibe el número en A: con los seis bits bajos elige "
      "el canal y la prioridad. Los números bajos son efectos y del 0x8D en "
      "adelante hay música de hasta tres voces. Las voces ocupan 14 bytes "
      "cada una desde 0xE010 y 0xE03A guarda la copia del mezclador del PSG, "
      "que el arranque deja en 0xB8. Las pistas «de la tabla» están en la "
      "tabla de pistas pero ninguna rutina las pide con un `ld a`; se "
      "omiten la 0x8D, la 0x8E y la 0x8F, de varios minutos sin repetirse.",
      "How a piece is asked for",
      "`ARRANCA_SONIDO` takes the number in A: the low six bits pick the "
      "channel and the priority. Low numbers are effects and from 0x8D up "
      "there is music of up to three voices. The voices take 14 bytes each "
      "from 0xE010 and 0xE03A holds the copy of the PSG mixer, which start-up "
      "leaves at 0xB8. The tracks marked «in the table» are in the track "
      "table but no routine asks for them with an `ld a`; 0x8D, 0x8E and "
      "0x8F, several minutes long without repeating, are left out.")])

CFG = dict(rom="hyperrally.rom", org=0x4000, frame=0x5FB7, pide=0x5ED9,
           ram=(0xE010, 0xE03B), ram0=[(0xE03A, 0xB8)],
           excluye=[0xE019, 0xE027, 0xE035], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x94, 254, None), (0x9A, 386, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
