# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`ACTUALIZA_SONIDO`, 0x5FB7, y `ARRANCA_SONIDO`, 0x5ED9, que le reparte los canales; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la pieza 0x94 entera, 254 cuadros;
- la pieza 0x9A entera, 386 cuadros, tal como el juego la pide;
- la pieza 0x97, sus primeros 401 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`ARRANCA_SONIDO` recibe el número en A: con los seis bits bajos elige el canal y la prioridad. Los números bajos son efectos y del 0x8D en adelante hay música de hasta tres voces. Las voces ocupan 14 bytes cada una desde 0xE010 y 0xE03A guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`; se omiten la 0x8D, la 0x8E y la 0x8F, de varios minutos sin repetirse.

## Las músicas

**La pieza del estado 6** (0x94)

Lo pide `ESTADO_6`; dura 4,2 s.

<audio controls preload="none" src="../audio/musica_94.mp3?v=d89fef3f"></audio>

**La pieza del estado 8** (0x97)

Lo pide `EST8_SUB2`; dura 28,0 s.

<audio controls preload="none" src="../audio/musica_97.mp3?v=dd379ca1"></audio>

**La pieza del estado 4** (0x9A)

Lo pide `EST4_SUB6`; dura 6,4 s.

<audio controls preload="none" src="../audio/musica_9A.mp3?v=79b7b004"></audio>

**Pista 0x90 de la tabla** (0x90)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 20,4 s.

<audio controls preload="none" src="../audio/musica_90.mp3?v=c944641f"></audio>

**Pista 0x91 de la tabla** (0x91)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,4 s.

<audio controls preload="none" src="../audio/musica_91.mp3?v=914d1ab7"></audio>

**Pista 0x92 de la tabla** (0x92)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,4 s.

<audio controls preload="none" src="../audio/musica_92.mp3?v=5a09caea"></audio>

**Pista 0x93 de la tabla** (0x93)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,4 s.

<audio controls preload="none" src="../audio/musica_93.mp3?v=7ead4fcf"></audio>

**Pista 0x95 de la tabla** (0x95)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 16,4 s y vuelve a empezar en el segundo 16,0.

<audio controls preload="none" src="../audio/musica_95.mp3?v=6c12835b"></audio>

**Pista 0x96 de la tabla** (0x96)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 28,0 s.

<audio controls preload="none" src="../audio/musica_96.mp3?v=b68d1be9"></audio>

**Pista 0x98 de la tabla** (0x98)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,8 s y vuelve a empezar en el segundo 6,4.

<audio controls preload="none" src="../audio/musica_98.mp3?v=18e4139a"></audio>

**Pista 0x99 de la tabla** (0x99)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,8 s y vuelve a empezar en el segundo 6,4.

<audio controls preload="none" src="../audio/musica_99.mp3?v=757fad9d"></audio>

**Pista 0x9B de la tabla** (0x9B)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,4 s.

<audio controls preload="none" src="../audio/musica_9B.mp3?v=73554b22"></audio>

**Pista 0x9C de la tabla** (0x9C)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,4 s.

<audio controls preload="none" src="../audio/musica_9C.mp3?v=65d04f14"></audio>
