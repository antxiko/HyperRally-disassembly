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


if __name__ == "__main__":
    unittest.main()
