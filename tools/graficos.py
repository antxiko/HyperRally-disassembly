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

# La paleta del TMS9918 tal como la miden las tablas al uso.
PALETA = [
    (0, 0, 0), (0, 0, 0), (62, 184, 73), (116, 208, 125),
    (89, 85, 224), (128, 118, 241), (185, 94, 81), (101, 219, 239),
    (219, 101, 89), (255, 137, 125), (204, 195, 94), (222, 208, 135),
    (58, 162, 65), (183, 102, 181), (204, 204, 204), (255, 255, 255),
]

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


def descomprime_en(rom, org, addr, vram, dest):
    """El descompresor de rachas entrando por DESC_ABRE (0x4475), que es donde
    el destino de VRAM lo trae el llamador en HL y NO el flujo.

    Cual de los dos casos es cual lo dice 0x4480: `cp b / jr z,DESC_REPITE`.
    Con el bit alto CLARO el byte entero vale lo que la cuenta, salta a
    DESC_REPITE y ese lee UN byte fuera del bucle -o sea repeticion-; con el
    bit alto puesto cae en DESC_COPIA, que lee uno DENTRO del bucle -o sea
    copia literal-. Devuelve donde se quedo y el byte que lo cerro: 0x00 acaba
    del todo y 0x80 dice que detras viene otro destino.
    """
    p, wr = addr, dest & 0x3FFF
    while True:
        x = rom[p - org]
        p += 1
        n = x & 0x7F
        if n == 0:
            return p, x
        if x != n:                           # bit alto puesto: copia literal
            for _ in range(n):
                vram[wr & 0x3FFF] = rom[p - org]
                p += 1
                wr += 1
        else:                                # bit alto claro: repite un byte
            val = rom[p - org]
            p += 1
            for _ in range(n):
                vram[wr & 0x3FFF] = val
                wr += 1


def descomprime(rom, org, addr, vram=None):
    """El mismo, entrando por DESC_BLOQUE (0x446F): cada bloque trae delante su
    destino de VRAM, y el 0x80 encadena con otro. Devuelve tambien donde se
    quedo, que es como se comprueba de verdad que el formato esta bien leido:
    la fuente de 0x4DEA tiene que acabar JUSTO en 0x518E, que es el guion que
    DIBUJA_MARCO vuelca a continuacion."""
    if vram is None:
        vram = bytearray(0x4000)
    p = addr
    while True:
        dest = rom[p - org] | (rom[p - org + 1] << 8)
        p += 2
        p, x = descomprime_en(rom, org, p, vram, dest)
        if x == 0:
            return vram, p


def desc_3_tercios(rom, org, addr, vram, dest):
    """DESC_3_TERCIOS (0x461C): el mismo bloque en los tres tercios."""
    for tercio in range(3):
        fin, _ = descomprime_en(rom, org, addr, vram, dest + tercio * 0x800)
    return fin


def guion(rom, org, p, vram):
    """VUELCA_GUION (0x45EC), el OTRO interprete: del flujo sale la casilla de
    VRAM y luego los bytes tal cual; 0xFE trae otra casilla y 0xFF lo acaba."""
    dest = rom[p - org] | (rom[p - org + 1] << 8)
    p += 2
    while True:
        x = rom[p - org]
        p += 1
        if x == 0xFF:
            return p
        if x == 0xFE:
            dest = rom[p - org] | (rom[p - org + 1] << 8)
            p += 2
            continue
        vram[dest & 0x3FFF] = x
        dest += 1


def vram_del_titulo(rom, org, fuente):
    """La pantalla del titulo, montada con los mismos pasos del cartucho:
    DIBUJA_MARCO (0x4D8E) para la fuente y los colores, DIBUJA_PANEL_JUEGO
    (0x4878) para el resto de la tabla de color, y el guion de 0x4C9E que
    vuelca PREPARA_PANTALLA_CARRERA (0x4451), que es el que trae el rotulo."""
    vram = bytearray(0x4000)
    desc_3_tercios(rom, org, fuente, vram, 0x2000)
    descomprime(rom, org, 0x518E, vram)
    for i in range(0x10):                    # 0x4D9D: tile n con el color n
        for tercio in range(3):
            for j in range(8):
                vram[(tercio * 0x800 + i * 8 + j) & 0x3FFF] = i
    for tercio in range(3):                  # 0x4DB4: la franja en blanco
        for j in range(0x278):
            vram[(0x80 + tercio * 0x800 + j) & 0x3FFF] = 0xF0
    for j in range(0x20):                    # 0x4DC3: y un tono menos
        vram[(0xE0 + j) & 0x3FFF] = 0xE0
    descomprime(rom, org, 0x488A, vram)
    guion(rom, org, 0x4C9E, vram)
    return vram


