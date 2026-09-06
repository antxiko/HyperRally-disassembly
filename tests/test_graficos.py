#!/usr/bin/env python3
"""Comprobaciones sobre los graficos que la web publica dibujados desde la ROM.

Estas SI necesitan el cartucho, igual que la que comprueba que las paginas no
inventan direcciones. Lo que vigilan es que las afirmaciones de las paginas -que
el coche rival de cerca son doce casillas, que la mitad derecha es la izquierda
con los bits del reves, que la tabla 0x7D94 va de cuatro sprites a uno- las siga
sosteniendo el binario, y no solo el texto.

El cotejo contra el emulador no necesita tener el volcado delante: los sha256
de abajo se midieron UNA vez sobre work/omsx/vram_etapa1.bin, que es VRAM real
de openMSX corriendo el cartucho, y aqui se comprueba que lo que monta Python
los reproduce. El volcado no se distribuye -son graficos del juego-, pero su
huella si, y con ella el control se ejecuta siempre.
"""
import hashlib
import os
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(RAIZ, "hyperrally.rom")
sys.path.insert(0, os.path.join(RAIZ, "tools"))

import carrera as C                                             # noqa: E402

# Medidos sobre la VRAM que openMSX tenia en la etapa 1, con
#     python -c "import hashlib; ..."  sobre work/omsx/vram_etapa1.bin
VRAM_SPRITES = "149bb690b9971f3382ded2c50a60874d849321348f60f03a7accf738b5089910"
VRAM_PATRONES = "9c20ef1b2b3794e02f42c484af05172e48e1d89ca86cc299bc4ca6bcf1390986"
VRAM_COLORES = "23d77dd33c2bee4a08d1a708f660599d597416b7987618ec6553ea2805d788ca"


