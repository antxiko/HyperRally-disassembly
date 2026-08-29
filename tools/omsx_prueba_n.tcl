# Fotografia UNA prueba desde una partida limpia.
#
# 0x4216 arranca la partida poniendo 0xE015 y 0xE016 a 1. Aqui se para justo
# despues (0x422E) y se cambia 0xE016 por la prueba que se quiere ver; de ahi
# en adelante corre el juego solo, con sus datos. Es una MEDIDA: no se toca el
# cartucho, solo el numero de prueba que el propio juego usa como indice.
#
# Uso: PRUEBA=2 openmsx -machine Philips_VG_8020 -cart hyperolympic2.rom \
#                       -script tools/omsx_prueba_n.tcl

proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::N [opcion PRUEBA 1]
set ::SALIDA [file normalize [opcion SALIDA "work/omsx"]]
file mkdir $::SALIDA

set renderer SDLGL-PP
set throttle on

proc tecla {f m} { keymatrixdown $f $m ; after time 0.15 "keymatrixup $f $m" }

debug set_bp 0x422E {} {
    debug write memory 0xE016 $::N
    debug remove_bp [lindex [debug list_bp] 0 0]
}

after time 12 {
    tecla 8 0x40
    after time 0.6 { tecla 8 0x40 ; after time 0.6 { tecla 8 0x01 } }
}

after time 26 {
    screenshot -raw [file join $::SALIDA "limpia$::N.png"]
    set f [open [file join $::SALIDA "limpia$::N.txt"] w]
    foreach {d n} {0xE015 ronda 0xE016 prueba 0xE010 dos_jugadores 0xE01B opcion
                   0xE021 en_juego 0xE025 intento 0xE016 prueba2} {
        puts $f [format "%s %-14s %02X" $d $n [debug read memory $d]]
    }
    close $f
    exit
}
after realtime 120 { exit }
