#!/usr/bin/env python3
"""Dibuja el recorrido de los rivales, ejecutando la aritmetica del cartucho.

El issue #3 pedia los "recorridos" de los coches rivales, y algo grafico. Aqui
no hay ni una captura del emulador: las dos imagenes se dibujan ejecutando en
Python las mismas cuentas que el Z80 hace en el cartucho, y los numeros que no
son cuentas se leen de la ROM.

  recorrido.png  la posicion relativa de un rival cuadro a cuadro, una curva
                 por cada una de las siete velocidades que 0x79A9 le puede
                 sortear. El paso lo da 0x7CCB:
                     byte 0 -= (velocidad del jugador - la del rival) >> 4
                 comprobado caso por caso contra el emulador en
                 tools/control_recorrido.py (102 de 102).

  franjas.png    por donde te cruza el rival. 0x7D02 mira 0xE121 -la X de TU
                 coche- y reparte en cuatro franjas; el byte 1 que deja es el
                 indice con el que 0x7F99 lee la tabla de 0x7FEE, que se lee
                 aqui DE LA ROM y no se escribe a mano.

Uso: recorrido.py <rom> <org> <notas> <destino>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from graficos import png, rango_por_nombre, desc_3_tercios   # noqa: E402

# --- lo que el cartucho decide, con su direccion --------------------------
# 0x79A9: base + (R & 3) * 8, con la base segun el bit 2 de la etapa
BASES = {0xA0: "etapas con el bit 2 a cero", 0x88: "etapas 4-7 y 12"}
VELOCIDADES = [b + i * 8 for b in (0x88, 0xA0) for i in range(4)]
VELOCIDADES = sorted(set(VELOCIDADES))
# 0x79D8 y 0x7A04: los dos cortes que reparten el dibujo en tres niveles
CORTES = (0x26, 0x38)
SESGO = 0x10                      # el `add a,010h` que precede a los cortes
UMBRAL_CRUCE = 0x17               # 0x6BA0, donde se cuenta el cruce
VEL_TOPE = 143                    # medido: el tope con el acelerador clavado

FONDO = (0x1A, 0x1A, 0x26)
REJA = (0x2E, 0x2E, 0x40)
TINTA = (0xF0, 0xF0, 0xE0)
APAGADO = (0x6A, 0x6A, 0x80)
# las tres bandas de dibujo, de lejos a cerca
BANDAS = [(0x28, 0x30, 0x48), (0x30, 0x3C, 0x50), (0x3E, 0x30, 0x40)]
# una curva por velocidad de rival: frias las lentas, calidas las rapidas
CURVAS = [(0x7C, 0xD0, 0x7D), (0x9C, 0xD8, 0x66), (0xC8, 0xD8, 0x5A),
          (0xE8, 0xC8, 0x50), (0xF0, 0xA0, 0x50), (0xF0, 0x78, 0x58),
          (0xE8, 0x58, 0x68)]


class Lienzo:
    def __init__(self, w, h, fondo=FONDO):
        self.w, self.h = w, h
        self.px = bytearray(bytes(fondo) * (w * h))

    def pon(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 3
            self.px[i:i + 3] = bytes(c)

    def caja(self, x0, y0, x1, y1, c):
        for y in range(max(0, y0), min(self.h, y1)):
            for x in range(max(0, x0), min(self.w, x1)):
                self.pon(x, y, c)

    def punto(self, x, y, c, r=1):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                self.pon(x + dx, y + dy, c)

    def guardar(self, ruta):
        png(self.w, self.h, self.px, ruta)


def glifos(rom, org, notas):
    """Los patrones de la fuente del cartucho, ya descomprimidos. El digito n
    es el patron 0x10+n (se ve en fuente.png, que sale del mismo bloque)."""
    ini, _ = rango_por_nombre(notas, "fuente_y_graficos")
    vram = bytearray(0x4000)
    desc_3_tercios(rom, org, ini, vram, 0x2000)
    return vram


def cifra(lienzo, vram, x, y, n, c=TINTA, esc=1):
    """Escribe un numero con la fuente DEL CARTUCHO, no con una de fuera."""
    for k, d in enumerate(str(n)):
        base = 0x2000 + (0x10 + int(d)) * 8
        for f in range(8):
            v = vram[base + f]
            for b in range(8):
                if (v >> (7 - b)) & 1:
                    for a in range(esc):
                        for e in range(esc):
                            lienzo.pon(x + k * 8 * esc + b * esc + e,
                                       y + f * esc + a, c)


def paso(vel, vrival):
    """0x7CCB, instruccion a instruccion. Lo que se le RESTA al byte 0."""
    a = (vel - vrival) & 0xFF
    if vel >= vrival:
        return (a >> 4) & 0x0F
    a = (-a) & 0xFF
    return (-((a >> 4) & 0x0F)) & 0xFF - 256


def nivel(byte0):
    """0x79D8 / 0x7A04: en que nivel de cercania cae, y con el `add a,010h`."""
    a = (byte0 + SESGO) & 0xFF
    if a < CORTES[0]:
        return 0
    return 1 if a < CORTES[1] else 2


def dibuja_recorrido(ruta, vram):
    """El paso del rival frente a TU velocidad, una curva por cada velocidad
    que 0x79A9 le puede sortear.

    Lo que se ve es que un rival no tiene recorrido propio: lo que hace depende
    entera y solamente de la diferencia con tu velocidad. Y que la division por
    16 machaca esa diferencia, asi que las siete velocidades distintas se
    quedan en cuatro comportamientos."""
    esc, izq, arr = 2, 52, 24
    ancho, alto = 256 * esc, 23 * 12          # los pasos van de +7 a -11
    L = Lienzo(izq + ancho + 60, arr + alto + 34)

    def ay(p):                                 # el paso p, a pixel
        return arr + (7 - p) * 12

    # la banda de arriba, donde el rival se queda atras y lo adelantas
    L.caja(izq, arr, izq + ancho, ay(0), (0x24, 0x34, 0x2C))
    L.caja(izq, ay(0), izq + ancho, arr + alto, (0x34, 0x28, 0x30))
    # el cero: por encima lo adelantas, por debajo se te escapa
    L.caja(izq, ay(0), izq + ancho, ay(0) + 1, TINTA)
    for p in range(-10, 8, 2):
        if p:
            L.caja(izq, ay(p), izq + ancho, ay(p) + 1, REJA)
        cifra(L, vram, 22 if abs(p) < 10 else 14, ay(p) - 3, abs(p), APAGADO)
    for v in range(0, 257, 32):
        L.caja(izq + v * esc, arr, izq + v * esc + 1, arr + alto, REJA)
        cifra(L, vram, izq + v * esc - 8, arr + alto + 6, v, APAGADO)

    # el tope de velocidad que se midio con el acelerador clavado
    for y in range(arr, arr + alto, 6):
        L.caja(izq + VEL_TOPE * esc, y, izq + VEL_TOPE * esc + 1, y + 3, TINTA)

    ocupadas = []
    for i, vr in enumerate(VELOCIDADES):
        antes = None
        for v in range(256):
            p = -paso(v, vr)                   # lo que se le suma al byte 0
            x, y = izq + v * esc, ay(p)
            if antes is not None:
                y0, y1 = sorted((antes, y))
                L.caja(x, y0, x + esc, y1 + 2, CURVAS[i])
            L.caja(x, y, x + esc, y + 2, CURVAS[i])
            antes = y
        # la etiqueta al final de su curva, bajada si ya hay otra en esa altura
        y = ay(-paso(255, vr)) - 3
        while any(abs(y - o) < 9 for o in ocupadas):
            y += 9
        ocupadas.append(y)
        cifra(L, vram, izq + ancho + 6, y, vr, CURVAS[i])

    L.guardar(ruta)
    return len(VELOCIDADES)


def dibuja_trayectorias(ruta, vram, cuadros=150):
    """Lo mismo, contado como recorrido: donde esta el rival cuadro a cuadro,
    con tu coche a tres velocidades. El byte 0 envuelve, asi que un rival que
    se te escapa reaparece por detras."""
    esc, izq, arr = 3, 46, 18
    alto, ancho = 256, cuadros * esc
    paneles = [(30, "parado"), (90, "a media"), (VEL_TOPE, "a tope")]
    L = Lienzo(izq + ancho + 40, (arr + alto + 22) * len(paneles))

    for n, (vjug, _) in enumerate(paneles):
        base = n * (arr + alto + 22) + arr
        for y in range(alto):
            L.caja(izq, base + y, izq + ancho, base + y + 1, BANDAS[nivel(y)])
        for x in range(izq, izq + ancho, 4):   # el umbral del cruce
            L.caja(x, base + UMBRAL_CRUCE, x + 2, base + UMBRAL_CRUCE + 1, TINTA)
        for y in range(0, alto, 64):
            L.caja(izq, base + y, izq + ancho, base + y + 1, REJA)
            cifra(L, vram, 6, base + y - 3, y, APAGADO)
        cifra(L, vram, izq + ancho + 6, base + 2, vjug, TINTA)

        for i, vr in enumerate(VELOCIDADES):
            p = paso(vjug, vr)
            pos, antes = 0x80, None
            for k in range(cuadros):
                x, y = izq + k * esc, base + pos
                if antes is not None and abs(pos - antes) < 64:
                    y0, y1 = sorted((base + antes, y))
                    L.caja(x, y0, x + esc, y1 + 1, CURVAS[i])
                L.caja(x, y, x + esc, y + 2, CURVAS[i])
                antes = pos
                pos = (pos - p) & 0xFF
    L.guardar(ruta)
    return [v for v, _ in paneles]


def dibuja_franjas(rom, org, notas, ruta, vram):
    """Las cuatro franjas del byte 1, con la tabla de 0x7FEE leida de la ROM."""
    ini, fin = rango_por_nombre(notas, "tabla_x_del_cruce")
    tabla = rom[ini - org:fin - org]
    # 0x7D02: los cortes de la X del jugador y el byte 1 que deja cada franja
    cortes = [(0, 0x59, 0), (0x59, 0x71, 3), (0x71, 0x99, 4), (0x99, 0x100, 1)]
    COLOR = {0: (0x7C, 0xD0, 0x7D), 3: (0xE8, 0xC8, 0x50),
             4: (0xF0, 0x90, 0x58), 1: (0x9C, 0xB0, 0xF0)}

    esc, izq, arr = 3, 16, 20
    L = Lienzo(izq * 2 + 256 * esc, arr + 146)
    for x0, x1, v in cortes:
        L.caja(izq + x0 * esc, arr, izq + x1 * esc, arr + 54, COLOR[v])
        cifra(L, vram, izq + (x0 + x1) // 2 * esc - 8, arr + 20, v, FONDO, 2)
    # debajo, la X con la que 0x7F99 compara la del jugador: sale de la ROM.
    # Cada franja se une con SU X por una diagonal, porque casi ninguna cae
    # debajo de la franja que la elige.
    for x0, x1, v in cortes:
        if v >= len(tabla):
            continue
        xa = izq + (x0 + x1) // 2 * esc
        xb = izq + tabla[v] * esc
        for k in range(41):                    # la diagonal, de la franja a su X
            t = k / 40.0
            L.caja(int(xa + (xb - xa) * t), arr + 58 + k,
                   int(xa + (xb - xa) * t) + 2, arr + 59 + k, COLOR[v])
        L.caja(xb - 1, arr + 99, xb + 2, arr + 108, COLOR[v])
        cifra(L, vram, xb - 12, arr + 110, tabla[v], COLOR[v])
    # la regla de la X del coche del jugador, de 0 a 255
    for x in range(0, 256, 32):
        L.caja(izq + x * esc, arr + 46, izq + x * esc + 1, arr + 54, TINTA)
        cifra(L, vram, izq + x * esc - 8, arr + 128, x, APAGADO)
    L.guardar(ruta)
    return tabla


def main(argv):
    if len(argv) < 5:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    org = int(argv[2], 0)
    notas, destino = argv[3], argv[4]
    os.makedirs(destino, exist_ok=True)
    vram = glifos(rom, org, notas)

    n = dibuja_recorrido(os.path.join(destino, "recorrido.png"), vram)
    print("  recorrido.png: %d velocidades de rival, con el paso de 0x7CCB" % n)
    vs = dibuja_trayectorias(os.path.join(destino, "trayectorias.png"), vram)
    print("  trayectorias.png: el recorrido con tu coche a %s"
          % ", ".join(str(v) for v in vs))
    tabla = dibuja_franjas(rom, org, notas,
                           os.path.join(destino, "franjas.png"), vram)
    print("  franjas.png: las cuatro franjas de 0x7D02 y la tabla de 0x7FEE (%s)"
          % " ".join("0x%02X" % b for b in tabla))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
