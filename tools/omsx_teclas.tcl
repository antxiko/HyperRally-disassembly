# omsx_teclas.tcl - Que tecla enciende cada bit de 0xE00A.
#
# LEE_MANDOS (0x466B) mezcla el joystick y dos filas del teclado en un solo
# byte, 0xE00A, con tres rotaciones. Deducir a mano que bit sale de que tecla
# es justo la clase de cosa que se lee mal, asi que se mide: se pulsa una sola
# tecla a la vez y se apunta el byte que queda.
#
# Ya se sabe, medido con omsx_acelerador.tcl, que el bit 4 ACELERA y el bit 0
# FRENA. Esto dice con que dedo se hace cada cosa.
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx"]
set ::corriendo 0
set ::apuntes {}
# fila 8 del MSX y fila 7, bit a bit; los nombres son los de la matriz estandar
set ::PRUEBAS {
    {8 0x01 "fila 8 bit 0"} {8 0x02 "fila 8 bit 1"} {8 0x04 "fila 8 bit 2"}
    {8 0x08 "fila 8 bit 3"} {8 0x10 "fila 8 bit 4"} {8 0x20 "fila 8 bit 5"}
    {8 0x40 "fila 8 bit 6"} {8 0x80 "fila 8 bit 7"}
    {7 0x40 "fila 7 bit 6"} {7 0x80 "fila 7 bit 7"}
    {6 0x20 "fila 6 bit 5"} {6 0x10 "fila 6 bit 4"}
}
set ::i 0

debug set_bp 0x4813 {} { if {!$::corriendo} { set ::corriendo 1 ; after time 2.0 prueba } }

proc prueba {} {
    if {$::i >= [llength $::PRUEBAS]} { informe }
    set p [lindex $::PRUEBAS $::i]
    keymatrixdown [lindex $p 0] [lindex $p 1]
    after time 0.4 lee
}
proc lee {} {
    set p [lindex $::PRUEBAS $::i]
    lappend ::apuntes [format "%-16s -> 0xE00A = %02X" [lindex $p 2] [debug read memory 0xE00A]]
    keymatrixup [lindex $p 0] [lindex $p 1]
    incr ::i
    after time 0.3 prueba
}
proc informe {} {
    set f [open "$::SALIDA/teclas.txt" w]
    puts $f "que enciende cada bit de 0xE00A (bit 4 = acelerador, bit 0 = freno):"
    foreach l $::apuntes { puts $f "  $l" }
    close $f
    exit
}
after realtime 150 { catch {informe} ; exit }
set ::turno 0
proc teclea {} {
    if {$::corriendo} return
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 { keymatrixup 8 0x01 ; keymatrixup 0 0x02 ; after time 0.7 teclea }
}
after time 6.0 teclea
