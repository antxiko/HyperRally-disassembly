# omsx_paso_rival.tcl - La formula del recorrido, medida DENTRO de la rutina.
#
# Muestrear la traza cada cuadro deja un 13 % de cambios del byte 0 que salen
# uno corto: entre la muestra y el instante en que el Z80 hace la cuenta, el
# jugador ha acelerado y la velocidad ya no es la que se leyo. No es un fallo
# del modelo, es que la muestra no es simultanea.
#
# Aqui no se muestrea: se lee todo DENTRO de 0x7CCB.
#
#   0x7CCB, a la entrada  -> 0xE085 (velocidad del jugador) y C (la del rival)
#   0x7CE3, a la salida   -> A, que es el paso ya calculado por el Z80
#
# Con esos tres numeros, el control es exacto: si `(vel - vrival) >> 4` con la
# saturacion de cuatro bits no da el A del Z80, la lectura del listado esta mal.
#
#   openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_paso_rival.tcl
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/recorrido"]
set ::SEGS   [expr {[opcion HR_SEGS 45]}]
file mkdir $::SALIDA
set renderer none
set throttle off

set ::corriendo 0
set ::listo 0
set ::vel 0
set ::vr 0
set ::casos [dict create]

debug set_bp 0x4813 {} {
    if {!$::corriendo} {
        debug write memory 0xE060 1
        debug write memory 0xE061 [debug read memory 0x4372]
        set ::corriendo 1
        after time [expr {double($::SEGS)}] informe
    }
}
debug set_bp 0x6943 {} {
    if {$::corriendo} {
        debug write memory 0xE00A [expr {([debug read memory 0xE00A] & 0xEE) | 0x10}]
    }
}
# a la entrada: la velocidad del jugador y la del rival, sin desfase
debug set_bp 0x7ccb {} {
    set ::vel [debug read memory 0xE085]
    set ::vr [reg c]
}
# a la salida: el paso que ha calculado el Z80
debug set_bp 0x7ce3 {} {
    dict incr ::casos [format "%d,%d,%d" $::vel $::vr [reg a]]
}

proc informe {} {
    if {$::listo} return
    set ::listo 1
    set f [open "$::SALIDA/paso.csv" w]
    puts $f "vel,vrival,paso,veces"
    foreach k [lsort [dict keys $::casos]] {
        puts $f "$k,[dict get $::casos $k]"
    }
    close $f
    exit
}
after realtime [expr {$::SEGS + 150}] { catch {informe} ; exit }

set ::turno 0
proc teclea {} {
    if {$::corriendo} return
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 { keymatrixup 8 0x01 ; keymatrixup 0 0x02 ; after time 0.7 teclea }
}
after time 6.0 teclea
