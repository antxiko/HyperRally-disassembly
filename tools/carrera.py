#!/usr/bin/env python3
"""Monta en Python la pantalla de la carrera, ejecutando lo que hace el Z80.

Esto no captura nada del emulador: ejecuta los mismos descompresores e
interpretes del cartucho sobre los mismos bytes, y lo que sale es una VRAM de
16 KB que se puede pintar igual que la pinta el VDP. La prueba de que la
lectura es correcta es el cotejo contra un volcado real (`--coteja`): el guion
de los patrones de sprite sale IGUAL byte a byte, y de las 768 casillas de la
pantalla solo bailan las que el juego repinta cuadro a cuadro.

Las cuatro piezas que hacian falta y no estaban portadas:

  DESC_DOBLE (0x44B0)   dos capas del MISMO bloque; la segunda sale por el
                        nucleo reubicado de 0xE310 con el bit 0 de C puesto, y
                        ese nucleo cae en INVIERTE_BITS (0xE334): la segunda
                        capa es la primera CON LOS BITS DEL REVES. Asi se
                        guarda media carretera -y medio coche rival- y sale
                        entera.
  PINTA_TIRA_1 (0x4529) el otro interprete: por debajo de 0x24 los bytes son
                        control (0x00 cierra la tira, el resto recoloca la
                        escritura), 0xFF sigue un puntero, y lo demas son
                        numeros de casilla que van por el puerto.
  PREPARA_RIVALES       monta en 0xE200 el buffer de tiras con el que se dibuja
    (0x7B67)            el rival de cerca.
  el nucleo de 0xE310   ld a,(de) + INVIERTE_BITS, con el interruptor que
                        FIJA_ORIGEN_DESC / CERO_ORIGEN_DESC (0x45B1 y 0x45B6)
                        conmutan escribiendo sobre el propio codigo.

Uso: carrera.py <rom> <org> [--coteja <vram.bin>]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from graficos import PALETA                                 # noqa: E402

# La curvatura (0xE074) y la fase de animacion (0xE075) de la salida, antes de
# que el scroll las mueva. El parametro de cada etapa -0xE061- sale de la tabla
# de 0x4371, y NO se escribe aqui a mano.
RECTA, PARADO = 0x0000, 8


class Maquina:
    """La ROM, la RAM de trabajo y la VRAM, con el puerto del VDP."""

    def __init__(self, rom, org=0x4000, etapa=1):
        self.rom, self.org = rom, org
        self.etapa = etapa
        # CARGA_PARAM_ETAPA (0x4364): 0xE061 = tabla_param_etapa[0xE060], con la
        # base en el `ret` de 0x4371, que es lo que hace el `ld hl` de 0x4364.
        self.param = rom[0x4371 + etapa - org]
        self.ram = bytearray(0x2000)         # 0xE000..0xFFFF
        self.vram = bytearray(0x4000)
        self.escrito = bytearray(0x4000)     # que casillas ha tocado el flujo
        self.wr = 0
        self.espejo = False                  # el bit 0 de C del descompresor
        self.cero = False                    # el interruptor de 0x45B6

    # --- memoria ---------------------------------------------------------
    def rb(self, a):
        return self.ram[a - 0xE000] if a >= 0xE000 else self.rom[a - self.org]

    def rw(self, a):
        return self.rb(a) | (self.rb(a + 1) << 8)

    def wb(self, a, v):
        self.ram[a - 0xE000] = v

    # --- el puerto del VDP -----------------------------------------------
    def setwrt(self, hl):
        self.wr = hl & 0x3FFF

    def out(self, v):
        self.vram[self.wr] = v
        self.escrito[self.wr] = 1
        self.wr = (self.wr + 1) & 0x3FFF

    def fill(self, hl, n, v):
        for i in range(n):
            self.vram[(hl + i) & 0x3FFF] = v
            self.escrito[(hl + i) & 0x3FFF] = 1

    def wrtvrm(self, hl, v):
        self.vram[hl & 0x3FFF] = v
        self.escrito[hl & 0x3FFF] = 1


def invierte(a):
    """INVIERTE_BITS (0x45E1), que se copia a 0xE334 detras del nucleo."""
    r = 0
    for i in range(8):
        r = (r << 1) | ((a >> i) & 1)
    return r


def nucleo(m, de, espejo):
    """El nucleo reubicado en 0xE310: lee un byte, avanza, y si el bit 0 de C
    esta puesto no retorna sino que cae en INVIERTE_BITS. Con el interruptor de
    0x45B6 (dos ceros sobre el `jr`) ademas traduce los nibbles."""
    a = m.rb(de)
    if m.cero:
        hi, lo = a & 0xF0, a & 0x0F
        a = (0x10 if hi in (0xE0, 0x30) else hi) | (0x01 if lo in (0x0E, 0x03) else lo)
    return (invierte(a) if espejo else a), de + 1


def desc_lee(m, de, espejo=False):
    """DESC_LEE (0x4478). La cuenta lleva en el bit alto si la racha es de
    bytes distintos (copia) o del mismo byte (repeticion): eso lo decide el
    `cp b` de 0x4480, no una bandera aparte. Un 0x00 cierra; un 0x80 encadena
    otro bloque con su destino delante."""
    while True:
        x = m.rb(de)
        n = x & 0x7F
        de += 1
        if n == 0:
            if x != n:                       # 0x80: viene otro destino
                m.setwrt(m.rw(de))
                de += 2
                continue
            return de
        if x == n:                           # bit alto claro: repite
            v, de = nucleo(m, de, espejo)
            for _ in range(n):
                m.out(v)
        else:                                # bit alto puesto: copia
            for _ in range(n):
                v, de = nucleo(m, de, espejo)
                m.out(v)


def desc_bloque(m, de, espejo=False):
    """DESC_BLOQUE (0x446F): el destino de VRAM va delante del bloque."""
    m.setwrt(m.rw(de))
    return desc_lee(m, de + 2, espejo)


def desc_3_tercios(m, de, hl):
    """DESC_3_TERCIOS (0x461C): el mismo bloque en los tres tercios."""
    for _ in range(3):
        m.setwrt(hl)
        fin = desc_lee(m, de)
        hl += 0x800
    return fin


def desc_doble(m, de):
    """DESC_DOBLE (0x44B0). Cada tramo trae DOS cuentas de pasadas; el bit 7 de
    cada una dice que delante viene su destino de VRAM. Las dos capas releen el
    MISMO origen (0xE0D6), y la segunda con los bits del reves."""
    while True:
        n1 = m.rb(de)
        de += 1
        p1 = None
        if n1 & 0x80:
            p1, de = m.rw(de), de + 2
        n2 = m.rb(de)
        de += 1
        p2 = None
        if n2 & 0x80:
            p2, de = m.rw(de), de + 2
        origen = de
        if p1 is not None:
            m.setwrt(p1)
        for _ in range((n1 & 0x7F) or 256):  # el bucle es un do-while
            de = desc_lee(m, origen, False)
        if n2 & 0x7F:
            if p2 is not None:
                m.setwrt(p2)
            for _ in range(n2 & 0x7F):
                de = desc_lee(m, origen, True)
        if m.rb(de) == 0xFF:                 # 0x7514: el `inc a` que cierra
            return de


def guion(m, de):
    """DESCOMPRIME_GUION (0x446D), que es DESC_BLOQUE sin espejo."""
    return desc_bloque(m, de, False)


def pinta_tira(m, de, hl):
    """PINTA_TIRA_1 (0x4529). HL es donde se fijo la escritura por ultima vez,
    NO donde va escribiendo el puerto: por eso un control de avance recoloca
    contando desde HL. Un 0x00 cierra la tira (el `dec a` / `ret m` de 0x4549)
    y un 0x01 mete un bloque comprimido en medio."""
    m.setwrt(hl)
    while True:
        a = m.rb(de)
        de += 1
        if a < 0x24:
            if a == 0:
                return de
            if a == 1:
                m.setwrt(hl)
                de = desc_lee(m, de)
                continue
            hl = (hl + a) & 0xFFFF
            m.setwrt(hl)
            continue
        if a == 0xFF:
            de = m.rw(de)
            continue
        m.out(a)


def sigue_puntero(m, de, hl=None):
    """PINTA_TIRA (0x4523): delante de la tira va su destino de VRAM."""
    return pinta_tira(m, de + 2, m.rw(de))


# --- las rutinas que montan la pantalla ------------------------------------
def dibuja_marco(m):
    """DIBUJA_MARCO (0x4D8E): la fuente en los tres tercios, el guion del marco
    y la tabla de color. Que la fuente acabe JUSTO en 0x518E -donde empieza el
    guion siguiente- es la prueba de que el formato esta bien leido."""
    fin = desc_3_tercios(m, 0x4DEA, 0x2000)
    if fin != 0x518E:
        raise SystemExit("  la fuente tenia que acabar en 0x518E y acabo en 0x%04X"
                         % fin)
    guion(m, 0x518E)
    for i in range(0x10):                    # 0x4D9D: tile n con el color n
        for t in range(3):
            m.fill(i * 8 + t * 0x800, 8, i)
    for t in range(3):                       # 0x4DB4: la franja en blanco
        m.fill(0x0080 + t * 0x800, 0x278, 0xF0)
    m.fill(0x00E0, 0x20, 0xE0)               # 0x4DC3: y un tono menos


def dibuja_panel(m):
    """DIBUJA_PANEL_JUEGO (0x4878). El nombre enganya: ademas del salpicadero,
    este guion es el que carga los PATRONES DE SPRITE en 0x1800."""
    guion(m, 0x488A)
    if m.param & 0x09:                       # 0x487E: el adorno de 0x4BA7
        guion(m, 0x4BA7)


def rellena_3_tercios(m, hl, n, v, tercios=3):
    """RELLENA_3_TERCIOS (0x460B), y su entrada de 0x460D con otro contador."""
    for _ in range(tercios):
        m.fill(hl, n, v)
        hl += 0x800


# Los ocho compositores de fondo, tal como los reparte la tabla de 0x481A. Cada
# uno hace lo que hace su rutina, en su orden; los que reusan a otro lo llaman
# igual que en el cartucho.
def fondo_1(m):
    """FONDO_ETAPA_1 (0x51B8), la primera familia de etapas."""
    desc_doble(m, 0x51F8)
    m.setwrt(0x0920)                         # 0x51BE: el destino lo pone aqui
    desc_doble(m, 0x5406)
    de = desc_doble(m, 0x5406)
    desc_doble(m, de + 1)
    guion(m, 0x54B0)
    if m.param == 0x40:                      # 0x51DA: una etapa suma cordillera
        fondo_3_5A58(m)
    de = desc_doble(m, 0x54F3)
    fondo_1_51E9(m, de + 1)


def fondo_1_51E9(m, de):
    """FONDO_ETAPA_1_51E9: la ultima capa y los patrones de la pista."""
    desc_doble(m, de)
    for i in range(0x38):                    # 0x51EC: 0x4E71 -> 0x3080
        m.wrtvrm(0x3080 + i, m.rb(0x4E71 + i))


def fondo_2(m):
    """FONDO_ETAPA_2 (0x586C): el base mas arboles y vallas. Es el UNICO que
    enciende el remapeo de color de CERO_ORIGEN_DESC (0x45B6), que escribe dos
    ceros sobre el operando de un salto del nucleo reubicado."""
    fondo_1(m)
    m.cero = True
    desc_doble(m, 0x5725)
    m.cero = False
    desc_doble(m, 0x5A29)
    de = desc_doble(m, 0x592C)
    m.setwrt(0x0920)
    desc_doble(m, de + 1)
    de = desc_doble(m, 0x598F)
    desc_doble(m, de + 1)
    guion(m, 0x58A5)                         # 0x589B: el `or a` deja C a cero


def fondo_3(m):
    """FONDO_ETAPA_3 (0x5A44): el base con una franja rellena y su decorado."""
    fondo_1(m)
    m.fill(0x0920, 0x250, 0xFE)
    desc_doble(m, 0x5A5E)
    fondo_3_5A58(m)


def fondo_3_5A58(m):
    """La cola de FONDO_ETAPA_3, que FONDO_ETAPA_1 tambien llama."""
    guion(m, 0x5ACC)


def fondo_4(m):
    """FONDO_ETAPA_4 (0x5B22): el 3 y un guion mas."""
    fondo_3(m)
    guion(m, 0x5B2B)


def fondo_5(m):
    """FONDO_ETAPA_5 (0x5B68): decorado propio y una franja repetida."""
    desc_doble(m, 0x5B96)
    guion(m, 0x5D20)
    desc_doble(m, 0x5A29)
    fondo_1_51E9(m, 0x56C1)
    desc_3_tercios(m, 0x5D38, 0x2798)
    rellena_franja_2(m, 0xD1)


def rellena_franja_2(m, a):
    """RELLENA_FRANJA_2 (0x5B8B): dos tercios desde 0x0798, no tres."""
    rellena_3_tercios(m, 0x0798, 0x48, a, tercios=2)


def fondo_6(m):
    """FONDO_ETAPA_6 (0x5D5B): el base y un guion corto."""
    fondo_1(m)
    guion(m, 0x5D6D)
    m.setwrt(0x2DD0)
    desc_lee(m, 0x512C)


def fondo_7(m):
    """FONDO_ETAPA_7 (0x5D86): el base con tres capas de decorado."""
    fondo_1(m)
    guion(m, 0x5DAB)
    m.setwrt(0x0920)
    desc_doble(m, 0x5DC1)
    de = desc_doble(m, 0x5DC1)
    desc_doble(m, de + 1)
    desc_doble(m, 0x5E20)


def fondo_8(m):
    """FONDO_ETAPA_8 (0x5E94): el 5 y una capa mas."""
    fondo_5(m)
    desc_doble(m, 0x5EA2)
    rellena_franja_2(m, 0xF4)


FONDOS = {0x51B8: fondo_1, 0x586C: fondo_2, 0x5A44: fondo_3, 0x5B22: fondo_4,
          0x5B68: fondo_5, 0x5D5B: fondo_6, 0x5D86: fondo_7, 0x5E94: fondo_8}


def despacha_fondo(m):
    """DESPACHA_FONDO_ETAPA (0x4813): la tabla de 0x481A, indexada por la etapa
    menos uno. Que compositor le toca a cada etapa NO se escribe aqui: se lee de
    la ROM."""
    destino = m.rw(0x481A + (m.etapa - 1) * 2)
    if destino not in FONDOS:
        raise SystemExit("  la etapa %d pide el fondo 0x%04X, sin portar"
                         % (m.etapa, destino))
    FONDOS[destino](m)
    return destino


def dibuja_tiles_etapa(m):
    """DIBUJA_TILES_ETAPA (0x4834): el par [cielo][suelo] de la tabla 0x485C."""
    cielo = m.rb(0x485C + m.etapa * 2)
    suelo = m.rb(0x485C + m.etapa * 2 + 1)
    rellena_3_tercios(m, 0x07E0, 8, suelo)
    rellena_3_tercios(m, 0x07E8, 8, cielo)
    rellena_3_tercios(m, 0x27E0, 0x10, 0)


def carga_carretera(m):
    """CARGA_CARRETERA (0x70E8): pasa el patron de la etapa a 0xE180, un nibble
    por casilla. El `rrd` con A a cero parte el byte en dos -el nibble ALTO se
    queda en (HL) y el BAJO se va a A-, y cada uno se traduce sumando 0xB3, o
    0xFC si vale 0x0F."""
    if m.param & 1:                          # 0x70EB: el `rra` y su `ret c`
        return
    de = m.rw(0x711C + m.etapa * 2)
    hl = 0xE180
    for _ in range(0x18):
        byte = m.rb(de)
        de += 1
        bajo, alto = byte & 0x0F, byte >> 4
        c = 0xFC if bajo == 0x0F else (bajo + 0xB3) & 0xFF
        m.wb(hl, 0xFC if alto == 0x0F else (alto + 0xB3) & 0xFF)
        m.wb(hl + 1, c)
        hl += 2


def scroll_vuelca(m):
    """SCROLL_VUELCA (0x70DC): las 32 casillas de 0xE180 a la fila 12."""
    for i in range(0x20):
        m.wrtvrm(0x3980 + i, m.rb(0xE180 + i))


def instala_estrellas(m):
    """INSTALA_ESTRELLAS (0x721D): los dos contadores y las 16 casillas."""
    for i in range(0x22):
        m.wb(0xE0AE + i, m.rb(0x7229 + i))


def escribe_estrellas(m):
    """ESCRIBE_ESTRELLAS (0x71FF): el mismo tile en las 16 casillas de 0xE0B0."""
    a = (m.rb(0xE0AF) + 0xF3) & 0xFF
    for i in range(0x10):
        m.wrtvrm(m.rw(0xE0B0 + i * 2), a)


def dibuja_horizonte(m):
    """DIBUJA_HORIZONTE (0x6D74): la franja del horizonte, por tipo de etapa."""
    if m.param == 0x01:                      # 0x6D7D: el tunel, relleno liso
        m.fill(0x3860, 0x280, 0xFC)
        return
    if m.param == 0x08:                      # 0x6D81: las dos de noche
        m.fill(0x3860, 0x280, 0xFC)
        if m.etapa == 0x0C:                  # 0x6DAC: la 12 lleva otra franja
            m.fill(0x3860, 0x280, 0xFC)
            m.fill(0x3860, 0x120, 0xFB)
        escribe_estrellas(m)
        return
    m.setwrt(0x3860)
    desc_lee(m, 0x6DC5)
    if m.param == 0x06:                      # 0x6D8D
        m.setwrt(0x3860)
        desc_lee(m, 0x6DFA)
    elif m.param == 0x20:                    # 0x6D8F: el desierto
        sigue_puntero(m, 0x6E0D)


def dibuja_escenario(m, fase):
    """DIBUJA_ESCENARIO (0x6E22): el decorado lateral, indexado por 0xE075."""
    if m.param == 1:
        hl, de = 0x6F7E, 0x6F87
    elif m.param & 0x08:
        hl, de = 0x703B, 0x7044
    else:
        hl, de = 0x6E55, 0x6E5E
    c = m.rb(hl + fase)
    if c == 0xFF:                            # 0x6E3B: esa fase no dibuja nada
        return
    sigue_puntero(m, de + c)


def dibuja_carretera(m, curva):
    """DIBUJA_CARRETERA (0x68D0): la forma sale de la curvatura de 0xE074."""
    if m.param == 0x08:                      # 0x68D3: de noche no hay rayas
        return
    h, l = (curva >> 8) & 0xFF, curva & 0xFF
    a = ((((h * 2) & 0xFF) + (l & 1)) * 2) & 0xFF   # add a,a / rr l / adc / add
    sigue_puntero(m, m.rw(0x767C + a))


def prot_puntero(m, de):
    """PROT_PUNTERO (0x458C): el rotulo sigue por otro sitio. Cambia DE y deja
    HL -la posicion de VRAM- como estaba, que es lo que hacen los dos `ex de,hl`
    de alrededor."""
    return m.rw(de + 1)


def pinta_rotulo(m, de, hl):
    """PINTA_ROTULO (0x455A), la tercera rutina de dibujo: la que se copia a
    0xE1C0 y corre en la RAM. Por encima de 0x30 los bytes son codigos que van
    por el puerto y la posicion avanza 0x20 -una fila-; por debajo son el
    avance en casillas, con el 0x01 como 'sigue escribiendo donde estabas' y el
    0x30 como 'sigue el puntero'. Un 0x00 lo cierra."""
    a = m.rb(de)
    while True:
        c, sin_recolocar = 0x20, False       # PROT_SALTO (0x4565)
        if a < 0x30:
            de += 1
            if a == 0x01:                    # 0x456C
                sin_recolocar = True
            else:
                c = a
        if not sin_recolocar:                # PROT_ESCRIBE (0x456F)
            hl = (hl + c) & 0xFFFF
            if m.rb(de) == 0x30:
                de = prot_puntero(m, de)
            m.setwrt(hl)
        m.out(m.rb(de))                      # PROT_BYTE (0x4579)
        de += 1
        a = m.rb(de)
        if a == 0:                           # 0x4581
            return de
        if a == 0x30:
            de = prot_puntero(m, de)
            a = m.rb(de)


def dibuja_bordes_tunel(m, curva):
    """DIBUJA_BORDES_TUNEL (0x68EC): las paredes del tunel, dos tiras por mitad.
    El indice sale de la curvatura partida en dos: el bit 0 de la parte baja
    elige el juego de tablas y el nibble bajo de la alta, por cuatro, el trozo
    de pared."""
    if m.param != 0x01:
        return
    h, l = (curva >> 8) & 0xFF, curva & 0xFF
    carry = l & 1                            # 0x68FB: `rr l`
    de, bc = (0x73F7, 0x740F) if carry else (0x73C7, 0x73DF)
    h = ((h << 1) | carry) & 0xFF            # 0x6905: `rl h`
    a = ((h & 0x0F) * 4) & 0xFF
    sigue_puntero(m, de)                     # BORDES_PINTA (0x6922)
    sigue_puntero(m, bc)
    p = 0x74E1 + a                           # 0x6911: la segunda mitad
    de, bc = m.rw(p), m.rw(p + 2)
    sigue_puntero(m, de)
    if bc:                                   # 0x691E: `or c` / `jr z`
        sigue_puntero(m, bc)


def suben_piramides(m, filas):
    """SUBEN_PIRAMIDES (0x731D): en el desierto la carretera no scrollea, suben
    piramides. Y no hay una piramide dibujada en ninguna parte: hay una VENTANA
    de 32 bytes en 0x7351 -dieciseis ceros y luego el triangulo- que se desliza
    una posicion cada vez que 0xE071 llega a uno de los dieciseis umbrales de
    0x7371. La mitad derecha es la izquierda pasada por INVIERTE_BITS, el mismo
    truco del coche rival."""
    de = 0x7351 + filas
    for i in range(0x10):
        m.wrtvrm(0x2D98 + i, m.rb(de + i))   # 0x7339: la mitad izquierda
    for i in range(0x10):                    # 0x7343: y la derecha, espejada
        m.wrtvrm(0x2DA8 + i, invierte(m.rb(de + i)))


def relampago(m, forma=0, columna=0):
    """RELAMPAGO / ELIGE_RAYO (0x724B y 0x72A5): en la etapa de tormenta cae un
    rayo cada pocos cuadros. La forma sale de los cuatro punteros de 0x72D2
    -tres distintas, la primera repetida- y se dibuja con PINTA_ROTULO desde
    0x3846, la fila 2. Aqui la forma y la columna se eligen a mano; en el juego
    las sortea el registro de refresco, asi que un dibujo no puede reproducir
    'el' rayo, solo uno de los suyos."""
    de = m.rw(0x72D2 + (forma & 3) * 2)
    pinta_rotulo(m, de, 0x3846 + columna)

def pantalla(rom, org=0x4000, etapa=1, curva=RECTA, fase=PARADO,
             etapa_previa=None, piramides=None, rayo=None):
    """La pantalla de la carrera tal como la deja INICIA_CARRERA (0x474E), en su
    mismo orden y sin los actores: sin tu coche, sin rivales y sin el marcador,
    que se pintan cuadro a cuadro.

    Faltan a proposito DIBUJA_CUENTAKM (0x6861), que va por PINTA_ROTULO y pinta
    el rotulo lateral, y DIBUJA_BORDES_TUNEL (0x68EC): las dos dependen del
    cuadro en curso y no del fondo.

    `etapa_previa` es para cotejar contra los volcados: ver el comentario de
    abajo."""
    m = Maquina(rom, org, etapa)
    dibuja_marco(m)                          # de antes, en EST0_SUB3 (0x40EA)
    if etapa_previa is not None:
        # El piloto que saco los volcados rompe en DESPACHA_FONDO_ETAPA y ahi
        # cambia la etapa, asi que CARGA_CARRETERA ya habia corrido con OTRA.
        # Para cotejar hay que hacer lo mismo, o la fila 12 no cuadra nunca.
        previo = Maquina(rom, org, etapa_previa)
        carga_carretera(previo)
        m.ram[0xE180 - 0xE000:0xE1B0 - 0xE000] = previo.ram[0xE180 - 0xE000:0xE1B0 - 0xE000]
    else:
        carga_carretera(m)                   # 0x4761
    instala_estrellas(m)                     # 0x4764
    despacha_fondo(m)                        # 0x4767
    dibuja_tiles_etapa(m)                    # 0x476A
    dibuja_panel(m)                          # 0x476D
    dibuja_horizonte(m)                      # 0x4770
    dibuja_escenario(m, fase)                # 0x4773
    dibuja_carretera(m, curva)               # 0x4776
    if m.param != 0x20:                      # 0x477C
        if m.param & 1:
            dibuja_bordes_tunel(m, curva)    # 0x4788
        else:
            scroll_vuelca(m)                 # 0x4785
    if piramides is not None:
        suben_piramides(m, piramides)
    if rayo is not None:
        relampago(m, *rayo)
    return m


# --- los actores -----------------------------------------------------------
def coche_jugador(m):
    """La plantilla de 0x66E2: seis sprites (Y, X, patron, color)."""
    return [tuple(m.rb(0x66E2 + i * 4 + k) for k in range(4)) for i in range(6)]


def rival_lejos(m, byte0, carril, fase=0):
    """La rama de 0x7A15: los sprites del rival, con su tamanyo y su color.

    Devuelve (indice de escala, [(Y, X, patron, color)...]). El indice sale de
    0x7A19 y con el se lee 0x7D94, que da el patron base y la altura; los dos
    bits bajos de ese patron dicen CUANTOS sprites se encienden, porque 0x7A73
    y 0x7A81 apagan los que sobran. Los cuatro son dos parejas SUPERPUESTAS,
    cada una de un color: asi se pinta un coche de dos colores con sprites de
    un color cada uno."""
    a = (byte0 >> 3) & 0x1F
    idx = (a - 5) & 0xFF if a < 0x12 else (a >> 1) + 4
    de = m.rw(0x7F47 + fase * 2)                 # 0x7A2E: la tabla de la fase
    fila = m.rb(de + idx)
    if fila == 0xFF:
        return None
    if idx < 9:
        hl = 0x7DBA + 6 * fila + carril          # 0x7A4A: seis bytes por fila
    else:
        hl = 0x7E68 + ((fila * 2) | (carril & 1))
    x = m.rb(hl)                                 # 0x7A61: la X del carril
    if x == 0xFF:
        return None
    pat, y = m.rb(0x7D94 + idx * 2), m.rb(0x7D94 + idx * 2 + 1)
    col1, col0 = m.rb(0x7B59 + 11), m.rb(0x7B59 + 10)   # (iy+1) y (iy+0)
    n = 4 if not pat & 1 else (2 if not pat & 2 else 1)
    pat &= 0xFC
    s = [(y, x, pat, col1)]
    if n >= 2:
        s.append((y, (x + 0x10) & 0xFF, pat + 4, col1))
    if n >= 4:                                   # la segunda capa de color
        s.append((y, (x + 0x10) & 0xFF, pat + 8, col0))
        s.append((y, x, pat + 12, col0))
    return idx, s


def prepara_rivales(m):
    """PREPARA_RIVALES (0x7B67): monta en 0xE200 el buffer de tiras del rival
    de cerca. Dos fases: la primera siembra los codigos de control leyendo
    pares (salto, valor) de 0x7BB9, y la segunda copia los doce numeros de
    casilla de 0x7BF3 -el coche entero- cada vez que la tabla trae un 0xFF."""
    for i in range(0x110):
        m.wb(0xE200 + i, 0xFD)
    hl, de = 0xE1FF, 0x7BB9
    for _ in range(3):                       # tres grupos
        for _ in range(4):                   # cuatro pasadas, la tabla rebobina
            d = de
            for _ in range(4):               # cuatro pares por pasada
                hl = (hl + m.rb(d)) & 0xFFFF
                m.wb(hl, m.rb(d + 1))
                d += 2
        de += 8
    bc, hl, de = 0x7BD1, 0xE200, None
    while True:
        a = m.rb(bc)
        bc += 1
        if a == 0xFE:                        # 0x7BA0: cierra
            return
        if a > 0xFE:                         # 0xFF: rebobina a los doce tiles
            de = 0x7BF3
            continue
        hl = (hl + a) & 0xFFFF
        for _ in range(4):
            m.wb(hl, m.rb(de))
            de += 1
            hl += 1


def rival_cerca(m, byte0, carril):
    """RIVAL_MEDIO (0x7AD1): el rival de cerca, dibujado con CASILLAS. Escribe
    en la tabla de nombres y devuelve donde lo ha puesto."""
    b = 0 if byte0 >= 0x20 else (1 if byte0 >= 0x18 else 2)
    a = ((carril & 0x0E) * 2 + b) & 0xFF
    de = 0xE200 + m.rb(0x7B30 + a)           # 0x7AE7: el trozo del buffer
    hl = 0x3A00 | m.rb(0x7B3C + carril)      # 0x7AF5: y el destino, con h=0x3A
    pinta_tira(m, de, hl)
    return hl


def nivel(byte0):
    """RIVAL_NIVEL (0x79D8): en que banda cae, con el `add a,010h` delante."""
    a = (byte0 + 0x10) & 0xFF
    return 0 if a < 0x26 else (1 if a < 0x38 else 2)


# --- pintar ----------------------------------------------------------------
def pinta_vram(vram, esc=2, f0=0, f1=23):
    """Las casillas como las lee el VDP en SCREEN 2."""
    w, h = 256 * esc, (f1 - f0 + 1) * 8 * esc
    px = bytearray(w * h * 3)
    for fila in range(f0, f1 + 1):
        tercio = fila // 8
        for col in range(32):
            t = vram[0x3800 + fila * 32 + col]
            pb, cb = 0x2000 + tercio * 0x800 + t * 8, tercio * 0x800 + t * 8
            for f in range(8):
                linea, color = vram[pb + f], vram[cb + f]
                tinta, papel = PALETA[color >> 4], PALETA[color & 15]
                for x in range(8):
                    c = tinta if (linea >> (7 - x)) & 1 else papel
                    for dy in range(esc):
                        base = ((((fila - f0) * 8 + f) * esc + dy) * w
                                + (col * 8 + x) * esc) * 3
                        for dx in range(esc):
                            px[base + dx * 3:base + dx * 3 + 3] = bytes(c)
    return w, h, px


def pinta_sprite(pon, vram, y, x, pat, color, esc=2, dx=0, dy=0):
    """Un sprite de 16x16 de la tabla de patrones de 0x1800 (R6=0x03). La Y del
    atributo es una fila MENOS que la de pantalla, y el color 0 no se ve."""
    if not color & 0x0F:
        return
    c = PALETA[color & 0x0F]
    for mitad in range(2):                   # 16 bytes por mitad, izq y der
        for f in range(16):
            linea = vram[0x1800 + pat * 8 + mitad * 16 + f]
            for b in range(8):
                if (linea >> (7 - b)) & 1:
                    for a in range(esc):
                        for o in range(esc):
                            pon(dx + (x + mitad * 8 + b) * esc + o,
                                dy + (y + 1 + f) * esc + a, c)


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    org = int(argv[2], 0)
    m = pantalla(rom, org)
    print("  pantalla de la carrera montada: %d bytes de VRAM escritos"
          % sum(m.escrito))
    if "--coteja" in argv:
        vol = open(argv[argv.index("--coteja") + 1], "rb").read()
        for nombre, ini, fin in (("patrones de sprite", 0x1800, 0x1E60),
                                 ("patrones de casilla", 0x2000, 0x3800),
                                 ("colores", 0x0000, 0x1800),
                                 ("tabla de nombres", 0x3800, 0x3B00)):
            tocado = [a for a in range(ini, fin) if m.escrito[a]]
            mal = [a for a in tocado if m.vram[a] != vol[a]]
            print("  %-20s %5d escritos, %4d distintos del volcado"
                  % (nombre, len(tocado), len(mal)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