class TestPantallaDeCarrera(unittest.TestCase):
    """La pantalla montada ejecutando los descompresores del cartucho."""

    @classmethod
    def setUpClass(cls):
        with open(ROM, "rb") as f:
            cls.rom = f.read()
        cls.m = C.pantalla(cls.rom)
        C.prepara_rivales(cls.m)

    def test_la_fuente_acaba_donde_empieza_el_guion_siguiente(self):
        """Si el formato del descompresor estuviera mal leido, la fuente no
        acabaria justo en 0x518E, que es el guion que DIBUJA_MARCO vuelca a
        continuacion."""
        m = C.Maquina(self.rom)
        self.assertEqual(C.desc_3_tercios(m, 0x4DEA, 0x2000), 0x518E)

    def test_los_doce_numeros_de_casilla_del_rival_estan_en_la_rom(self):
        """0x7BF3: el coche de cerca, cuatro de ancho por tres de alto."""
        esperado = [0x24, 0x27, 0x2D, 0x2A,
                    0x25, 0x28, 0x2E, 0x2B,
                    0x26, 0x29, 0x29, 0x2C]
        self.assertEqual([self.m.rb(0x7BF3 + i) for i in range(12)], esperado)

    def test_el_buffer_de_tiras_lleva_el_coche_y_sus_controles(self):
        """PREPARA_RIVALES deja en 0xE200 las tres filas separadas por 0x20 -el
        salto de fila de PINTA_TIRA- y cerradas con un 0x00."""
        b = [self.m.rb(0xE200 + i) for i in range(20)]
        self.assertEqual(b[:5], [0x24, 0x27, 0x2D, 0x2A, 0x20])
        self.assertEqual(b[5:10], [0x25, 0x28, 0x2E, 0x2B, 0x20])
        self.assertEqual(b[10:15], [0x26, 0x29, 0x29, 0x2C, 0x20])
        self.assertEqual(b[19], 0x00)

    def test_la_mitad_derecha_del_rival_es_la_izquierda_del_reves(self):
        """El hallazgo que publica rival_espejo.png: los patrones 0x2A..0x2E
        del tercer tercio son los 0x24..0x28 con los bits invertidos, porque la
        segunda capa de DESC_DOBLE pasa por INVIERTE_BITS."""
        for izq, der in ((0x24, 0x2A), (0x25, 0x2B), (0x26, 0x2C),
                         (0x27, 0x2D), (0x28, 0x2E)):
            a = self.m.vram[0x3000 + izq * 8:0x3000 + izq * 8 + 8]
            b = self.m.vram[0x3000 + der * 8:0x3000 + der * 8 + 8]
            self.assertEqual(bytes(C.invierte(x) for x in a), bytes(b),
                             "0x%02X no es el espejo de 0x%02X" % (der, izq))

    def test_el_tile_de_enmedio_es_su_propio_espejo(self):
        """Por eso 0x29 sale dos veces en la tira."""
        a = self.m.vram[0x3000 + 0x29 * 8:0x3000 + 0x29 * 8 + 8]
        self.assertEqual(bytes(C.invierte(x) for x in a), bytes(a))

    def test_la_escala_del_rival_va_de_cuatro_sprites_a_uno(self):
        """La tabla 0x7D94: los dos bits bajos del patron dicen cuantos sprites
        se encienden, y la altura sube segun se aleja."""
        piezas, alturas = [], []
        for idx in range(19):
            pat, y = self.m.rb(0x7D94 + idx * 2), self.m.rb(0x7D94 + idx * 2 + 1)
            piezas.append(4 if not pat & 1 else (2 if not pat & 2 else 1))
            alturas.append(y)
        self.assertEqual(piezas[:5], [4] * 5)
        self.assertEqual(piezas[5:14], [2] * 9)
        self.assertEqual(piezas[14:], [1] * 5)
        self.assertEqual(alturas, sorted(alturas, reverse=True),
                         "la altura tiene que subir sin volver atras")

    def test_las_bandas_del_rival_son_las_publicadas(self):
        """RIVAL_NIVEL (0x79D8): el byte 0 reparte en tres, y la frontera entre
        los sprites y las casillas esta en 0x28."""
        self.assertEqual(C.nivel(0x28), 2)
        self.assertEqual(C.nivel(0x27), 1)
        self.assertEqual(C.nivel(0x16), 1)
        self.assertEqual(C.nivel(0x15), 0)

    def test_el_rival_de_cerca_ocupa_cuatro_por_tres_casillas(self):
        """RIVAL_MEDIO lo escribe en la tabla de nombres, no en los sprites."""
        m = C.pantalla(self.rom)
        C.prepara_rivales(m)
        antes = bytes(m.vram[0x3800:0x3B00])
        hl = C.rival_cerca(m, 0x26, 0)
        movidas = [i for i in range(0x300) if m.vram[0x3800 + i] != antes[i]]
        filas = sorted({i // 32 for i in movidas})
        columnas = sorted({i % 32 for i in movidas})
        self.assertEqual(len(columnas), 4)
        self.assertEqual(len(filas), 4)          # tres del coche y una que borra
        self.assertEqual(hl - 0x3800, filas[0] * 32 + columnas[0])


class TestContraElEmulador(unittest.TestCase):
    """Lo montado en Python contra lo que el MSX tenia de verdad en la VRAM."""

    @classmethod
    def setUpClass(cls):
        with open(ROM, "rb") as f:
            cls.m = C.pantalla(f.read())

    def sha(self, datos):
        return hashlib.sha256(bytes(datos)).hexdigest()

    def test_los_patrones_de_sprite_salen_iguales_byte_a_byte(self):
        """El guion de 0x488A: 1632 bytes y ni uno distinto."""
        self.assertEqual(self.sha(self.m.vram[0x1800:0x1E60]), VRAM_SPRITES)

    def test_todos_esos_patrones_los_escribe_el_flujo(self):
        """Que cuadre el sha256 no vale si la mitad se quedo a cero de fabrica:
        el flujo del cartucho tiene que haber escrito los 1632."""
        self.assertEqual(sum(self.m.escrito[0x1800:0x1E60]), 0x1E60 - 0x1800)

    def test_los_patrones_del_coche_rival_salen_iguales(self):
        """Los once del coche de cerca, en el tercer tercio, y sus colores."""
        for t in range(0x24, 0x2F):
            a = 0x3000 + t * 8
            self.assertTrue(all(self.m.escrito[a + i] for i in range(8)),
                            "el tile 0x%02X no lo escribe el flujo" % t)
        self.assertEqual(
            self.sha(b"".join(bytes(self.m.vram[0x3000 + t * 8:0x3000 + t * 8 + 8])
                              for t in range(0x24, 0x2F))), VRAM_PATRONES)
        self.assertEqual(
            self.sha(b"".join(bytes(self.m.vram[0x1000 + t * 8:0x1000 + t * 8 + 8])
                              for t in range(0x24, 0x2F))), VRAM_COLORES)


# Las doce etapas, medidas UNA vez sobre los volcados de openMSX de
# work/omsx/vram_etapaN.bin. Cada huella es el sha256 de todo lo que el flujo
# del cartucho escribe en la VRAM MENOS lo que el juego repinta cuadro a cuadro
# (ver `repintado`), que es lo unico que puede haber cambiado entre que la
# pantalla se monto y el piloto volco la VRAM.
VRAM_ETAPAS = {
    1: "117eff29253025987a9d3f840e29495a51ef5aade8e6cb591be4353b26e35183",
    2: "4bc9c61ebcdf56c6ba7a5ea0f32840c8e0a448dd9562d8d4e047f93cb1aee055",
    3: "33d8cae86e08f95e563f037bc5ff0e88ab6f07d326a625f9ae5bf25637686db5",
    4: "21f3df0e90b477127d8ee0c6cc317680ea47a02eb8f9d7d07e220fb48f4498d5",
    5: "6822169e5e29b7f9083ef2554124eb3c9fe301756d6fdcf1a1540863d1af7139",
    6: "117eff29253025987a9d3f840e29495a51ef5aade8e6cb591be4353b26e35183",
    7: "12d1e70da6de13b859b84dfe4476afb5eab4036cbddc43bf76588c1706b15703",
    8: "ad26c9ef3cb2e5b6adbd1b51d754857d6e8e6efa182a8cb0cae4c6b12edfedc8",
    9: "33d8cae86e08f95e563f037bc5ff0e88ab6f07d326a625f9ae5bf25637686db5",
    10: "4bc9c61ebcdf56c6ba7a5ea0f32840c8e0a448dd9562d8d4e047f93cb1aee055",
    11: "b45c3ae2e1731ee45042e9d9411dc093778223be9f7f5a391c5738c272e8ebba",
    12: "5893f8df5c4c3e5f69efaf318221bcd03a709d70e8a58a517a57addd3e7f7c8d",
}


def repintado(a):
    """Lo unico que se deja fuera del cotejo, y por que: el rotulo READY (que lo
    pinta otra rutina), la raya central de la carretera (que se mueve sola), la
    franja del marcador y los tiles del cuentakilometros."""
    if 0x3800 <= a < 0x3B00:
        f, c = (a - 0x3800) // 32, (a - 0x3800) % 32
        return (f == 7 and 14 <= c <= 18) or (c == 15 and f >= 13)
    if a < 0x1800 or 0x2000 <= a < 0x3800:
        o = a % 0x800
        return 0x80 <= o < 0x2F8 or 0xD0 <= o < 0xF0
    return False


def huella(m):
    return hashlib.sha256(bytes(
        m.vram[a] for a in range(0x4000)
        if m.escrito[a] and not repintado(a))).hexdigest()


class TestLasDoceEtapas(unittest.TestCase):
    """Los ocho compositores de fondo, contra los doce volcados del emulador."""

    @classmethod
    def setUpClass(cls):
        with open(ROM, "rb") as f:
            cls.rom = f.read()

    def test_cada_etapa_cuadra_con_la_vram_del_emulador(self):
        for etapa, sha in VRAM_ETAPAS.items():
            # El piloto que saco los volcados cambia la etapa DESPUES de que
            # CARGA_CARRETERA haya corrido, asi que hay que montarla igual.
            m = C.pantalla(self.rom, 0x4000, etapa, etapa_previa=1)
            self.assertEqual(huella(m), sha, "la etapa %d no cuadra" % etapa)

    def test_los_doce_fondos_los_cubren_ocho_rutinas(self):
        """La tabla 0x481A, leida de la ROM: doce entradas y ocho destinos."""
        m = C.Maquina(self.rom)
        destinos = [m.rw(0x481A + i * 2) for i in range(12)]
        self.assertEqual(len(set(destinos)), 8)
        for d in destinos:
            self.assertIn(d, C.FONDOS, "el fondo 0x%04X no esta portado" % d)

    def test_las_etapas_del_mismo_fondo_y_parametro_salen_iguales(self):
        """1 y 6, 2 y 10, 3 y 9: mismo compositor y mismo 0xE061."""
        for a, b in ((1, 6), (2, 10), (3, 9)):
            self.assertEqual(VRAM_ETAPAS[a], VRAM_ETAPAS[b])
        # y las que comparten compositor pero NO parametro no salen iguales
        self.assertNotEqual(VRAM_ETAPAS[1], VRAM_ETAPAS[8])

    def test_ninguna_etapa_se_queda_sin_dibujar(self):
        """Doce pantallas distintas de verdad: nueve huellas para doce etapas."""
        self.assertEqual(len(set(VRAM_ETAPAS.values())), 9)

    def test_la_piramide_es_media_y_se_refleja(self):
        """SUBEN_PIRAMIDES (0x731D): el patron de la derecha (0x2DA8) es el de
        la izquierda (0x2D98) con los bits del reves, como el coche rival."""
        m = C.pantalla(self.rom, 0x4000, 11, piramides=15)
        izq = m.vram[0x2D98:0x2DA8]
        der = m.vram[0x2DA8:0x2DB8]
        self.assertEqual(bytes(C.invierte(x) for x in izq), bytes(der))

    def test_la_piramide_sube_y_no_baja(self):
        """Cada umbral de 0x7371 abre una fila mas, y ninguna se cierra."""
        antes = 0
        for filas in range(0, 16):
            m = C.pantalla(self.rom, 0x4000, 11, piramides=filas)
            puestos = sum(bin(x).count("1") for x in m.vram[0x2D98:0x2DA8])
            self.assertGreaterEqual(puestos, antes)
            antes = puestos
        self.assertGreater(antes, 0)

    def test_el_rayo_tiene_tres_formas(self):
        """Los cuatro punteros de 0x72D2 dan tres rayos distintos: el primero
        sale dos veces."""
        m = C.Maquina(self.rom)
        p = [m.rw(0x72D2 + i * 2) for i in range(4)]
        self.assertEqual(len(set(p)), 3)
        self.assertEqual(p[0], p[2])
        pintados = set()
        for forma in range(4):
            v = C.pantalla(self.rom, 0x4000, 7, rayo=(forma, 0))
            pintados.add(bytes(v.vram[0x3840:0x3900]))
        self.assertEqual(len(pintados), 3)


if __name__ == "__main__":
    unittest.main()