def marco(vram, desde=0):
    """Las cuatro esquinas de lo escrito en la tabla de nombres, contando solo
    los tiles a partir de `desde`. El guion de 0x4C9E pinta el rotulo con los
    tiles de dibujo (0x3E y arriba) y las dos lineas de debajo con los glifos
    de la fuente (por debajo de 0x3E), asi que con desde=0x3E salen las
    esquinas del rotulo y de nada mas. No hay ningun recorte a ojo."""
    o = [(f, c) for f in range(24) for c in range(32)
         if vram[0x3800 + f * 32 + c] >= max(desde, 1)]
    return (min(f for f, _ in o), max(f for f, _ in o),
            min(c for _, c in o), max(c for _, c in o))


def pinta(vram, f0, f1, c0, c1, esc=2):
    """Las casillas [f0,f1]x[c0,c1] como las lee el VDP en SCREEN 2."""
    w, h = (c1 - c0 + 1) * 8 * esc, (f1 - f0 + 1) * 8 * esc
    px = bytearray(w * h * 3)
    for fila in range(f0, f1 + 1):
        tercio = fila // 8
        for col in range(c0, c1 + 1):
            t = vram[0x3800 + fila * 32 + col]
            pb, cb = 0x2000 + tercio * 0x800 + t * 8, tercio * 0x800 + t * 8
            for f in range(8):
                linea, color = vram[pb + f], vram[cb + f]
                tinta, papel = PALETA[color >> 4], PALETA[color & 15]
                for x in range(8):
                    c = tinta if (linea >> (7 - x)) & 1 else papel
                    for dy in range(esc):
                        base = ((((fila - f0) * 8 + f) * esc + dy) * w
                                + ((col - c0) * 8 + x) * esc) * 3
                        for dx in range(esc):
                            px[base + dx * 3:base + dx * 3 + 3] = bytes(c)
    return w, h, px


def hoja(vram, primero, ultimo, cols=16, esc=3, margen=1, origen=0x2000):
    """Los patrones de 8x8 de `primero` a `ultimo` en una rejilla. El origen es
    donde el cartucho pone la tabla de patrones: 0x2000, no 0 (registro 4 del
    VDP = 0x07, en la tabla de 0x4651)."""
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
        base = origen + (primero + k) * 8
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

    # DIBUJA_MARCO (0x4D8E) entra por DESC_3_TERCIOS con HL=0x2000: el destino
    # lo pone EL LLAMADOR, no el flujo. Que acabe justo en 0x518E -el guion
    # siguiente- es la prueba de que el formato esta bien leido.
    vram = bytearray(0x4000)
    fin = desc_3_tercios(rom, org, ini, vram, 0x2000)
    if fin != 0x518E:
        raise SystemExit("  la fuente tenia que acabar en 0x518E y acabo en 0x%04X"
                         % fin)

    # La fuente son los glifos con dibujo desde 0x08; los tiles de carretera van
    # detras. Se parten donde el usuario los lee en el listado.
    w, h, px = hoja(vram, 0x08, 0x3D)
    png(w, h, px, os.path.join(destino, "fuente.png"))
    print("  fuente.png: glifos 0x08..0x3D descomprimidos desde 0x%04X" % ini)

    w, h, px = hoja(vram, 0x3E, 0xAE)
    png(w, h, px, os.path.join(destino, "tiles.png"))
    print("  tiles.png: tiles 0x3E..0xAE de la carretera y el decorado")

    # La pantalla del titulo entera, y de ella el rotulo solo. El marco no se
    # recorta a ojo: el guion de 0x4C9E pinta el rotulo y nada mas, asi que las
    # esquinas de lo escrito SON las del rotulo.
    v2 = vram_del_titulo(rom, org, ini)
    png(*pinta(v2, 0, 23, 0, 31), os.path.join(destino, "titulo.png"))
    print("  titulo.png: la pantalla del titulo, montada con el guion de 0x4C9E")
    f0, f1, c0, c1 = marco(v2, 0x3E)
    png(*pinta(v2, f0, f1, c0, c1, esc=4), os.path.join(destino, "rotulo.png"))
    print("  rotulo.png: el rotulo Hyper Rally, filas %d a %d y columnas %d a %d"
          % (f0, f1, c0, c1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
