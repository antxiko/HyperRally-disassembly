# omsx_rival_talla.tcl - Un valor de ficha de rival mas alto, un coche mas
# grande? Se mide siguiendo UNA sola ficha.
#
# El reparto de 0x79FF usa la profundidad del rival: <0x26, <0x38 y el resto.
# Pero 0xE09E es global -hay TRES rivales- asi que correlacionar 0xE09E con una
# captura no demuestra nada: no se sabe cual de los tres se estaba dibujando.
#
# Aqui se sigue SOLO la ficha del primer rival (0xE090) y se hace una captura
# cada vez que su byte de profundidad entra en una banda nueva de 0x10, con las
# TRES fichas apuntadas en el diario. Si a mas valor mas cerca, los coches
# tienen que ir creciendo de una captura a la siguiente.
#
# Se conduce solo con el bit 4 de 0xE00A (el acelerador, medido antes) y sin
# cambiar de marcha, que es cuando los rivales adelantan y se recorre el rango.
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/talla"]
set ::FICHA [expr {[opcion HR_FICHA 0xE090]}]
set ::corriendo 0
set ::bandas {}
set ::apuntes {}

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
    set v [debug read memory $::FICHA]
    set banda [expr {$v >> 4}]
    if {$v > 0 && [lsearch $::bandas $banda] < 0} {
        lappend ::bandas $banda
        lappend ::apuntes [format "%7.2f s  0x%04X=%02X (banda %X)  las tres fichas: %02X %02X %02X  velocidad=%3d" \
            [machine_info time] $::FICHA $v $banda \
            [debug read memory 0xE090] [debug read memory 0xE093] [debug read memory 0xE096] \
            [debug read memory 0xE085]]
        catch { screenshot -raw "$::SALIDA/ficha_[format %02X $v].png" }
    }
    if {[machine_info time] > 100.0} { informe }
    after time 0.06 sondea
}

proc informe {} {
    set f [open "$::SALIDA/talla.txt" w]
    puts $f "ficha seguida: [format 0x%04X $::FICHA]"
    puts $f "bandas vistas: $::bandas"
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
