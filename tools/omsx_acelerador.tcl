# omsx_acelerador.tcl - Cual es el bit del acelerador y cual el del freno.
#
# El listado publicado dice que el bit 0 de 0xE00A es el acelerador ("a fondo
# si esta pulsado", 0x6948) y que el bit 4 es el freno (0x695A). Leyendo el
# codigo parece al reves: la rama del bit 4 (ACELERA, 0x6957) SUBE 0xE085 con
# tope 0x8F/0xEF, y la del bit 0 (0x69C6) acaba llamando a FRENA_2, que RESTA.
#
# Esto lo zanja midiendo. No se pulsa ninguna tecla: en 0x6943, que es donde
# CONTROL_ACELERADOR lee 0xE00A, se le pone el bit que toque segun la fase, y
# se apunta la velocidad. Primero doce segundos con el bit 4, luego doce con el
# bit 0. Si la lectura nueva es la buena, la velocidad sube en el primer tramo
# y baja en el segundo.
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx"]
set ::corriendo 0
set ::t0 0
set ::bit 0x10
set ::apuntes {}

debug set_bp 0x4813 {} {
    if {!$::corriendo} { set ::corriendo 1 ; set ::t0 [machine_info time] ; after time 1.0 mira }
}
# en el punto exacto donde la rutina lee los mandos
debug set_bp 0x6943 {} {
    if {$::corriendo} {
        debug write memory 0xE00A [expr {([debug read memory 0xE00A] & 0xEE) | $::bit}]
    }
}
proc mira {} {
    set t [expr {[machine_info time] - $::t0}]
    if {$t > 12.0 && $::bit == 0x10} { set ::bit 0x01 ; lappend ::apuntes "--- cambio al bit 0 ---" }
    lappend ::apuntes [format "%6.1f s  bit=0x%02X  velocidad=%3d  0xE08B/8C=%02X%02X" \
        $t $::bit [debug read memory 0xE085] \
        [debug read memory 0xE08C] [debug read memory 0xE08B]]
    if {$t > 24.0} {
        set f [open "$::SALIDA/acelerador.txt" w]
        foreach l $::apuntes { puts $f $l }
        close $f
        exit
    }
    after time 1.0 mira
}
set ::turno 0
proc teclea {} {
    if {$::corriendo} return
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 { keymatrixup 8 0x01 ; keymatrixup 0 0x02 ; after time 0.7 teclea }
}
after realtime 180 { catch { set f [open "$::SALIDA/acelerador.txt" w] ; foreach l $::apuntes { puts $f $l } ; close $f } ; exit }
after time 6.0 teclea
