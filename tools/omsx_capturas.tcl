# omsx_capturas.tcl - Una captura de cada etapa, con el rayo y con las piramides.
#
# omsx_fondos.tcl saca las doce etapas, pero con el coche parado dos de ellas
# mienten: en la 7 no cae ningun rayo y en la 11 no ha subido ninguna piramide,
# porque los dos efectos estan condicionados a lo que se lleva recorrido.
#
# Aqui no se simula conducir: se le da a cada rutina EL VALOR QUE ESTA
# ESPERANDO, leido de las tablas del propio cartucho, y se dispara la captura
# en el momento bueno.
#
#   etapa 7   0x7266 mira 0xE070 y solo destella si esta entre 8 y 0xCB; se le
#             pone 0x20 y se captura justo tras el destello (0x7276).
#   etapa 11  0x731D solo dibuja una fila cuando 0xE071 vale el umbral que la
#             tabla de 0x7371 guarda para esa fila; se le van dando los
#             dieciseis y se captura con las piramides arriba.
#   las demas a los HR_ESPERA segundos.
#
#   HR_ETAPA=7 openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_capturas.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}
set ::ETAPA  [opcion HR_ETAPA 1]
set ::ESPERA [expr {double([opcion HR_ESPERA 3.0])}]
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/capturas"]
set ::corriendo 0
set ::listo 0
set ::filas 0

proc retrata {razon} {
    if {$::listo} return
    set ::listo 1
    catch { screenshot -raw "$::SALIDA/etapa[format %02d $::ETAPA].png" }
    set f [open "$::SALIDA/etapa[format %02d $::ETAPA].txt" w]
    puts $f "etapa          : $::ETAPA"
    puts $f "0xE061         : [format 0x%02X [debug read memory 0xE061]]"
    puts $f "momento        : $razon"
    puts $f "filas piramide : $::filas"
    close $f
    exit
}

debug set_bp 0x4813 {} {
    debug write memory 0xE060 $::ETAPA
    debug write memory 0xE061 [debug read memory [expr {0x4371 + $::ETAPA}]]
    if {!$::corriendo} {
        set ::corriendo 1
        if {$::ETAPA != 7 && $::ETAPA != 11} {
            after time $::ESPERA { retrata "fondo compuesto" }
        }
    }
}

if {$::ETAPA == 7} {
    # 0x7266 corta si 0xE070 esta fuera de rango; se le da uno que si lo esta
    debug set_bp 0x7266 {} { if {$::corriendo} { debug write memory 0xE070 0x20 } }
    debug set_bp 0x7276 {} {
        if {$::corriendo} { after time 0.04 { retrata "justo tras el destello del rayo" } }
    }
    after time 60.0 { retrata "no cayo ningun rayo en 60 s" }
}

if {$::ETAPA == 11} {
    debug set_bp 0x731d {} {
        set fila [debug read memory 0xE06B]
        if {$fila < 16} {
            debug write memory 0xE071 [debug read memory [expr {0x7371 + $fila}]]
            set ::filas [expr {$fila + 1}]
        } else {
            after time 0.5 { retrata "con las dieciseis filas de piramide arriba" }
        }
    }
    after time 60.0 { retrata "las piramides no acabaron de subir" }
}

set ::turno 0
proc teclea {} {
    if {$::corriendo || $::listo} return
    if {[machine_info time] > 120.0} { retrata "no arranco la carrera" }
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 suelta
}
proc suelta {} { keymatrixup 8 0x01 ; keymatrixup 0 0x02 ; after time 0.7 teclea }
after realtime 200 { catch {retrata "perro guardian"} ; exit }
after time 6.0 teclea
