# omsx_rivales.tcl - Como se dibuja un rival segun se acerca.
#
# El reparto de 0x79FF manda a tres sitios segun la profundidad del rival:
#   < 0x26  -> 0x7B01   (el listado la llama RIVAL_CERCA y su comentario dice
#                        "rival lejano": una de las dos miente)
#   < 0x38  -> 0x7AD1   RIVAL_MEDIO
#   >= 0x38 -> 0x7A10   la rama con sombras
# y 0x79D8 guarda ese mismo reparto en 0xE09E como 0, 1 o 2.
#
# Aqui NO se ponen puntos de ruptura en las ramas: disparan cada cuadro y
# ahogan al emulador. Se conduce solo (bit 4 de 0xE00A, el acelerador, medido
# con omsx_acelerador.tcl) y se SONDEA: cada decima se mira el nivel 0xE09E y,
# la primera vez que sale cada uno, se hace una captura. Comparando las tres
# se ve cual es el rival grande, y las Y de los sprites dicen si en alguna
# estan escondidos -que es lo que haria falta si de cerca fuese de tiles-.
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx"]
set ::corriendo 0
set ::vistos {}
set ::apuntes {}

proc ys {} {
    set r ""
    for {set i 0} {$i < 6} {incr i} {
        append r [format "%02X " [debug read VRAM [expr {0x3B18 + $i*4}]]]
    }
    return $r
}

debug set_bp 0x4813 {} {
    if {!$::corriendo} {
        debug write memory 0xE060 1
        debug write memory 0xE061 [debug read memory 0x4372]
        set ::corriendo 1
        after time 2.0 sondea
    }
}
debug set_bp 0x6943 {} {
    if {$::corriendo} {
        debug write memory 0xE00A [expr {([debug read memory 0xE00A] & 0xEE) | 0x10}]
    }
}

proc sondea {} {
    set n [debug read memory 0xE09E]
    if {[lsearch $::vistos $n] < 0} {
        lappend ::vistos $n
        lappend ::apuntes [format "%7.2f s  nivel 0xE09E=%d  velocidad=%3d  fichas %02X %02X %02X  Ys de rival: %s" \
            [machine_info time] $n [debug read memory 0xE085] \
            [debug read memory 0xE090] [debug read memory 0xE093] [debug read memory 0xE096] [ys]]
        catch { screenshot -raw "$::SALIDA/rival_nivel$n.png" }
    }
    if {[llength $::vistos] >= 3 || [machine_info time] > 90.0} { informe }
    after time 0.1 sondea
}

proc informe {} {
    set f [open "$::SALIDA/rivales.txt" w]
    puts $f "niveles vistos: $::vistos"
    puts $f "velocidad al cerrar: [debug read memory 0xE085]"
    puts $f ""
    foreach l $::apuntes { puts $f $l }
    close $f
    exit
}
after realtime 170 { catch {informe} ; exit }
set ::turno 0
proc teclea {} {
    if {$::corriendo} return
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 { keymatrixup 8 0x01 ; keymatrixup 0 0x02 ; after time 0.7 teclea }
}
after time 6.0 teclea
