# Hyper Rally (Konami, RC-718) — desensamblado comentado

Un desensamblado comentado del cartucho de MSX de 16 KB, reproducible byte a byte.

**[Lee la documentación →](https://antxiko.github.io/HyperRally-disassembly/es/)**
· [In English](README.md)

    make            # traza, genera el listado, lo reensambla y pasa los tests
    make verify     # la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     # que ni un byte quede sin explicar
    make densidad   # cuánto está comentado, rutina a rutina
    make web        # rehace la web

La ROM **no se distribuye aquí**. Va en la raíz como `hyperrally.rom`, 16384
bytes, sha256

    eca2c0d6057b3829210b5fccd0d0005ea6ada7560f5446d9bbc2db2d06d96aae

`make comprueba` lo verifica.

## Cómo está

| | |
|---|---|
| reensambla byte a byte | sí |
| bytes explicados | 16.384 de 16.384 (100 %) |
| código trazado | 6.452 bytes, 3.350 instrucciones |
| datos identificados | 9.932 bytes en 50 rangos con nombre |
| comentado | 511 comentarios de línea, 15,3 % |
| rutinas flojas (bajo el 10 %) | 0 de 428 |

Las anotaciones viven aparte del listado, ancladas a la dirección que describen,
así que sobreviven a un retrazado. Lo que guarda el fichero `.notes`:

| | |
|---|---|
| etiquetas con nombre | 429 |
| comentarios anclados | 476 |
| rangos de datos con explicación | 50 |

## Qué hay aquí

- `src/hyperrally.asm` — el listado; generado, no editado a mano
- `src/hyperrally.notes` — las anotaciones, ancladas a direcciones
- `src/hyperrally.entries` — los puntos de entrada, cada uno justificado
- `docs/` — la web, en inglés y castellano
- `tools/` — el trazador, el generador del listado, los recorredores de datos y
  el descompresor de guiones que dibuja las imágenes de la web desde la ROM

## La documentación

| | |
|---|---|
| [Empezar](docs/es/EMPEZAR.md) | qué necesitas y qué hace cada orden |
| [El juego](docs/es/EL-JUEGO.md) | un rally de doce etapas, una carretera en falso 3D y un salpicadero |
| [El cartucho](docs/es/EL-CARTUCHO.md) | la cabecera, el mapa de memoria y la pantalla |
| [El código](docs/es/EL-CODIGO.md) | la máquina de estados, los intérpretes de guiones y el sonido |
| [Hallazgos](docs/es/HALLAZGOS.md) | lo que dice el binario |
| [En el emulador](docs/es/EN-EL-EMULADOR.md) | lo que se puede medir, y cómo |
| [Preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md) | lo que aún no está cerrado |

Ver `AVISO-LEGAL.md`.
