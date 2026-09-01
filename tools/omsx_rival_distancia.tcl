# omsx_rival_distancia.tcl - Que dibuja cada valor de distancia de rival.
#
# El reparto de 0x7A04 hace `add a,010h / cp 026h / cp 038h` sobre la ficha del
# rival, y de ahi salen las tres ramas. Correlacionar el nivel 0xE09E con una
# captura NO demuestra nada, porque hay tres rivales y no se sabe cual se esta
# dibujando.
#
# Asi que se fuerza: en 0x7A04, justo antes del `add a,010h`, se le mete a A el
# valor que se quiera. Los TRES rivales se dibujan entonces a esa misma
# distancia, y la captura ensena sin lugar a dudas de que talla es ese valor.
#
#   HR_VALOR=0x60 openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_rival_distancia.tcl
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/distancia"]
set ::VALOR [expr {[opcion HR_VALOR 0x60]}]
set ::corriendo 0
set ::listo 0

debug set_bp 0x4813 {} {
    if {!$::corriendo} {
        debug write memory 0xE060 1
        debug write memory 0xE061 [debug read memory 0x4372]
        set ::corriendo 1
        after time 12.0 retrata
    }
}
debug set_bp 0x6943 {} {
    if {$::corriendo} {
        debug write memory 0xE00A [expr {([debug read memory 0xE00A] & 0xEE) | 0x10}]
    }
}
# la distancia de TODOS los rivales, forzada al valor pedido
debug set_bp 0x7a04 {} { if {$::corriendo} { reg a $::VALOR } }

proc retrata {} {
    if {$::listo} return
    set ::listo 1
    set v [format %02X $::VALOR]
    catch { screenshot -raw "$::SALIDA/dist_$v.png" }
    set f [open "$::SALIDA/dist_$v.txt" w]
    set s [expr {($::VALOR + 0x10) & 0xFF}]
    puts $f "valor forzado : 0x$v   (+0x10 = 0x[format %02X $s])"
    puts $f "rama          : [expr {$s < 0x26 ? {0x7B01 (tier 0)} : ($s < 0x38 ? {0x7AD1 (tier 1)} : {0x7A10 (tier 2)})}]"
    puts $f "velocidad     : [debug read memory 0xE085]"
    close $f
    exit
}
after realtime 150 { catch {retrata} ; exit }
set ::turno 0
proc teclea {} {
    if {$::corriendo} return
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 { keymatrixup 8 0x01 ; keymatrixup 0 0x02 ; after time 0.7 teclea }
}
after time 6.0 teclea
