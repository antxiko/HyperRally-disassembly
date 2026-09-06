# omsx_marcador_cruces.tcl - Que hace 0x6B7D, la que el listado llamaba
# COLOCA_RIVALES_VRAM.
#
# La rutina no escribe una sola casilla de la VRAM. Lo que hace es comparar el
# byte 0 de cada ficha (donde esta el rival AHORA) con su byte 2 (donde estaba
# el cuadro anterior) contra el umbral 0x17, y cuando el rival lo cruza, mueve
# el marcador BCD de 0xE05B/0xE05C: arriba por 0x6BB5, abajo -y con
# SUMA_PUNTOS 0x0250- por 0x6BC0.
#
# Se comprueba contando las dos ramas y viendo si el marcador se mueve
# exactamente esas veces. Y de paso se cuenta 0x7F89, que el listado llama
# CHOQUE_OBSTACULO y que recorre las MISMAS tres fichas de rival.
#
#   openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_marcador_cruces.tcl
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/recorrido"]
set ::SEGS   [expr {[opcion HR_SEGS 45]}]
file mkdir $::SALIDA
set renderer none
set throttle off

set ::corriendo 0
set ::listo 0
set ::sube 0
set ::baja 0
set ::obst 0
set ::choca 0
set ::ini ""

debug set_bp 0x4813 {} {
    if {!$::corriendo} {
        debug write memory 0xE060 1
        debug write memory 0xE061 [debug read memory 0x4372]
        set ::corriendo 1
        after time 1.0 arranca
        after time [expr {double($::SEGS)}] informe
    }
}
debug set_bp 0x6943 {} {
    if {$::corriendo} {
        debug write memory 0xE00A [expr {([debug read memory 0xE00A] & 0xEE) | 0x10}]
    }
}
proc arranca {} {
    set ::ini [format "%02X%02X" [debug read memory 0xE05B] [debug read memory 0xE05C]]
    set ::sube 0 ; set ::baja 0 ; set ::obst 0 ; set ::choca 0
    set ::midiendo 1
}
set ::midiendo 0
debug set_bp 0x6bb5 {} { if {$::midiendo} { incr ::sube } }
debug set_bp 0x6bc0 {} { if {$::midiendo} { incr ::baja } }
# la que el listado llama CHOQUE_OBSTACULO, y el punto donde da el golpe por bueno
debug set_bp 0x7f89 {} { if {$::midiendo} { incr ::obst } }
debug set_bp 0x7fac {} { if {$::midiendo} { incr ::choca } }
# 0x7CCB, la que el listado llama IMPACTO: en la MISMA pasada, para poder
# comparar sus veces con los golpes de verdad
set ::avance 0
set ::reaccion 0
debug set_bp 0x7ccb {} { if {$::midiendo} { incr ::avance } }
debug set_bp 0x7d32 {} { if {$::midiendo} { incr ::reaccion } }

proc informe {} {
    if {$::listo} return
    set ::listo 1
    set fin [format "%02X%02X" [debug read memory 0xE05B] [debug read memory 0xE05C]]
    set f [open "$::SALIDA/marcador.txt" w]
    puts $f "marcador 0xE05B/0xE05C al empezar : $::ini"
    puts $f "marcador 0xE05B/0xE05C al acabar  : $fin"
    puts $f "0x6BB5 (rama que SUBE el marcador): $::sube"
    puts $f "0x6BC0 (rama que lo BAJA)         : $::baja"
    puts $f "movimiento neto esperado          : [expr {$::sube - $::baja}]"
    puts $f ""
    puts $f "0x7F89 CHOQUE_OBSTACULO, pasadas  : $::obst"
    puts $f "0x7FAC, golpes dados por buenos   : $::choca"
    puts $f "0x7D32 REACCION_CHOQUE, pasadas   : $::reaccion"
    puts $f ""
    puts $f "0x7CCB (el llamado IMPACTO)       : $::avance"
    puts $f "  si esto pasa cientos de veces y los golpes son cero, 0x7CCB no es"
    puts $f "  un impacto: es el avance del rival."
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
