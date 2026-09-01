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
una etapa —y varias comparten una: ocho rutinas cubren las doce—. 0xE061 (tabla
de 0x4372) no es un código de terreno sino un **campo de bits** con lo que cada
etapa hace distinto: el bit 1 hace derrapar el coche y suaviza el volante
(0x65C7 y 0x6658, la nieve), 0x01 es el túnel, 0x10 la tormenta y 0x08 la noche.
Las dos tablas casan exacto —mismo compositor, mismo 0xE061— y esa coincidencia
es la prueba de que la lectura es la buena:

| Etapa | Compositor | 0xE061 | Lo que se ve |
|---|---|---|---|
| 1, 6 | 0x51B8 | 0x00 | día: cielo cian, colinas verdes |
| 2, 10 | 0x586C | 0x01 | túnel: todo negro, luces en las dos paredes |
| 3, 9 | 0x5A44 | 0x02 | nieve: suelo blanco, montañas al fondo |
| 4 | 0x5B22 | 0x06 | nieve bajo un cielo a bandas rojas |
| 5 | 0x5B68 | 0x08 | noche: cielo negro, estrellas magenta |
| 7 | 0x5D5B | 0x10 | tormenta: cielo gris **y borde gris** |
| 8 | 0x51B8 | 0x40 | la etapa 1 más una cordillera nevada |
| 11 | 0x5D86 | 0x20 | desierto: suelo ocre, y tres pirámides que suben al final |
| 12 | 0x5E94 | 0x08 | noche: cielo azul oscuro, estrellas blancas |

0x51B8 es el compositor genérico: dentro, en 0x51DA, mira si vale 0x40 y sólo
entonces añade las montañas; por eso la etapa 8 puede compartirlo. Y el
compositor de la etapa 12 llama al de la 5, la otra nocturna.

## No hay etapa acuática: es un campo de estrellas

Una versión anterior de esta página decía que 0xE061 = 8 marcaba una etapa
corrida sobre agua. Ni lo marca ni Hyper Rally tiene etapa acuática; lo señaló
[theNestruo](https://github.com/theNestruo). 0xE061 = 8 son las dos etapas **de
noche**, la 5 y la 12, y 0x71AC no anima ninguna superficie: corre el cielo.

La rutina escribe en dieciséis casillas de la tabla de nombres (0x3884 a
0x3930, filas 4 a 9, la franja del cielo), que están listadas en 0x7229 junto a
sus dos contadores. Los tiles 0xF3 a 0xFA son **un solo píxel** recorriendo la
fila de abajo del carácter (0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01) y
0xFB lo borra: ocho subposiciones dentro de una casilla, así que cada estrella
corre a precisión de píxel, y al cerrarse el ciclo la casilla salta una columna.
El retardo entre pasos sale de la velocidad del coche (tabla de 0x7215, índice =
velocidad >> 5): diecisiete cuadros parado, diez a tope. El bit 2 de 0xE075 le
cambia el sentido.

## Las pirámides suben de fila en fila

La etapa 11 es aquella cuyo fondo theNestruo recordaba *apareciendo línea a
línea*, y así se dibuja exactamente. En todas las demás etapas 0x707A desplaza
las rayas de la carretera; cuando el bit 5 de 0xE061 está puesto —el desierto—
salta a 0x731D en su lugar.

Esa rutina lleva un contador de fila en 0xE06B y no hace absolutamente nada
hasta que 0xE071, lo que queda de etapa, vale **exactamente** el umbral que la
tabla de 0x7371 guarda para la fila que toca: `34 2C 26 20 1C 18 14 10 0E 0C 0A
08 07 06 05 04`. Los huecos se van cerrando conforme te acercas, así que las
pirámides crecen más deprisa cuanto más cerca está la meta.

Cada vez que uno se cumple se copian dieciséis bytes a la tabla de patrones
desde una **ventana deslizante** sobre 0x7351 que avanza un byte por fila. Por
lo que desliza es dieciséis ceros seguidos de `01 03 07 0F 1F 3F 7F FF` y luego
`FF` macizo: empezar dentro de los ceros e ir entrando en el triángulo es lo que
hace que la forma suba de fila en fila. La mitad izquierda va de un bloque; la
derecha se escribe byte a byte pasando por INVIERTE_BITS, o sea el mismo
triángulo **espejado** —y dos triángulos espejados son una pirámide—.

Llevada a mano por sus dieciséis pasos en openMSX, los cuatro tiles quedan
exactamente como dice la ROM: 0xB3 = `01 03 07 0F 1F 3F 7F FF`, 0xB4 macizo,
0xB5 = `80 C0 E0 F0 F8 FC FE FF` (0xB3 con los bits del revés) y 0xB6 macizo.

## La etapa de tormenta echa rayos

0x724B sólo corre cuando 0xE061 vale 0x10 —la etapa 7, la del cielo gris y,
porque 0x418E escribe 0xEE en el registro 7 del VDP, también el borde gris—.
Tras una espera al azar (0x18, 0x38, 0x58 o 0x78 cuadros: de medio segundo a dos
y medio) elige uno de los cuatro guiones de 0x72D2 —tres formas distintas—, lo
suelta en la fila 2 de la tabla de nombres, arranca el sonido 0x43, pone el
borde en 0xEF en 0x7276 y lo devuelve a 0xEE una décima después. Es un rayo, no
los fuegos artificiales de meta que esta página venía diciendo.

## Comparte el reproductor de sonido, poco más

Medido con los operandos de dieciséis bits puestos a cero, Hyper Rally comparte
el reproductor de sonido de tres canales de Konami y las rutinas del VDP con los
otros cartuchos de MSX de la casa, pero es su propio programa: la máquina de
estados, el motor de carretera y las colisiones se leyeron aquí, en esta ROM.
