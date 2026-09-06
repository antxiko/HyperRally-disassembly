# omsx_lado_cruce.tcl - El byte 1 de la ficha del rival: quien lo decide.
#
# 0x7D02 escribe el byte 1 de la ficha mirando 0xE121, que es la X del primer
# sprite del coche DEL JUGADOR (0x65FE la escribe ahi). O sea: el byte 1 no dice
# por que carril viene el rival, sino DONDE ESTABAS TU cuando el rival llego a
# tu altura. La aritmetica reparte en cuatro franjas:
#
#     < 0x59        -> 0        0x59..0x70 -> 3
#     0x71..0x98    -> 4        >= 0x99    -> 1
#
# Con el coche clavado en el centro (el piloto de las otras medidas no gira) el
# byte 1 sale casi siempre 0 y no se comprueba nada. Aqui el piloto BARRE la
# carretera de lado a lado, y un punto de ruptura en 0x7D17 -el `ld (hl),e` que
# escribe el byte- apunta el par (0xE121, valor escrito). Si el mapa medido
# coincide con las cuatro franjas, queda cerrado.
#
#   openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_lado_cruce.tcl
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/recorrido"]
set ::SEGS   [expr {[opcion HR_SEGS 60]}]
file mkdir $::SALIDA
set renderer none
set throttle off

set ::corriendo 0
set ::listo 0
set ::pares [dict create]
set ::xs    [dict create]

debug set_bp 0x4813 {} {
    if {!$::corriendo} {
        debug write memory 0xE060 1
        debug write memory 0xE061 [debug read memory 0x4372]
        set ::corriendo 1
        after time 1.0 barre
        after time [expr {double($::SEGS)}] informe
    }
}
# acelerador a fondo (bit 4) mas el giro que toque. Los bits del mando 0xE00A
# estan medidos en work/omsx/teclas.txt: 0x10 acelerador, 0x01 freno,
# 0x04 izquierda, 0x08 derecha.
set ::dir 0x04
debug set_bp 0x6943 {} {
    if {$::corriendo} {
        debug write memory 0xE00A [expr {([debug read memory 0xE00A] & 0xE2) | 0x10 | $::dir}]
    }
}
# el barrido: un segundo a un lado, un segundo al otro
proc barre {} {
    if {$::listo} return
    set ::dir [expr {$::dir == 0x04 ? 0x08 : 0x04}]
    after time 1.0 barre
}

# el par (X del jugador, valor que se escribe en el byte 1)
debug set_bp 0x7d17 {} {
    dict incr ::pares [format "%d,%d" [debug read memory 0xE121] [reg e]]
    dict incr ::xs [debug read memory 0xE121]
}

proc informe {} {
    if {$::listo} return
    set ::listo 1
    set f [open "$::SALIDA/lado_cruce.txt" w]
    set tot 0 ; dict for {k n} $::pares { incr tot $n }
    puts $f "pasadas totales : $tot"
    puts $f "X del jugador vista : de [lindex [lsort -integer [dict keys $::xs]] 0] a [lindex [lsort -integer [dict keys $::xs]] end]"
    puts $f ""
    puts $f "valor  X minima  X maxima  veces   (franja esperada)"
    foreach v {0 1 3 4} {
        set mn 999 ; set mx -1 ; set n 0
        dict for {k c} $::pares {
            lassign [split $k ,] x vv
            if {$vv == $v} {
                if {$x < $mn} { set mn $x }
                if {$x > $mx} { set mx $x }
                incr n $c
            }
        }
        if {$n == 0} { puts $f [format "%5d  %8s  %8s  %5d" $v "-" "-" 0] ; continue }
        puts $f [format "%5d  %8d  %8d  %5d" $v $mn $mx $n]
    }
    puts $f ""
    puts $f "esperado: <0x59(89)->0   0x59..0x70(89..112)->3   0x71..0x98(113..152)->4   >=0x99(153)->1"
    puts $f ""
    puts $f "todos los pares (X del jugador, byte 1, veces):"
    foreach k [lsort -command cmpx [dict keys $::pares]] {
        lassign [split $k ,] x v
        puts $f [format "  X=%3d (0x%02X)  byte1=%d  x%d" $x $x $v [dict get $::pares $k]]
    }
    close $f
    exit
}
proc cmpx {a b} {
    set xa [lindex [split $a ,] 0] ; set xb [lindex [split $b ,] 0]
    if {$xa < $xb} { return -1 } elseif {$xa > $xb} { return 1 } else { return 0 }
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
