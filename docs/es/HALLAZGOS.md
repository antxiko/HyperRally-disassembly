# Hallazgos

## Lleva la marca oculta de Konami

Detrás del relleno del final de la ROM, Konami escondía en muchos cartuchos su
número de catálogo y el título en katakana. El hallazgo no es nuestro: lo
descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) y explicó el formato. En
Hyper Rally los últimos once bytes, desde 0x7FF5, son el título al revés, su
longitud (8), el **18** del RC-718 en BCD, y el 0xAA que cierra la marca.
`tools/marca_konami.py` la lee.

## Todo el juego es una interrupción

INIT cae en un `jr` muerto en 0x404F y no vuelve. Cada cuadro la interrupción lee
el estado de 0xE000 y salta por la tabla de nueve manejadores de 0x40AA; dentro
de cada manejador el subestado de 0xE001 mueve una cadena de `djnz`. Es una forma
compacta de encadenar pantallas y fases con dos bytes de estado.

## La carretera es una tabla, no geometría

0x68D0 convierte la curvatura de 0xE074 en un índice de la tabla de formas de
0x767C. Las rayas se mueven desplazando un buffer (0x707A) al ritmo de la
velocidad, y el escalado de los objetos del borde por profundidad sale de las
tablas de 0x6CD5. Ni multiplicaciones ni divisiones: lo que la carretera necesita
está precalculado en tablas.

## Doce etapas con ocho compositores

0xE060 (1..0x0C) elige, por la tabla de 0x481A, la rutina que compone el fondo de
una etapa —y varias etapas comparten una—. El parámetro de terreno 0xE061 (de
0x4372) decide la superficie: cuando vale 8 la etapa es acuática y 0x71AC anima
la superficie aparte.

## Comparte el reproductor de sonido, poco más

Medido con los operandos de dieciséis bits puestos a cero, Hyper Rally comparte
el reproductor de sonido de tres canales de Konami y las rutinas del VDP con los
otros cartuchos de MSX de la casa, pero es su propio programa: la máquina de
estados, el motor de carretera y las colisiones se leyeron aquí, en esta ROM.
