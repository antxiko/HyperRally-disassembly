# omsx_velocidad_rival.tcl - 0xE09C: ¿el color del rival, o su velocidad?
#
# El listado dice en 0x79A9 "elige el color aleatorio del proximo rival" y deja
# en 0xE09C el valor 0xA0+(R&3)*8 (o 0x88+... en ciertas etapas). Pero ese byte
# no llega nunca a la VRAM: el UNICO sitio que lo lee es 0x7C65, dentro de la
# aritmetica que mueve la ficha del rival:
#
#     ld a,(0e085h)   ; la velocidad del jugador
#     sub c           ; menos 0xE09C
#     ... /16 ...     ; y el resultado se le RESTA al byte 0 de la ficha
#
# Si 0xE09C fuese un color, forzarlo no cambiaria como se acercan los rivales.
# Si es la velocidad del rival, forzarlo a 0x00 hace que el jugador se los coma
# a todos, y forzarlo a 0xFF hace que se le escapen. Se mide el SIGNO del
# avance del byte 0 en los dos casos.
#
#   HR_VRIVAL=0x00 openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_velocidad_rival.tcl
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/recorrido"]
set ::VR   [opcion HR_VRIVAL "libre"]
set ::SEGS [expr {[opcion HR_SEGS 45]}]
file mkdir $::SALIDA

set ::corriendo 0
set ::listo 0
set ::traza {}

debug set_bp 0x4813 {} {
    if {!$::corriendo} {
        debug write memory 0xE060 1
        debug write memory 0xE061 [debug read memory 0x4372]
        set ::corriendo 1
        after time 1.0 muestrea
        after time [expr {double($::SEGS)}] informe
    }
}
debug set_bp 0x6943 {} {
    if {$::corriendo} {
        debug write memory 0xE00A [expr {([debug read memory 0xE00A] & 0xEE) | 0x10}]
    }
}
# se le pisa el valor justo DESPUES de que 0x79A9 lo sortee
if {$::VR ne "libre"} {
    set ::VRV [expr {$::VR}]
    debug set_bp 0x79c6 {} { debug write memory 0xE09C $::VRV }
}

# cada pasada por 0x7CCB: la velocidad del jugador y el 0xE09C que se le resta
set ::pasadas 0
set ::vmin 999
set ::vmax -999
debug set_bp 0x7ccb {} {
    incr ::pasadas
    set v [debug read memory 0xE085]
    if {$v < $::vmin} { set ::vmin $v }
    if {$v > $::vmax} { set ::vmax $v }
}

proc muestrea {} {
    if {$::listo} return
    after time 0.02 muestrea
    catch {
        lappend ::traza [list [debug read memory 0xE090] [debug read memory 0xE093] \
            [debug read memory 0xE096] [debug read memory 0xE085] [debug read memory 0xE09C] \
            [debug read memory 0xE05B] [debug read memory 0xE05C]]
    }
}

proc informe {} {
    if {$::listo} return
    set ::listo 1
    # el avance del byte 0 de cada rival, con envoltura, sumado a lo largo de la partida
    set sube 0 ; set baja 0 ; set suma 0
    for {set i 1} {$i < [llength $::traza]} {incr i} {
        set a [lindex $::traza [expr {$i-1}]]
        set b [lindex $::traza $i]
        foreach j {0 1 2} {
            set d [expr {([lindex $b $j] - [lindex $a $j]) & 0xFF}]
            if {$d > 128} { set d [expr {$d - 256}] }
            if {$d > 0} { incr sube } elseif {$d < 0} { incr baja }
            incr suma $d
        }
    }
    set u [lindex $::traza end]
    set f [open "$::SALIDA/vrival_$::VR.txt" w]
    puts $f "0xE09C forzado a : $::VR"
    puts $f "muestras         : [llength $::traza]"
    puts $f "pasadas por 0x7CCB: $::pasadas   (velocidad del jugador entre $::vmin y $::vmax)"
    puts $f "avance del byte 0 : sube $sube veces, baja $baja veces, neto $suma"
    puts $f "velocidad final   : [lindex $u 3]"
    puts $f "0xE09C final      : [lindex $u 4]"
    puts $f "contador 0xE05B/5C: [format %02X%02X [lindex $u 5] [lindex $u 6]]"
    close $f
    exit
}
after realtime [expr {$::SEGS + 120}] { catch {informe} ; exit }

set ::turno 0
proc teclea {} {
    if {$::corriendo} return
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 { keymatrixup 8 0x01 ; keymatrixup 0 0x02 ; after time 0.7 teclea }
}
after time 6.0 teclea
