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
