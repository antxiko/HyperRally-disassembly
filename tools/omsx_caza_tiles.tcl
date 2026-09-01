# omsx_caza_tiles.tcl - Cuando deja el rival de ser sprites?
#
# 0x7B21 escribe Y=0xE0 en cuatro sprites, o sea los ESCONDE. Si theNestruo
# tiene razon y de cerca el rival se dibuja con tiles, esconder los sprites
# tiene que pasar justo cuando un rival esta ENCIMA. Y si es al reves, pasara
# con los lejanos.
#
# Esto no lo puede decidir un piloto automatico: hace falta alguien que adelante
# de verdad. Asi que este guion NO toca teclas. Juegas tu; el se queda parado en
# 0x7B21 y, las primeras veces que pasa, hace una captura y apunta las tres
# fichas de rival (0xE090/93/96) y la velocidad.
#
# Mandos, medidos con omsx_teclas.tcl: ESPACIO acelera, flecha ARRIBA frena,
# izquierda/derecha giran. Para meter la marcha larga, por debajo de 144 km/h,
# SUELTA espacio y vuelve a pulsarlo.
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/tiles"]
set ::DIARIO "$::SALIDA/caza_tiles.txt"
set ::n 0
set ::armado 0

set f [open $::DIARIO w]
puts $f "caza del cambio sprites->tiles: paradas en 0x7B21 (esconde 4 sprites)"
puts $f "fichas de rival: 0xE090 0xE093 0xE096   |   velocidad 0xE085"
close $f

debug set_bp 0x4813 {} {
    debug write memory 0xE060 1
    debug write memory 0xE061 [debug read memory 0x4372]
    set ::armado 1
}

debug set_bp 0x7b21 {} {
    if {$::armado && $::n < 8} {
        incr ::n
        set f [open $::DIARIO a]
        puts $f [format "%3d  %7.2f s  fichas %02X %02X %02X  velocidad %3d  0xE09E=%d" \
            $::n [machine_info time] \
            [debug read memory 0xE090] [debug read memory 0xE093] [debug read memory 0xE096] \
            [debug read memory 0xE085] [debug read memory 0xE09E]]
        close $f
        catch { screenshot -raw "$::SALIDA/tiles_$::n.png" }
    }
}
