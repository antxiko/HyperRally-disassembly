# Mide a que ritmo corre el reloj de la prueba comparado con el reloj de verdad.
#
# 0x5695 suma 0x0166 o 0x0167 al contador BCD de 0xE0A9-0xE0AB una vez por
# cuadro. Si eso son centesimas de segundo, la media -1,665- es un sesentavo,
# y el reloj solo va bien en una maquina de 60 Hz. Aqui se comprueba corriendo
# los 100 metros con el boton apretado y muestreando las dos cosas.
#
# Uso: openmsx -machine <maquina> -cart hyperrally.rom \
#              -script tools/omsx_reloj.tcl

proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [file normalize [opcion SALIDA "work/omsx"]]
set ::NOMBRE [opcion NOMBRE "reloj"]
file mkdir $::SALIDA

set renderer SDLGL-PP
set throttle on

proc tecla {f m} { keymatrixdown $f $m ; after time 0.12 "keymatrixup $f $m" }

# el menu: dos veces abajo (1 jugador, teclado) y espacio
after time [opcion ARRANQUE 12] { tecla 8 0x40 ; after time 0.6 { tecla 8 0x40 ; after time 0.6 { tecla 8 0x01 } } }

# machaca el espacio, que es lo que hace correr al atleta
proc machaca {} {
    keymatrixdown 8 0x01
    after time 0.04 { keymatrixup 8 0x01 }
    after time 0.08 machaca
}
after time [expr {[opcion ARRANQUE 12] + 10}] machaca

proc bcd {a} { return [format %02X [debug read memory $a]] }

set ::t0 0
proc muestra {n} {
    set r "[bcd 0xE0A9][bcd 0xE0AA][bcd 0xE0AB]"
    if {$::t0 == 0 && $r ne "000000"} { set ::t0 [machine_info time] }
    lappend ::filas [list [format %.3f [machine_info time]] $r]
    if {$n <= 0} {
        set f [open [file join $::SALIDA "$::NOMBRE.txt"] w]
        puts $f "maquina: [machine_info config_name]"
        puts $f "tiempo_emulado  reloj_del_juego(BCD)"
        foreach x $::filas { puts $f "  [lindex $x 0]        [lindex $x 1]" }
        close $f
        screenshot -raw [file join $::SALIDA "$::NOMBRE.png"]
        exit
    }
    after time 1 "muestra [expr {$n - 1}]"
}
after time [expr {[opcion ARRANQUE 12] + 12}] { muestra 12 }
after realtime 150 { exit }
