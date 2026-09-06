#!/usr/bin/env python3
"""Los dibujos del rival: como se acerca, y de que esta hecho en cada tramo.

El issue #3 preguntaba por el recorrido de los coches rivales. La parte de la
aritmetica esta en recorrido.py; esto es la otra mitad, la que se ve: un rival
que se acerca NO crece pintando el mismo dibujo mas grande, sino que cambia de
material por el camino. De lejos es un sprite, luego dos, luego cuatro en dos
capas de color, y al llegar encima el cartucho APAGA los sprites y lo repinta
con casillas de la pantalla.

Aqui no hay ni una captura del emulador: la pantalla se monta con carrera.py,
que ejecuta los descompresores del cartucho, y los coches se pintan leyendo los
patrones que esos descompresores dejan en la VRAM. Los ROTULOS son anotacion,
con la fuente de tools/rotulos.py.

  rival_acercandose.png  la escena de la carretera con el mismo rival a cuatro
                         distancias, y al lado de que esta hecho cada uno.
  rival_escala.png       los veinte escalones de la tabla 0x7D94, en fila.
  rival_espejo.png       el coche de cerca, casilla a casilla: la mitad derecha
                         es la izquierda con los bits del reves.

Uso: escena.py <rom> <org> <destino>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import carrera as C                                         # noqa: E402
import rotulos as R                                         # noqa: E402
from graficos import png, PALETA                            # noqa: E402

FONDO = (0x16, 0x17, 0x21)
PANEL = (0x1F, 0x21, 0x2E)
REJA = (0x33, 0x36, 0x48)
TINTA = (0xF2, 0xF2, 0xEA)
FLOJO = (0x8A, 0x90, 0xA8)
ASFALTO = PALETA[14]
MARCA = (0xF0, 0xA2, 0x52)

# Las cuatro distancias que se dibujan, con el carril en el que va cada una.
# El byte 0 de la ficha es la distancia: cuanto MAS grande, mas lejos. El
# carril es el byte 1, y los que el juego usa de verdad son 0, 1, 3 y 4.
PASOS = [(0xC8, 1), (0x88, 1), (0x48, 1), (0x26, 0)]


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

    def marco(self, x0, y0, x1, y1, c):
        self.caja(x0, y0, x1, y0 + 1, c)
        self.caja(x0, y1 - 1, x1, y1, c)
        self.caja(x0, y0, x0 + 1, y1, c)
        self.caja(x1 - 1, y0, x1, y1, c)

    def pega(self, x0, y0, w, h, px):
        for y in range(h):
            for x in range(w):
                i = (y * w + x) * 3
                self.pon(x0 + x, y0 + y, px[i:i + 3])

    def texto(self, x, y, s, c=TINTA, esc=1):
        return R.escribe(self.pon, x, y, s, c, esc)

    def centrado(self, x0, x1, y, s, c=TINTA, esc=1):
        return self.texto((x0 + x1 - R.ancho(s, esc)) // 2, y, s, c, esc)

    def guardar(self, ruta):
        png(self.w, self.h, self.px, ruta)
        print("  %s" % os.path.basename(ruta))


def de_que_esta_hecho(m, byte0, carril):
    """Cuantas piezas y de que tipo, segun la banda en la que cae el byte 0."""
    if C.nivel(byte0) < 2:
        return "casillas", 12
    r = C.rival_lejos(m, byte0, carril)
    return "sprites", len(r[1])


# ---------------------------------------------------------------------------
def dibuja_acercandose(m, ruta, idioma):
    """La escena: el mismo rival a cuatro distancias sobre la carretera, y al
    lado la ficha de lo que el cartucho enciende en cada una."""
    esc, f0, f1 = 2, 3, 22
    m2 = C.pantalla(m.rom, m.org)
    C.prepara_rivales(m2)
    for byte0, carril in PASOS:              # los de casillas van a la pantalla
        if C.nivel(byte0) < 2:
            C.rival_cerca(m2, byte0, carril)
    w, h, px = C.pinta_vram(m2.vram, esc, f0, f1)

    izq, arr, fila, hueco = 24, 82, 84, 30
    ancho_ficha = 372
    alto_fichas = 4 * fila + hueco - 10
    L = Lienzo(izq + w + 22 + ancho_ficha + 24,
               arr + max(h, alto_fichas) + 44)
    L.pega(izq, arr, w, h, px)
    L.marco(izq - 1, arr - 1, izq + w + 1, arr + h + 1, REJA)

    def pon(x, y, c):
        L.pon(izq + x, arr + y - f0 * 8 * esc, c)

    for byte0, carril in PASOS:
        if C.nivel(byte0) >= 2:
            for (y, x, pat, col) in C.rival_lejos(m2, byte0, carril)[1]:
                C.pinta_sprite(pon, m2.vram, y, x, pat, col, esc)
    for (y, x, pat, col) in C.coche_jugador(m2):
        C.pinta_sprite(pon, m2.vram, y, x, pat, col, esc)

    # el numerito que ata cada coche de la escena con su ficha de la derecha
    for i, (byte0, carril) in enumerate(PASOS):
        if C.nivel(byte0) < 2:
            hl = C.rival_cerca(m2, byte0, carril)
            cy = ((hl - 0x3800) // 32) * 8 * esc
            cx = ((hl - 0x3800) % 32) * 8 * esc + 34 * esc
        else:
            s = C.rival_lejos(m2, byte0, carril)[1]
            cy, cx = (s[0][0] + 3) * esc, s[0][1] * esc - 16
        y = arr + cy - f0 * 8 * esc
        L.caja(izq + cx - 3, y - 3, izq + cx + 12, y + 12, FONDO)
        L.texto(izq + cx + 1, y + 1, str(i + 1), MARCA)

    t = ("HOW A RIVAL COMES CLOSER" if idioma == "en"
         else "COMO SE ACERCA UN RIVAL")
    p = ("THE SAME CAR AT FOUR DISTANCES. FAR AWAY IT IS SPRITES; ON THE LAST "
         "STEP THE CARTRIDGE SWITCHES" if idioma == "en" else
         "EL MISMO COCHE A CUATRO DISTANCIAS. DE LEJOS ES SPRITES; EN EL "
         "ULTIMO ESCALON EL CARTUCHO")
    p2 = ("THEM OFF (0x7B21) AND REPAINTS IT WITH SCREEN TILES."
          if idioma == "en" else
          "LOS APAGA (0x7B21) Y LO REPINTA CON CASILLAS DE LA PANTALLA.")
    L.texto(izq, 24, t, TINTA, 2)
    L.texto(izq, 50, p, FLOJO, 1)
    L.texto(izq, 64, p2, FLOJO, 1)

    # las cuatro fichas
    x0 = izq + w + 22
    for i, (byte0, carril) in enumerate(PASOS):
        y0 = arr + i * fila + (hueco if C.nivel(byte0) < 2 else 0)
        casillas = C.nivel(byte0) < 2
        L.caja(x0, y0, x0 + ancho_ficha, y0 + fila - 10, PANEL)
        L.caja(x0, y0, x0 + 3, y0 + fila - 10, MARCA if casillas else REJA)
        L.texto(x0 + 14, y0 + 10, str(i + 1), MARCA, 2)
        # el recorte, sobre el gris del asfalto
        cx, cy, cw, ch = x0 + 40, y0 + 8, 34 * 2, fila - 26
        L.caja(cx, cy, cx + cw, cy + ch, ASFALTO)
        if casillas:
            hl = C.rival_cerca(m2, byte0, carril)
            f, c = (hl - 0x3800) // 32, (hl - 0x3800) % 32
            for fy in range(3):
                for cxx in range(4):
                    pinta_casilla(L, m2.vram, f + fy, c + cxx,
                                  cx + (cw - 64) // 2 + cxx * 16,
                                  cy + (ch - 48) // 2 + fy * 16, 2)
            n, alto_px = 12, (24, 32)
            base = ("TILES 0x24-0x2E" if idioma == "en"
                    else "CASILLAS 0x24-0x2E")
        else:
            s = C.rival_lejos(m2, byte0, carril)[1]
            oy = min(y for y, _x, _p, _c in s)
            ox = min(x for _y, x, _p, _c in s)
            an = 32 if len(s) > 1 else 16
            for (y, x, pat, col) in s:
                C.pinta_sprite(lambda a, b, c2: L.pon(a, b, c2), m2.vram,
                               y - oy, x - ox, pat, col, 2,
                               dx=cx + (cw - an * 2) // 2,
                               dy=cy + (ch - 32) // 2 - 2)
            n, alto_px = len(s), (16, an)
            base = ("PATTERN 0x%02X" if idioma == "en"
                    else "PATRON 0x%02X") % s[0][2]
        tx = cx + cw + 16
        if idioma == "en":
            s1 = ("%d SCREEN TILES" % n if casillas
                  else "%d SPRITE%s" % (n, "" if n == 1 else "S"))
            s2 = "%d x %d PIXELS, %s" % (alto_px[1], alto_px[0], base)
            s3 = "BYTE 0 = 0x%02X" % byte0
        else:
            s1 = ("%d CASILLAS DE PANTALLA" % n if casillas
                  else "%d SPRITE%s" % (n, "" if n == 1 else "S"))
            s2 = "%d x %d PIXELES, %s" % (alto_px[1], alto_px[0], base)
            s3 = "BYTE 0 = 0x%02X" % byte0
        L.texto(tx, y0 + 12, s1, MARCA if casillas else TINTA)
        L.texto(tx, y0 + 28, s2, FLOJO)
        L.texto(tx, y0 + 42, s3, FLOJO)
        if not casillas and len(s) == 4:
            L.texto(tx, y0 + 56, "DOS CAPAS DE COLOR" if idioma == "es"
                    else "TWO COLOUR LAYERS", FLOJO)

    # la raya de la frontera, entre el ultimo de sprites y el de casillas
    yf = arr + 3 * fila + 6
    L.caja(x0, yf, x0 + ancho_ficha, yf + 1, MARCA)
    L.texto(x0 + 4, yf + 6,
            "0x7B21: Y = 0xE0 ON ALL FOUR SPRITES" if idioma == "en"
            else "0x7B21: Y = 0xE0 EN LOS CUATRO SPRITES", MARCA)

    pie = ("DRAWN FROM THE CARTRIDGE: THE SCREEN IS BUILT BY RUNNING ITS OWN "
           "DECOMPRESSORS (0x44B0, 0x4529) AND THE CARS ARE ITS OWN PATTERNS."
           if idioma == "en" else
           "DIBUJADO DESDE EL CARTUCHO: LA PANTALLA SE MONTA EJECUTANDO SUS "
           "DESCOMPRESORES (0x44B0, 0x4529) Y LOS COCHES SON SUS PATRONES.")
    L.texto(izq, arr + max(h, alto_fichas) + 18, pie, FLOJO)
    L.guardar(ruta)


# ---------------------------------------------------------------------------
def dibuja_escala(m, ruta, idioma):
    """Los escalones de la tabla 0x7D94, uno al lado de otro.

    El vigesimo (indice 19, patron 0x88) NO entra: sus patrones no son el coche
    en perspectiva sino el coche DE LADO, y pide un byte 0 de 0xF0 para arriba,
    que es justo el valor con el que MUEVE_RIVAL (0x7CA2) decide que el rival
    ya no va delante. Se dice en el pie y no se dibuja como si fuera escala."""
    esc, celda, alto = 2, 72, 96
    vistos = []
    for idx in range(19):                    # el 19 se queda fuera, ver arriba
        pat = m.rb(0x7D94 + idx * 2)
        if not vistos or vistos[-1][1] != pat:
            vistos.append((idx, pat))
    arr, marg = 104, 20
    L = Lienzo(marg + (len(vistos) + 1) * celda + marg,
               arr + alto + 76)

    m2 = C.pantalla(m.rom, m.org)
    C.prepara_rivales(m2)
    for i, (idx, pat) in enumerate(vistos):
        x0 = marg + i * celda
        L.caja(x0, arr, x0 + celda - 8, arr + alto, ASFALTO)
        byte0 = ((idx + 5) * 8) if idx < 13 else ((idx - 4) * 16)
        r = C.rival_lejos(m2, byte0, 0)
        s = r[1]
        oy = min(y for y, _x, _p, _c in s)
        ox = min(x for _y, x, _p, _c in s)
        an = 32 if len(s) > 1 else 16
        for (y, x, p2, col) in s:
            C.pinta_sprite(lambda a, b, c2: L.pon(a, b, c2), m2.vram,
                           y - oy, x - ox, p2, col, esc,
                           dx=x0 + (celda - 8 - an * esc) // 2,
                           dy=arr + alto - 20 - 16 * esc)
        L.centrado(x0, x0 + celda - 8, arr + alto + 8, str(len(s)), TINTA)
        L.centrado(x0, x0 + celda - 8, arr + alto + 22,
                   "0X%02X" % (pat & 0xFC), FLOJO)
        L.centrado(x0, x0 + celda - 8, arr - 16, str(idx), FLOJO)

    x0 = marg + len(vistos) * celda
    L.caja(x0, arr, x0 + celda - 8, arr + alto, ASFALTO)
    L.marco(x0, arr, x0 + celda - 8, arr + alto, MARCA)
    hl = C.rival_cerca(m2, 0x26, 0)
    f, c = (hl - 0x3800) // 32, (hl - 0x3800) % 32
    for fy in range(3):
        for cx in range(4):
            pinta_casilla(L, m2.vram, f + fy, c + cx,
                          x0 + (celda - 8 - 32 * esc) // 2 + cx * 8 * esc,
                          arr + alto - 20 - 24 * esc + fy * 8 * esc, esc)
    L.centrado(x0, x0 + celda - 8, arr + alto + 8, "12", MARCA)
    L.centrado(x0, x0 + celda - 8, arr + alto + 22, "0X24", MARCA)
    L.centrado(x0, x0 + celda - 8, arr - 16,
               "TILES" if idioma == "en" else "CASILLAS", MARCA)

    t = ("THE STEPS OF A RIVAL" if idioma == "en"
         else "LOS ESCALONES DE UN RIVAL")
    p = ("TABLE 0x7D94 GIVES THE BASE PATTERN AND THE HEIGHT ON SCREEN; THE TWO "
         "LOW BITS OF THAT PATTERN SAY HOW MANY SPRITES LIGHT UP (0x7A73)."
         if idioma == "en" else
         "LA TABLA 0x7D94 DA EL PATRON BASE Y LA ALTURA EN PANTALLA; LOS DOS "
         "BITS BAJOS DE ESE PATRON DICEN CUANTOS SPRITES SE ENCIENDEN (0x7A73).")
    p2 = ("THE LAST ONE IS NOT A SPRITE ANY MORE: IT IS FOUR BY THREE SCREEN "
          "TILES, AND BY THEN THE SPRITES ARE OFF."
          if idioma == "en" else
          "EL ULTIMO YA NO ES UN SPRITE: SON CUATRO POR TRES CASILLAS DE LA "
          "PANTALLA, Y PARA ENTONCES LOS SPRITES ESTAN APAGADOS.")
    L.texto(marg, 26, t, TINTA, 2)
    L.texto(marg, 52, p, FLOJO)
    L.texto(marg, 66, p2, FLOJO)
    L.texto(marg, arr + alto + 42,
            "INDEX ABOVE; PIECES AND BASE PATTERN BELOW."
            if idioma == "en" else
            "ARRIBA EL INDICE; DEBAJO LAS PIEZAS Y EL PATRON BASE.", FLOJO)
    L.texto(marg, arr + alto + 56,
            "A TWENTIETH STEP EXISTS (0x88) BUT ITS PATTERNS ARE THE CAR "
            "SIDEWAYS, NOT A SMALLER ONE." if idioma == "en" else
            "HAY UN ESCALON VEINTE (0x88), PERO SUS PATRONES SON EL COCHE DE "
            "LADO, NO UNO MAS PEQUENYO.", FLOJO)
    L.guardar(ruta)


def pinta_casilla(L, vram, fila, col, x0, y0, esc):
    """Una casilla de la tabla de nombres, con su patron y su color."""
    tercio = fila // 8
    t = vram[0x3800 + fila * 32 + col]
    pb, cb = 0x2000 + tercio * 0x800 + t * 8, tercio * 0x800 + t * 8
    for f in range(8):
        linea, color = vram[pb + f], vram[cb + f]
        tinta, papel = PALETA[color >> 4], PALETA[color & 15]
        for x in range(8):
            c = tinta if (linea >> (7 - x)) & 1 else papel
            for a in range(esc):
                for o in range(esc):
                    L.pon(x0 + x * esc + o, y0 + f * esc + a, c)
    return t


# ---------------------------------------------------------------------------
def dibuja_espejo(m, ruta, idioma):
    """El coche de cerca entero, y al lado sus doce casillas una a una."""
    grande, chico = 6, 4
    celda = 8 * chico + 20
    m2 = C.pantalla(m.rom, m.org)
    C.prepara_rivales(m2)
    hl = C.rival_cerca(m2, 0x26, 0)
    f0, c0 = (hl - 0x3800) // 32, (hl - 0x3800) % 32

    izq, arr = 30, 104
    ancho_coche = 32 * grande
    x_desglose = izq + ancho_coche + 44
    L = Lienzo(x_desglose + 4 * celda + 30, arr + 3 * celda + 234)

    for fy in range(3):                      # el coche entero, sin separacion
        for cx in range(4):
            pinta_casilla(L, m2.vram, f0 + fy, c0 + cx,
                          izq + cx * 8 * grande, arr + fy * 8 * grande, grande)
    L.marco(izq - 1, arr - 1, izq + ancho_coche + 1,
            arr + 24 * grande + 1, REJA)

    for fy in range(3):                      # y casilla a casilla
        for cx in range(4):
            x0, y0 = x_desglose + cx * celda, arr + fy * celda
            t = pinta_casilla(L, m2.vram, f0 + fy, c0 + cx, x0, y0, chico)
            L.marco(x0 - 1, y0 - 1, x0 + 8 * chico + 1, y0 + 8 * chico + 1,
                    REJA)
            L.centrado(x0, x0 + 8 * chico, y0 + 8 * chico + 5, "0X%02X" % t,
                       MARCA if cx >= 2 else FLOJO)
    eje = x_desglose + 2 * celda - 10        # el espejo cae entre 2 y 3
    L.caja(eje, arr - 8, eje + 1, arr + 3 * celda - 12, MARCA)

    t = ("HALF A CAR IN THE ROM" if idioma == "en"
         else "MEDIO COCHE EN LA ROM")
    L.texto(izq, 28, t, TINTA, 2)
    L.texto(izq, 54, ("THE RIVAL UP CLOSE, AND ITS TWELVE SCREEN TILES ONE BY "
                      "ONE." if idioma == "en" else
                      "EL RIVAL DE CERCA, Y SUS DOCE CASILLAS DE PANTALLA UNA "
                      "A UNA."), FLOJO)
    lineas = ([
        "THE TWELVE TILE NUMBERS ARE LITERAL IN THE ROM AT 0x7BF3, AND",
        "PREPARE_RIVALS (0x7B67) COPIES THEM INTO THE STRIP BUFFER AT 0xE200.",
        "",
        "BUT ONLY HALF OF THE PATTERNS ARE THERE: 0x2A IS 0x24 WITH ITS BITS",
        "REVERSED, 0x2B IS 0x25, 0x2C IS 0x26, 0x2D IS 0x27 AND 0x2E IS 0x28.",
        "THE CARTRIDGE STORES HALF A CAR AND MIRRORS IT.",
        "",
        "THAT IS NOT A TRICK OF THIS DRAWING: IT IS DESC_DOBLE (0x44B0), WHICH",
        "RUNS THE SAME BLOCK TWICE AND SENDS THE SECOND PASS THROUGH THE",
        "RELOCATED CORE AT 0xE310 WITH BIT 0 OF C SET, SO IT FALLS INTO",
        "INVERT_BITS AT 0xE334. THE SAME TRICK DRAWS THE ROAD.",
        "",
        "0x29 IS ITS OWN MIRROR, WHICH IS WHY IT APPEARS TWICE.",
    ] if idioma == "en" else [
        "LOS DOCE NUMEROS DE CASILLA ESTAN LITERALES EN LA ROM, EN 0x7BF3, Y",
        "PREPARA_RIVALES (0x7B67) LOS COPIA AL BUFFER DE TIRAS DE 0xE200.",
        "",
        "PERO LOS PATRONES SOLO A MEDIAS: 0x2A ES 0x24 CON LOS BITS DEL REVES,",
        "0x2B ES 0x25, 0x2C ES 0x26, 0x2D ES 0x27 Y 0x2E ES 0x28. EL CARTUCHO",
        "GUARDA MEDIO COCHE Y LO REFLEJA.",
        "",
        "NO ES UN INVENTO DE ESTE DIBUJO: ES DESC_DOBLE (0x44B0), QUE PASA EL",
        "MISMO BLOQUE DOS VECES Y LA SEGUNDA LA MANDA POR EL NUCLEO REUBICADO",
        "DE 0xE310 CON EL BIT 0 DE C PUESTO, CON LO QUE CAE EN INVIERTE_BITS",
        "(0xE334). CON EL MISMO TRUCO SE DIBUJA LA CARRETERA.",
        "",
        "0x29 ES SU PROPIO ESPEJO, POR ESO SALE DOS VECES.",
    ])
    y = arr + 3 * celda + 26
    for i, s in enumerate(lineas):
        L.texto(izq, y + i * 14, s, TINTA if i < 2 else FLOJO)
    L.guardar(ruta)


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    org = int(argv[2], 0)
    destino = argv[3]
    os.makedirs(destino, exist_ok=True)
    m = C.Maquina(rom, org)
    for idioma, sufijo in (("es", ""), ("en", "_en")):
        dibuja_acercandose(m, os.path.join(
            destino, "rival_acercandose%s.png" % sufijo), idioma)
        dibuja_escala(m, os.path.join(
            destino, "rival_escala%s.png" % sufijo), idioma)
        dibuja_espejo(m, os.path.join(
            destino, "rival_espejo%s.png" % sufijo), idioma)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
