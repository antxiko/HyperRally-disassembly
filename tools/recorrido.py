#!/usr/bin/env python3
"""Dibuja el recorrido de los rivales, ejecutando la aritmetica del cartucho.

El issue #3 pedia los "recorridos" de los coches rivales, y algo grafico. Aqui
no hay ni una captura del emulador: las curvas se dibujan ejecutando en Python
las mismas cuentas que el Z80 hace en el cartucho, y los numeros que no son
cuentas se leen de la ROM. Los ROTULOS son anotacion, con la fuente de
tools/rotulos.py, porque la del cartucho tiene el alfabeto incompleto y un
diagrama sin rotular no se entiende.

  recorrido.png     cuanto se mueve el rival en cada pasada, frente a TU
                    velocidad. El paso lo da 0x7CCB:
                        byte 0 -= (velocidad del jugador - la del rival) >> 4
                    comprobado caso por caso contra el emulador en
                    tools/control_recorrido.py (102 de 102).

  trayectorias.png  lo mismo contado como recorrido: donde esta el rival cuadro
                    a cuadro, con tu coche a tres velocidades.

  franjas.png       por donde te cruza el rival. 0x7D02 mira 0xE121 -la X de TU
                    coche- y reparte en cuatro franjas; el byte 1 que deja es el
                    indice con el que 0x7F99 lee la tabla de 0x7FEE, que se lee
                    aqui DE LA ROM y no se escribe a mano.

Uso: recorrido.py <rom> <org> <notas> <destino>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from graficos import png, rango_por_nombre                  # noqa: E402
import rotulos as R                                         # noqa: E402

# --- lo que el cartucho decide, con su direccion --------------------------
# 0x79A9: base + (R & 3) * 8, con la base segun el bit 2 de la etapa
VELOCIDADES = sorted({b + i * 8 for b in (0x88, 0xA0) for i in range(4)})
# 0x79D8 y 0x7A04: los dos cortes que reparten el dibujo en tres niveles
CORTES = (0x26, 0x38)
SESGO = 0x10                      # el `add a,010h` que precede a los cortes
UMBRAL_CRUCE = 0x17               # 0x6BA0, donde se mueve el RANK
VEL_TOPE = 143                    # medido: el tope con el acelerador clavado

FONDO = (0x16, 0x17, 0x21)
PANEL = (0x1F, 0x21, 0x2E)
REJA = (0x33, 0x36, 0x48)
TINTA = (0xF2, 0xF2, 0xEA)
FLOJO = (0x8A, 0x90, 0xA8)
VERDE = (0x2A, 0x3C, 0x33)
ROJO = (0x3C, 0x2A, 0x33)
# las tres bandas de dibujo, de lejos a cerca
BANDAS = [(0x24, 0x2B, 0x3E), (0x2C, 0x35, 0x48), (0x38, 0x2C, 0x3C)]
NOMBRE_BANDA = ["LEJOS: CUATRO SPRITES", "MEDIO", "CERCA: CASILLAS"]
# una curva por velocidad de rival: frias las lentas, calidas las rapidas
CURVAS = [(0x6E, 0xC8, 0x8A), (0x9A, 0xD4, 0x70), (0xC6, 0xD6, 0x5E),
          (0xE6, 0xC6, 0x54), (0xF0, 0xA2, 0x52), (0xF0, 0x7C, 0x5C),
          (0xE6, 0x5C, 0x6C)]


class Lienzo:
    def __init__(self, w, h, fondo=FONDO):
        self.w, self.h = w, h
        self.px = bytearray(bytes(fondo) * (w * h))

    def pon(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 3
            self.px[i:i + 3] = bytes(c)

    def caja(self, x0, y0, x1, y1, c):
        for y in range(max(0, int(y0)), min(self.h, int(y1))):
            for x in range(max(0, int(x0)), min(self.w, int(x1))):
                self.pon(x, y, c)

    def texto(self, x, y, s, c=TINTA, esc=1):
        return R.escribe(self.pon, x, y, s, c, esc)

    def centrado(self, x0, x1, y, s, c=TINTA, esc=1):
        return self.texto((x0 + x1 - R.ancho(s, esc)) // 2, y, s, c, esc)

    def derecha(self, x, y, s, c=TINTA, esc=1):
        return self.texto(x - R.ancho(s, esc), y, s, c, esc)

    def guardar(self, ruta):
        png(self.w, self.h, self.px, ruta)


def paso(vel, vrival):
    """0x7CCB, instruccion a instruccion. Lo que se le RESTA al byte 0.

    OJO con el cero: el `neg` final de 0x7CD9 sobre un nibble que ya es cero
    deja cero, no -256. Escrito de otra forma salen saltos de una punta a otra
    del diagrama, que fue justo lo que paso al reescribir esto."""
    a = (vel - vrival) & 0xFF
    if vel >= vrival:                          # sub sin acarreo
        return (a >> 4) & 0x0F
    return -((((-a) & 0xFF) >> 4) & 0x0F)      # neg, >>4, neg


def nivel(byte0):
    """0x79D8 / 0x7A04: en que nivel de cercania cae, con el `add a,010h`."""
    a = (byte0 + SESGO) & 0xFF
    return 0 if a < CORTES[0] else (1 if a < CORTES[1] else 2)


# ---------------------------------------------------------------------------
def dibuja_recorrido(ruta):
    """Cuanto se mueve el rival en cada pasada, frente a TU velocidad."""
    esc, izq, arr = 2, 92, 62
    ancho, alto = 256 * esc, 19 * 14
    L = Lienzo(izq + ancho + 132, arr + alto + 74)

    def ay(p):
        return arr + (7 - p) * 14

    L.texto(20, 16, "CUANTO SE ACERCA UN RIVAL EN CADA PASADA", TINTA, 2)
    L.texto(20, 36, "0x7CCB:  SU POSICION += (SU VELOCIDAD - LA TUYA) / 16",
            FLOJO, 1)

    L.caja(izq, arr, izq + ancho, ay(0), VERDE)
    L.caja(izq, ay(0), izq + ancho, arr + alto, ROJO)
    for p in range(-10, 8, 2):
        if p:
            L.caja(izq, ay(p), izq + ancho, ay(p) + 1, REJA)
        L.derecha(izq - 10, ay(p) - 3, "%+d" % p if p else "0", FLOJO)
    for v in range(0, 257, 32):
        L.caja(izq + v * esc, arr, izq + v * esc + 1, arr + alto, REJA)
        L.centrado(izq + v * esc - 12, izq + v * esc + 12, arr + alto + 10,
                   str(v), FLOJO)
    L.caja(izq, ay(0), izq + ancho, ay(0) + 2, TINTA)

    # que significa cada mitad, escrito DENTRO de su mitad
    L.texto(izq + 12, arr + 10, "ARRIBA DEL CERO: LO VAS ALCANZANDO",
            (0x86, 0xC8, 0x96))
    L.texto(izq + 12, arr + alto - 20, "DEBAJO: SE TE ESCAPA", (0xE0, 0x8A, 0x96))

    # el tope de velocidad medido
    for y in range(arr, arr + alto, 8):
        L.caja(izq + VEL_TOPE * esc, y, izq + VEL_TOPE * esc + 1, y + 4, TINTA)
    L.texto(izq + VEL_TOPE * esc + 5, arr - 14, "TU TOPE: 143", TINTA)

    ocupadas = []
    for i, vr in enumerate(VELOCIDADES):
        antes = None
        for v in range(256):
            p = -paso(v, vr)
            x, y = izq + v * esc, ay(p)
            if antes is not None:
                y0, y1 = sorted((antes, y))
                L.caja(x, y0, x + esc, y1 + 3, CURVAS[i])
            L.caja(x, y, x + esc, y + 3, CURVAS[i])
            antes = y
        y = ay(-paso(255, vr)) - 3
        while any(abs(y - o) < 11 for o in ocupadas):
            y += 11
        ocupadas.append(y)
        L.caja(izq + ancho, y + 3, izq + ancho + 8, y + 5, CURVAS[i])
        L.texto(izq + ancho + 12, y, str(vr), CURVAS[i])

    L.texto(izq, arr + alto + 30, "EJE HORIZONTAL: TU VELOCIDAD (0xE085)", FLOJO)
    L.texto(izq, arr + alto + 44,
            "CADA LINEA, UNA DE LAS SIETE VELOCIDADES QUE 0x79A9 LE SORTEA "
            "AL RIVAL (0xE09C)", FLOJO)
    L.derecha(izq - 10, arr - 30, "PASOS", FLOJO)
    L.derecha(izq - 10, arr - 18, "POR PASADA", FLOJO)
    L.guardar(ruta)
    return len(VELOCIDADES)


# ---------------------------------------------------------------------------
def dibuja_trayectorias(ruta, cuadros=150):
    """Donde esta el rival cuadro a cuadro, con tu coche a tres velocidades."""
    esc, izq, arr = 3, 92, 88
    alto, ancho = 256, cuadros * esc
    paneles = [(30, "ARRANCANDO"), (90, "A MEDIO GAS"), (VEL_TOPE, "A TOPE")]
    salto = alto + 62
    L = Lienzo(izq + ancho + 158, arr + salto * len(paneles) + 20)

    L.texto(20, 16, "DONDE ESTA EL RIVAL, CUADRO A CUADRO", TINTA, 2)
    L.texto(20, 36, "LA MISMA CUENTA DE 0x7CCB, REPETIDA "
            "%d CUADROS (UNOS TRES SEGUNDOS)" % cuadros, FLOJO)
    L.texto(20, 50, "CADA LINEA ES UN RIVAL. LO UNICO QUE CAMBIA ENTRE LOS TRES "
            "PANELES ES TU VELOCIDAD", FLOJO)

    for n, (vjug, mote) in enumerate(paneles):
        base = arr + n * salto
        for y in range(alto):
            L.caja(izq, base + y, izq + ancho, base + y + 1, BANDAS[nivel(y)])
        # el titulo del panel
        L.texto(izq, base - 16, "TU VELOCIDAD: %d  (%s)" % (vjug, mote), TINTA)
        # el umbral: aqui es donde el rival esta a tu altura
        for x in range(izq, izq + ancho, 5):
            L.caja(x, base + UMBRAL_CRUCE, x + 3, base + UMBRAL_CRUCE + 1, TINTA)
        L.texto(izq + ancho + 8, base + UMBRAL_CRUCE - 3,
                "A TU ALTURA: AQUI CAMBIA EL RANK", TINTA)
        for y in range(0, alto + 1, 64):
            if y:
                L.caja(izq, base + y, izq + ancho, base + y + 1, REJA)
            L.derecha(izq - 10, base + y - 3, str(min(y, 255)), FLOJO)
        # el nombre de cada banda de dibujo, dentro de su banda
        for b in (0, 1, 2):
            ys = [y for y in range(alto) if nivel(y) == b]
            if ys and n == 0:
                L.texto(izq + 6, base + (min(ys) + max(ys)) // 2 - 3,
                        NOMBRE_BANDA[b], FLOJO)

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
        if n == len(paneles) - 1:
            L.texto(izq, base + alto + 14,
                    "A TOPE, TRES RIVALES SE QUEDAN CLAVADOS: LA DIVISION "
                    "ENTRE 16 REDONDEA SU DIFERENCIA A CERO", FLOJO)
        elif n == 0:
            L.texto(izq, base + alto + 14,
                    "LENTO TU, TE PASAN SIN PARAR: LAS LINEAS DAN LA VUELTA "
                    "ENTERA Y REAPARECEN POR ARRIBA", FLOJO)

    L.derecha(izq - 10, arr - 40, "DISTANCIA", FLOJO)
    L.derecha(izq - 10, arr - 28, "AL RIVAL", FLOJO)
    L.guardar(ruta)
    return [v for v, _ in paneles]


# ---------------------------------------------------------------------------
def dibuja_franjas(rom, org, notas, ruta):
    """Las cuatro franjas del byte 1, con la tabla de 0x7FEE leida de la ROM."""
    ini, fin = rango_por_nombre(notas, "tabla_x_del_cruce")
    tabla = rom[ini - org:fin - org]
    # 0x7D02: los cortes de la X del jugador y el byte 1 que deja cada franja
    cortes = [(0, 0x59, 0), (0x59, 0x71, 3), (0x71, 0x99, 4), (0x99, 0x100, 1)]
    COLOR = {0: (0x6E, 0xC8, 0x8A), 3: (0xE6, 0xC6, 0x54),
             4: (0xF0, 0x8A, 0x58), 1: (0x8E, 0xA8, 0xF0)}

    esc, izq, arr = 3, 60, 96
    L = Lienzo(izq * 2 + 256 * esc, arr + 214)
    L.texto(20, 16, "POR DONDE TE CRUZA UN RIVAL", TINTA, 2)
    L.texto(20, 36, "EL BYTE 1 DE SU FICHA NO DICE DE QUE CARRIL VIENE EL "
            "RIVAL: 0x7D02 LO ESCRIBE", FLOJO)
    L.texto(20, 50, "MIRANDO 0xE121, QUE ES LA X DE TU PROPIO COCHE", FLOJO)

    L.texto(izq, arr - 18, "DONDE ESTA TU COCHE, Y EL BYTE 1 QUE DEJA:", TINTA)
    for x0, x1, v in cortes:
        L.caja(izq + x0 * esc, arr, izq + x1 * esc, arr + 46, COLOR[v])
        L.centrado(izq + x0 * esc, izq + x1 * esc, arr + 8, str(v), FONDO, 3)
        L.centrado(izq + x0 * esc, izq + x1 * esc, arr + 34,
                   "%d-%d" % (x0, x1 - 1), FONDO)
    for x in range(0, 257, 32):
        L.caja(izq + x * esc, arr + 46, izq + x * esc + 1, arr + 54, FLOJO)
        L.centrado(izq + x * esc - 12, izq + x * esc + 12, arr + 58,
                   str(x), FLOJO)

    L.texto(izq, arr + 76, "Y LA X CON LA QUE 0x7F99 LO COMPARA DESPUES, "
            "SACADA DE LA TABLA DE 0x7FEE:", TINTA)
    for x0, x1, v in cortes:
        if v >= len(tabla):
            continue
        xa = izq + (x0 + x1) // 2 * esc
        xb = izq + tabla[v] * esc
        for k in range(31):
            t = k / 30.0
            L.caja(xa + (xb - xa) * t, arr + 92 + k,
                   xa + (xb - xa) * t + 2, arr + 93 + k, COLOR[v])
        L.caja(xb - 1, arr + 123, xb + 2, arr + 140, COLOR[v])
        L.centrado(xb - 14, xb + 14, arr + 144, str(tabla[v]), COLOR[v])
    L.texto(izq, arr + 168, "CASI NINGUNA CAE DEBAJO DE LA FRANJA QUE LA "
            "ELIGIO: POR ESO LAS RAYAS SE CRUZAN", FLOJO)
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

    n = dibuja_recorrido(os.path.join(destino, "recorrido.png"))
    print("  recorrido.png: %d velocidades de rival, con el paso de 0x7CCB" % n)
    vs = dibuja_trayectorias(os.path.join(destino, "trayectorias.png"))
    print("  trayectorias.png: el recorrido con tu coche a %s"
          % ", ".join(str(v) for v in vs))
    tabla = dibuja_franjas(rom, org, notas,
                           os.path.join(destino, "franjas.png"))
    print("  franjas.png: las cuatro franjas de 0x7D02 y la tabla de 0x7FEE (%s)"
          % " ".join("0x%02X" % b for b in tabla))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
