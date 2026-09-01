# omsx_piramides.tcl - Hace salir las piramides de la etapa 11 sin conducir.
#
# DIBUJA_EYECATCH (0x731D) solo dibuja cuando 0xE071 -lo que queda de etapa-
# vale EXACTAMENTE el umbral que la tabla de 0x7371 guarda para la fila que
# toca (contador en 0xE06B). Conduciendo, eso pasa al final del recorrido. Aqui
# se para en la entrada de la rutina y se le pone a 0xE071 el umbral que espera,
# asi que la secuencia entera de dieciseis pasos se ve en unos segundos.
#
# El umbral NO se escribe a mano: se lee de la tabla del propio cartucho.
#
#   openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_piramides.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx"]
set ::ETAPA 11
set ::pasos 0
set ::hecho 0

debug set_bp 0x4813 {} {
    debug write memory 0xE060 $::ETAPA
    debug write memory 0xE061 [debug read memory [expr {0x4371 + $::ETAPA}]]
}

# en la entrada de DIBUJA_EYECATCH, dale el umbral que espera
debug set_bp 0x731d {} {
    if {!$::hecho} {
        set fila [debug read memory 0xE06B]
        if {$fila < 16} {
            debug write memory 0xE071 [debug read memory [expr {0x7371 + $fila}]]
            incr ::pasos
        } elseif {!$::hecho} {
            set ::hecho 1
            after time 0.3 retrata
        }
    }
}

proc retrata {} {
    set f [open "$::SALIDA/piramides.txt" w]
    puts $f "etapa 11, pasos dados: $::pasos   0xE06B = [debug read memory 0xE06B]"
    puts $f "tiles 0xB3..0xB6 del tercio 1, tal como quedan en la VRAM:"
    foreach t {0xB3 0xB4 0xB5 0xB6} {
        set base [expr {0x2000 + 0x800 + $t * 8}]
        set fila ""
        for {set i 0} {$i < 8} {incr i} {
            append fila [format "%02X " [debug read VRAM [expr {$base + $i}]]]
        }
        puts $f [format "  tile %s : %s" $t $fila]
    }
    close $f
    catch { screenshot -raw "$::SALIDA/piramides.png" }
    exit
}

set ::turno 0
proc teclea {} {
    if {$::hecho} return
    if {[machine_info time] > 120.0} { catch {retrata} ; exit }
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 suelta
}
proc suelta { } { keymatrixup 8 0x01 ; keymatrixup 0 0x02 ; after time 0.7 teclea }
after realtime 200 { catch {retrata} ; exit }
after time 6.0 teclea
