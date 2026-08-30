# Fotografia las cuatro pruebas del cartucho, para saber CUALES son.
#
# El cartucho encadena pruebas con 0xE016 (1..4) y las monta desde 0x4234. En
# vez de jugarlas -que exige clasificar en cada una-, se pone 0xE016 a mano y
# se salta a 0x4234 con la pila en su sitio (0xE3FE, la que deja INIT). Es una
# MEDIDA, no una modificacion del cartucho: la pantalla que sale la dibuja el
# propio juego con sus propios datos.
#
# Uso: openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#              -script tools/omsx_pruebas.tcl

set ::SALIDA [file normalize "work/omsx"]
file mkdir $::SALIDA

set renderer SDLGL-PP
set throttle on

proc tecla {fila mascara} {
    keymatrixdown $fila $mascara
    after time 0.15 "keymatrixup $fila $mascara"
}
proc espacio {} { tecla 8 0x01 }
proc abajo   {} { tecla 8 0x40 }

proc foto {nombre} {
    screenshot -raw [file join $::SALIDA "$nombre.png"]
    set f [open [file join $::SALIDA "$nombre.txt"] w]
    foreach {d n} {0xE015 ronda 0xE016 prueba 0xE010 dos_jugadores 0xE01B opcion
                   0xE004 joystick 0xE021 en_juego 0xE025 intento} {
        puts $f [format "%s %-14s %02X" $d $n [debug read memory $d]]
    }
    puts $f "tiempo [machine_info time]"
    close $f
}

after time 12 {
    foto titulo
    abajo
    after time 0.6 { abajo ; after time 0.6 {
        foto menu_1jug_teclado
        espacio
        after time 9 { paso 1 }
    } }
}

proc paso {n} {
    foto "prueba$n"
    if {$n >= 4} { after time 1 { exit } ; return }
    debug write memory 0xE016 [expr {$n + 1}]
    debug write memory 0xE015 [expr {$n + 1}]
    reg sp 0xE3FE
    reg pc 0x4234
    after time 12 "paso [expr {$n + 1}]"
}

after realtime 200 { foto perro ; exit }
