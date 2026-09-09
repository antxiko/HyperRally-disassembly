# omsx_detecta_choque.tcl - Que dispara 0x7CE8, y que byte escribe 0x7CFF.
#
# En el issue #3 se publico que 0x7CFF era un segundo escritor del BYTE 0 de la
# ficha del rival, detras de un `cp 0f0h / ret c` sobre el byte 1, y que en 45 s
# no llego a dispararse ni una vez. Leyendo otra vez de donde viene HL, eso esta
# desplazado un byte: 0x7A02 hace `inc hl` ANTES de llamar, asi que dentro de
# 0x7CE8 HL apunta al BYTE 1. Luego la puerta esta en el BYTE 2 y lo que se
# escribe es el BYTE 1.
#
# Aqui se mide, y se mide TODA la cadena: con solo mirar 0x7CE8 sale cero y no
# se puede distinguir "la puerta no se abre" de "no se llega a llamar".
#
# Y hay que TECLEAR: poner la etapa en 0xE060 no arranca la partida, deja el
# juego en la pantalla de atraccion, donde ninguna de estas rutinas corre. Eso
# es lo que hizo que la primera version diera cero en todo.
#
#   HR_ETAPA=1 openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_detecta_choque.tcl
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/choque"]
set ::ETAPA  [expr {[opcion HR_ETAPA 1]}]
set ::SEGS   [expr {[opcion HR_SEGS 45]}]
file mkdir $::SALIDA
set renderer none
set throttle off

set ::corriendo 0          ; # la etapa ya esta puesta
set ::jugando 0            ; # la partida corre de verdad
set ::turno 0
set ::hl [dict create]
set ::b0 [dict create]
set ::b2 [dict create]
set ::escrito [dict create]
set ::muestras {}
set ::prev [dict create]   ; # ultimo byte 0 visto por ficha
set ::salto [dict create]  ; # cuanto avanza el byte 0 de un cuadro al siguiente
foreach k {c4813 c79f7 c7a00 c7a15 c7ccb c7ce8 c7cff} { set ::$k 0 }

debug set_bp 0x4813 {} {
    incr ::c4813
    debug write memory 0xE060 $::ETAPA
    debug write memory 0xE061 [debug read memory [expr {0x4371 + $::ETAPA}]]
    if {!$::corriendo} { set ::corriendo 1 ; after time 1.0 teclea }
}
# el acelerador clavado, para que el coche corra y alcance a alguien
debug set_bp 0x6943 {} {
    if {$::corriendo} {
        debug write memory 0xE00A [expr {([debug read memory 0xE00A] & 0xEE) | 0x10}]
    }
}

# ---- teclear hasta que la partida arranque de verdad ----------------------
proc teclea {} {
    if {$::jugando} { return }
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 suelta
}
proc suelta {} {
    keymatrixup 8 0x01
    keymatrixup 0 0x02
    after time 0.7 teclea
}

# 0x7CCB solo corre con la partida en marcha: es el disparo de salida
debug set_bp 0x7ccb {} {
    incr ::c7ccb
    if {!$::jugando} {
        set ::jugando 1
        keymatrixup 8 0x01
        keymatrixup 0 0x02
        after time [expr {double($::SEGS)}] informe
    }
}
# 1. RIVAL_COLISION: aqui HL apunta al BYTE 0 de la ficha
debug set_bp 0x7a00 {} {
    incr ::c7a00
    if {$::jugando} {
        set h [reg HL]
        set v [debug read memory $h]
        dict incr ::b0 [format %02X $v]
        # cuanto avanza de un cuadro al siguiente: es lo que decide si el
        # byte 0 puede saltar de 0xF0-0xFF a 0x28 o mas y abrir la puerta
        if {[dict exists $::prev $h]} {
            dict incr ::salto [format %02X [expr {($v - [dict get $::prev $h]) & 0xFF}]]
        }
        dict set ::prev $h $v
    }
}
# 2. el CALL: solo se llega con (byte0 + 0x10) >= 0x38
debug set_bp 0x7a15 {} { incr ::c7a15 }
# 3. la entrada de DETECTA_CHOQUE: HL y lo que hay alrededor
debug set_bp 0x7ce8 {} {
    if {!$::jugando} { return }
    incr ::c7ce8
    set h [reg HL]
    dict incr ::hl [format %04X $h]
    # si HL es el byte 1, HL+1 es el byte 2, que es lo que 0x7CEB compara
    dict incr ::b2 [format %02X [debug read memory [expr {$h + 1}]]]
    if {[llength $::muestras] < 24} {
        lappend ::muestras [format "HL=%04X  (HL-1)=%02X (HL)=%02X (HL+1)=%02X" \
            $h [debug read memory [expr {$h - 1}]] [debug read memory $h] \
            [debug read memory [expr {$h + 1}]]]
    }
}
# 4. la escritura, ya pasada la puerta
debug set_bp 0x7cff {} {
    if {!$::jugando} { return }
    incr ::c7cff
    dict incr ::escrito [format "%04X<-%02X" [reg HL] [reg A]]
}
debug set_bp 0x79f7 {} { incr ::c79f7 }

proc informe {} {
    set f [open "$::SALIDA/etapa-$::ETAPA.txt" w]
    puts $f "etapa $::ETAPA, $::SEGS s de PARTIDA, acelerador a fondo"
    puts $f ""
    puts $f "la cadena, punto a punto:"
    puts $f "   0x4813 compone fondo        $::c4813"
    puts $f "   0x79F7 antes de MUEVE_RIVAL $::c79f7"
    puts $f "   0x7A00 RIVAL_COLISION       $::c7a00"
    puts $f "   0x7A15 call DETECTA_CHOQUE  $::c7a15"
    puts $f "   0x7CCB paso del rival       $::c7ccb"
    puts $f "   0x7CE8 DETECTA_CHOQUE       $::c7ce8"
    puts $f "   0x7CFF ld (hl),a            $::c7cff"
    puts $f ""
    puts $f "el BYTE 0 que ve RIVAL_COLISION (para llamar hace falta"
    puts $f "byte0+0x10 >= 0x38, o sea byte0 >= 0x28):"
    foreach k [lsort [dict keys $::b0]] { puts $f "   $k  x[dict get $::b0 $k]" }
    puts $f ""
    puts $f "lo que AVANZA el byte 0 de un cuadro al siguiente:"
    foreach k [lsort [dict keys $::salto]] { puts $f "   +$k  x[dict get $::salto $k]" }
    puts $f ""
    puts $f "HL con el que se entra en 0x7CE8:"
    foreach k [lsort [dict keys $::hl]] { puts $f "   $k  x[dict get $::hl $k]" }
    puts $f "el byte de la puerta, (HL+1), que 0x7CEB compara con 0xF0:"
    foreach k [lsort [dict keys $::b2]] { puts $f "   $k  x[dict get $::b2 $k]" }
    puts $f "lo que escribe 0x7CFF, en la forma HL<-A:"
    foreach k [lsort [dict keys $::escrito]] { puts $f "   $k  x[dict get $::escrito $k]" }
    puts $f "primeras entradas en 0x7CE8:"
    foreach m $::muestras { puts $f "   $m" }
    close $f
    exit
}

# perro guardian de tiempo REAL: un guion roto no puede colgar el emulador
after realtime 240 { catch {informe} ; exit }
