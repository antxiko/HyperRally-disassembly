#!/usr/bin/env python3
"""Control: la formula del recorrido contra lo que hizo el juego de verdad.

El listado dice que el byte 0 de la ficha del rival lo mueve 0x7CCB asi:

    ld a,(0e085h) / sub c / rrca x4 / and 00fh   ; (y con neg a los dos lados)
    ld a,(hl) / sub c / ld (hl),a

o sea `byte 0 -= (velocidad del jugador - la del rival) >> 4`, con el resultado
saturado a cuatro bits. Aqui se rehace esa cuenta en Python y se compara con el
paso que el Z80 calculo de verdad, leido DENTRO de la rutina por
`tools/omsx_paso_rival.tcl` (a la entrada la velocidad del jugador y la del
rival; a la salida el registro A ya calculado). Sin muestreo por medio, asi que
o cuadran los 102 casos o la lectura del listado esta mal.

Uso: control_recorrido.py [work/omsx/recorrido/paso.csv]
"""
import csv
import sys


def paso(vel, vrival):
    """Lo que 0x7CCB deja en A: el Z80, instruccion a instruccion."""
    a = (vel - vrival) & 0xFF
    if vel >= vrival:                      # sub sin acarreo
        return (a >> 4) & 0x0F             # rrca x4 + and 0x0F
    a = (-a) & 0xFF                        # neg
    return (-((a >> 4) & 0x0F)) & 0xFF     # rrca x4 + and 0x0F + neg


def main(ruta):
    filas = list(csv.DictReader(open(ruta)))
    if not filas:
        print("no hay casos en %s" % ruta)
        return 1
    malos = []
    veces = 0
    for f in filas:
        vel, vr, real, n = (int(f["vel"]), int(f["vrival"]),
                            int(f["paso"]), int(f["veces"]))
        veces += n
        mio = paso(vel, vr)
        if mio != real:
            malos.append((vel, vr, real, mio, n))

    print("casos distintos (velocidad, velocidad del rival) : %d" % len(filas))
    print("pasadas por 0x7CCB                               : %d" % veces)
    print("los reproduce la formula                         : %d de %d"
          % (len(filas) - len(malos), len(filas)))
    if malos:
        print()
        for vel, vr, real, mio, n in malos:
            print("  vel=%3d vrival=%3d  el Z80 dio %3d y la formula %3d  (x%d)"
                  % (vel, vr, real, mio, n))
        return 1
    print()
    print("Cuadran todos. El byte 0 avanza (velocidad del rival - la tuya) / 16.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1
                  else "work/omsx/recorrido/paso.csv"))
