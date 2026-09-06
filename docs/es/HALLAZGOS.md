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

## De cerca, el rival deja de ser sprites

Son tres rivales, con fichas de tres bytes en 0xE090, 0xE093 y 0xE096. 0x79D8
clasifica a cada uno en tres niveles de cercanía —suma 0x10 a la ficha y compara
contra 0x26 y 0x38— y deja el nivel en 0xE09E. 0x7C34 se queda con el más
cercano de los tres.

Esos tres niveles son **métodos de dibujo, no tallas**: forzando a todos los
rivales por la misma rama salen a la vez un coche grande y uno pequeño, o sea
que la talla la pone un índice escalado dentro de cada rama (0x7A10 lo desplaza
y lo desvía, e indexa la tabla de sombras de 0x7F47 por la fase de animación).

Lo que pasa cuando un rival se te pone al lado es que **0x7B21 escribe 0xE0 en
la Y de sus cuatro sprites**: los apaga. Visto jugando: ocho pasadas seguidas
por ahí mientras la ficha de un rival subía de 0x29 a 0x45 y su nivel pasaba de
1 a 2, con ese coche grande y pegado en pantalla. Así que el rival cercano no
son esos sprites, que es lo que
[theNestruo](https://github.com/theNestruo) describía como sprites primero y
tiles al acercarse.

Dónde aparece el siguiente lo decide 0x7F65, y sólo en la fase 0 de 0xE003: la
mitad de las veces (por el registro de refresco) la X es 0x1F, y si no sale de
(etapa − 1) mod 4 — 0x7F, 0x5F, 0x3F, 0x1F. **Cicla cada cuatro etapas**, no
crece con la etapa. Medida en las doce, la X de aparición es exactamente la que
predice esa cuenta, sin una sola excepción.

## Un rival no tiene recorrido propio

La ficha de tres bytes se cierra poniendo un punto de observación de escritura
sobre cada byte y apuntando sólo contadores de programa
(`tools/omsx_recorrido.tcl`). En 45 segundos de carrera, **cada byte tiene
exactamente un escritor** y nadie más lo toca:

| byte | quién lo escribe | veces |
|---|---|---|
| 0xE090 | 0x7CE6 | 425 |
| 0xE091 | 0x7D17 | 270 |
| 0xE092 | 0x79D5 | 682 |

El byte 0 es la posición relativa a ti, y da la vuelta entera. El byte 1 es por
dónde te cruza. Y el byte 2 no es una propiedad del rival: es **el byte 0 tal
como estaba el cuadro anterior**.

**0x7CCB no es un impacto.** El listado lo llamaba así y decía que frenaba de
golpe según la velocidad del choque, y no toca tu velocidad para nada. Lo único
que escribe es el byte 0:

    ld a,(0e085h) / sub c / rrca x4 / and 00fh    ; (con neg a los dos lados)
    ld a,(hl) / sub c / ld (hl),a

o sea **byte 0 += (velocidad del rival − la tuya) / 16**. Es el motor entero del
acercamiento, y no hay ninguna otra escritura sobre el byte 0 en todo el
cartucho. En una carrera de 45 segundos con **cero choques** —0x7FAC, donde un
golpe se da por bueno, saltó 0 veces, y la sacudida de 0x7D32 tampoco— corrió
**1329 veces** en esa misma pasada.

La fórmula se comprobó sin ningún muestreo por medio, leyendo la velocidad del
jugador y la del rival a la entrada de 0x7CCB y el registro A que el Z80 había
calculado a la salida (`tools/omsx_paso_rival.tcl`). Rehecha en Python
reproduce **102 de 102** casos distintos sobre esas 1329 pasadas
(`tools/control_recorrido.py`, y `make control` lo ejecuta).

## 0xE09C no es un color: es la velocidad del rival

El listado decía que 0x79A9 "elige el color aleatorio del próximo rival". Ese
byte **no llega nunca a la VRAM**: el único sitio que lo lee es 0x7C65, dentro
de la resta de arriba. Forzarlo lo zanja —mismo piloto, mismos 45 segundos—:

| 0xE09C | el byte 0 sube | baja | neto |
|---|---|---|---|
| forzado a 0x00 | **ninguna vez** | 1535 | −9788 |
| forzado a 0xFF | 1357 | **ninguna vez** | +13298 |
| sin tocar | 1327 | 0 | +5989 |

Con el rival "parado" te los comes a todos; con el rival a tope se te escapan
todos. El signo se invierte entero. Si fuese un color no cambiaría nada.

0x79A9 lo sortea como **base + (R & 3) × 8**, y la base sale de la etapa: 0xA0, o
0x88 con el bit 2 de 0xE060 puesto. O sea que las etapas 4-7 y 12 son las que
pueden dar rivales **más lentos que tú** (0x88 = 136 contra un tope medido de
143), y a ésos los alcanzas por detrás.

## El byte 1 es dónde estabas TÚ, no el carril del que venía

0x7D02 lo escribe mirando 0xE121, la X del primer sprite del coche del jugador,
repartida en cuatro franjas. Con el piloto barriendo la carretera de lado a
lado, 975 pasadas por el `ld (hl),e` de 0x7D17:

| byte 1 | X medida | franja en el código |
|---|---|---|
| 0 | 44..88 | < 0x59 |
| 3 | 90..112 | 0x59..0x70 |
| 4 | 114..152 | 0x71..0x98 |
| 1 | 154..195 | ≥ 0x99 |

975 de 975 dentro de su franja, cero excepciones. (El 89 no aparece porque la X
del coche va de dos en dos.)

## 0x6B7D no escribe en la VRAM: es el marcador RANK

Se llamaba COLOCA_RIVALES_VRAM y no escribe una sola casilla. Lo que hace es
comparar el byte 0 con el byte 2 —dónde está el rival ahora contra dónde estaba
el cuadro anterior— contra el umbral **0x17**, y cuando uno lo cruza, mueve el
número BCD de tres dígitos de 0xE05B/0xE05C: arriba por 0x6BB5, abajo por
0x6BC0, y ésa además paga SUMA_PUNTOS 0x0250. Sale por un `pop hl`, así que
mueve **como mucho un puesto por cuadro**.

Ese número es el **RANK** de abajo a la derecha del salpicadero, y se empieza la
carrera **el 680**: 0x435A carga HL con 0x8006 y lo mete en 0xE05B, que en BCD
es 0680. O sea que un rival que te pasa te cuesta un puesto y uno al que pasas
te gana uno, más 250 puntos.

Medido en 45 segundos con el acelerador clavado y sin girar nunca, el puesto
pasó de 0680 a 0704 —**24 puestos perdidos**— y la rama que sube saltó
exactamente **24** veces, la que baja 0. Que es lo que tiene que pasar: en esa
etapa todos los rivales son más rápidos que un coche clavado a 143.

## ¿Hay más coches cruzando en las etapas altas?

A igualdad de conducción, no. Doce pasadas, una por etapa, mismo piloto con el
acelerador clavado, 40 segundos cada una (`tools/omsx_cruces_etapa.tcl`):

| etapa | bit 2 | cruces | velocidades del rival | X de aparición |
|---|---|---|---|---|
| 1 | 0 | 18 | A0 A8 B0 B8 | 1F, 7F |
| 2 | 0 | 17 | A0 A8 B0 B8 | 1F, 5F |
| 3 | 0 | 17 | A0 A8 B0 B8 | 1F, 3F |
| 4 | 1 | 15 | **88 90 98** + A0 A8 B0 B8 | 1F |
| 5 | 1 | 15 | **88 90 98** + A0 A8 B0 B8 | 1F, 7F |
| 6 | 1 | 15 | **88 90 98** + A0 A8 B0 B8 | 1F, 5F |
| 7 | 1 | 15 | **88 90 98** + A0 A8 B0 B8 | 1F, 3F |
| 8 | 0 | 18 | A0 A8 B0 B8 | 1F |
| 9 | 0 | 17 | A0 A8 B0 B8 | 1F, 7F |
| 10 | 0 | 17 | A0 A8 B0 B8 | 1F, 5F |
| 11 | 0 | 18 | A0 A8 B0 B8 | 1F, 3F |
| 12 | 1 | 14 | **88 90 98** + A0 A8 B0 B8 | 1F |

Los cruces no crecen con la etapa —de 14 a 18 en las doce— y las etapas con el
bit 2 puesto tienen **menos**, no más. Lo que sí cambia con la etapa son las
otras dos columnas: la X de aparición cicla cada cuatro, y las etapas 4-7 y 12
ponen rivales más lentos en la carretera. Un rival lento es uno al que llegas
por detrás y con el que te quedas emparejado, en vez de uno que te pasa de
largo, y ése se queda en pantalla mucho más rato.

El piloto de estas pasadas no gira nunca y siempre llega a 143, así que los
números comparan unas etapas con otras —que es lo que se pregunta— y no son una
cuenta absoluta de una carrera de verdad.

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
