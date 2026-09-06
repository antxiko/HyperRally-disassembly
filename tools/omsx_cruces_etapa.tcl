# omsx_cruces_etapa.tcl - Cuantos rivales te cruzan en cada etapa, y por donde.
#
# La pregunta del issue #3 es "por que en las fases altas hay mas coches
# cruzando". Se mide, etapa por etapa, con el acelerador clavado a fondo y el
# mismo tiempo emulado en todas:
#
#   * cruces: pasadas por 0x6BAD, el `pop hl` donde 0x6B7D descubre que un rival
#     ha cruzado el umbral 0x17 -o sea, que ha pasado a tu altura- y mueve el
#     marcador. Un cruce contado ahi es un coche que te pasa o al que pasas.
#   * la velocidad del rival, 0xE09C, que 0x79A9 sortea con una base que DEPENDE
#     DE LA ETAPA (0xA0 si el bit 2 de 0xE060 esta a cero, 0x88 si no).
#   * la X de aparicion, 0xE09D, que 0x7F65 saca de (etapa-1) mod 4.
#   * el reparto del byte 1 de las fichas, que es el lado por el que cruzan.
#
#   HR_ETAPA=7 openmsx -machine Philips_VG_8020 -cart hyperrally.rom \
#       -script tools/omsx_cruces_etapa.tcl
proc opcion {n d} { global env ; if {[info exists env($n)]} { return $env($n) } ; return $d }
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx/cruces"]
set ::ETAPA  [expr {[opcion HR_ETAPA 1]}]
set ::SEGS   [expr {[opcion HR_SEGS 40]}]
file mkdir $::SALIDA
set renderer none
set throttle off

set ::corriendo 0
set ::listo 0
set ::cruces 0
set ::vrival [dict create]
set ::spawn  [dict create]
set ::lado   [dict create]
set ::velmax 0

debug set_bp 0x4813 {} {
    if {!$::corriendo} {
        debug write memory 0xE060 $::ETAPA
        debug write memory 0xE061 [debug read memory 0x4372]
        set ::corriendo 1
        after time 1.0 muestrea
        after time [expr {double($::SEGS)}] informe
    }
}
debug set_bp 0x6943 {} {
    if {$::corriendo} {
        debug write memory 0xE00A [expr {([debug read memory 0xE00A] & 0xEE) | 0x10}]
    }
}
# el punto donde 0x6B7D da un cruce por bueno: descarta su propio retorno
debug set_bp 0x6bad {} { if {$::corriendo} { incr ::cruces } }

proc muestrea {} {
    if {$::listo} return
    after time 0.02 muestrea
    catch {
        dict incr ::vrival [debug read memory 0xE09C]
        dict incr ::spawn  [debug read memory 0xE09D]
        foreach a {0xE091 0xE094 0xE097} { dict incr ::lado [debug read memory $a] }
        set v [debug read memory 0xE085]
        if {$v > $::velmax} { set ::velmax $v }
    }
}

proc reparto {d} {
    set r ""
    foreach k [lsort -integer [dict keys $d]] {
        append r [format "0x%02X:%d  " $k [dict get $d $k]]
    }
    return $r
}

proc informe {} {
    if {$::listo} return
    set ::listo 1
    set f [open "$::SALIDA/etapa[format %02d $::ETAPA].txt" w]
    puts $f "etapa            : $::ETAPA"
    puts $f "bit 2 de la etapa: [expr {($::ETAPA >> 2) & 1}]"
    puts $f "segundos medidos : $::SEGS"
    puts $f "CRUCES (0x6BAD)  : $::cruces"
    puts $f "velocidad tope   : $::velmax"
    puts $f "0xE09C velocidad del rival : [reparto $::vrival]"
    puts $f "0xE09D X de aparicion      : [reparto $::spawn]"
    puts $f "byte 1 (lado del cruce)    : [reparto $::lado]"
    close $f
    exit
}
after realtime [expr {$::SEGS + 150}] { catch {informe} ; exit }

set ::turno 0
proc teclea {} {
    if {$::corriendo} return
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 { keymatrixup 8 0x01 ; keymatrixup 0 0x02 ; after time 0.7 teclea }
}
after time 6.0 teclea
