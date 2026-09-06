#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: se dibujan a partir de los
propios bytes de la ROM por tools/graficos.py, ejecutando en Python el mismo
descompresor de guiones que el Z80 corre en 0x446D. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a ojo:
# 16384 = 6464 + 9920, que es lo que imprime tools/presupuesto.py (make sanity).
# RUTINAS son las etiquetas de codigo con nombre propio, las mismas que cuenta
# el .notes con su directiva L. ETAPAS es el rally de doce etapas (0xE060 de 1
# a 0x0C).
CODIGO = 6464
DATOS = 9920
RUTINAS = 431
ETAPAS = 12


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Hyper Rally — desensamblado comentado",
        aviso="<b>Aquí no hay ninguna ilustración ni captura.</b> La fuente y "
              "los tiles están <b>dibujados desde los bytes de la ROM</b>, "
              "ejecutando en Python el mismo descompresor de guiones que corre "
              "el Z80; hasta la <b>escena de la carretera</b> se monta así, "
              "ejecutando los descompresores del cartucho y pintando los coches "
              "con sus propios patrones. El listado y las cifras salen del "
              "binario y se reproducen con <code>make</code>.",
        claim="Un rally de doce etapas en un cartucho de 16 KB: una carretera "
              "en falso 3D, un salpicadero con cuentakilómetros, gasolina, "
              "marcha y reloj, coches rivales que colisionan por profundidad, "
              "y todo movido por la interrupción de cada cuadro.",
        ficha=["Konami · <b>© Konami 1985</b>",
               "Cartucho <b>RC-718</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>eca2c0d6…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "rutinas identificadas"),
                (str(ETAPAS), "etapas del rally"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen está de dónde sale y qué se está "
                 "viendo.",
        pie_leg="Esto es trabajo de documentación y preservación: el código y "
                "los gráficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Hyper Rally — a commented disassembly",
        aviso="<b>There is not one illustration or capture here.</b> The font "
              "and the tiles are <b>drawn from the bytes of the ROM</b>, by "
              "running in Python the same script decompressor the Z80 runs; "
              "even the <b>road scene</b> is built that way, running the "
              "cartridge's decompressors and painting the cars with its own "
              "patterns. The listing and the numbers come from the binary and "
              "are reproducible with <code>make</code>.",
        claim="A twelve-stage rally in a 16 KB cartridge: a fake-3D road, a "
              "dashboard with a speedometer, fuel, gear and clock, rival cars "
              "that collide by depth, and everything driven by the per-frame "
              "interrupt.",
        ficha=["Konami · <b>© Konami 1985</b>",
               "An <b>RC-718</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>eca2c0d6…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "routines identified"),
                (str(ETAPAS), "stages of the rally"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("Lleva la marca oculta de Konami",
         "<p>Al final de la ROM, detrás del relleno, Konami escondía en muchos "
         "cartuchos su número de catálogo y el título en katakana; lo descubrió "
         "<b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>). "
         "Aquí está: los últimos once bytes de 0x7FF5 son el título al revés, "
         "su longitud, el <b>18</b> del RC-718 en BCD y el 0xAA que la cierra.</p>"),
        ("Un solo bucle muerto y toda la máquina en la interrupción",
         "<p>INIT engancha la interrupción a 0x4051 y cae en un <code>jr</code> "
         "a sí mismo. A partir de ahí <b>el programa principal no hace nada</b>: "
         "cada cuadro, la interrupción lee 0xE000 (el estado, de 0 a 8), salta "
         "por una tabla de nueve manejadores, y dentro de cada uno el byte "
         "0xE001 reparte los subestados con cadenas de <code>djnz</code>.</p>"),
        ("La carretera es una tabla de formas indexada por la curvatura",
         "<p>No hay geometría: 0x68D0 lee 0xE074 —la curvatura y la posición del "
         "trazado— e indexa la tabla de 0x767C para elegir qué forma de "
         "carretera dibujar. Las rayas se mueven hacia el jugador desplazando "
         "un buffer (0x707A) al ritmo de la velocidad, y el escalado de los "
         "objetos por profundidad sale de las tablas de 0x6CD5.</p>"),
        ("Doce etapas de ocho compositores, y dos son de noche",
         "<p>0xE060 va de 1 a 0x0C y con él se elige, por la tabla de 0x481A, "
         "el compositor de fondo de cada etapa: ocho rutinas cubren las doce, y "
         "el compositor de la 12 llama al de la 5. El parámetro 0xE061 (tabla "
         "0x4372) es un <b>campo de bits</b> con lo que cada etapa tiene de "
         "particular: el bit 1 es el suelo resbaladizo de la nieve, 0x01 el "
         "túnel, 0x10 la tormenta y 0x08 la noche. En las dos nocturnas, 0x71AC "
         "corre un campo de <b>dieciséis estrellas</b> por el cielo, a "
         "precisión de píxel y al ritmo de la velocidad del coche.</p>"),
        ("El sonido es el reproductor de tres canales de la casa",
         "<p>El motor de 0x5FB7 recorre tres fichas de catorce bytes (0xE010), "
         "lee las melodías con su intérprete de órdenes y escribe el PSG por la "
         "BIOS. Es el mismo armazón de reproductor que Konami repartía entre "
         "sus cartuchos de MSX; 0x5ED9 arranca una melodía o un efecto por su "
         "número, mirando antes la prioridad para no pisar lo que ya suena.</p>"),
        ("El coche del jugador son seis sprites, y los rivales colisionan por profundidad",
         "<p>El coche se monta con seis sprites (plantilla en 0x66E2) que "
         "0x65FA recoloca cada cuadro según el volante. Los tres rivales llevan "
         "sus fichas en 0xE138/48/58; 0x7C34 los ordena por cercanía antes de "
         "dibujarlos, y 0x7F89 parte la velocidad por la mitad al chocar contra "
         "uno.</p>"),
        ("Un rival no tiene recorrido propio",
         "<p>0x7CCB estaba en el listado como el impacto, "
         "<b>y no toca tu velocidad</b>: lo único que escribe es la posición "
         "del rival, y le suma <b>(la velocidad del rival − la tuya) / 16</b>. "
         "En una carrera de 45 segundos sin un solo golpe corrió 1329 veces. "
         "Y 0xE09C, que el listado llamaba el color del rival, es su "
         "velocidad: forzado a 0 te los comes a todos, forzado a 255 se te "
         "escapan todos. La cuenta rehecha en Python reproduce "
         "<b>102 de 102</b> casos leídos dentro de la propia rutina.</p>"),
        ("Un rival que se acerca cambia de material por el camino",
         "<p>No crece: <b>deja de ser sprites y pasa a ser pantalla</b>. La "
         "tabla 0x7D94 da veinte escalones, y los dos bits bajos de cada patrón "
         "dicen cuántos sprites se encienden —uno de lejos, dos más cerca, y "
         "cuatro en <b>dos capas de color</b> superpuestas, que es como se pinta "
         "un coche de dos colores con sprites de un color cada uno—. Cuando el "
         "byte 0 de la ficha baja de <b>0x28</b>, 0x7B21 pone <b>Y = 0xE0</b> en "
         "los cuatro sprites y RIVAL_MEDIO (0x7AD1) lo repinta con <b>doce "
         "casillas</b> de la tabla de nombres.</p>"
         "<p>Y de esas doce, el cartucho sólo guarda la mitad: <b>0x2A es 0x24 "
         "con los bits del revés</b>, y así hasta 0x2E. La otra mitad la pone "
         "DESC_DOBLE (0x44B0), que pasa el mismo bloque dos veces y la segunda "
         "por el núcleo reubicado de 0xE310, que cae en INVIERTE_BITS.</p>"),
    ],
    "en": [
        ("It carries Konami's hidden mark",
         "<p>At the end of the ROM, behind the filler, Konami hid in many "
         "cartridges its catalogue number and the title in katakana; "
         "<b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>) "
         "found it. Here it is: the last eleven bytes from 0x7FF5 are the title "
         "reversed, its length, the <b>18</b> of RC-718 in BCD and the 0xAA "
         "that closes it.</p>"),
        ("One dead loop, and the whole machine in the interrupt",
         "<p>INIT hooks the interrupt to 0x4051 and falls into a <code>jr</code> "
         "to itself. From there <b>the main program does nothing</b>: each "
         "frame the interrupt reads 0xE000 (the state, 0 to 8), jumps through a "
         "table of nine handlers, and inside each one the byte 0xE001 splits "
         "the sub-states with <code>djnz</code> chains.</p>"),
        ("The road is a table of shapes indexed by curvature",
         "<p>There is no geometry: 0x68D0 reads 0xE074 —the curvature and "
         "position of the track— and indexes the table at 0x767C to pick which "
         "road shape to draw. The stripes move toward the player by scrolling a "
         "buffer (0x707A) at the speed's pace, and the depth scaling of the "
         "roadside objects comes from the tables at 0x6CD5.</p>"),
        ("Twelve stages from eight composers, and two of them at night",
         "<p>0xE060 runs from 1 to 0x0C and with it, through the table at "
         "0x481A, the background composer of each stage is chosen: eight "
         "routines cover the twelve, and stage 12's composer calls stage 5's. "
         "The parameter 0xE061 (table at 0x4372) is a <b>bit field</b> holding "
         "what is particular about each stage: bit 1 is the slippery snow, "
         "0x01 the tunnel, 0x10 the storm and 0x08 the night. In the two night "
         "stages, 0x71AC runs a field of <b>sixteen stars</b> across the sky, "
         "at pixel precision and at the pace of the car's speed.</p>"),
        ("The sound is the house's three-channel player",
         "<p>The engine at 0x5FB7 walks three fourteen-byte records (0xE010), "
         "reads the melodies with its command interpreter and writes the PSG "
         "through the BIOS. It is the same player framework Konami spread "
         "across its MSX cartridges; 0x5ED9 starts a melody or an effect by its "
         "number, checking priority first so it does not step on what already "
         "plays.</p>"),
        ("The player car is six sprites, and rivals collide by depth",
         "<p>The car is assembled from six sprites (template at 0x66E2) that "
         "0x65FA repositions every frame from the wheel. The three rivals keep "
         "their records at 0xE138/48/58; 0x7C34 sorts them by nearness before "
         "drawing, and 0x7F89 halves your speed when you hit one.</p>"),
        ("An opponent has no path of its own",
         "<p>0x7CCB was in the listing as the impact, <b>and it does not touch "
         "your speed</b>: the only thing it writes is the opponent's position, "
         "to which it adds <b>(the opponent's speed − yours) / 16</b>. In a "
         "45-second race without a single hit it ran 1329 times. And 0xE09C, "
         "which the listing called the opponent's colour, is its speed: forced "
         "to 0 you eat all of them, forced to 255 they all get away. The "
         "arithmetic redone in Python reproduces <b>102 of 102</b> cases read "
         "inside the routine itself.</p>"),
        ("An opponent coming closer changes material on the way",
         "<p>It does not grow: <b>it stops being sprites and becomes screen</b>. "
         "Table 0x7D94 gives twenty steps, and the two low bits of each pattern "
         "say how many sprites light up —one far away, two closer, and four in "
         "<b>two overlaid colour layers</b>, which is how you paint a two-colour "
         "car out of sprites that only take one colour each—. When byte 0 of the "
         "record drops below <b>0x28</b>, 0x7B21 writes <b>Y = 0xE0</b> into all "
         "four sprites and RIVAL_MEDIO (0x7AD1) repaints it with <b>twelve "
         "tiles</b> of the name table.</p>"
         "<p>And of those twelve, the cartridge only stores half: <b>0x2A is "
         "0x24 with its bits reversed</b>, and so on up to 0x2E. The other half "
         "is put there by DESC_DOBLE (0x44B0), which runs the same block twice "
         "and sends the second pass through the relocated core at 0xE310, which "
         "falls into INVIERTE_BITS.</p>"),
    ],
}

GALERIA = [
    ("titulo.png",
     "La pantalla del título, montada con los mismos pasos del cartucho: "
     "DIBUJA_MARCO (0x4D8E) descomprime la fuente en la tabla de patrones y "
     "reparte los colores, DIBUJA_PANEL_JUEGO (0x4878) llena el resto de la "
     "tabla de color, y el guión de 0x4C9E -el que vuelca "
     "PREPARA_PANTALLA_CARRERA- pinta el rótulo en las filas 5 a 7 y las dos "
     "líneas de texto con los glifos de la fuente",
     "The title screen, built with the cartridge's own steps: DIBUJA_MARCO "
     "(0x4D8E) decompresses the font into the pattern table and lays out the "
     "colours, DIBUJA_PANEL_JUEGO (0x4878) fills the rest of the colour table, "
     "and the script at 0x4C9E -the one PREPARA_PANTALLA_CARRERA dumps- paints "
     "the wordmark on rows 5 to 7 and the two lines of text with the font's "
     "glyphs"),
    ("fuente.png",
     "La fuente del cartucho, dibujada desde la ROM por "
     "<code>tools/graficos.py</code>, descomprimiendo el guión de 0x4DEA con el "
     "mismo formato que el Z80. Digitos, símbolos y el alfabeto con el que se "
     "escribe todo el juego, incluida la unidad km/h del cuentakilómetros",
     "The cartridge's font, drawn from the ROM by "
     "<code>tools/graficos.py</code>, decompressing the script at 0x4DEA with "
     "the same format the Z80 uses. Digits, symbols and the alphabet the whole "
     "game is written with, including the km/h unit of the speedometer"),
    ("tiles.png",
     "Los tiles de la carretera y el decorado que van detrás de la fuente en el "
     "mismo bloque, descomprimidos igual. Son las piezas con las que se arman "
     "los bordes del trazado y el paisaje de cada etapa",
     "The road and scenery tiles that follow the font in the same block, "
     "decompressed the same way. They are the pieces the track edges and each "
     "stage's landscape are built from"),
    # Las tres del rival llevan sus rotulos DENTRO, asi que hay una version por
    # idioma: la inglesa es el mismo nombre con _en. La escena no es una
    # captura: la pantalla se monta ejecutando en Python los descompresores del
    # cartucho (tools/carrera.py) y los coches se pintan con sus patrones.
    ("rival_acercandose.png",
     "Cómo se acerca un rival, sobre la pantalla de carrera montada ejecutando "
     "los descompresores del cartucho. El mismo coche a cuatro distancias: de "
     "lejos son sprites -uno, luego dos, luego cuatro en dos capas de color- y "
     "en el último escalón el cartucho los apaga (0x7B21, Y = 0xE0) y lo "
     "repinta con doce casillas de la pantalla",
     "How a rival comes closer, over the race screen built by running the "
     "cartridge's own decompressors. The same car at four distances: far away "
     "it is sprites -one, then two, then four in two colour layers- and on the "
     "last step the cartridge switches them off (0x7B21, Y = 0xE0) and repaints "
     "it with twelve screen tiles"),
    ("rival_escala.png",
     "Los escalones de un rival, leídos de la tabla 0x7D94: el patrón base y su "
     "altura en pantalla. Los dos bits bajos de ese patrón dicen cuántos "
     "sprites se encienden, porque 0x7A73 apaga los que sobran; el último ya no "
     "es un sprite, son cuatro por tres casillas",
     "The steps of a rival, read from table 0x7D94: the base pattern and its "
     "height on screen. The two low bits of that pattern say how many sprites "
     "light up, because 0x7A73 switches off the spare ones; the last one is not "
     "a sprite any more, it is four by three tiles"),
    ("rival_espejo.png",
     "El rival de cerca y sus doce casillas una a una. Los doce números están "
     "literales en la ROM en 0x7BF3, pero los patrones sólo a medias: 0x2A es "
     "0x24 con los bits del revés, y así hasta 0x2E. El cartucho guarda medio "
     "coche, y la otra mitad la pone DESC_DOBLE (0x44B0) pasando el mismo "
     "bloque por INVIERTE_BITS",
     "The rival up close and its twelve tiles one by one. The twelve numbers "
     "are literal in the ROM at 0x7BF3, but only half of the patterns are: 0x2A "
     "is 0x24 with its bits reversed, and so on up to 0x2E. The cartridge "
     "stores half a car, and the other half is put there by DESC_DOBLE (0x44B0) "
     "sending the same block through INVIERTE_BITS"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # que el propio cartucho pinta en su pantalla de titulo, las filas 5 a 7 del
    # guion de 0x4C9E, dibujadas desde la ROM por graficos.py. Si el PNG no
    # esta, se cae al texto.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Hyper Rally">'
                if os.path.exists(ruta_logo) else "<h1>Hyper Rally</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if idioma == "en":                   # las que llevan rotulos dentro
            otra = os.path.join(imgdir, fich.replace(".png", "_en.png"))
            if os.path.exists(otra):
                ruta = otra
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
