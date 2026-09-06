# omsx_recorrido.tcl - El recorrido de los tres rivales, cuadro a cuadro.
#
# El issue #3 pide los "recorridos" de los rivales. El listado dice que cada
# rival es una ficha de tres bytes en 0xE090 / 0xE093 / 0xE096, pero no dice
# QUE es cada byte ni QUIEN los mueve: en el listado no hay ni una escritura
# visible sobre el byte 0, asi que o lo escribe alguien con un puntero que no
# se ve, o no se mueve nunca.
#
# Aqui se contestan las dos cosas de golpe:
#
#   1. tres puntos de observacion de ESCRITURA, uno por byte del primer rival,
#      que solo cuentan PCs en un dict (callback barato, como manda la
#      experiencia de Stardust). Eso da la lista de rutinas que tocan la ficha.
#   2. una traza cuadro a cuadro de las NUEVE casillas de las tres fichas, mas
#      la velocidad, la X de aparicion y la etapa. Eso da el recorrido.
#
# La etapa se fuerza por HR_ETAPA para poder comparar una baja con una alta,
# que es la otra mitad de lo que pregunta el issue.
#
#   HR_ETAPA=1 openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_recorrido.tcl
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/recorrido"]
set ::ETAPA  [expr {[opcion HR_ETAPA 1]}]
set ::SEGS   [expr {[opcion HR_SEGS 45]}]
file mkdir $::SALIDA

set ::corriendo 0
set ::listo 0
set ::traza {}
# un dict por byte del primer rival: PC -> veces
set ::w0 [dict create]
set ::w1 [dict create]
set ::w2 [dict create]

debug set_bp 0x4813 {} {
    if {!$::corriendo} {
        debug write memory 0xE060 $::ETAPA
        debug write memory 0xE061 [debug read memory 0x4372]
        set ::corriendo 1
        after time 1.0 muestrea
        after time [expr {double($::SEGS)}] informe
    }
}
# el acelerador a fondo (bit 4 de 0xE00A), medido en omsx_acelerador.tcl
debug set_bp 0x6943 {} {
    if {$::corriendo} {
        debug write memory 0xE00A [expr {([debug read memory 0xE00A] & 0xEE) | 0x10}]
    }
}

# --- quien escribe la ficha del primer rival ----------------------------
# El callback no formatea nada: solo un dict incr, que es lo unico que aguanta
# el ritmo sin ahogar al emulador.
debug set_watchpoint write_mem 0xE090 {} { dict incr ::w0 [reg pc] }
debug set_watchpoint write_mem 0xE091 {} { dict incr ::w1 [reg pc] }
debug set_watchpoint write_mem 0xE092 {} { dict incr ::w2 [reg pc] }

proc muestrea {} {
    if {$::listo} return
    after time 0.02 muestrea
    catch {
        lappend ::traza [list [machine_info time] \
            [debug read memory 0xE090] [debug read memory 0xE091] [debug read memory 0xE092] \
            [debug read memory 0xE093] [debug read memory 0xE094] [debug read memory 0xE095] \
            [debug read memory 0xE096] [debug read memory 0xE097] [debug read memory 0xE098] \
            [debug read memory 0xE085] [debug read memory 0xE09D] [debug read memory 0xE09E] \
            [debug read memory 0xE060] [debug read memory 0xE003] [debug read memory 0xE099] \
            [debug read memory 0xE05B] [debug read memory 0xE05C] [debug read memory 0xE09C]]
    }
}

proc vuelca_pcs {f nombre d} {
    puts $f "\n$nombre:"
    if {[dict size $d] == 0} { puts $f "  (nadie)" ; return }
    foreach pc [lsort -integer [dict keys $d]] {
        puts $f [format "  PC=0x%04X  %d veces" $pc [dict get $d $pc]]
    }
}

proc informe {} {
    if {$::listo} return
    set ::listo 1
    set f [open "$::SALIDA/quien_escribe_etapa$::ETAPA.txt" w]
    puts $f "etapa forzada : $::ETAPA"
    puts $f "tiempo        : [machine_info time] s emulados"
    puts $f "muestras      : [llength $::traza]"
    puts $f "OJO: el PC de un punto de observacion de escritura cae DENTRO de la"
    puts $f "instruccion, no en su primer byte."
    vuelca_pcs $f "0xE090 (byte 0 del primer rival)" $::w0
    vuelca_pcs $f "0xE091 (byte 1)" $::w1
    vuelca_pcs $f "0xE092 (byte 2)" $::w2
    close $f

    set f [open "$::SALIDA/traza_etapa$::ETAPA.csv" w]
    puts $f "t,r1a,r1b,r1c,r2a,r2b,r2c,r3a,r3b,r3c,vel,spawnx,nivel,etapa,fase,agita,cnt_hi,cnt_lo,vrival"
    foreach l $::traza {
        set fila [format "%.3f" [lindex $l 0]]
        foreach v [lrange $l 1 end] { append fila ",$v" }
        puts $f $fila
    }
    close $f
    exit
}

after realtime [expr {$::SEGS + 120}] { catch {informe} ; exit }

# el menu: alterna fuego (fila 8) y la tecla 1 (fila 0) hasta que arranca
set ::turno 0
proc teclea {} {
    if {$::corriendo} return
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 { keymatrixup 8 0x01 ; keymatrixup 0 0x02 ; after time 0.7 teclea }
}
after time 6.0 teclea
