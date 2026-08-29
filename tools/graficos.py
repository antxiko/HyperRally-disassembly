#!/usr/bin/env python3
"""Dibuja para la web los graficos que el cartucho lleva DENTRO, desde sus bytes.

Las imagenes de esta web no son ilustraciones traidas de fuera ni capturas del
emulador: se dibujan leyendo los propios bytes del cartucho. Los graficos van
COMPRIMIDOS en guiones de rachas, asi que aqui se ejecuta en Python el mismo
descompresor que el Z80 corre en 0x446D, y lo que sale es la prueba de que la
lectura del binario es correcta: si el rango o el formato estuvieran mal, saldria
ruido en vez de la fuente y los tiles de la carretera.

No se escribe ninguna direccion a mano: el rango se busca por el NOMBRE del
bloque en las anotaciones (`D <inicio> <fin> <nombre> ...`), asi que si un
retrazado lo mueve, la imagen sigue saliendo sin tocar esto.

Lo que dibuja:
  fuente.png  los glifos de 8x8 con los que se escribe todo (digitos y letras)
  tiles.png   los tiles de la carretera y el decorado que siguen a la fuente

Uso: graficos.py <rom> <org> <notas> <docs/imagenes>
"""
import os
import re
import struct
import sys
import zlib

FONDO = (0x20, 0x20, 0x30)
TINTA = (0xF0, 0xF0, 0xE0)
REJA = (0x38, 0x38, 0x4A)


def png(w, h, px, fn):
    raw = b"".join(b"\0" + bytes(px[y * w * 3:(y + 1) * w * 3]) for y in range(h))

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def rango_por_nombre(notas, nombre):
    for linea in open(notas, encoding="utf-8"):
        m = re.match(r"^D\s+0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+)\s+(\S+)", linea)
        if m and m.group(3) == nombre:
            return int(m.group(1), 16), int(m.group(2), 16)
    raise SystemExit("  no hay ningun bloque llamado %r en %s" % (nombre, notas))


def descomprime(rom, org, addr):
    """Equivalente del descompresor de guiones de 0x446D: vuelca a un buffer de
    16 KB de VRAM. Formato: [destino:2] y luego rachas [cuenta][bytes], donde el
    bit alto de la cuenta distingue copia literal de repeticion; 0x00 cierra."""
    vram = bytearray(0x4000)
    p = addr
    while True:
        dest = rom[p - org] | (rom[p - org + 1] << 8)
        p += 2
        wr = dest & 0x3FFF
        while True:
            x = rom[p - org]
            p += 1
            n = x & 0x7F
            if n == 0:
                break
            if x == n:                       # bit alto claro: copia literal
                for _ in range(n):
                    vram[wr & 0x3FFF] = rom[p - org]
                    p += 1
                    wr += 1
            else:                            # bit alto puesto: repite un byte
                val = rom[p - org]
                p += 1
                for _ in range(n):
                    vram[wr & 0x3FFF] = val
                    wr += 1
        if x == 0:                           # cuenta 0 y byte 0: fin de todo
            break
    return vram


def hoja(vram, primero, ultimo, cols=16, esc=3, margen=1):
    """Los patrones de 8x8 de `primero` a `ultimo` en una rejilla."""
    n = ultimo - primero + 1
    filas = (n + cols - 1) // cols
    celda = 8 * esc + margen
    w, h = cols * celda + margen, filas * celda + margen
    px = bytearray(bytes(REJA) * (w * h))

    def pon(x, y, c):
        if 0 <= x < w and 0 <= y < h:
            i = (y * w + x) * 3
            px[i:i + 3] = bytes(c)

    for k in range(n):
        gx = margen + (k % cols) * celda
        gy = margen + (k // cols) * celda
        base = (primero + k) * 8
        for f in range(8):
            v = vram[base + f]
            for c in range(8):
                col = TINTA if (v >> (7 - c)) & 1 else FONDO
                for a in range(esc):
                    for b in range(esc):
                        pon(gx + c * esc + b, gy + f * esc + a, col)
    return w, h, px


def main(argv):
    if len(argv) < 5:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    org = int(argv[2], 0)
    notas, destino = argv[3], argv[4]
    os.makedirs(destino, exist_ok=True)

    ini, _fin = rango_por_nombre(notas, "fuente_y_graficos")
    vram = descomprime(rom, org, ini)

    # La fuente son los glifos con dibujo desde 0x08; los tiles de carretera van
    # detras. Se parten donde el usuario los lee en el listado.
    w, h, px = hoja(vram, 0x08, 0x3D)
    png(w, h, px, os.path.join(destino, "fuente.png"))
    print("  fuente.png: glifos 0x08..0x3D descomprimidos desde 0x%04X" % ini)

    w, h, px = hoja(vram, 0x3E, 0xAE)
    png(w, h, px, os.path.join(destino, "tiles.png"))
    print("  tiles.png: tiles 0x3E..0xAE de la carretera y el decorado")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
