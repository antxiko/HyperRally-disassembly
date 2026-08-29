# En el emulador

El listado y cada cifra de esta web salen del binario y se reproducen con `make`.
Aquí no se ha medido nada a ojo.

## Ejecutarlo

    openmsx -machine Philips_VG_8020 -cart hyperrally.rom

Basta una máquina MSX1; el cartucho se mapea en la página 1 y mueve todo desde la
interrupción de cada cuadro.

## Qué se puede medir

Para confirmar un estado o una cadencia, pon un breakpoint y vigila la RAM que
nombran las notas: 0xE000 es el estado principal, 0xE060 la etapa, 0xE085 la
velocidad. El coste por cuadro de una rutina es la diferencia de
`machine_info time` entre un breakpoint en su entrada y otro en su `ret`, por
3579545 para dar los ciclos del Z80.

Las rutas de salida de cualquier script Tcl tienen que ser de Windows, nunca
`/tmp`.
