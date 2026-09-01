# omsx_caza_relampago.tcl - Juegas tu la etapa 7; el guion caza el relampago.
#
# 0x724B solo corre con 0xE061 = 0x10, que es la etapa 7 (cielo y borde grises).
# El listado publicado lo llama "fuegos artificiales al llegar a meta", pero se
# dispara en plena carrera. Este guion NO toca teclas: fuerza la etapa 7 en cada
# composicion de fondo (0x4813) y se queda apuntando, con su instante, cada vez
# que pasa por los cuatro hitos de la secuencia, con una CAPTURA justo despues
# del destello, que es la unica prueba de que dibuja.
#
# Hitos:
#   0x7266  entra en la rama que suena y destella
#   0x7276  va a poner el borde en 0xEF (el destello)
#   0x729B  va a dibujar la forma (FUEGOS_3 -> 0xE1C0)
#   0x728B  devuelve el borde a 0xEE
#
# El diario se vuelca a disco en cada apunte, para poder leerlo en marcha.
#
#   HR_ETAPA=7 openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_caza_relampago.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}
set ::ETAPA  [opcion HR_ETAPA 7]
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx"]
set ::DIARIO "$::SALIDA/caza_relampago.txt"
set ::n 0
set ::capturas 0
set ::ultimoR7 -1

proc apunta {texto} {
    incr ::n
    set f [open $::DIARIO a]
    puts $f [format "%4d  %8.2f s  %s" $::n [machine_info time] $texto]
    close $f
}

set f [open $::DIARIO w]
puts $f "caza del relampago - etapa forzada $::ETAPA"
puts $f "hitos: 0x7266 rama  0x7276 destello  0x729B dibuja  0x728B apaga"
close $f

debug set_bp 0x4813 {} {
    debug write memory 0xE060 $::ETAPA
    debug write memory 0xE061 [debug read memory [expr {0x4371 + $::ETAPA}]]
}

debug set_bp 0x7266 {} {
    apunta [format "0x7266 entra en la rama   0xE070=0x%02X  0xE0A9=0x%02X" \
               [debug read memory 0xE070] [debug read memory 0xE0A9]]
}
debug set_bp 0x7276 {} {
    apunta "0x7276 DESTELLO: borde a 0xEF"
    after time 0.04 captura_relampago
}
debug set_bp 0x729b {} { apunta "0x729B dibuja la forma" }
debug set_bp 0x728b {} { apunta "0x728B apaga: borde a 0xEE" }

proc captura_relampago {} {
    incr ::capturas
    catch { screenshot -raw "$::SALIDA/relampago_visto_$::capturas.png" }
    set r7 [debug read {VDP regs} 7]
    apunta [format "captura %d tomada, R7=0x%02X" $::capturas $r7]
}

proc vigila_borde {} {
    set v [debug read {VDP regs} 7]
    if {$v != $::ultimoR7} {
        if {$::ultimoR7 != -1} { apunta [format "el borde cambia a 0x%02X" $v] }
        set ::ultimoR7 $v
    }
    after time 0.02 vigila_borde
}
vigila_borde
