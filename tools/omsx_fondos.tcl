# omsx_fondos.tcl - Fuerza una etapa de Hyper Rally y vuelca su VRAM.
#
# Para que sirve: el issue #1 de theNestruo dice que NO hay etapa acuatica, y
# el #4 pide documentar los distintos compositores de fondo. Leer el codigo da
# la tabla (0x481A) y el parametro por etapa (0xE061), pero NO dice que se ve.
# Esto lo ensena: pone el numero de etapa que se pida justo cuando el juego va
# a componer el fondo (DESPACHA_FONDO_ETAPA, 0x4813) y, cuando ya esta dibujado,
# vuelca los 16 KB de VRAM y hace una captura.
#
# El volcado es la prueba: con el se compara byte a byte lo que dibuja
# graficos.py desde la ROM, que es lo que va a la web.
#
# Variables de entorno:
#   HR_ETAPA   etapa a forzar, 1..12 (por defecto 5, la del 0xE061=0x08)
#   HR_ESPERA  segundos emulados desde que se compone hasta volcar (2.0)
#   HR_SALIDA  carpeta de salida
#
#   HR_ETAPA=5 "C:/Program Files/openMSX/openmsx.exe" \
#       -machine Philips_VG_8020 -cart hyperrally.rom -script tools/omsx_fondos.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::ETAPA  [opcion HR_ETAPA 5]
set ::ESPERA [expr {double([opcion HR_ESPERA 2.0])}]
set ::SALIDA [opcion HR_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/HYPERRALLY_DISAM/work/omsx"]

set ::forzada 0
set ::compuesta 0
set ::traza {}

proc apunta {t} {
    lappend ::traza [format "%8.3f s  %s" [machine_info time] $t]
}

# El parametro de etapa sale de la MISMA tabla que usa el cartucho (0x4371+N),
# leida de la ROM en marcha; aqui no se escribe ninguna constante a mano.
proc param_de_etapa {n} {
    return [debug read memory [expr {0x4371 + $n}]]
}

proc informe {} {
    set f [open "$::SALIDA/fondo_etapa$::ETAPA.txt" w]
    puts $f "etapa forzada : $::ETAPA"
    puts $f "0xE060        : [debug read memory 0xE060]"
    puts $f "0xE061        : [format 0x%02X [debug read memory 0xE061]]"
    puts $f "0xE061 tabla  : [format 0x%02X [param_de_etapa $::ETAPA]]"
    puts $f "tiempo        : [machine_info time]"
    puts $f "traza:"
    foreach l $::traza { puts $f "  $l" }
    close $f
}

proc vuelca {} {
    # los 16 KB de VRAM tal cual los ve el VDP
    set datos [debug read_block VRAM 0 16384]
    set f [open "$::SALIDA/vram_etapa$::ETAPA.bin" w]
    fconfigure $f -translation binary
    puts -nonewline $f $datos
    close $f
    # y los registros, que dicen donde estan las tablas
    set r {}
    for {set i 0} {$i < 8} {incr i} { lappend r [format %02X [debug read "VDP regs" $i]] }
    set f [open "$::SALIDA/vdpregs_etapa$::ETAPA.txt" w]
    puts $f [join $r " "]
    close $f
    catch { screenshot -raw "$::SALIDA/etapa$::ETAPA.png" }
    apunta "volcada la VRAM"
    informe
    exit
}

# Cuando el juego va a componer el fondo, le cambiamos la etapa por la pedida.
debug set_bp 0x4813 {} {
    if {!$::forzada} {
        debug write memory 0xE060 $::ETAPA
        debug write memory 0xE061 [param_de_etapa $::ETAPA]
        set ::forzada 1
        apunta "forzada la etapa $::ETAPA (0xE061 = [format 0x%02X [param_de_etapa $::ETAPA]])"
    }
    if {$::forzada && !$::compuesta} {
        set ::compuesta 1
        after time $::ESPERA vuelca
    }
}

# --- llevar el juego a que empiece una carrera --------------------------
# Se pulsa la barra (fila 8, mascara 0x01) y el 1 (fila 0, mascara 0x02) por
# turnos hasta que salte el punto de ruptura; no se supone cual es la tecla.
set ::turno 0
proc teclea {} {
    if {$::compuesta} return
    if {[machine_info time] > 120.0} {
        apunta "FALLO: 120 s emulados sin llegar a componer un fondo"
        informe
        exit
    }
    set ::turno [expr {($::turno + 1) % 2}]
    if {$::turno} { keymatrixdown 8 0x01 } else { keymatrixdown 0 0x02 }
    after time 0.3 suelta
}
proc suelta {} {
    keymatrixup 8 0x01
    keymatrixup 0 0x02
    after time 0.7 teclea
}

# perro guardian de tiempo REAL: un guion roto no puede colgar el emulador
after realtime 180 {
    apunta "PERRO GUARDIAN a los 180 s reales"
    catch {informe}
    exit
}

after time 6.0 teclea
