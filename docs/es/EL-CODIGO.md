# El código

## La máquina de estados

La interrupción (0x4051) llama a 0x4089 cada cuadro. Lee la palabra de 0xE000:
el byte bajo es el **estado principal**, de 0 a 8, y con él un salto por la tabla
de 0x40AA llega a uno de nueve manejadores; el byte alto es el **subestado**, y
cada manejador lo reparte con cadenas de `djnz`. Cambiar de estado es escribir
0xE000; avanzar un subestado es `inc (0xE001)`. No hay más hilos: todo es esta
única interrupción.

## Dibujar por guiones

Nada de lo que sale en pantalla es un mapa de bits guardado. Tres intérpretes
arman la VRAM:

- **0x446D** descomprime guiones de rachas (un byte de cuenta, y luego una racha
  literal o un byte repetido) a la tabla de nombres o de patrones.
- **0x45EC** copia bloques: `[destino][cuenta][bytes]` hasta un 0xFF.
- **0x455A** dibuja los rótulos grandes, y se copia a la RAM (0xE1C0) para correr
  allí.

La fuente y los tiles de la carretera son uno de esos guiones, en 0x4DEA; las
imágenes de esta web se dibujan ejecutando ese mismo descompresor en Python.

## La carretera

No hay matemática de perspectiva. 0x68D0 lee la curvatura de 0xE074 e indexa la
tabla de formas de carretera de 0x767C para elegir qué dibujar; 0x707A desplaza
las rayas hacia el jugador; los objetos del borde se escalan por profundidad con
las tablas de 0x6CD5.

## El sonido

0x5FB7 es el reproductor de cada cuadro: tres fichas de canal de catorce bytes en
0xE010, cada una leyendo su melodía con un pequeño intérprete de órdenes y
escribiendo el PSG por la BIOS. 0x5ED9 arranca una melodía o un efecto por su
número, mirando antes la prioridad. Es el armazón que Konami reutilizó entre sus
cartuchos de MSX.
