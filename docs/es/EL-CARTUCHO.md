# El cartucho

16 KB en la página 1 (0x4000–0x7FFF), sin cambio de banco. La cabecera "AB"
declara solo **INIT** (0x4010); STATEMENT, DEVICE y TEXT van a cero.

## Qué hace INIT

INIT pone modo de interrupción 1, escribe un `jp` en el gancho H.KEYI (0xFD9A)
que apunta a **0x4051**, pone la pila en 0xE800, limpia la RAM de trabajo
0xE000–0xE7FF, prepara el VDP y la primera pantalla, y cae en un `jr` a sí mismo
en 0x404F. A partir de ahí el programa principal no hace nada: la interrupción,
una vez por cuadro, mueve todo el juego.

## La pantalla

SCREEN 2. La tabla de nombres está en 0x3800 y la de atributos de sprite en
0x3B00. El cartucho no guarda pantallas enteras: guarda guiones comprimidos que
un descompresor (0x446D, con su núcleo `out (c),a` reubicado a 0xE310) vuelca a
la VRAM.

## El mapa de la RAM

Todo lo que el juego toca vive de 0xE000 hacia arriba, bajo la pila:

- **0xE000** estado principal (0..8), el índice en la tabla de saltos de 0x40AA
- **0xE001** subestado, repartido por las cadenas de `djnz` de cada manejador
- **0xE004** un retardo en cuadros que los manejadores cargan y esperan
- **0xE010–0xE03A** los tres canales de sonido, catorce bytes cada uno
- **0xE055–0xE058** la puntuación y la mejor marca en BCD
- **0xE060** el número de etapa (1..0x0C); **0xE061** su parámetro de terreno
- **0xE074** la curvatura de la carretera; **0xE085** la velocidad
- **0xE120..** las fichas de sprite del coche y los rivales
