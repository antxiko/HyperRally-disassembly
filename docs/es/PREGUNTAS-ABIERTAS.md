# Preguntas abiertas

Lo que el binario no cierra por sí solo:

- **Una rutina de dibujo sin quien la llame.** 0x4DCC dibuja diecinueve filas de
  dieciséis bytes desde 0x518E, decodifica limpio hasta su `ret` de 0x4DE9, y sin
  embargo ninguna instrucción de la ROM la referencia. Se desensambla como
  código, con la nota de que puede ser un resto.
- **El significado exacto de cada uno de los nueve estados.** Están nombrados por
  lo que hace su código (arranque de etapa, cuenta atrás, carrera, resultados);
  atar cada número a la pantalla que pinta pediría una partida con 0xE000 a la
  vista.
- **Las melodías no están despiezadas.** Los datos de sonido de 0x61C5 son una
  tabla de punteros de melodía seguida de las melodías; el reproductor se
  entiende, pero las notas de cada tema no se transcriben aquí.
- **El dibujado de una pantalla entera.** La web dibuja la fuente y los tiles de
  la carretera desde la ROM; componer una pantalla de etapa entera pediría portar
  a Python también el intérprete de guiones de dos capas (0x44B0) y el
  renderizador de la carretera.
- ~~**¿Código o datos en 0x68BE?**~~ **CERRADA el 2026-09-15: son datos.** Lo
  que empujan 0x6868 y 0x68A2 no es una dirección de retorno sino un **puntero**:
  `CUENTAKM_INDEXA` lo recoge con el `pop hl` de 0x6894, le suma el índice de
  0xE075 y lee el byte con `ld c,(hl)`. Son dos tablas de nueve bytes, la de día
  en 0x68BE y la de noche en 0x68C7, y el trazado las había seguido como código
  porque dio el `push` por un retorno; de ahí salía el `ld (2F2Fh),a` sobre la
  ROM de la BIOS, que no existe. Ya están en el listado como datos, y el
  cartucho sigue reensamblando byte a byte.
