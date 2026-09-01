# omsx_juega_etapa.tcl - Deja el juego SIEMPRE en la etapa que se pida, para
# jugarla a mano.
#
# A diferencia de omsx_fondos.tcl, este NO pulsa teclas ni vuelca nada ni cierra
# el emulador: se limita a poner el numero de etapa (y su parametro 0xE061)
# cada vez que el juego va a componer un fondo, en 0x4813. Arrancas la partida
# tu y siempre te toca esa etapa, tambien al pasar de una a la siguiente.
#
# El parametro sale de la MISMA tabla del cartucho (0x4371+N), leida en marcha.
#
#   HR_ETAPA=7 openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_juega_etapa.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}
set ::ETAPA [opcion HR_ETAPA 7]

debug set_bp 0x4813 {} {
    debug write memory 0xE060 $::ETAPA
    debug write memory 0xE061 [debug read memory [expr {0x4371 + $::ETAPA}]]
}
