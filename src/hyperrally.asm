; ==========================================================================
; HYPER RALLY - Konami - MSX1 - cartucho RC-718 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Etiquetas que no caen en ninguna posicion emitida del listado
; (destinos fuera del binario o dentro de una instruccion).
; ----------------------------------------------------------------------
INIT_68F9:	equ 0x068f9

; ----------------------------------------------------------------------
; DATOS cabecera_cartucho: AB, el puntero INIT (0x4010) y los tres punteros a
;   cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_cartucho:
	defb 041h,042h	; 4000
	defw 04010h,00000h,00000h,00000h	; 4002  -> INIT 0x0000 0x0000 0x0000
	defw 00000h,00000h,00000h	; 400a

; ======================================================================
; CODIGO 0x4010..0x40aa  (154 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ARRANQUE. La BIOS entra aqui por la cabecera del cartucho.
; ----------------------------------------------------------------------
INIT:		; Prepara la maquina y engancha la interrupcion
	di			;4010
	im 1		;4011   ; modo de interrupcion 1
	ld a,0c3h		;4013   ; escribe un jp en el gancho H.KEYI (0xFD9A/0xFD9B)...
	ld (0fd9ah),a		;4015
	ld hl,INT		;4018   ; ...que apunta a la rutina de interrupcion, 0x4051
	ld (0fd9bh),hl		;401b
	ld sp,0e800h		;401e   ; la pila arranca en 0xE800
	ld hl,0e000h		;4021   ; borra de un ldir la RAM de trabajo, 0xE000-0xE7FF
	ld de,0e001h		;4024
	ld bc,007ffh		;4027
	ld (hl),000h		;402a
	ldir		;402c
	call PREPARA_ETAPA		;402e   ; inicializa el VDP y sus tablas
	ld a,001h		;4031
	ld (0e057h),a		;4033
	ld a,001h		;4036
	ld (0e006h),a		;4038
	call LIMPIA_VRAM		;403b   ; prepara la primera pantalla
	xor a			;403e
	ld (0e006h),a		;403f
	call 0013eh		;4042   ; BIOS RDVDP - Reads VDP status register
	ei			;4045
	call LEE_MANDOS_FLANCO		;4046   ; lee los mandos una vez
	ld a,(0e00ah)		;4049
	ld (0e00bh),a		;404c
BUCLE_MUERTO:		; jr a si mismo: el trabajo lo hace la interrupcion
	jr BUCLE_MUERTO		;404f   ; bucle muerto: a partir de aqui solo trabaja la interrupcion
INT:		; Rutina de interrupcion: un cuadro de juego
	call 0013eh		;4051   ; BIOS RDVDP - Reads VDP status register | lee el estado del VDP (limpia la peticion de interrupcion)
	di			;4054
	call ACTUALIZA_SONIDO		;4055   ; atiende el sonido
	ld hl,0e006h		;4058   ; candado de reentrada: si ya estaba dentro, se va
	bit 0,(hl)		;405b
	jr nz,INT_406B		;405d
	inc (hl)			;405f
	ei			;4060
	call LEE_MANDOS_FLANCO		;4061   ; relee los mandos
	call MAQUINA_ESTADOS		;4064   ; avanza la maquina de estados
	xor a			;4067
	ld (0e006h),a		;4068   ; suelta el candado
INT_406B:
	call 0013eh		;406b   ; BIOS RDVDP - Reads VDP status register
	or a			;406e
	di			;406f
	call m,ACTUALIZA_SONIDO		;4070   ; segunda pasada de sonido si toca (signo)
	ei			;4073
	ret			;4074
HL_MAS_A:		; HL += A (con acarreo a H), devuelve
	add a,l			;4075
	ld l,a			;4076
	ret nc			;4077
	inc h			;4078
	ret			;4079
DE_MAS_A:		; DE += A (con acarreo a D), devuelve
	add a,e			;407a
	ld e,a			;407b
	ret nc			;407c
	inc d			;407d
	ret			;407e
SALTA_POR_TABLA:		; Salta a la entrada A de la tabla que sigue al call
	pop hl			;407f   ; saca la direccion de la tabla (esta detras del call)
	add a,a			;4080   ; indexa por 2*A
	call HL_MAS_A		;4081
	ld e,(hl)			;4084
	inc hl			;4085
	ld d,(hl)			;4086
	ex de,hl			;4087
	jp (hl)			;4088   ; salta a la rutina de esa casilla
MAQUINA_ESTADOS:		; Reparte segun 0xE000 (estado) y 0xE001 (subestado)
	ld hl,0e003h		;4089   ; sube la fase de interrupcion 0xE003 y la enmascara a 0..7
	inc (hl)			;408c
	ld a,(hl)			;408d
	and 007h		;408e
	inc hl			;4090
	inc hl			;4091
	ld (hl),a			;4092
	ld a,(0e002h)		;4093   ; bit6 de 0xE002: modo demo
	and 040h		;4096
	ld bc,(0e000h)		;4098   ; C = estado (0xE000), B = subestado (0xE001)
	ld a,c			;409c   ; A = estado, con el se indexa la tabla de abajo
	jr nz,MAQUINA_ESTADOS_40A7		;409d
	cp 003h		;409f
	jr z,MAQUINA_ESTADOS_40A7		;40a1
	ld hl,046a4h		;40a3   ; fuera de demo empuja la rutina de mandos como retorno
	push hl			;40a6
MAQUINA_ESTADOS_40A7:
	call SALTA_POR_TABLA		;40a7   ; salta al manejador del estado

; ----------------------------------------------------------------------
; DATOS tabla_estados: Nueve manejadores de estado, indexados por 0xE000
;   0x40aa..0x40bc  (18 bytes)
DATA_tabla_estados:
	defw 040bch,040f5h,040fdh,04127h,0412dh,0421bh,0422eh,04270h,042e9h	; 40aa

; ======================================================================
; CODIGO 0x40bc..0x4372  (694 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ESTADO 0. Secuencia de arranque de una etapa.
; ----------------------------------------------------------------------
ESTADO_0:		; Primer manejador; el djnz reparte los subestados
	djnz EST0_SUB2		;40bc   ; subestado 1 cae aqui; los demas saltan con el djnz
	ld a,(0e003h)		;40be
	rra			;40c1
	ret nc			;40c2
	call BAJA_ROTULO		;40c3
	ret nz			;40c6
	ld de,04c2ch		;40c7   ; vuelca el guion 0x4C2C
	call DESCOMPRIME_GUION		;40ca
	xor a			;40cd
	jr FIJA_ESPERA		;40ce
EST0_SUB2:
	djnz EST0_SUB3		;40d0
	ld hl,0e004h		;40d2
	dec (hl)			;40d5   ; espera a que 0xE004 baje a cero
	ret nz			;40d6
	call PREPARA_PANTALLA_CARRERA		;40d7
	xor a			;40da
	jp FIJA_ESPERA_Y_AVANZA		;40db
EST0_SUB3:
	call INSTALA_ROTULOS		;40de   ; encadena varias rutinas de dibujo del cuadro
	call INSTALA_DESC		;40e1
	call CARGA_REGISTROS_VDP		;40e4
	call LIMPIA_NOMBRES		;40e7
	call DIBUJA_MARCO		;40ea
	call DIBUJA_PANEL_JUEGO		;40ed
	call PREPARA_SCROLL		;40f0
	jr SIGUE_SUBESTADO		;40f3
ESTADO_1:		; Espera con retardo y salta al cierre de subestado
	ld hl,0e004h		;40f5
	dec (hl)			;40f8
	ret nz			;40f9
	jp PON_ESPERA_20B		;40fa
ESTADO_2:
	djnz EST2_SUB2		;40fd
	ld a,(0e003h)		;40ff
	or a			;4102
	ret nz			;4103
REARMA_FASE:
	xor a			;4104   ; reinicia la fase y pone 0x20 cuadros de espera
PON_ESPERA_32:
	ld (0e000h),a		;4105
	ld a,020h		;4108
	ld (0e004h),a		;410a
	jp LIMPIA_SUBESTADO		;410d
EST2_SUB2:
	call LIMPIA_FRANJA		;4110
	call OCULTA_SPRITES		;4113
	call AVANZA_ETAPA_CICLA		;4116
	xor a			;4119
	ld (0e003h),a		;411a
PON_ESPERA_20:
	ld a,020h		;411d
FIJA_ESPERA:		; Guarda A en 0xE004 (retardo en cuadros)
	ld (0e004h),a		;411f
SIGUE_SUBESTADO:		; inc 0xE001 y vuelve
	ld hl,0e001h		;4122   ; pasa al siguiente subestado
	inc (hl)			;4125
	ret			;4126
ESTADO_3:
	call PREPARA_ETAPA		;4127
	jp PON_ESPERA_20B		;412a
ESTADO_4:		; Pinta el numero de etapa
	djnz EST4_SUB2		;412d   ; el djnz reparte los cuatro subestados del estado 4
	call LIMPIA_FRANJA		;412f
	call DIBUJA_MARCO		;4132
	ld a,0f1h		;4135
	call TINTA_FRANJA		;4137
	ld hl,04d12h		;413a
	ld a,(0e060h)		;413d   ; si la etapa es 0x0D usa otro rotulo
	cp 00dh		;4140
	jr nz,EST4_ROTULO		;4142
	call VUELCA_GUION		;4144
	jr EST4_UNIDADES_4171		;4147
EST4_ROTULO:
	ld hl,04cf6h		;4149   ; vuelca el rotulo de la etapa
	call VUELCA_GUION		;414c
	ld hl,03912h		;414f
	ld a,(0e060h)		;4152
	cp 00ah		;4155
	jr c,EST4_UNIDADES		;4157
	ld c,a			;4159
	ld a,011h		;415a
	call 0004dh		;415c   ; BIOS WRTVRM - Writes data in VRAM | escribe el digito de las decenas de etapa en la VRAM
	ld a,c			;415f
	sub 00ah		;4160
EST4_UNIDADES:
	inc hl			;4162
	add a,010h		;4163
	call 0004dh		;4165   ; BIOS WRTVRM - Writes data in VRAM | y el de las unidades
	ld hl,03998h		;4168
	ld de,0e05eh		;416b
	call ARRANCA_CRONO_6C07		;416e
EST4_UNIDADES_4171:
	call DIBUJA_PANEL		;4171
	jr SIGUE_SUBESTADO		;4174
EST4_SUB2:
	djnz EST4_SUB3		;4176
	ld a,(0e012h)		;4178
	or a			;417b
	ret nz			;417c
	jr PON_ESPERA_20		;417d
EST4_SUB3:
	djnz EST4_SUB4		;417f   ; arranca la carrera en el subestado 3
	call LIMPIA_FRANJA		;4181
	call INICIA_CARRERA		;4184
	ld a,(0e061h)		;4187
	cp 010h		;418a
	ld b,0eeh		;418c
	call z,FIJA_BORDE		;418e   ; si la etapa vale 0x10 dibuja un adorno extra
	ld hl,04d66h		;4191
	call VUELCA_GUION		;4194
	ld a,004h		;4197
	ld (0e06ch),a		;4199
	ld a,020h		;419c
	jp FIJA_ESPERA		;419e
EST4_SUB4:
	djnz EST4_SUB5		;41a1   ; espera a que acabe el aviso (0xE020)
	ld a,(0e020h)		;41a3
	or a			;41a6
	ret nz			;41a7
	ld hl,0e06ch		;41a8
	dec (hl)			;41ab   ; cuenta atras en 0xE06C
	ld a,00eh		;41ac
	jp nz,ARRANCA_SONIDO		;41ae
	ld hl,04d6eh		;41b1
	call VUELCA_GUION		;41b4
	ld a,008h		;41b7
	call ARRANCA_SONIDO		;41b9
	jp SIGUE_SUBESTADO		;41bc
EST4_SUB5:
	djnz EST4_SUB6		;41bf   ; actualiza la carrera y mira el fin de tramo (0xE02E)
	call ESTADO_5		;41c1
	ld a,(0e02eh)		;41c4   ; espera a que se cierre el intento (0xE02E)
	or a			;41c7
	ret nz			;41c8
	ld a,001h		;41c9
	call ARRANCA_SONIDO		;41cb
	ld a,(0e085h)		;41ce
	or a			;41d1
	ret z			;41d2
	ld hl,04d76h		;41d3
	ld a,(0e060h)		;41d6
	cp 004h		;41d9
	jr nz,EST4_SEL_ROTULO		;41db
	ld hl,04d7eh		;41dd
EST4_SEL_ROTULO:
	cp 00ch		;41e0
	jr nz,EST4_PINTA		;41e2
	ld hl,04d86h		;41e4
EST4_PINTA:
	call VUELCA_GUION		;41e7
PON_ESPERA_20B:
	ld a,020h		;41ea
FIJA_ESPERA_Y_AVANZA:
	ld (0e004h),a		;41ec   ; guarda el retardo y avanza el estado principal
AVANZA_ESTADO:		; inc 0xE000, subestado a 0
	ld hl,0e000h		;41ef
	inc (hl)			;41f2
LIMPIA_SUBESTADO:
	xor a			;41f3
	ld (0e001h),a		;41f4
	ret			;41f7
EST4_SUB6:
	ld hl,0e061h		;41f8   ; limpia el bloque de estado de carrera 0xE061..
	ld de,0e062h		;41fb   ; pone a cero el bloque de estado de la carrera
	ld bc,00117h		;41fe
	ld (hl),000h		;4201
	ldir		;4203
	ld a,09ah		;4205
	call ARRANCA_SONIDO		;4207
	call CARGA_PARAM_ETAPA		;420a
	call ARRANCA_CRONO_6C19		;420d
	ld b,0e0h		;4210
	call FIJA_BORDE		;4212
	call OCULTA_SPRITES_DESDE_C		;4215
	jp PON_ESPERA_20		;4218
ESTADO_5:
	call ACTUALIZA_CARRERA		;421b
	ld a,(0e062h)		;421e   ; segun 0xE062/0xE063 rebota a otros subestados
	or a			;4221
	ld a,007h		;4222
	jp nz,PON_ESPERA_32		;4224
	ld a,(0e063h)		;4227
	or a			;422a
	jr nz,AVANZA_ESTADO		;422b
	ret			;422d
ESTADO_6:
	djnz EST6_SUB2		;422e   ; el djnz reparte los subestados del estado 6
	call ACTUALIZA_Y_MIRA_META		;4230
	ld a,(0e062h)		;4233   ; si el jugador ha llegado a meta (0xE062), rebota
	or a			;4236
	jp nz,PON_ESPERA_20B		;4237
	ld a,(0e085h)		;423a
	or a			;423d
	ret nz			;423e
	ld a,094h		;423f
	call ARRANCA_SONIDO		;4241
	jp SIGUE_SUBESTADO		;4244
EST6_SUB2:
	djnz EST6_SUB3		;4247
	ld a,(0e012h)		;4249
	or a			;424c
	ret nz			;424d
EST6_REDIBUJA:
	call OCULTA_SPRITES_DESDE_C		;424e
	jp PON_ESPERA_20		;4251
EST6_SUB3:
	djnz EST6_SUB4		;4254
EST6_LIMPIA_DEMO:		; borra bit6 de 0xE002 (sale de demo)
	ld hl,0e002h		;4256
	ld a,(hl)			;4259
	and 0bfh		;425a
	ld (hl),a			;425c
	jp REARMA_FASE		;425d
EST6_SUB4:
	xor a			;4260   ; vuelca dos veces el mismo guion (0x4C72)
	ld (0e063h),a		;4261
	ld hl,04c72h		;4264
	call VUELCA_GUION		;4267
	call VUELCA_GUION		;426a
	jp SIGUE_SUBESTADO		;426d
ESTADO_7:
	djnz EST7_SUB2		;4270   ; el djnz reparte los subestados del estado 7
	call ACTUALIZA_SI_JUEGA		;4272
	ld a,(0e012h)		;4275
	or a			;4278
	ret nz			;4279
	ld (0e085h),a		;427a
	call DIBUJA_VELOCIMETRO		;427d
	jp SIGUE_SUBESTADO		;4280
EST7_SUB2:
	djnz EST7_SUB3		;4283   ; si 0xE063 esta a cero, pasa de etapa
	ld hl,0e063h		;4285
	xor a			;4288
	cp (hl)			;4289
	jp z,EST7_AVANZA_ETAPA		;428a
	ld (hl),a			;428d
	ld a,006h		;428e
	ld (0e000h),a		;4290
	jp EST6_REDIBUJA		;4293
EST7_AVANZA_ETAPA:		; inc 0xE060
	ld hl,0e060h		;4296
	inc (hl)			;4299
	ld a,004h		;429a
	jp PON_ESPERA_32		;429c
EST7_SUB3:
	ld hl,04c72h		;429f   ; compara la posicion alcanzada con la meta de la etapa
	call VUELCA_GUION		;42a2
	call LEE_GUION_PISTA		;42a5   ; descomprime el siguiente trozo del guion de pista
	ld a,(0e060h)		;42a8
	cp 00dh		;42ab   ; si la etapa llega a 0x0D, fin
	jp z,AVANZA_ESTADO		;42ad
	call ARRANCA_CRONO		;42b0   ; prepara el bloque del cronometro
	ld hl,0e05bh		;42b3   ; lee la posicion alcanzada (0xE05B) en HL
	ld d,(hl)			;42b6
	inc hl			;42b7
	ld e,(hl)			;42b8
	inc hl			;42b9
	ld a,(hl)			;42ba
	inc hl			;42bb
	ld l,(hl)			;42bc
	ld h,a			;42bd
	xor a			;42be   ; la resta de la meta decide si clasifica
	sbc hl,de		;42bf   ; compara la posicion alcanzada (0xE05B) con la meta
	ld c,a			;42c1
	ld a,091h		;42c2
	ld hl,04d5ch		;42c4
	ld de,038abh		;42c7
	jr nc,EST7_PINTA_RESULTADO		;42ca
	ld a,(0e00bh)		;42cc   ; si el crono marca justo 0x3F, tambien pasa
	cp 03fh		;42cf
	ld a,091h		;42d1
	jr z,EST7_PINTA_RESULTADO		;42d3
	ld a,001h		;42d5   ; si no, marca fallo (0xE063) y el rotulo rojo
	ld (0e063h),a		;42d7
	ld a,094h		;42da
	ld hl,04d59h		;42dc
	dec e			;42df
EST7_PINTA_RESULTADO:
	call ARRANCA_SONIDO		;42e0
	call GUION_BYTE		;42e3
	jp SIGUE_SUBESTADO		;42e6
ESTADO_8:
	djnz EST8_SUB2		;42e9   ; el djnz reparte los subestados del estado 8
	call EST8_CUENTA		;42eb
	call AVANZA_ANIMACION		;42ee
	call ANIMA_RUEDAS		;42f1
	call VUELCA_SPRITES_COCHE		;42f4
	ld a,(0e012h)		;42f7
	or a			;42fa
	ret nz			;42fb
	call PREPARA_ETAPA		;42fc
	jp EST6_LIMPIA_DEMO		;42ff
EST8_CUENTA:
	ld a,(0e003h)		;4302   ; solo cuenta en la fase 0 de la interrupcion
	or a			;4305
	ret nz			;4306   ; solo trabaja en la fase 0 de la interrupcion
	ld hl,0e064h		;4307
	inc (hl)			;430a
	ld a,(hl)			;430b
	cp 001h		;430c
	jp z,ARRANCA_CRONO		;430e
	ld hl,04d3ah		;4311
	cp 002h		;4314
	jr z,EST8_CUENTA_431E		;4316
	ld hl,04d21h		;4318
	cp 004h		;431b
	ret nz			;431d
EST8_CUENTA_431E:
	jp VUELCA_GUION		;431e
EST8_SUB2:
	ld hl,04c81h		;4321   ; borra la pizarra y vuelca su rotulo
	call VUELCA_GUION		;4324
	ld a,097h		;4327
	call ARRANCA_SONIDO		;4329
	ld hl,01120h		;432c
	ld bc,00058h		;432f
	ld a,0eeh		;4332
	call 00056h		;4334   ; BIOS FILVRM - Fills VRAM with value | rellena una franja de la VRAM
	ld hl,03b28h		;4337
	ld b,00ch		;433a
	call ESCRIBE_CADA_4		;433c
	xor a			;433f
	ld (0e003h),a		;4340
	ld (0e064h),a		;4343
	jp SIGUE_SUBESTADO		;4346
PREPARA_ETAPA:		; Limpia el bloque 0xE058-0xE178 y avanza la etapa
	ld hl,0e058h		;4349   ; borra de un ldir el estado de la etapa
	ld de,0e059h		;434c
	ld bc,00120h		;434f
	ld (hl),000h		;4352
	ldir		;4354
	ld hl,0e060h		;4356   ; sube 0xE060 a la etapa siguiente
	inc (hl)			;4359
	ld hl,08006h		;435a   ; arranca los dos punteros de posicion en 0x8006
	ld (0e05bh),hl		;435d
	ld (0e05dh),hl		;4360
	ret			;4363
CARGA_PARAM_ETAPA:		; 0xE061 = tabla_param_etapa[0xE060]
	ld hl,tabla_param_etapa_base		;4364
	ld a,(0e060h)		;4367   ; indexa por el numero de etapa
	call HL_MAS_A		;436a
	ld a,(hl)			;436d
	ld (0e061h),a		;436e
tabla_param_etapa_base:
	ret			;4371

; ----------------------------------------------------------------------
; DATOS tabla_param_etapa: Parametro por etapa (indexada por 0xE060)
;   0x4372..0x437f  (13 bytes)
DATA_tabla_param_etapa:
	defb 000h,001h,002h,006h,008h,000h,010h,040h,002h,001h,020h,008h,040h	; 4372  .......@.. .@

; ======================================================================
; CODIGO 0x437f..0x45bd  (574 bytes)
; ======================================================================


AVANZA_ETAPA_CICLA:		; Etapa +1; al llegar a 0x0D vuelve a 1
	call DIBUJA_PANEL		;437f
	ld hl,0e060h		;4382
	inc (hl)			;4385
	ld a,(hl)			;4386
	cp 00dh		;4387   ; 0x0D es una vuelta entera: reinicia a la etapa 1
	jr nz,AVANZA_ETAPA_CICLA_438D		;4389
	ld (hl),001h		;438b
AVANZA_ETAPA_CICLA_438D:
	call CARGA_PARAM_ETAPA		;438d
	jp INICIA_CARRERA		;4390
LIMPIA_NOMBRES:		; Rellena la tabla de nombres 0x3800 (0x300 bytes)
	xor a			;4393
	jr LIMPIA_NOMBRES_1_4398		;4394
LIMPIA_NOMBRES_1:
	ld a,001h		;4396
LIMPIA_NOMBRES_1_4398:
	push af			;4398   ; guarda el byte de relleno mientras limpia los sprites
	call OCULTA_SPRITES		;4399
	pop af			;439c
	ld hl,03800h		;439d
	ld bc,00300h		;43a0
	jp 00056h		;43a3   ; BIOS FILVRM - Fills VRAM with value
LIMPIA_FRANJA:		; Rellena 0x2A0 bytes desde 0x3860 con el tile 1
	ld bc,002a0h		;43a6
	ld hl,03860h		;43a9
	ld a,001h		;43ac
	jp 00056h		;43ae   ; BIOS FILVRM - Fills VRAM with value
OCULTA_SPRITES:		; Y=0xDF en los 32 sprites de 0x3B00 (los saca de pantalla)
	ld hl,03b00h		;43b1
	ld b,020h		;43b4
ESCRIBE_CADA_4:		; Escribe A en la VRAM cada 4 bytes, B veces
	ld de,00004h		;43b6
	ld a,0dfh		;43b9
ESCRIBE_CADA_4_43BB:
	call 0004dh		;43bb   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;43be
	djnz ESCRIBE_CADA_4_43BB		;43bf
	ret			;43c1
OCULTA_SPRITES_DESDE_C:		; Igual desde 0x3B0C, 0x1D sprites
	ld hl,03b0ch		;43c2
	ld b,01dh		;43c5
	jr ESCRIBE_CADA_4		;43c7
SUMA_PUNTOS:		; Suma en BCD a la puntuacion (0xE058), tope 999999
	ld c,000h		;43c9
	ld a,(0e002h)		;43cb   ; en demo (bit7 de 0xE002) no puntua
	add a,a			;43ce
	ret p			;43cf
	ld hl,0e058h		;43d0
	ld a,(hl)			;43d3
	add a,e			;43d4
	daa			;43d5   ; suma tres bytes en BCD con ajuste decimal
	ld (hl),a			;43d6
	ld e,a			;43d7
	inc l			;43d8
	ld a,(hl)			;43d9
	adc a,d			;43da
	daa			;43db
	ld (hl),a			;43dc
	ld d,a			;43dd
	inc hl			;43de
	ld a,(hl)			;43df
	adc a,c			;43e0
	daa			;43e1
	ld (hl),a			;43e2
	jr nc,ACTUALIZA_TOPE		;43e3   ; si desborda, clava marca y mejor en 9999
	ld bc,09999h		;43e5   ; al desbordar, clava la marca en 9999
	ld (0e055h),bc		;43e8
	ld (0e056h),bc		;43ec
	jr PINTA_MARCADOR		;43f0
ACTUALIZA_TOPE:
	ld a,(0e057h)		;43f2   ; actualiza el tope de la marca si procede
	ld b,(hl)			;43f5
	sub b			;43f6   ; compara con el tope guardado
	jr c,GUARDA_MARCA		;43f7
	jr nz,PINTA_MARCADOR		;43f9
	ld hl,(0e055h)		;43fb
	sbc hl,de		;43fe
	jr nc,PINTA_MARCADOR		;4400
GUARDA_MARCA:
	ld (0e055h),de		;4402   ; y lo actualiza si procede
	ld a,b			;4406
	ld (0e057h),a		;4407
	jr PINTA_MARCADOR		;440a
DIBUJA_PANEL:		; Vuelca el guion 0x4C42 y refresca actores
	ld hl,04c42h		;440c   ; vuelca el guion del panel y refresca el estado
	call VUELCA_GUION		;440f
	call DIBUJA_VELOCIMETRO		;4412
	call RELOJ_PINTA		;4415
	call INSTALA_MARCHA		;4418
	call INSTALA_GASOLINA		;441b
PINTA_MARCADOR:		; Escribe los digitos BCD del marcador en 0x3822
	ld de,0e05ah		;441e
	ld a,(0e002h)		;4421
	bit 6,a		;4424   ; bit6 de 0xE002: en demo pinta otra cosa
	jr nz,PINTA_MARCADOR_A		;4426
	ld hl,04c3dh		;4428
	call VUELCA_GUION		;442b
	ld de,0e057h		;442e
PINTA_MARCADOR_A:
	ld hl,03822h		;4431
	ld b,003h		;4434
PINTA_MARCADOR_BUCLE:
	ld a,(de)			;4436   ; parte cada byte BCD en dos digitos y los escribe
PINTA_MARCADOR_BUCLE_4437:
	ld c,a			;4437   ; parte cada byte BCD en dos digitos
	rra			;4438
	rra			;4439
	rra			;443a
	rra			;443b
	and 00fh		;443c
	add a,010h		;443e   ; el nibble alto es la decena
	call 0004dh		;4440   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4443
	ld a,c			;4444
	and 00fh		;4445   ; el nibble bajo la unidad
	add a,010h		;4447
	call 0004dh		;4449   ; BIOS WRTVRM - Writes data in VRAM
	dec de			;444c
	inc hl			;444d
	djnz PINTA_MARCADOR_BUCLE		;444e
	ret			;4450
PREPARA_PANTALLA_CARRERA:		; Limpia pantalla, dibuja marco y actores
	xor a			;4451   ; limpia la pantalla y coloca el marco y los actores
	ld (0e00dh),a		;4452
	call LIMPIA_NOMBRES		;4455
	call DIBUJA_MARCO		;4458
	ld b,0e0h		;445b
	call FIJA_BORDE		;445d
	call LIMPIA_NOMBRES_1		;4460
	ld hl,04c9eh		;4463
	jp VUELCA_GUION		;4466
VUELCA_A_VRAM:		; ex de,hl y salta a LDIRVM
	ex de,hl			;4469
	jp 0005ch		;446a   ; BIOS LDIRVM - Block transfers to VRAM from memory
DESCOMPRIME_GUION:		; Interprete de guiones comprimidos de pantalla (RLE)
	ld c,000h		;446d   ; C=0: escribe en la tabla de nombres
DESC_BLOQUE:
	ex de,hl			;446f   ; toma el puntero del bloque siguiente y lo sigue
	ld e,(hl)			;4470
	inc hl			;4471
	ld d,(hl)			;4472
	ex de,hl			;4473
	inc de			;4474
DESC_ABRE:
	call FIJA_ESCRITURA		;4475
DESC_LEE:
	ld a,(de)			;4478   ; lee la cuenta; 0 cierra el bloque
	and 07fh		;4479
	ld b,a			;447b
	ld a,(de)			;447c
	inc de			;447d
	jr z,DESC_FIN		;447e
	cp b			;4480
	jr z,DESC_REPITE		;4481
DESC_COPIA:
	call 0e310h		;4483   ; racha distinta: vuelca B bytes por el puerto reubicado
	exx			;4486
	out (c),a		;4487
	exx			;4489
	djnz DESC_COPIA		;448a
	jr DESC_LEE		;448c
DESC_REPITE:
	call 0e310h		;448e   ; racha igual: repite el mismo byte B veces
DESC_REPITE_4491:
	exx			;4491   ; repite el mismo byte por el puerto B veces
	out (c),a		;4492
	exx			;4494
	push hl			;4495
	pop hl			;4496
	djnz DESC_REPITE_4491		;4497
	jr DESC_LEE		;4499
DESC_FIN:
	cp b			;449b
	jr nz,DESC_BLOQUE		;449c
	ei			;449e   ; fin de todos los bloques
	ret			;449f
DESC_NOMBRES_ABRE:
	ld c,000h		;44a0
	jr DESC_ABRE		;44a2
DESC_NOMBRES:
	ld c,000h		;44a4
	jr DESC_LEE		;44a6
DESC_PATRONES_ABRE:
	ld c,001h		;44a8
	jr DESC_BLOQUE		;44aa
DESC_PATRONES:
	ld c,001h		;44ac
	jr DESC_LEE		;44ae
DESC_DOBLE:		; Variante que dibuja dos capas (mascara y patron)
	ld a,(de)			;44b0
	ld (0e0d0h),a		;44b1   ; cuenta de la primera capa
	inc de			;44b4
	rla			;44b5
	jr nc,DESC_DOBLE_2		;44b6
	ex de,hl			;44b8
	ld e,(hl)			;44b9
	inc hl			;44ba
	ld d,(hl)			;44bb
	inc hl			;44bc
	ex de,hl			;44bd
	ld (0e0d1h),hl		;44be   ; puntero opcional de la primera capa
DESC_DOBLE_2:
	ld a,(de)			;44c1   ; lee la cuenta de la segunda capa
	ld (0e0d3h),a		;44c2
	inc de			;44c5   ; apunta al mismo origen para las dos capas
	rla			;44c6
	jr nc,DESC_DOBLE_ORIG		;44c7
	ex de,hl			;44c9
	ld e,(hl)			;44ca
	inc hl			;44cb
	ld d,(hl)			;44cc
	inc hl			;44cd
	ex de,hl			;44ce
	ld (0e0d4h),hl		;44cf
DESC_DOBLE_ORIG:
	ld (0e0d6h),de		;44d2   ; guarda el origen comun de las dos
	ld hl,0e0d0h		;44d6
	bit 7,(hl)		;44d9
	res 7,(hl)		;44db
	jr z,DESC_DOBLE_CAPA1		;44dd
	ld hl,(0e0d1h)		;44df
	call FIJA_ESCRITURA		;44e2
DESC_DOBLE_CAPA1:
	ld de,(0e0d6h)		;44e5   ; vuelca la primera capa byte a byte
	call DESC_NOMBRES		;44e9
	ld hl,0e0d0h		;44ec   ; baja el contador de la primera capa
	dec (hl)			;44ef
	jr nz,DESC_DOBLE_CAPA1		;44f0
	ld hl,0e0d3h		;44f2
	ld a,(hl)			;44f5
	or a			;44f6
	jr z,DESC_DOBLE_SIGUE		;44f7
	bit 7,(hl)		;44f9
	res 7,(hl)		;44fb
	jr z,DESC_DOBLE_CAPA2		;44fd
	ld hl,(0e0d4h)		;44ff
	call FIJA_ESCRITURA		;4502
DESC_DOBLE_CAPA2:
	ld de,(0e0d6h)		;4505
	call DESC_PATRONES		;4509
	ld hl,0e0d3h		;450c
	dec (hl)			;450f
	jr nz,DESC_DOBLE_CAPA2		;4510
DESC_DOBLE_SIGUE:
	ld a,(de)			;4512
	inc a			;4513
	jr nz,DESC_DOBLE		;4514
	ret			;4516
FIJA_ESCRITURA:		; SETWRT y guarda el puerto de datos del VDP en C'
	ex af,af'			;4517
	call 00053h		;4518   ; BIOS SETWRT - Enables VDP to write | abre la VRAM para escribir en (HL)
	exx			;451b
	ld a,(00007h)		;451c   ; lee el puerto de datos del VDP (0x0007) a C'
	ld c,a			;451f
	exx			;4520
	ex af,af'			;4521
	ret			;4522
PINTA_TIRA:		; Vuelca una tira con codigos de control (0x24, 0xFF)
	ex de,hl			;4523   ; sigue un puntero y vuelca la tira
	ld e,(hl)			;4524
	inc hl			;4525
	ld d,(hl)			;4526
	inc hl			;4527
	ex de,hl			;4528
PINTA_TIRA_1:
	exx			;4529
	ld a,(00007h)		;452a
	ld c,a			;452d
	exx			;452e
	ld b,000h		;452f
PINTA_TIRA_FIJA:
	call 00053h		;4531   ; BIOS SETWRT - Enables VDP to write
PINTA_TIRA_BUCLE:
	ld a,(de)			;4534
	inc de			;4535
	cp 024h		;4536   ; por debajo de 0x24 es un salto de posicion
	jr c,PINTA_TIRA_AVANZA		;4538
	cp 0ffh		;453a   ; 0xFF sigue un puntero
	jr z,PINTA_TIRA_PUNTERO		;453c
	exx			;453e
	out (c),a		;453f
	exx			;4541
	jr PINTA_TIRA_BUCLE		;4542
PINTA_TIRA_SALTO:
	call DESC_NOMBRES_ABRE		;4544
	jr PINTA_TIRA_BUCLE		;4547
PINTA_TIRA_AVANZA:
	dec a			;4549   ; por debajo de 0x24 mueve la posicion de escritura
	ret m			;454a
	jr z,PINTA_TIRA_SALTO		;454b
	inc a			;454d
	ld c,a			;454e
	add hl,bc			;454f
	jr PINTA_TIRA_FIJA		;4550
PINTA_TIRA_PUNTERO:
	ex de,hl			;4552   ; 0xFF: salta al puntero que sigue
	ld a,(hl)			;4553
	inc hl			;4554
	ld h,(hl)			;4555
	ld l,a			;4556
	ex de,hl			;4557
	jr PINTA_TIRA_BUCLE		;4558
PINTA_ROTULO:		; Rutina de rotulos (se copia a 0xE1C0 y corre alli)
	exx			;455a
	ld a,(00007h)		;455b
	ld c,a			;455e
	exx			;455f
	ld b,000h		;4560
PINTA_ROTULO_4562:
	ld a,(de)			;4562   ; 0x30 marca fin de tramo; por debajo, es control
	cp 030h		;4563
PROT_SALTO:
	ld c,020h		;4565   ; recoloca la posicion de escritura del rotulo
	jr nc,PROT_ESCRIBE		;4567
	inc de			;4569
	cp 001h		;456a
	jr z,PROT_BYTE		;456c
	ld c,a			;456e
PROT_ESCRIBE:
	add hl,bc			;456f
	ld a,(de)			;4570
	cp 030h		;4571
	call z,PROT_PUNTERO		;4573
	call 00053h		;4576   ; BIOS SETWRT - Enables VDP to write | abre la VRAM en la posicion calculada
PROT_BYTE:
	ld a,(de)			;4579   ; saca el caracter por el puerto de datos
	nop			;457a
	exx			;457b
	out (c),a		;457c   ; saca el codigo de caracter por el puerto
	exx			;457e
	inc de			;457f
	ld a,(de)			;4580
	or a			;4581
	ret z			;4582
	cp 030h		;4583
	jr nz,PROT_SALTO		;4585
	call PROT_PUNTERO		;4587
	jr PINTA_ROTULO_4562		;458a
PROT_PUNTERO:		; Sigue el puntero de continuacion del rotulo
	ex de,hl			;458c   ; sigue el puntero de continuacion del rotulo
	inc hl			;458d
	ld a,(hl)			;458e
	inc hl			;458f
	ld h,(hl)			;4590
	ld l,a			;4591
	ex de,hl			;4592
	ret			;4593
INSTALA_ROTULOS:		; Copia PINTA_ROTULO a 0xE1C0
	ld hl,PINTA_ROTULO		;4594   ; copia la rutina de rotulos a la RAM (0xE1C0)
	ld de,0e1c0h		;4597
	ld bc,00032h		;459a
	ldir		;459d
	ld hl,0fc3eh		;459f
	ld (0e1dfh),hl		;45a2
	ret			;45a5
INSTALA_DESC:		; Copia el nucleo out(c),a a 0xE310
	ld hl,045bdh		;45a6
	ld de,0e310h		;45a9
	ld bc,0002fh		;45ac
	ldir		;45af
FIJA_ORIGEN_DESC:
	ld hl,(045beh)		;45b1
	jr CERO_ORIGEN_DESC_45B9		;45b4
CERO_ORIGEN_DESC:
	ld hl,00000h		;45b6
CERO_ORIGEN_DESC_45B9:
	ld (0e311h),hl		;45b9
	ret			;45bc

; ----------------------------------------------------------------------
; DATOS nucleo_desc_reubicado: Nucleo del descompresor que corre en 0xE310
;   0x45bd..0x45e1  (36 bytes)
DATA_nucleo_desc_reubicado:
	defb 01ah,018h,01dh,0c5h,0e6h,0f0h,0feh,0e0h,028h,004h,0feh,030h,020h,002h,03eh,010h	; 45bd  ........(..0 .>.
	defb 04fh,01ah,0e6h,00fh,0feh,00eh,028h,004h,0feh,003h,020h,002h,03eh,001h,0b1h,0c1h	; 45cd  O.....(... .>...
	defb 013h,0cbh,041h,0c8h	; 45dd

; ======================================================================
; CODIGO 0x45e1..0x4651  (112 bytes)
; ======================================================================


INVIERTE_BITS:		; Devuelve A con sus 8 bits del reves (para espejar dibujos)
	push bc			;45e1
	ld c,a			;45e2
	ld b,008h		;45e3
INVIERTE_BITS_45E5:
	rr c		;45e5
	rla			;45e7
	djnz INVIERTE_BITS_45E5		;45e8
	pop bc			;45ea
	ret			;45eb
VUELCA_GUION:		; Interprete de guion [destino][cuenta][bytes]... a la VRAM
	ld c,000h		;45ec   ; c=0: escribe tal cual
GUION_DESTINO:
	ld e,(hl)			;45ee   ; toma el destino de VRAM del guion
	inc hl			;45ef
	ld d,(hl)			;45f0
	inc hl			;45f1
GUION_BYTE:
	ld a,(hl)			;45f2   ; la cuenta: 0xFF cierra el guion, 0xFE abre otro destino
	inc hl			;45f3
	ld b,a			;45f4
	inc b			;45f5
	ret z			;45f6
	inc b			;45f7
	jr z,GUION_DESTINO		;45f8
	bit 0,c		;45fa
	jr z,GUION_ESCRIBE		;45fc
	ld a,c			;45fe
GUION_ESCRIBE:
	ex de,hl			;45ff
	call 0004dh		;4600   ; BIOS WRTVRM - Writes data in VRAM | saca el byte a la VRAM
	ex de,hl			;4603
	inc de			;4604
	jr GUION_BYTE		;4605
VUELCA_GUION_INV:		; Igual pero marca los bytes (c=1)
	ld c,001h		;4607
	jr GUION_DESTINO		;4609
RELLENA_3_TERCIOS:		; Rellena el mismo patron en los tres tercios de pantalla
	ld d,003h		;460b
RELLENA_3_TERCIOS_460D:
	push bc			;460d
	push de			;460e
	call 00056h		;460f   ; BIOS FILVRM - Fills VRAM with value
	ld de,00800h		;4612
	add hl,de			;4615
	pop de			;4616
	pop bc			;4617
	dec d			;4618
	jr nz,RELLENA_3_TERCIOS_460D		;4619
	ret			;461b
DESC_3_TERCIOS:		; Descomprime el mismo bloque en los tres tercios
	ld b,003h		;461c
DESC_3_TERCIOS_461E:
	push bc			;461e   ; descomprime el mismo bloque en los tres tercios
	push de			;461f
	call DESC_NOMBRES_ABRE		;4620
	ld de,00800h		;4623
	add hl,de			;4626
	pop de			;4627
	pop bc			;4628
	djnz DESC_3_TERCIOS_461E		;4629
	ret			;462b
LIMPIA_VRAM:		; Silencia el sonido y borra los 16 KB de VRAM
	ld a,0b8h		;462c
	call FIJA_MEZCLADOR		;462e
	ld a,01dh		;4631
	call ARRANCA_SONIDO		;4633
	ld hl,00000h		;4636
	ld bc,04000h		;4639
	xor a			;463c
	call 00056h		;463d   ; BIOS FILVRM - Fills VRAM with value
CARGA_REGISTROS_VDP:		; Escribe los ocho registros del VDP desde la tabla
	ld hl,04651h		;4640
	ld d,008h		;4643
	ld c,000h		;4645
CARGA_REGISTROS_VDP_4647:
	ld b,(hl)			;4647
	call 00047h		;4648   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;464b
	inc c			;464c
	dec d			;464d
	jr nz,CARGA_REGISTROS_VDP_4647		;464e
	ret			;4650

; ----------------------------------------------------------------------
; DATOS tabla_registros_vdp: Los ocho valores de registro del VDP (SCREEN 2)
;   0x4651..0x4659  (8 bytes)
DATA_tabla_registros_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e4h	; 4651  .....v..

; ======================================================================
; CODIGO 0x4659..0x481a  (449 bytes)
; ======================================================================


FIJA_BORDE:		; WRTVDP registro 7 (color de borde y fondo) = C
	ld c,007h		;4659
	jp 00047h		;465b   ; BIOS WRTVDP - Writes data in the VDP-register
LEE_MANDOS_FLANCO:		; Lee los mandos y deja en 0xE00A los recien pulsados
	call LEE_MANDOS		;465e
	ld hl,0e00ah		;4661
FLANCO:		; Deja en 0xE00A las teclas que pasan de sueltas a pulsadas
	ld c,(hl)			;4664   ; deja en 0xE00A los mandos que acaban de pulsarse
	ld (hl),a			;4665
	xor c			;4666
	and (hl)			;4667
	dec hl			;4668
	ld (hl),a			;4669
	ret			;466a
LEE_MANDOS:		; Junta joystick (PSG) y teclado (filas 7 y 8) en un byte
	ld e,08fh		;466b   ; selecciona el puerto de mando en el registro 15 del PSG
	ld a,00fh		;466d   ; registro 14 del PSG: el joystick
	call 00093h		;466f   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;4672
	di			;4674
	call 00096h		;4675   ; BIOS RDPSG - Reads value from PSG-register | lee el registro 14 del PSG (el estado del joystick)
	ei			;4678
	cpl			;4679
	and 03fh		;467a
	push af			;467c
	ld a,007h		;467d   ; fila 7 del teclado (flechas)
	call 00141h		;467f   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | fila 7 del teclado
	cpl			;4682
	rrca			;4683   ; deja el bit de arriba/abajo
	and 020h		;4684
	ld e,a			;4686
	ld a,008h		;4687   ; fila 8 del teclado (espacio)
	call 00141h		;4689   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | fila 8 del teclado
	cpl			;468c
	rrca			;468d   ; separa disparo y direccion
	rrca			;468e
	ld b,a			;468f
	and 004h		;4690
	or e			;4692
	ld c,a			;4693
	ld a,b			;4694
	rrca			;4695
	rrca			;4696
	ld b,a			;4697
	and 018h		;4698
	or c			;469a
	ld c,a			;469b
	ld a,b			;469c
	rrca			;469d   ; y el ultimo bit de direccion
	and 003h		;469e
	or c			;46a0
	pop bc			;46a1   ; mezcla joystick y teclado en el mismo byte
	or b			;46a2   ; junta joystick y teclado
	ret			;46a3
MANDOS_REPOSO:		; Fuera de partida: START empieza, o entra en demo
	call LEE_MANDOS		;46a4
	ld hl,0e051h		;46a7   ; flanco del disparo/START (0xE051)
	call FLANCO		;46aa
	or a			;46ad
	ret z			;46ae
	ld b,a			;46af
	xor a			;46b0
	ld (0e004h),a		;46b1
	ld a,001h		;46b4
	ld hl,0e000h		;46b6
	cp (hl)			;46b9
	jr z,REPOSO_DEMO		;46ba
	ld (hl),a			;46bc
	jp PREPARA_PANTALLA_CARRERA		;46bd   ; START pulsado: prepara la pantalla de carrera
REPOSO_DEMO:
	ld a,b			;46c0
	and 030h		;46c1
	ret z			;46c3
	ld hl,0e002h		;46c4
	set 6,(hl)		;46c7   ; si no, marca demo (bit6 de 0xE002) y salta al estado 3
	ld hl,00003h		;46c9
	ld (0e000h),hl		;46cc
	ret			;46cf
PREPARA_SCROLL:		; Arranca el puntero (0xE00D/0xE00E) del rotulo que baja
	ld a,00eh		;46d0
	ld (0e00dh),a		;46d2
	ld hl,03aaah		;46d5
	ld (0e00eh),hl		;46d8
	ret			;46db
BAJA_ROTULO:		; Sube el puntero de VRAM una fila y pinta tres tiras
	ld hl,(0e00eh)		;46dc
	ld de,0ffe0h		;46df   ; resta 0x20 (una fila de la tabla de nombres)
	add hl,de			;46e2
	ld (0e00eh),hl		;46e3
	ld a,045h		;46e6
	ld b,003h		;46e8
	call ESCRIBE_INCR		;46ea
	ld bc,00b0ch		;46ed
	call ESCRIBE_INCR		;46f0
	ld b,c			;46f3
	call ESCRIBE_INCR		;46f4
	xor a			;46f7
	call 00056h		;46f8   ; BIOS FILVRM - Fills VRAM with value
	ld hl,0e00dh		;46fb
	dec (hl)			;46fe
	ret			;46ff
ESCRIBE_INCR:		; Escribe B caracteres correlativos y avanza una fila
	push hl			;4700
ESCRIBE_INCR_4701:
	call 0004dh		;4701   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4704
	inc a			;4705
	djnz ESCRIBE_INCR_4701		;4706
	pop de			;4708
	ld hl,00020h		;4709
	add hl,de			;470c
	ret			;470d
INICIA_CARRERA:		; Fija las variables del coche y prepara la etapa
	ld a,001h		;470e   ; marca la carrera como no acabada
	ld (0e06ah),a		;4710
	ld a,0ffh		;4713
	ld (0e089h),a		;4715
	ld (0e065h),a		;4718
	ld a,080h		;471b
	ld (0e080h),a		;471d
	ld hl,00009h		;4720   ; arranca los contadores de tramo
	ld (0e072h),hl		;4723
	ld l,h			;4726
	ld (0e07ch),hl		;4727
	ld hl,06d3dh		;472a   ; puntero de la pista en curso (0xE07E)
	ld (0e07eh),hl		;472d   ; apunta al guion de la pista
	ld hl,00801h		;4730
	ld (0e087h),hl		;4733
	call PREPARA_RIVALES		;4736   ; arranca las melodias de la etapa
	call CHOCA_RIVAL_2		;4739
	call SONIDO_ETAPA		;473c
	ld a,(0e060h)		;473f   ; a partir de la etapa 0x0A cambia el paso del marcador
	cp 00ah		;4742
	ld l,028h		;4744
	ld h,l			;4746
	jr c,INICIA_CARRERA_474B		;4747
	ld l,024h		;4749
INICIA_CARRERA_474B:
	ld (0e066h),hl		;474b   ; sobre la etapa 10 acorta el marcador
	ld hl,07381h		;474e
	call HL_MAS_A		;4751   ; indexa la tabla de anchos de marcador por la etapa
	ld a,(hl)			;4754
	ld hl,0738fh		;4755
	call HL_MAS_A		;4758
	ld (0e07ah),hl		;475b
	call LEE_PISTA_TRAMO		;475e   ; coloca coche, salpicadero y decorado
	call CARGA_CARRETERA		;4761
	call INSTALA_ACUATICO		;4764
	call DESPACHA_FONDO_ETAPA		;4767
	call DIBUJA_TILES_ETAPA		;476a   ; dibuja el fondo y los tiles de la etapa
	call DIBUJA_PANEL_JUEGO		;476d
	call DIBUJA_HORIZONTE		;4770
	call DIBUJA_ESCENARIO		;4773
	call DIBUJA_CARRETERA		;4776
	call DIBUJA_CUENTAKM		;4779
	ld a,(0e061h)		;477c
	cp 020h		;477f
	jr z,INICIA_CARRERA_478B		;4781
	bit 0,a		;4783
	call z,SCROLL_VUELCA		;4785
	call nz,DIBUJA_BORDES		;4788
INICIA_CARRERA_478B:
	call ALGO_6B5E		;478b
	jp INSTALA_SPRITES_COCHE		;478e
ACTUALIZA_CARRERA:		; Un cuadro del motor: direccion, fisica y actores
	call LEE_REVOLUCIONES		;4791   ; encadena direccion, fisica y actores del cuadro
	ld (0e087h),a		;4794
	call FIJA_SPAWN_RIVAL		;4797   ; elige donde aparece el proximo rival
	call CONTROL_ACELERADOR		;479a
	call SCROLL_CARRETERA		;479d
	call SCROLL_ACUATICO		;47a0
	call FUEGOS_META		;47a3
	call RELOJ_PINTA_6B37		;47a6
	call AVANZA_RELOJ		;47a9
	call GASTA_GASOLINA		;47ac
	call AVANZA_CARRERA		;47af
DIBUJA_CARRERA:		; La tuberia de dibujado del cuadro de carrera
	call AGITA_RIVALES		;47b2   ; encadena las rutinas de dibujado del cuadro
	call DIBUJA_RIVALES		;47b5
	call LEE_VOLANTE		;47b8
	call MUEVE_COCHE_X		;47bb
	call ANIMA_RUEDAS		;47be
	call MIRA_CHOQUE_LATERAL		;47c1
	call AJUSTA_ALTURA_COCHE		;47c4
	call VUELCA_SPRITES_COCHE		;47c7
	jp CHOQUE_OBSTACULO		;47ca
ACTUALIZA_SI_JUEGA:		; Solo con partida en marcha (0xE085)
	ld a,(0e085h)		;47cd
	or a			;47d0
	ret z			;47d1
	call DIBUJA_CARRERA		;47d2
ACTUALIZA_COCHE:
	ld a,001h		;47d5
	call FRENA		;47d7
	call DIBUJA_VELOCIMETRO		;47da
AVANZA_ANIMACION:		; Cada 0xE072 cuadros pasa al siguiente fotograma
	ld hl,0e072h		;47dd   ; cada 0xE072 cuadros pasa al fotograma siguiente
	dec (hl)			;47e0
	ret nz			;47e1   ; si aun no toca, se va
	call VELOCIDAD_A_INDICE		;47e2
	ld (hl),a			;47e5
	inc hl			;47e6
	inc (hl)			;47e7
	ld a,(hl)			;47e8
	and 003h		;47e9
	inc hl			;47eb
	ld (hl),a			;47ec
	call DIBUJA_CARRETERA		;47ed
	call DIBUJA_CUENTAKM		;47f0
	jp DIBUJA_BORDES		;47f3
ACTUALIZA_Y_MIRA_META:
	ld a,(0e085h)		;47f6
	or a			;47f9
	ret z			;47fa
	call ACTUALIZA_COCHE		;47fb
	call APARECEN_OBJETOS		;47fe
	ld a,(0e07ch)		;4801
	cp 01ah		;4804   ; si el avance (0xE07C) llega a 0x1A, marca meta (0xE062)
	jr nz,ACT_META_2		;4806
	ld a,001h		;4808
	ld (0e062h),a		;480a
ACT_META_2:
	call RELOJ_PINTA_6B37		;480d
	jp DIBUJA_CARRERA		;4810
DESPACHA_FONDO_ETAPA:		; Dibuja el fondo segun la etapa (0xE060), via tabla
	ld a,(0e060h)		;4813
	dec a			;4816   ; indexa desde 1
	call SALTA_POR_TABLA		;4817

; ----------------------------------------------------------------------
; DATOS tabla_fondos_etapa: Rutina de fondo por etapa (indexada por 0xE060)
;   0x481a..0x4834  (26 bytes)
DATA_tabla_fondos_etapa:
	defw 051b8h,0586ch,05a44h,05b22h,05b68h,051b8h,05d5bh,051b8h,05a44h,0586ch,05d86h,05e94h,051b8h	; 481a

; ======================================================================
; CODIGO 0x4834..0x485e  (42 bytes)
; ======================================================================


DIBUJA_TILES_ETAPA:		; Pone los tiles de cielo y suelo segun la etapa
	ld de,0485ch		;4834   ; rellena cielo y suelo en los tres tercios
	ld a,(0e060h)		;4837   ; indexa la tabla de tiles por la etapa
	add a,a			;483a
	call DE_MAS_A		;483b   ; indexa la tabla 0x485C por la etapa
	ld a,(de)			;483e   ; el primero es el tile del cielo
	push af			;483f
	inc de			;4840
	ld a,(de)			;4841
	ld hl,007e0h		;4842   ; lo pone en la banda alta de la pantalla
	ld bc,00008h		;4845
	push bc			;4848
	call RELLENA_3_TERCIOS		;4849
	ld hl,007e8h		;484c
	pop bc			;484f
	pop af			;4850
	call RELLENA_3_TERCIOS		;4851
	ld hl,027e0h		;4854   ; y el resto en la banda del suelo
	ld bc,00010h		;4857
	xor a			;485a
	jp RELLENA_3_TERCIOS		;485b

; ----------------------------------------------------------------------
; DATOS tabla_tiles_etapa: Pares [cielo][suelo] de tiles por etapa (indexada
;   por 0xE060)
;   0x485e..0x4878  (26 bytes)
DATA_tabla_tiles_etapa:
	defb 00eh,007h	; 485e
	defb 001h,001h	; 4860
	defb 00eh,007h	; 4862
	defb 00eh,006h	; 4864
	defb 001h,001h	; 4866
	defb 00eh,007h	; 4868
	defb 00eh,00eh	; 486a
	defb 00eh,007h	; 486c
	defb 00eh,007h	; 486e
	defb 001h,001h	; 4870
	defb 00eh,00fh	; 4872
	defb 001h,001h	; 4874
	defb 00eh,007h	; 4876

; ======================================================================
; CODIGO 0x4878..0x488a  (18 bytes)
; ======================================================================


DIBUJA_PANEL_JUEGO:		; Vuelca el guion del salpicadero; si toca, uno extra
	ld de,0488ah		;4878
	call DESCOMPRIME_GUION		;487b
	ld a,(0e061h)		;487e
	and 009h		;4881   ; el bit 0/3 de 0xE061 pide el adorno de 0x4BA7
	ret z			;4883
	ld de,04ba7h		;4884
	jp DESCOMPRIME_GUION		;4887

; ----------------------------------------------------------------------
; DATOS guiones_panel: Guiones comprimidos del salpicadero y la pista
;   0x488a..0x4c2a  (928 bytes)
DATA_guiones_panel:
	defb 000h,018h,08ch,038h,030h,001h,003h,007h,000h,007h,00dh,00ah,00ah,00dh,007h,004h	; 488a  ...80...........
	defb 000h,08ch,07fh,0c0h,0ffh,000h,0ffh,003h,0f0h,0dfh,0afh,0afh,0dfh,0e0h,006h,000h	; 489a  ................
	defb 088h,001h,003h,006h,00dh,00ah,014h,038h,077h,006h,07fh,085h,03fh,0ffh,0ffh,07fh	; 48aa  .......8w...?...
	defb 080h,004h,000h,007h,0ffh,085h,03eh,03fh,03eh,02ah,03eh,00bh,000h,085h,01fh,0f0h	; 48ba  ......>?>*>.....
	defb 000h,000h,0ffh,00bh,000h,082h,03eh,02bh,003h,03eh,00bh,000h,085h,01fh,0f0h,000h	; 48ca  ......>+.>......
	defb 000h,0ffh,00bh,000h,08ch,0feh,003h,0ffh,000h,0ffh,0c0h,00fh,0fbh,0f5h,0f5h,0fbh	; 48da  ................
	defb 007h,004h,000h,08ch,01ch,00ch,080h,0c0h,0e0h,000h,0e0h,0b0h,050h,050h,0b0h,0e0h	; 48ea  ............PP..
	defb 004h,000h,085h,0fch,0ffh,0ffh,0feh,001h,004h,000h,007h,0ffh,08ah,000h,000h,080h	; 48fa  ................
	defb 0c0h,060h,0b0h,050h,028h,01ch,0eeh,006h,0feh,085h,0f8h,00fh,000h,000h,0ffh,00bh	; 490a  .`.P(...........
	defb 000h,085h,07ch,0fch,07ch,054h,07ch,00bh,000h,085h,0f8h,00fh,000h,000h,0ffh,00bh	; 491a  ..|.|T|.........
	defb 000h,082h,07ch,0d4h,003h,07ch,00bh,000h,00eh,000h,082h,060h,0f0h,01eh,000h,082h	; 492a  ..|..|.....`....
	defb 070h,0f8h,012h,000h,001h,084h,01dh,000h,082h,078h,0fch,021h,000h,001h,0c3h,01ch	; 493a  p........x.!....
	defb 000h,083h,03ch,0ffh,0ffh,021h,000h,001h,0c1h,00fh,000h,001h,080h,00bh,000h,084h	; 494a  ..<..!..........
	defb 03eh,063h,0ffh,0ffh,00eh,000h,002h,080h,010h,000h,082h,0c0h,0ffh,00eh,000h,082h	; 495a  >c..............
	defb 060h,0e0h,00ah,000h,084h,01fh,071h,0ffh,0ffh,00dh,000h,083h,0c0h,0e0h,0e0h,00fh	; 496a  `.....q.........
	defb 000h,084h,039h,000h,0c0h,0ffh,00ch,000h,084h,0c0h,000h,030h,0f0h,009h,000h,085h	; 497a  ..9........0....
	defb 01fh,070h,0ffh,0c6h,0ffh,00bh,000h,085h,080h,0e0h,0f0h,030h,0f0h,00fh,000h,084h	; 498a  .p.........0....
	defb 01fh,040h,0e0h,0ffh,00ch,000h,084h,0e0h,008h,01ch,0fch,008h,000h,086h,00fh,03fh	; 499a  .@.............?
	defb 070h,0ffh,0e0h,0ffh,00ah,000h,086h,0c0h,0f0h,038h,0fch,01ch,0fch,00eh,000h,085h	; 49aa  p........8......
	defb 03fh,01ch,041h,0e0h,0ffh,00bh,000h,085h,0fch,038h,082h,007h,0ffh,007h,000h,087h	; 49ba  ?.A......8......
	defb 00fh,03ch,070h,0ffh,0c0h,0e3h,0ffh,009h,000h,087h,0f0h,03ch,00eh,0ffh,003h,0c7h	; 49ca  .<p........<....
	defb 0ffh,00eh,000h,086h,01fh,018h,04fh,020h,070h,07fh,00ah,000h,086h,01fh,0e3h,01eh	; 49da  ......O p.......
	defb 000h,001h,0ffh,00ch,000h,084h,040h,080h,0c0h,0c0h,017h,000h,082h,080h,040h,005h	; 49ea  ......@.......@.
	defb 0e0h,017h,000h,089h,007h,01fh,02ch,058h,0ffh,0e0h,0e7h,0f0h,0ffh,007h,000h,089h	; 49fa  ......,X........
	defb 0fch,0ffh,006h,003h,0ffh,0e0h,01ch,0e1h,0ffh,00ch,000h,087h,01fh,018h,04fh,020h	; 4a0a  ..............O 
	defb 077h,070h,07fh,008h,000h,088h,078h,003h,0fch,003h,030h,0ffh,000h,0ffh,009h,000h	; 4a1a  wp....x...0.....
	defb 087h,0e0h,060h,0c8h,010h,0b8h,038h,0f8h,015h,000h,088h,0c0h,0a0h,0d8h,0f8h,01ch	; 4a2a  ..`...8.........
	defb 09ch,03ch,0fch,017h,000h,089h,003h,00fh,016h,06ch,07fh,0e0h,0e7h,0f0h,0ffh,007h	; 4a3a  .<.......l......
	defb 000h,089h,0ffh,0ffh,001h,000h,087h,0fch,003h,0fch,0cfh,00eh,000h,087h,01fh,058h	; 4a4a  ...............X
	defb 04fh,020h,07bh,078h,07fh,007h,000h,089h,0ffh,018h,081h,0ffh,081h,018h,0ffh,000h	; 4a5a  O {x............
	defb 0ffh,009h,000h,087h,0f8h,01ah,0f2h,004h,0deh,01eh,0feh,012h,000h,08bh,080h,0e0h	; 4a6a  ................
	defb 0d0h,06eh,03ch,0feh,0ffh,007h,0e7h,00fh,0ffh,015h,000h,08bh,001h,007h,00bh,076h	; 4a7a  .n<............v
	defb 03ch,07fh,0ffh,0e0h,0e7h,0f0h,0ffh,005h,000h,003h,0ffh,003h,000h,085h,0e7h,07eh	; 4a8a  <..............~
	defb 000h,07eh,0e7h,00ch,000h,088h,01fh,019h,059h,04fh,020h,07bh,078h,07fh,006h,000h	; 4a9a  .~......YO {x...
	defb 08ah,0ffh,00ch,0c0h,07fh,07fh,0c0h,00ch,0ffh,000h,0ffh,006h,000h,08ah,0c0h,000h	; 4aaa  ................
	defb 0feh,0a6h,0a6h,0fch,001h,0f7h,007h,0ffh,00ah,000h,093h,080h,080h,000h,080h,080h	; 4aba  ................
	defb 080h,000h,0e0h,0f8h,034h,01bh,00eh,03fh,0ffh,001h,059h,059h,003h,0ffh,007h,000h	; 4aca  ....4..?..YY....
	defb 083h,080h,000h,080h,006h,0c0h,004h,000h,08ch,001h,007h,00bh,076h,01ch,07fh,0ffh	; 4ada  ............v...
	defb 0e0h,0e6h,0e6h,0f0h,0ffh,004h,000h,002h,0ffh,004h,000h,086h,0f3h,03fh,080h,080h	; 4aea  .............?..
	defb 03fh,0f3h,007h,000h,082h,001h,002h,003h,000h,088h,01fh,019h,059h,04fh,020h,079h	; 4afa  ?...........YO y
	defb 078h,07fh,006h,000h,08ah,0ffh,00fh,0c0h,07fh,07fh,0c0h,007h,0ffh,000h,0ffh,003h	; 4b0a  x...............
	defb 000h,08dh,004h,002h,000h,0f8h,080h,01fh,0f4h,0f4h,01fh,000h,0fch,000h,0ffh,008h	; 4b1a  ................
	defb 000h,085h,0c0h,0c0h,0d0h,090h,020h,003h,0f0h,08dh,0f8h,0feh,0fdh,006h,003h,001h	; 4b2a  ...... .........
	defb 0ffh,0ffh,0e0h,00bh,00bh,0e0h,0ffh,006h,000h,085h,0e0h,0c0h,0f0h,0d8h,0f8h,003h	; 4b3a  ................
	defb 038h,082h,078h,0f8h,004h,000h,08ch,003h,005h,03bh,01eh,07ch,0dfh,0ffh,0e0h,0e6h	; 4b4a  8.x......;.|....
	defb 0e6h,0f0h,0ffh,003h,000h,003h,0ffh,003h,000h,087h,0ffh,0ffh,03fh,080h,080h,03fh	; 4b5a  ............?..?
	defb 0ffh,003h,000h,00fh,000h,001h,0ffh,00fh,000h,001h,0ffh,00eh,000h,002h,0ffh,00eh	; 4b6a  ................
	defb 000h,002h,0ffh,00fh,000h,001h,0ffh,010h,000h,084h,060h,0f0h,0f0h,060h,01ch,000h	; 4b7a  ..........`..`..
	defb 002h,000h,006h,0ffh,00ah,000h,006h,0ffh,008h,000h,001h,01ch,003h,03ch,001h,01ch	; 4b8a  .............<..
	defb 01bh,000h,010h,000h,001h,070h,003h,078h,001h,070h,00bh,000h,000h,000h,01ah,004h	; 4b9a  .....p.x.p......
	defb 000h,002h,0c0h,00eh,000h,002h,060h,00ah,000h,080h,040h,01ah,005h,000h,002h,0c0h	; 4baa  ......`...@.....
	defb 00eh,000h,002h,030h,009h,000h,080h,080h,01ah,006h,000h,002h,0e0h,00eh,000h,002h	; 4bba  ...0............
	defb 01ch,008h,000h,080h,0c0h,01ah,007h,000h,002h,0e0h,00eh,000h,002h,007h,007h,000h	; 4bca  ................
	defb 080h,000h,01bh,009h,000h,002h,070h,00eh,000h,002h,001h,005h,000h,009h,000h,002h	; 4bda  ......p.........
	defb 0c0h,015h,000h,080h,080h,01bh,009h,000h,003h,070h,014h,000h,009h,000h,003h,038h	; 4bea  .........p.....8
	defb 014h,000h,080h,000h,01ch,00bh,000h,003h,078h,012h,000h,00bh,000h,003h,01eh,012h	; 4bfa  ........x.......
	defb 000h,080h,080h,01ch,00ch,000h,003h,078h,011h,000h,00ch,000h,003h,007h,00dh,000h	; 4c0a  .......x........
	defb 003h,080h,001h,000h,080h,000h,01dh,00dh,000h,003h,078h,010h,000h,01dh,000h,003h	; 4c1a  ..........x.....

; ----------------------------------------------------------------------
; DATOS guiones_rotulos: Guiones de los rotulos de texto de las pantallas
;   0x4c2a..0x4d8e  (356 bytes)
DATA_guiones_rotulos:
	defb 0f0h,000h,04ah,039h,00ch,044h,080h,06ch,039h,088h,021h,02fh,02ah,032h,035h,024h	; 4c2a  ..J9.D.l9.!/*25$
	defb 023h,029h,000h,001h,038h,02bh,02ch,0ffh,003h,038h,021h,027h,02fh,023h,029h,001h	; 4c3a  #)..8+,..8!'/#).
	defb 021h,030h,029h,029h,028h,001h,001h,022h,029h,024h,023h,001h,0feh,01bh,038h,032h	; 4c4a  !0))(..")$#...82
	defb 02ch,02eh,029h,0feh,02ch,038h,03bh,03ch,03dh,001h,01ch,01dh,01eh,01fh,001h,0f0h	; 4c5a  ,.).,8;<=.......
	defb 0f0h,0f0h,0f0h,0feh,03ch,038h,020h,0feh,015h,038h,02ah,033h,029h,02dh,0ffh,0eeh	; 4c6a  ....<8 ..8*3)-..
	defb 038h,029h,02eh,030h,032h,034h,0ffh,0eeh,038h,022h,02fh,024h,02dh,01bh,0ffh,0e3h	; 4c7a  8).024..8"/$-...
	defb 03ah,082h,011h,017h,00ch,018h,08ch,019h,012h,001h,001h,013h,014h,015h,016h,010h	; 4c8a  :...............
	defb 01ah,01bh,01ch,000h,0a9h,038h,05fh,060h,061h,062h,063h,064h,065h,066h,067h,068h	; 4c9a  .....8_`abcdefgh
	defb 069h,06ah,06bh,06ch,06dh,0feh,0c8h,038h,080h,06eh,06fh,070h,071h,072h,073h,074h	; 4caa  ijklm..8.nopqrst
	defb 075h,076h,077h,078h,079h,07ah,07bh,07ch,0feh,0e8h,038h,081h,082h,082h,07dh,07eh	; 4cba  uvwxyz{|..8...}~
	defb 082h,082h,082h,082h,082h,082h,082h,082h,082h,07dh,07fh,0feh,0e9h,039h,030h,033h	; 4cca  .........}...903
	defb 021h,02bh,000h,021h,030h,024h,027h,029h,000h,026h,029h,034h,0feh,02ah,039h,01ah	; 4cda  !+.!0$').&)4.*9.
	defb 026h,02fh,025h,024h,02eh,02ch,000h,011h,019h,018h,015h,0ffh,00ch,039h,021h,032h	; 4cea  &/%$.,.......9!2
	defb 024h,022h,029h,0feh,086h,039h,031h,033h,024h,02dh,02ch,02ah,034h,02ch,025h,022h	; 4cfa  $")..913$-,*4,%"
	defb 001h,023h,024h,025h,026h,001h,020h,0ffh,04ah,039h,02ah,02ch,025h,024h,02dh,001h	; 4d0a  .#$%&. .J9*,%$-.
	defb 021h,032h,024h,022h,029h,01bh,0ffh,0e5h,038h,025h,02fh,035h,036h,024h,025h,02fh	; 4d1a  !2$")...8%/56$%/
	defb 032h,02bh,029h,023h,001h,027h,02bh,024h,02dh,02dh,029h,025h,022h,029h,01bh,0ffh	; 4d2a  2+)#.'+$--)%")..
	defb 0e8h,038h,027h,02fh,025h,022h,023h,024h,032h,033h,02dh,024h,032h,02ch,02fh,025h	; 4d3a  .8'/%"#$23-$2,/%
	defb 021h,01bh,0ffh,0eah,038h,023h,024h,025h,026h,02ch,025h,022h,001h,020h,0ffh,028h	; 4d4a  !...8#$%&,%". .(
	defb 02ch,021h,031h,033h,024h,02dh,02ch,02ah,02ch,029h,028h,0ffh,0eeh,038h,023h,029h	; 4d5a  ,!13$-,*,)(..8#)
	defb 024h,028h,034h,0ffh,0eeh,038h,021h,032h,024h,023h,032h,0ffh,0eeh,038h,0fch,0fch	; 4d6a  $(4..8!2$#2..8..
	defb 0fch,0fch,0fch,0ffh,0eeh,038h,085h,085h,085h,085h,085h,0ffh,0eeh,038h,0fbh,0fbh	; 4d7a  .....8.......8..
	defb 0fbh,0fbh,0fbh,0ffh	; 4d8a

; ======================================================================
; CODIGO 0x4d8e..0x4dea  (92 bytes)
; ======================================================================


DIBUJA_MARCO:		; Carga la fuente y el marco de la pantalla de carrera
	ld de,04deah		;4d8e   ; descomprime la fuente en la tabla de patrones (0x2000)
	ld hl,02000h		;4d91
	call DESC_3_TERCIOS		;4d94
	ld de,0518eh		;4d97   ; vuelca el guion comun del marco
	call DESCOMPRIME_GUION		;4d9a
	ld hl,00000h		;4d9d
	xor a			;4da0
	ld b,010h		;4da1   ; rellena 16 bloques de la tabla de color
MARCO_COLOR:
	push bc			;4da3   ; rellena 16 bloques de la tabla de color
	push hl			;4da4
	ld bc,00008h		;4da5   ; rellena de ocho en ocho bytes
	call RELLENA_3_TERCIOS		;4da8
	pop hl			;4dab
	pop bc			;4dac
	ld de,00008h		;4dad
	add hl,de			;4db0
	inc a			;4db1
	djnz MARCO_COLOR		;4db2
	ld a,0f0h		;4db4
TINTA_FRANJA:		; Rellena una franja de color y baja un tono
	push af			;4db6
	ld hl,00080h		;4db7
	ld bc,00278h		;4dba
	call RELLENA_3_TERCIOS		;4dbd
	pop af			;4dc0
	sub 010h		;4dc1
	ld hl,000e0h		;4dc3
	ld bc,00020h		;4dc6
	jp 00056h		;4dc9   ; BIOS FILVRM - Fills VRAM with value
DIBUJA_PODIO:		; Rutina de dibujo sin referencia estatica (posible resto)
	ld de,04fd7h		;4dcc   ; dibuja 19 filas de 16 bytes desde 0x518E
	call DESCOMPRIME_GUION		;4dcf
	ld hl,006d0h		;4dd2
	ld b,013h		;4dd5
PODIO_FILA:
	push bc			;4dd7   ; dibuja 19 filas de 16 bytes desde 0x518E
	ld de,0518eh		;4dd8
	ld bc,00010h		;4ddb
	call VUELCA_A_VRAM		;4dde
	ld a,010h		;4de1
	call HL_MAS_A		;4de3
	pop bc			;4de6
	djnz PODIO_FILA		;4de7
	ret			;4de9

; ----------------------------------------------------------------------
; DATOS fuente_y_graficos: Fuente de 8x8 y graficos comunes de la carrera
;   0x4dea..0x518e  (932 bytes)
DATA_fuente_y_graficos:
	defb 040h,000h,040h,000h,0e0h,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h	; 4dea  @.@...."ccc"...8
	defb 018h,018h,018h,018h,07eh,000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h	; 4dfa  ....~.>c..<p..>c
	defb 003h,00eh,003h,063h,03eh,000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h	; 4e0a  ...c>...6ff....`
	defb 07eh,063h,003h,063h,03eh,000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h	; 4e1a  ~c.c>.>c`~cc>..c
	defb 006h,00ch,018h,018h,018h,000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h	; 4e2a  ......>cc>cc>.>c
	defb 063h,03fh,003h,063h,03eh,03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,004h,00eh,00eh	; 4e3a  c?.c><B....B<...
	defb 00ch,008h,000h,000h,018h,0a0h,000h,030h,030h,030h,030h,030h,03fh,03fh,000h,01eh	; 4e4a  .......00000??..
	defb 022h,042h,042h,042h,022h,01eh,000h,0f1h,089h,085h,085h,085h,089h,0f1h,000h,08ch	; 4e5a  "BBB"...........
	defb 08ch,08ch,0fch,08ch,08ch,08ch,0e8h,000h,000h,000h,018h,000h,000h,018h,000h,000h	; 4e6a  ................
	defb 03eh,063h,060h,03eh,003h,063h,03eh,000h,03eh,063h,060h,067h,063h,063h,03fh,000h	; 4e7a  >c`>.c>.>c`gcc?.
	defb 07eh,063h,063h,062h,07ch,066h,063h,000h,01ch,036h,063h,063h,07fh,063h,063h,000h	; 4e8a  ~ccb|fc..6cc.cc.
	defb 063h,073h,07bh,07fh,06fh,067h,063h,000h,063h,066h,06ch,078h,07ch,06eh,067h,000h	; 4e9a  cs{.ogc.cflx|ng.
	defb 03eh,063h,060h,060h,060h,063h,03eh,000h,07ch,066h,063h,063h,063h,066h,07ch,000h	; 4eaa  >c```c>.|fcccf|.
	defb 07fh,060h,060h,07eh,060h,060h,07fh,000h,07fh,060h,060h,07eh,060h,060h,060h,000h	; 4eba  .``~``...``~```.
	defb 063h,063h,063h,07fh,063h,063h,063h,000h,03ch,018h,018h,018h,018h,018h,03ch,0c8h	; 4eca  ccc.ccc.<.....<.
	defb 000h,060h,060h,060h,060h,060h,060h,07fh,000h,063h,077h,07fh,07fh,06bh,063h,063h	; 4eda  .``````..cw..kcc
	defb 000h,03eh,063h,063h,063h,063h,063h,03eh,000h,07eh,063h,063h,063h,07eh,060h,060h	; 4eea  .>ccccc>.~ccc~``
	defb 000h,03eh,063h,063h,063h,06fh,066h,03dh,000h,07eh,018h,018h,018h,018h,018h,018h	; 4efa  .>cccof=.~......
	defb 000h,063h,063h,063h,063h,063h,063h,03eh,000h,066h,066h,07eh,03ch,018h,018h,018h	; 4f0a  .cccccc>.ff~<...
	defb 000h,063h,063h,06bh,06bh,07fh,077h,022h,004h,000h,084h,030h,030h,010h,020h,022h	; 4f1a  .cckk.w"...00. "
	defb 000h,093h,020h,020h,02bh,032h,02ah,02ah,000h,000h,002h,002h,0c4h,0a4h,0a8h,0a8h	; 4f2a  ..  +2**........
	defb 000h,000h,080h,080h,0c0h,003h,0a0h,033h,000h,001h,0ffh,012h,000h,082h,007h,00fh	; 4f3a  .......3........
	defb 006h,000h,082h,0f8h,0f0h,004h,03eh,004h,03fh,08bh,01fh,03fh,07fh,0ffh,0feh,0fch	; 4f4a  ......>.?..?....
	defb 0f8h,0f0h,0e0h,0c0h,080h,003h,000h,002h,03eh,005h,000h,083h,01fh,07fh,0fbh,005h	; 4f5a  ........>.......
	defb 000h,083h,00fh,0cfh,0efh,005h,000h,083h,078h,0fch,0bch,005h,000h,083h,03fh,07fh	; 4f6a  ........x.....?.
	defb 0f3h,005h,000h,083h,087h,0c7h,0c7h,005h,000h,083h,0bch,0feh,0dfh,005h,000h,088h	; 4f7a  ................
	defb 078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,003h,0f0h,002h,03fh,006h,03eh,088h,0f8h	; 4f8a  x..`..`....?.>..
	defb 0fch,0feh,07fh,03fh,01fh,00fh,007h,003h,03eh,085h,07eh,0fch,0fch,0f8h,0e0h,005h	; 4f9a  ...?....>.~.....
	defb 0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h,0cfh,00fh,008h,01eh,088h,0e1h,003h,03fh	; 4faa  ...............?
	defb 0f1h,0e1h,0f3h,07fh,01eh,007h,0e7h,081h,0f7h,008h,08fh,008h,01eh,082h,0f1h,0f2h	; 4fba  ................
	defb 004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h,010h,0e0h,0f0h,001h,001h	; 4fca  ........h.(.....
	defb 003h,003h,003h,007h,007h,00fh,0f0h,0f0h,0e0h,0e0h,0e0h,0c1h,0c1h,083h,07ch,07ch	; 4fda  ..............||
	defb 0f8h,0fbh,0fbh,0f3h,0f3h,0e3h,000h,000h,000h,081h,082h,082h,084h,085h,000h,000h	; 4fea  ................
	defb 000h,07fh,040h,0f0h,0f0h,0e0h,000h,000h,000h,0e1h,0f3h,0f7h,0f7h,0efh,000h,000h	; 4ffa  ..@.............
	defb 000h,0ffh,0c3h,083h,083h,007h,000h,000h,000h,01fh,090h,0bch,0bch,078h,000h,000h	; 500a  .............x..
	defb 001h,0e1h,0f1h,073h,073h,0e3h,0ffh,0c0h,0f0h,0f0h,0f0h,0e1h,0e1h,0c3h,0e0h,0f0h	; 501a  ...ss...........
	defb 0f0h,0f3h,0f3h,0e7h,0e0h,0c0h,000h,000h,000h,0feh,087h,007h,00fh,00eh,00fh,00fh	; 502a  ................
	defb 01eh,01eh,01eh,03ch,03ch,079h,03ch,03ch,078h,07bh,07bh,0f3h,0f3h,0e3h,0f0h,000h	; 503a  ...<<y<<x{{.....
	defb 000h,000h,081h,082h,082h,084h,084h,00fh,00fh,01fh,01fh,03eh,03eh,03eh,07ch,0ffh	; 504a  ...........>>>|.
	defb 083h,007h,007h,00fh,00fh,00fh,01fh,0e3h,0e3h,0c3h,0c3h,083h,083h,083h,003h,089h	; 505a  ................
	defb 089h,093h,093h,0a7h,0a7h,0c7h,0c7h,0e1h,0e1h,0c1h,0c3h,083h,083h,007h,07fh,0efh	; 506a  ................
	defb 0eeh,0dfh,0deh,0bch,0bch,0bch,01fh,007h,00fh,0feh,000h,001h,001h,001h,0f3h,078h	; 507a  ...............x
	defb 078h,0f0h,0f0h,0e0h,0e0h,0e0h,0c0h,0e7h,007h,00fh,00fh,01fh,01fh,01fh,03eh,0feh	; 508a  x.............>.
	defb 0cfh,08fh,08fh,00fh,00fh,00fh,00fh,00fh,01eh,01ch,03ch,038h,078h,078h,03fh,0feh	; 509a  ..........<8xx?.
	defb 01eh,01ch,03ch,039h,039h,019h,0fbh,0f9h,0f9h,0f3h,0f3h,0e7h,0e7h,0e7h,0cfh,0c0h	; 50aa  ..<99...........
	defb 0e3h,0e3h,0c3h,0c3h,083h,083h,083h,003h,088h,088h,090h,090h,0a0h,0a0h,0c0h,0c0h	; 50ba  ................
	defb 003h,007h,03fh,000h,0ffh,000h,000h,000h,08fh,08eh,01eh,000h,0ffh,000h,000h,000h	; 50ca  ..?.............
	defb 080h,080h,0feh,000h,0fch,000h,000h,000h,003h,000h,007h,000h,00fh,000h,01fh,000h	; 50da  ................
	defb 03fh,000h,07fh,000h,0ffh,000h,000h,000h,0ffh,000h,0ffh,000h,0ffh,000h,000h,000h	; 50ea  ?...............
	defb 007h,0ffh,081h,000h,003h,0ffh,081h,000h,004h,0ffh,088h,000h,0ffh,0ffh,0ffh,000h	; 50fa  ................
	defb 0ffh,0ffh,000h,098h,010h,020h,020h,020h,050h,090h,090h,090h,00ch,00ah,009h,004h	; 510a  .....   P.......
	defb 004h,004h,00ah,032h,008h,008h,010h,020h,040h,040h,040h,080h,005h,000h,083h,003h	; 511a  ...2... @@@.....
	defb 00ch,010h,0e0h,008h,008h,004h,002h,002h,002h,001h,001h,020h,020h,040h,040h,0a0h	; 512a  ...........  @@.
	defb 010h,010h,010h,001h,001h,002h,002h,002h,004h,008h,010h,080h,080h,060h,010h,010h	; 513a  .............`..
	defb 008h,008h,008h,000h,000h,080h,040h,040h,020h,010h,010h,008h,006h,001h,001h,002h	; 514a  ......@@ .......
	defb 002h,004h,008h,0c0h,020h,050h,050h,08ch,082h,081h,001h,002h,002h,004h,018h,020h	; 515a  .... PP........ 
	defb 020h,041h,041h,000h,000h,000h,000h,001h,001h,032h,0ceh,007h,080h,010h,060h,001h	; 516a   AA......2....`.
	defb 001h,002h,002h,010h,010h,010h,020h,020h,0c0h,000h,000h,012h,022h,022h,0c4h,004h	; 517a  ......  ....""..
	defb 008h,008h,008h,000h	; 518a

; ----------------------------------------------------------------------
; DATOS guion_marco: Guion comun del marco de la pantalla de carrera
;   0x518e..0x51b8  (42 bytes)
DATA_guion_marco:
	defb 0f8h,002h,078h,0f0h,078h,0f0h,083h,0f4h,0f0h,0f4h,005h,040h,083h,0f4h,0f0h,0f4h	; 518e  ..x.x......@....
	defb 005h,040h,082h,0f4h,0f0h,01eh,040h,018h,0d6h,020h,00eh,060h,00eh,080h,080h,027h	; 519e  .@....@.. .`...'
	defb 002h,0ffh,006h,000h,080h,080h,007h,008h,017h,000h	; 51ae  ..........

; ======================================================================
; CODIGO 0x51b8..0x51f8  (64 bytes)
; ======================================================================


FONDO_ETAPA_1:		; Dibuja el fondo de la primera familia de etapas
	ld de,051f8h		;51b8
	call DESC_DOBLE		;51bb   ; dibuja las dos capas (patron y color)
	ld hl,00920h		;51be
	call FIJA_ESCRITURA		;51c1
	ld de,05406h		;51c4
	call DESC_DOBLE		;51c7
	ld de,05406h		;51ca
	call DESC_DOBLE		;51cd
	inc de			;51d0
	call DESC_DOBLE		;51d1
	ld de,054b0h		;51d4   ; anade el guion del suelo
	call DESCOMPRIME_GUION		;51d7
	ld a,(0e061h)		;51da
	cp 040h		;51dd
	call z,FONDO_ETAPA_3_5A58		;51df   ; en un tipo de etapa suma un adorno
	ld de,054f3h		;51e2
	call DESC_DOBLE		;51e5
	inc de			;51e8
FONDO_ETAPA_1_51E9:
	call DESC_DOBLE		;51e9
	ld hl,03080h		;51ec
	ld de,04e71h		;51ef   ; vuelca los patrones de la pista
	ld bc,00038h		;51f2
	jp VUELCA_A_VRAM		;51f5

; ----------------------------------------------------------------------
; DATOS graficos_fondo_1: Graficos comprimidos del fondo (patron, color, mapa)
;   0x51f8..0x586c  (1652 bytes)
DATA_graficos_fondo_1:
	defb 081h,020h,029h,001h,005h,0ffh,087h,0feh,0fch,0f8h,0fch,0f0h,0e0h,0c0h,004h,000h	; 51f8  . ).............
	defb 004h,0ffh,087h,0fch,0f8h,0f0h,0e0h,0e0h,0c0h,080h,005h,000h,088h,0ffh,0ffh,0feh	; 5208  ................
	defb 0fch,0f0h,0e0h,0c0h,080h,007h,0ffh,001h,0fch,005h,0ffh,001h,0e0h,002h,000h,003h	; 5218  ................
	defb 0ffh,001h,0fch,004h,000h,003h,0ffh,002h,000h,086h,00fh,01fh,01fh,0f0h,0e0h,080h	; 5228  ................
	defb 005h,000h,003h,0ffh,085h,0feh,0f8h,0e0h,0c0h,080h,006h,0ffh,082h,0feh,0e0h,004h	; 5238  ................
	defb 0ffh,088h,0fch,0e0h,000h,000h,0ffh,0feh,0f8h,0c0h,004h,000h,0c8h,0f8h,007h,0ffh	; 5248  ................
	defb 0e0h,00fh,03fh,07fh,07fh,0ffh,000h,0ffh,018h,0e3h,03ch,0c0h,000h,000h,0ffh,000h	; 5258  ..?.......<.....
	defb 00fh,0f0h,007h,0ffh,0ffh,000h,0ffh,03fh,0c0h,01fh,0ffh,0ffh,0ffh,0ffh,0fch,0e0h	; 5268  .......?........
	defb 000h,001h,002h,030h,000h,0ffh,0fch,0e0h,000h,000h,004h,008h,0c0h,0ffh,0f8h,003h	; 5278  ...0............
	defb 0fch,000h,000h,00ah,0a0h,0ffh,0ffh,0feh,000h,03fh,0c0h,000h,000h,0ffh,0f8h,003h	; 5288  .........?......
	defb 0fch,000h,000h,005h,050h,005h,0ffh,083h,0fch,0e0h,003h,003h,0ffh,0b5h,0feh,080h	; 5298  ....P...........
	defb 002h,098h,000h,0ffh,0ffh,000h,0ffh,000h,001h,01eh,0e0h,0ffh,000h,0ffh,000h,003h	; 52a8  ................
	defb 07ch,080h,001h,0ffh,0ffh,0ffh,0ffh,0ffh,0f8h,0e0h,008h,0ffh,0ffh,0ffh,0feh,080h	; 52b8  |...............
	defb 005h,060h,000h,0ffh,0ffh,0ffh,000h,01fh,0e0h,000h,000h,0ffh,000h,0ffh,003h,03ch	; 52c8  .`.............<
	defb 0c1h,002h,004h,005h,0ffh,083h,0f0h,000h,019h,004h,0ffh,094h,0c0h,00fh,070h,080h	; 52d8  ..............p.
	defb 0ffh,0ffh,000h,01fh,0e0h,000h,000h,000h,0fch,0e0h,003h,00ch,030h,0c0h,000h,000h	; 52e8  ............0...
	defb 005h,0ffh,08bh,0f0h,000h,006h,0ffh,0ffh,0ffh,0fch,0e0h,000h,007h,018h,000h,002h	; 52f8  ................
	defb 002h,098h,080h,002h,004h,008h,010h,020h,040h,080h,0f8h,0e0h,080h,006h,018h,030h	; 5308  ....... @......0
	defb 0c0h,080h,07fh,03fh,03fh,01fh,00fh,007h,003h,080h,000h,001h,001h,08ah,030h,0c0h	; 5318  ...??.........0.
	defb 003h,004h,008h,010h,020h,0c0h,002h,082h,006h,002h,082h,008h,060h,006h,000h,083h	; 5328  .... .......`...
	defb 014h,000h,080h,005h,000h,0c0h,002h,008h,000h,020h,000h,0c0h,080h,000h,001h,004h	; 5338  ......... ......
	defb 010h,000h,040h,000h,080h,080h,002h,008h,000h,020h,000h,040h,000h,080h,001h,004h	; 5348  ..@...... .@....
	defb 010h,000h,040h,000h,080h,000h,000h,002h,000h,008h,000h,020h,000h,080h,001h,000h	; 5358  ..@........ ....
	defb 004h,000h,010h,040h,000h,000h,000h,002h,000h,008h,000h,020h,080h,000h,001h,000h	; 5368  ...@....... ....
	defb 004h,000h,010h,040h,000h,000h,000h,002h,002h,003h,004h,08ah,006h,002h,003h,001h	; 5378  ...@............
	defb 000h,000h,003h,00ch,030h,0c0h,003h,000h,008h,002h,082h,060h,080h,005h,000h,081h	; 5388  ....0......`....
	defb 001h,000h,001h,000h,094h,000h,001h,000h,001h,000h,001h,000h,001h,001h,000h,000h	; 5398  ................
	defb 001h,001h,001h,000h,000h,001h,001h,000h,000h,005h,001h,08ah,000h,001h,000h,001h	; 53a8  ................
	defb 000h,001h,000h,000h,001h,001h,003h,000h,004h,001h,002h,000h,002h,001h,005h,000h	; 53b8  ................
	defb 082h,001h,000h,002h,001h,004h,000h,095h,001h,000h,000h,001h,001h,000h,000h,001h	; 53c8  ................
	defb 000h,001h,000h,000h,001h,000h,000h,000h,001h,000h,001h,000h,000h,008h,0ffh,008h	; 53d8  ................
	defb 000h,003h,0ffh,001h,000h,004h,0ffh,083h,000h,0ffh,000h,005h,0ffh,002h,000h,006h	; 53e8  ................
	defb 0ffh,001h,000h,007h,0ffh,084h,000h,0ffh,0ffh,000h,004h,0ffh,000h,0ffh,001h,000h	; 53f8  ................
	defb 070h,03eh,001h,03eh,003h,0feh,005h,03eh,00ch,0feh,003h,03eh,004h,0feh,007h,03eh	; 5408  p>.>...>...>...>
	defb 005h,0feh,003h,03eh,005h,0feh,002h,03eh,006h,0feh,000h,004h,000h,003h,03eh,005h	; 5418  ...>...>......>.
	defb 0feh,002h,03eh,006h,0feh,007h,03eh,001h,0feh,005h,03eh,003h,0feh,000h,0ffh,002h	; 5428  ..>...>...>.....
	defb 000h,090h,03eh,0eeh,0feh,0eeh,0feh,0feh,0eeh,0eeh,03eh,03eh,03eh,0feh,0eeh,0feh	; 5438  ..>.......>>>...
	defb 0eeh,0eeh,007h,03eh,001h,0eeh,090h,03eh,0feh,0eeh,0feh,0eeh,0eeh,0feh,0feh,03eh	; 5448  ...>...>.......>
	defb 03eh,03eh,0eeh,0feh,0eeh,0feh,0feh,007h,03eh,001h,0feh,000h,002h,000h,060h,0feh	; 5458  >>......>.....`.
	defb 000h,002h,000h,08ch,0feh,0eeh,0feh,0eeh,0feh,0feh,0eeh,0eeh,0feh,0feh,0eeh,0feh	; 5468  ................
	defb 004h,0eeh,003h,0feh,085h,0eeh,0feh,0eeh,0feh,0eeh,008h,0feh,08ch,0eeh,0feh,0eeh	; 5478  ................
	defb 0feh,0eeh,0eeh,0feh,0feh,0eeh,0eeh,0feh,0eeh,004h,0feh,087h,0eeh,0feh,0eeh,0feh	; 5488  ................
	defb 0eeh,0feh,0eeh,008h,0feh,001h,0eeh,000h,001h,000h,050h,0feh,019h,03eh,001h,0feh	; 5498  ..........P..>..
	defb 016h,03eh,004h,0feh,004h,03eh,000h,0ffh,098h,02dh,005h,000h,09bh,001h,00fh,07fh	; 54a8  .>...>...-......
	defb 003h,007h,00fh,03fh,0fbh,0f7h,0e7h,0abh,000h,001h,003h,007h,04fh,0fdh,0f6h,0ddh	; 54b8  ...?........O...
	defb 080h,0c0h,0f0h,0f8h,082h,0d1h,00ch,0c7h,005h,000h,083h,0b3h,0cfh,0ffh,006h,000h	; 54c8  ................
	defb 082h,0f0h,0ffh,080h,098h,00dh,00ch,0c7h,004h,0c2h,005h,0c7h,003h,0c2h,002h,0c7h	; 54d8  ................
	defb 002h,027h,004h,0c2h,005h,0c7h,003h,0c2h,008h,0c7h,000h,081h,080h,031h,001h,007h	; 54e8  .'...........1..
	defb 0ffh,081h,0feh,005h,0ffh,083h,0feh,0fch,0f8h,004h,0ffh,08ch,0fch,0f8h,0f0h,0e0h	; 54f8  ................
	defb 0ffh,0ffh,0feh,0fch,0f0h,0e0h,0c0h,080h,005h,0ffh,083h,0fch,0e0h,000h,004h,0ffh	; 5508  ................
	defb 084h,0fch,0f0h,0c0h,000h,004h,0ffh,088h,0feh,0fch,0f0h,0e0h,01fh,03fh,07fh,07fh	; 5518  .............?..
	defb 006h,0ffh,0c6h,07fh,07fh,03fh,03fh,01fh,00fh,0ffh,0ffh,0fch,0e0h,000h,000h,001h	; 5528  .....??.........
	defb 000h,0ffh,0ffh,0feh,0f0h,080h,000h,006h,03ch,0ffh,0ffh,0feh,0f0h,080h,000h,001h	; 5538  ........<.......
	defb 000h,0feh,0e0h,000h,000h,01eh,010h,000h,000h,0feh,0e0h,000h,003h,000h,0e0h,080h	; 5548  ................
	defb 000h,0fch,0f0h,0c0h,000h,000h,000h,018h,070h,0fch,0f0h,0c0h,000h,001h,007h,004h	; 5558  ........p.......
	defb 000h,0ffh,0ffh,0fch,0e0h,000h,000h,006h,03ch,000h,002h,002h,0b8h,0feh,0fch,0f8h	; 5568  ........<.......
	defb 0f0h,0c0h,080h,000h,001h,0f8h,0f0h,0e0h,0c0h,000h,000h,001h,003h,0e0h,0c0h,080h	; 5578  ................
	defb 000h,000h,001h,003h,007h,080h,000h,000h,000h,001h,003h,007h,00fh,0fch,0f0h,0e0h	; 5588  ................
	defb 080h,000h,000h,003h,007h,0e0h,000h,000h,007h,03ch,0e0h,080h,000h,007h,003h,001h	; 5598  .........<......
	defb 080h,080h,0c0h,0e0h,0f0h,000h,001h,001h,0b2h,000h,000h,000h,001h,003h,007h,00fh	; 55a8  ................
	defb 01fh,03fh,07eh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,001h,003h,007h,00fh,01fh	; 55b8  .?~.............
	defb 03fh,07fh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,001h,003h,007h,00fh,01fh,03fh	; 55c8  ?..............?
	defb 07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,0e0h,080h,007h,000h,082h,001h,078h	; 55d8  ...............x
	defb 006h,000h,083h,00eh,000h,0c0h,004h,000h,081h,0c0h,008h,000h,083h,004h,01ch,070h	; 55e8  ...............p
	defb 005h,000h,084h,003h,000h,000h,0c0h,009h,000h,086h,001h,006h,000h,004h,008h,010h	; 55f8  ................
	defb 006h,000h,082h,008h,030h,004h,000h,082h,003h,030h,006h,000h,083h,006h,020h,040h	; 5608  ....0....0.... @
	defb 005h,000h,083h,005h,008h,0c0h,005h,000h,083h,001h,018h,080h,005h,000h,081h,030h	; 5618  ...............0
	defb 007h,000h,000h,002h,002h,0adh,003h,006h,00ch,018h,030h,060h,0c0h,080h,007h,00eh	; 5628  ..........0`....
	defb 01ch,038h,070h,0e0h,0c0h,080h,00fh,01eh,03ch,078h,0f0h,0e0h,0c0h,080h,01fh,03eh	; 5638  .8p.....<x.....>
	defb 07ch,0f8h,0f0h,0e0h,0c0h,080h,000h,003h,00fh,01eh,078h,0f0h,0e0h,0c0h,003h,006h	; 5648  |.........x.....
	defb 004h,00ch,008h,008h,018h,003h,00ch,08bh,00eh,006h,007h,007h,003h,003h,001h,000h	; 5658  ................
	defb 007h,038h,0e0h,005h,000h,008h,004h,008h,00ch,003h,001h,005h,003h,088h,002h,004h	; 5668  .8..............
	defb 008h,020h,040h,080h,000h,000h,000h,003h,003h,085h,00ch,030h,060h,0c0h,080h,007h	; 5678  . @........0`...
	defb 000h,089h,001h,003h,006h,00ch,018h,030h,030h,060h,060h,003h,0c0h,004h,080h,004h	; 5688  .......00``.....
	defb 000h,000h,004h,004h,088h,000h,000h,001h,006h,018h,060h,080h,000h,000h,001h,000h	; 5698  ..........`.....
	defb 005h,000h,008h,001h,005h,000h,00ah,001h,008h,000h,011h,003h,008h,000h,005h,003h	; 56a8  ................
	defb 008h,000h,00eh,007h,008h,000h,008h,0ffh,000h,081h,0b8h,030h,000h,005h,000h,082h	; 56b8  ...........0....
	defb 030h,03fh,006h,000h,082h,010h,0ffh,006h,000h,083h,018h,0f8h,000h,000h,081h,0f0h	; 56c8  0?..............
	defb 030h,000h,007h,000h,001h,0ffh,004h,000h,001h,0ffh,004h,000h,001h,0ffh,00ch,000h	; 56d8  0...............
	defb 002h,0ffh,005h,000h,008h,0ffh,003h,000h,000h,081h,020h,031h,001h,094h,000h,001h	; 56e8  .......... 1....
	defb 002h,005h,07bh,07fh,01eh,07fh,0dfh,0ffh,00fh,00ch,00ch,047h,043h,020h,07dh,07ch	; 56f8  ..{........GC }|
	defb 07ch,07fh,004h,000h,094h,07fh,0ffh,0ffh,07fh,080h,000h,000h,0ffh,007h,000h,0f8h	; 5708  |...............
	defb 04fh,04fh,0ffh,0f0h,007h,0ffh,000h,000h,0ffh,004h,000h,000h,0ffh,082h,080h,011h	; 5718  OO..............
	defb 000h,048h,03eh,004h,03eh,004h,0feh,005h,03eh,003h,0feh,005h,03eh,003h,0feh,003h	; 5728  .H>.>...>...>...
	defb 03eh,005h,0feh,003h,03eh,005h,0feh,004h,03eh,004h,0feh,004h,03eh,004h,0feh,004h	; 5738  >...>...>...>...
	defb 03eh,004h,0feh,000h,002h,000h,006h,03eh,002h,0feh,006h,03eh,002h,0feh,003h,03eh	; 5748  >......>...>...>
	defb 005h,0feh,001h,03eh,007h,0feh,004h,03eh,004h,0feh,001h,03eh,003h,0eeh,001h,0feh	; 5758  ...>...>...>....
	defb 003h,0eeh,003h,03eh,002h,0feh,003h,0eeh,006h,03eh,002h,0eeh,006h,03eh,002h,0eeh	; 5768  ...>.....>...>..
	defb 003h,03eh,005h,0eeh,001h,03eh,007h,0eeh,004h,03eh,004h,0eeh,001h,03eh,003h,0feh	; 5778  .>...>...>...>..
	defb 001h,0eeh,003h,0feh,003h,03eh,002h,0eeh,003h,0feh,000h,002h,000h,070h,0feh,030h	; 5788  .....>.......p.0
	defb 0feh,000h,002h,000h,002h,0feh,003h,0eeh,007h,0feh,009h,0eeh,005h,0feh,00bh,0eeh	; 5798  ................
	defb 004h,0feh,08ch,0eeh,0feh,0eeh,0feh,0eeh,0feh,0eeh,0eeh,0feh,0feh,0eeh,0eeh,008h	; 57a8  ................
	defb 0feh,004h,0eeh,001h,0feh,007h,0eeh,08ch,0feh,0eeh,0feh,0eeh,0feh,0eeh,0feh,0feh	; 57b8  ................
	defb 0eeh,0eeh,0feh,0feh,005h,0eeh,008h,0feh,001h,0eeh,005h,0feh,002h,0eeh,003h,0feh	; 57c8  ................
	defb 007h,0eeh,009h,0feh,005h,0eeh,00bh,0feh,004h,0eeh,08ch,0feh,0eeh,0feh,0eeh,0feh	; 57d8  ................
	defb 0eeh,0feh,0feh,0eeh,0eeh,0feh,0feh,008h,0eeh,004h,0feh,001h,0eeh,007h,0feh,08ch	; 57e8  ................
	defb 0eeh,0feh,0eeh,0feh,0eeh,0feh,0eeh,0eeh,0feh,0feh,0eeh,0eeh,00bh,0feh,084h,0eeh	; 57f8  ................
	defb 0feh,0feh,0eeh,004h,0feh,000h,002h,000h,003h,0eeh,00ah,0feh,007h,0eeh,006h,0feh	; 5808  ................
	defb 006h,0eeh,003h,0feh,00ah,0eeh,007h,0feh,006h,0eeh,026h,0feh,000h,002h,000h,087h	; 5818  ..........&.....
	defb 0eeh,0eeh,0feh,0feh,0eeh,0eeh,0feh,004h,0eeh,002h,0feh,007h,0eeh,002h,0feh,004h	; 5828  ................
	defb 0eeh,086h,0feh,0eeh,0eeh,0feh,0feh,0eeh,000h,001h,000h,060h,0feh,008h,030h,000h	; 5838  ...........`..0.
	defb 081h,080h,010h,000h,050h,0f1h,000h,081h,0f0h,010h,000h,030h,0feh,000h,082h,020h	; 5848  ....P......0... 
	defb 011h,000h,00ah,04eh,006h,014h,008h,01eh,003h,04eh,001h,014h,004h,01eh,008h,014h	; 5858  ...N.....N......
	defb 008h,01eh,000h,0ffh	; 5868

; ======================================================================
; CODIGO 0x586c..0x58a5  (57 bytes)
; ======================================================================


FONDO_ETAPA_2:		; Fondo base mas capas de decorado (arboles, vallas)
	call FONDO_ETAPA_1		;586c   ; reusa el fondo base y le suma capas de decorado
	call CERO_ORIGEN_DESC		;586f   ; fija el origen comun de las dos capas
	ld de,05725h		;5872
	call DESC_DOBLE		;5875   ; dibuja la capa de decorado
	call FIJA_ORIGEN_DESC		;5878
	ld de,05a29h		;587b   ; y la de arboles/vallas
	call DESC_DOBLE		;587e
	ld de,0592ch		;5881
	call DESC_DOBLE		;5884
	ld hl,00920h		;5887   ; abre la VRAM en otra fila
	call FIJA_ESCRITURA		;588a
	inc de			;588d
	call DESC_DOBLE		;588e
	ld de,0598fh		;5891
	call DESC_DOBLE		;5894
	inc de			;5897
	call DESC_DOBLE		;5898
	or a			;589b
FONDO_ETAPA_2_589C:
	ld de,058a5h		;589c
	jp nc,DESCOMPRIME_GUION		;589f
	jp DESC_PATRONES_ABRE		;58a2

; ----------------------------------------------------------------------
; DATOS graficos_fondo_2: Graficos comprimidos del fondo de tipo 2
;   0x58a5..0x5a44  (415 bytes)
DATA_graficos_fondo_2:
	defb 020h,02eh,007h,000h,083h,0e0h,015h,001h,007h,000h,083h,040h,055h,005h,007h,000h	; 58a5   ..........@U...
	defb 081h,055h,008h,000h,083h,080h,088h,008h,007h,000h,082h,080h,088h,004h,000h,083h	; 58b5  .U..............
	defb 020h,022h,002h,007h,000h,084h,020h,022h,0a0h,00bh,008h,000h,082h,0e0h,01fh,007h	; 58c5   ".... "........
	defb 000h,082h,080h,02ah,006h,000h,005h,060h,005h,000h,005h,018h,00dh,000h,004h,008h	; 58d5  ...*...`........
	defb 006h,000h,004h,004h,006h,000h,003h,004h,006h,000h,003h,004h,007h,000h,003h,004h	; 58e5  ................
	defb 008h,000h,002h,004h,007h,000h,001h,004h,008h,000h,001h,004h,008h,000h,005h,003h	; 58f5  ................
	defb 00dh,000h,005h,080h,005h,000h,004h,040h,006h,000h,003h,040h,007h,000h,003h,040h	; 5905  .......@...@...@
	defb 006h,000h,003h,040h,006h,000h,003h,040h,008h,000h,001h,040h,007h,000h,002h,040h	; 5915  ...@...@...@...@
	defb 008h,000h,001h,040h,004h,000h,000h,081h,020h,029h,081h,048h,02ah,005h,000h,00eh	; 5925  ...@.... ).H*...
	defb 0f0h,00ah,000h,00eh,007h,008h,000h,00ah,01fh,00ah,000h,008h,078h,004h,000h,006h	; 5935  ............x...
	defb 007h,00ch,000h,005h,006h,00dh,000h,081h,001h,003h,011h,081h,010h,005h,000h,083h	; 5945  ................
	defb 001h,011h,010h,008h,000h,084h,003h,01eh,0e0h,000h,000h,081h,070h,02dh,081h,0c0h	; 5955  ............p-..
	defb 02dh,005h,000h,009h,078h,003h,000h,007h,01ch,004h,000h,005h,060h,00dh,000h,005h	; 5965  -...x.......`...
	defb 060h,00ch,000h,002h,004h,003h,044h,006h,000h,083h,004h,044h,044h,003h,000h,000h	; 5975  `.....D....DD...
	defb 081h,010h,02eh,000h,00ch,07eh,004h,000h,000h,0ffh,001h,000h,060h,081h,030h,081h	; 5985  .....~......`.0.
	defb 003h,011h,005h,0f1h,003h,011h,005h,0f1h,002h,011h,006h,0f1h,000h,004h,000h,003h	; 5995  ................
	defb 011h,005h,0f1h,002h,011h,006h,0f1h,007h,011h,001h,0f1h,005h,011h,003h,0f1h,000h	; 59a5  ................
	defb 0ffh,002h,000h,086h,011h,011h,0f1h,011h,0f1h,0f1h,005h,011h,083h,0f1h,011h,0f1h	; 59b5  ................
	defb 00bh,011h,087h,0f1h,011h,0f1h,011h,011h,0f1h,0f1h,004h,011h,084h,0f1h,011h,0f1h	; 59c5  ................
	defb 0f1h,007h,011h,001h,0f1h,000h,002h,000h,060h,0f1h,000h,002h,000h,08ch,0f1h,011h	; 59d5  ........`.......
	defb 0f1h,011h,0f1h,0f1h,011h,011h,0f1h,0f1h,011h,0f1h,004h,011h,003h,0f1h,085h,011h	; 59e5  ................
	defb 0f1h,011h,0f1h,011h,008h,0f1h,08ch,011h,0f1h,011h,0f1h,011h,011h,0f1h,0f1h,011h	; 59f5  ................
	defb 011h,0f1h,011h,004h,0f1h,087h,011h,0f1h,011h,0f1h,011h,0f1h,011h,008h,0f1h,001h	; 5a05  ................
	defb 011h,000h,001h,000h,050h,0f1h,010h,011h,050h,081h,060h,081h,060h,081h,070h,081h	; 5a15  ....P...P.`.`.p.
	defb 058h,081h,000h,0ffh,082h,020h,011h,000h,00ah,041h,006h,014h,00bh,041h,001h,014h	; 5a25  X.... ...A...A..
	defb 004h,011h,008h,014h,008h,011h,000h,081h,0f0h,010h,000h,030h,0f1h,000h,0ffh	; 5a35  ...........0...

; ======================================================================
; CODIGO 0x5a44..0x5a5e  (26 bytes)
; ======================================================================


FONDO_ETAPA_3:		; Fondo base con una franja rellena y su decorado
	call FONDO_ETAPA_1		;5a44
	ld hl,00920h		;5a47
	ld bc,00250h		;5a4a
	ld a,0feh		;5a4d
	call 00056h		;5a4f   ; BIOS FILVRM - Fills VRAM with value
	ld de,05a5eh		;5a52
	call DESC_DOBLE		;5a55
FONDO_ETAPA_3_5A58:
	ld de,05acch		;5a58
	jp DESCOMPRIME_GUION		;5a5b

; ----------------------------------------------------------------------
; DATOS graficos_fondo_3: Graficos comprimidos del fondo de tipo 3
;   0x5a5e..0x5b22  (196 bytes)
DATA_graficos_fondo_3:
	defb 082h,070h,00bh,000h,088h,0feh,0eeh,0feh,0eeh,0feh,0feh,0eeh,0eeh,004h,0feh,084h	; 5a5e  .p..............
	defb 0eeh,0feh,0eeh,0eeh,007h,0feh,087h,0eeh,0feh,0feh,0eeh,0feh,0eeh,0eeh,005h,0feh	; 5a6e  ................
	defb 083h,0eeh,0feh,0eeh,00ah,0feh,000h,081h,060h,00dh,000h,038h,0feh,000h,082h,080h	; 5a7e  ........`..8....
	defb 011h,000h,048h,0feh,040h,0feh,000h,082h,090h,012h,000h,029h,0feh,003h,0eeh,001h	; 5a8e  ..H.@......)....
	defb 0feh,003h,0eeh,005h,0feh,003h,0eeh,006h,0feh,002h,0eeh,006h,0feh,002h,0eeh,003h	; 5a9e  ................
	defb 0feh,005h,0eeh,001h,0feh,007h,0eeh,004h,0feh,004h,0eeh,004h,0feh,001h,0eeh,006h	; 5aae  ................
	defb 0feh,002h,0eeh,003h,0feh,000h,081h,0b0h,017h,000h,008h,0f0h,000h,0ffh,098h,00dh	; 5abe  ................
	defb 00ch,047h,004h,04eh,005h,047h,003h,04eh,003h,0f7h,002h,04fh,003h,04eh,002h,0f7h	; 5ace  .G.N.G.N...O.N..
	defb 006h,04fh,004h,0f7h,002h,04fh,002h,04eh,007h,0f7h,081h,04fh,080h,098h,02dh,005h	; 5ade  .O...O.N...O..-.
	defb 000h,0abh,001h,00fh,07fh,003h,007h,00fh,03fh,0f6h,0eeh,09eh,024h,000h,001h,003h	; 5aee  ........?...$...
	defb 007h,01fh,0ffh,0ffh,0ddh,000h,080h,0e0h,040h,0f7h,08eh,099h,03eh,080h,0c1h,00ch	; 5afe  ........@...>...
	defb 003h,0a5h,0deh,0ffh,0b3h,000h,000h,080h,0c0h,041h,0b3h,0cfh,0dfh,005h,000h,083h	; 5b0e  .........A......
	defb 0c0h,0f8h,0f4h,000h	; 5b1e

; ======================================================================
; CODIGO 0x5b22..0x5b2b  (9 bytes)
; ======================================================================


FONDO_ETAPA_4:		; Reusa el 3 y le anade un guion mas
	call FONDO_ETAPA_3		;5b22
	ld de,05b2bh		;5b25
	jp DESCOMPRIME_GUION		;5b28

; ----------------------------------------------------------------------
; DATOS graficos_fondo_4: Graficos comprimidos del fondo de tipo 4
;   0x5b2b..0x5b68  (61 bytes)
DATA_graficos_fondo_4:
	defb 0d0h,02dh,096h,0ffh,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h	; 5b2b  .-..............
	defb 000h,0ffh,000h,000h,0ffh,000h,000h,000h,0ffh,004h,000h,081h,0ffh,005h,000h,080h	; 5b3b  ................
	defb 098h,00dh,018h,0d6h,003h,096h,002h,0d9h,003h,0d8h,002h,096h,003h,0d9h,003h,0d8h	; 5b4b  ................
	defb 004h,096h,002h,0d9h,002h,0d8h,007h,096h,081h,0d8h,020h,0d6h,000h	; 5b5b  .......... ..

; ======================================================================
; CODIGO 0x5b68..0x5b96  (46 bytes)
; ======================================================================


FONDO_ETAPA_5:		; Fondo con decorado propio y una franja repetida
	ld de,05b96h		;5b68   ; dibuja el fondo con su decorado y una franja repetida
	call DESC_DOBLE		;5b6b
	ld de,05d20h		;5b6e   ; vuelca ademas un guion de decorado
	call DESCOMPRIME_GUION		;5b71
	ld de,05a29h		;5b74
	call DESC_DOBLE		;5b77
	ld de,056c1h		;5b7a
	call FONDO_ETAPA_1_51E9		;5b7d
	ld hl,02798h		;5b80
	ld de,05d38h		;5b83
	call DESC_3_TERCIOS		;5b86
	ld a,0d1h		;5b89
RELLENA_FRANJA_2:		; Rellena dos tercios desde 0x0798
	ld hl,00798h		;5b8b
	ld bc,00048h		;5b8e
	ld d,002h		;5b91
	jp RELLENA_3_TERCIOS_460D		;5b93

; ----------------------------------------------------------------------
; DATOS graficos_fondo_5: Graficos comprimidos del fondo de tipo 5
;   0x5b96..0x5d5b  (453 bytes)
DATA_graficos_fondo_5:
	defb 081h,098h,02dh,000h,007h,000h,081h,0ddh,005h,000h,083h,007h,07ch,0dfh,088h,000h	; 5b96  ..-.........|...
	defb 000h,040h,020h,0b8h,01eh,014h,020h,005h,000h,083h,080h,060h,01dh,005h,010h,083h	; 5ba6  .@ ... ....`....
	defb 038h,028h,045h,007h,000h,081h,052h,006h,000h,082h,06ch,0dbh,003h,000h,095h,00ch	; 5bb6  8(E...R...l.....
	defb 008h,068h,048h,0dbh,000h,006h,004h,004h,076h,044h,044h,0cdh,000h,000h,00eh,068h	; 5bc6  .hH.....vDD....h
	defb 048h,048h,048h,0d9h,018h,000h,000h,001h,000h,089h,000h,000h,000h,001h,000h,001h	; 5bd6  HHH.............
	defb 000h,000h,001h,004h,000h,081h,001h,004h,000h,088h,001h,000h,001h,000h,001h,000h	; 5be6  ................
	defb 000h,001h,005h,000h,08ch,001h,000h,000h,001h,000h,001h,000h,000h,001h,000h,000h	; 5bf6  ................
	defb 001h,005h,000h,084h,001h,000h,000h,001h,00ch,000h,000h,001h,001h,095h,040h,000h	; 5c06  ..............@.
	defb 080h,000h,000h,080h,000h,000h,000h,040h,000h,080h,000h,000h,000h,080h,000h,000h	; 5c16  .......@........
	defb 040h,000h,080h,006h,000h,0a4h,040h,000h,080h,000h,000h,000h,001h,004h,010h,000h	; 5c26  @.....@.........
	defb 000h,080h,000h,000h,001h,004h,000h,020h,000h,000h,080h,000h,000h,004h,010h,000h	; 5c36  ....... ........
	defb 040h,000h,000h,000h,000h,004h,010h,000h,000h,080h,008h,000h,081h,054h,007h,000h	; 5c46  @............T..
	defb 081h,0a8h,006h,000h,081h,002h,006h,000h,087h,001h,000h,002h,000h,000h,000h,080h	; 5c56  ................
	defb 004h,000h,000h,081h,000h,032h,000h,002h,003h,007h,000h,002h,003h,007h,000h,002h	; 5c66  .....2..........
	defb 003h,007h,000h,002h,003h,007h,000h,002h,003h,007h,000h,083h,003h,003h,000h,003h	; 5c76  ................
	defb 007h,009h,000h,003h,007h,006h,000h,003h,007h,081h,000h,003h,007h,00ch,000h,000h	; 5c86  ................
	defb 001h,001h,006h,000h,002h,003h,002h,000h,002h,030h,005h,000h,002h,030h,006h,000h	; 5c96  .........0...0..
	defb 081h,030h,009h,000h,082h,0c0h,080h,007h,000h,081h,001h,009h,000h,081h,003h,007h	; 5ca6  .0..............
	defb 000h,082h,006h,00ch,007h,000h,082h,00ch,080h,009h,000h,082h,001h,003h,004h,000h	; 5cb6  ................
	defb 082h,005h,050h,006h,000h,082h,00ah,0a0h,00bh,000h,083h,00ch,00ch,000h,000h,004h	; 5cc6  ..P.............
	defb 004h,090h,000h,000h,003h,00ch,030h,0c0h,000h,000h,004h,008h,008h,010h,020h,020h	; 5cd6  ......0.......  
	defb 040h,000h,000h,082h,038h,013h,000h,004h,000h,001h,081h,003h,000h,084h,081h,000h	; 5ce6  @...8...........
	defb 000h,081h,009h,000h,088h,081h,000h,000h,000h,081h,000h,000h,081h,005h,000h,001h	; 5cf6  ................
	defb 081h,005h,000h,086h,081h,000h,081h,000h,000h,081h,005h,000h,001h,081h,005h,000h	; 5d06  ................
	defb 087h,081h,000h,081h,000h,000h,081h,000h,000h,0ffh,098h,00dh,020h,041h,001h,081h	; 5d16  ............ A..
	defb 047h,071h,040h,081h,068h,081h,068h,081h,080h,000h,012h,058h,081h,070h,081h,070h	; 5d26  Gq@.h.h....X.p.p
	defb 081h,000h,007h,000h,001h,080h,007h,000h,001h,040h,007h,000h,001h,020h,007h,000h	; 5d36  .........@... ..
	defb 001h,010h,007h,000h,001h,008h,007h,000h,001h,004h,007h,000h,001h,002h,007h,000h	; 5d46  ................
	defb 001h,001h,008h,000h,000h	; 5d56

; ======================================================================
; CODIGO 0x5d5b..0x5d6d  (18 bytes)
; ======================================================================


FONDO_ETAPA_6:		; Fondo base mas un guion corto
	call FONDO_ETAPA_1		;5d5b   ; reusa el fondo base y le anade un guion corto
	ld de,05d6dh		;5d5e
	call DESCOMPRIME_GUION		;5d61
	ld hl,02dd0h		;5d64
	ld de,0512ch		;5d67
	jp DESC_NOMBRES_ABRE		;5d6a

; ----------------------------------------------------------------------
; DATOS graficos_fondo_6: Graficos comprimidos del fondo de tipo 6
;   0x5d6d..0x5d86  (25 bytes)
DATA_graficos_fondo_6:
	defb 098h,00dh,00ch,0ceh,004h,0c2h,005h,0ceh,003h,0c2h,002h,0ceh,002h,02eh,004h,0c2h	; 5d6d  ................
	defb 005h,0ceh,003h,0c2h,010h,0ceh,060h,00eh,000h	; 5d7d  ......`..

; ======================================================================
; CODIGO 0x5d86..0x5dab  (37 bytes)
; ======================================================================


FONDO_ETAPA_7:		; Fondo base con tres capas de decorado
	call FONDO_ETAPA_1		;5d86   ; reusa el fondo base con tres capas de decorado
	ld de,05dabh		;5d89
	call DESCOMPRIME_GUION		;5d8c   ; descomprime la primera capa del fondo
	ld hl,00920h		;5d8f
	call FIJA_ESCRITURA		;5d92
	ld de,05dc1h		;5d95
	call DESC_DOBLE		;5d98
	ld de,05dc1h		;5d9b
	call DESC_DOBLE		;5d9e
	inc de			;5da1
	call DESC_DOBLE		;5da2
	ld de,05e20h		;5da5
	jp DESC_DOBLE		;5da8

; ----------------------------------------------------------------------
; DATOS graficos_fondo_7: Graficos comprimidos del fondo de tipo 7
;   0x5dab..0x5e94  (233 bytes)
DATA_graficos_fondo_7:
	defb 098h,02dh,020h,000h,080h,060h,00dh,019h,0aeh,001h,0feh,016h,0aeh,004h,0feh,004h	; 5dab  .- ..`..........
	defb 0aeh,010h,06fh,010h,09fh,000h,001h,000h,070h,0aeh,001h,0aeh,003h,0feh,005h,0aeh	; 5dbb  ..o.....p.......
	defb 00ch,0feh,003h,0aeh,004h,0feh,007h,0aeh,005h,0feh,003h,0aeh,005h,0feh,002h,0aeh	; 5dcb  ................
	defb 006h,0feh,000h,004h,000h,003h,0aeh,005h,0feh,002h,0aeh,006h,0feh,007h,0aeh,001h	; 5ddb  ................
	defb 0feh,005h,0aeh,003h,0feh,000h,0ffh,002h,000h,090h,0aeh,0eeh,0feh,0eeh,0feh,0feh	; 5deb  ................
	defb 0eeh,0eeh,0aeh,0aeh,0aeh,0feh,0eeh,0feh,0eeh,0eeh,007h,0aeh,001h,0eeh,090h,0aeh	; 5dfb  ................
	defb 0feh,0eeh,0feh,0eeh,0eeh,0feh,0feh,0aeh,0aeh,0aeh,0eeh,0feh,0eeh,0feh,0feh,007h	; 5e0b  ................
	defb 0aeh,001h,0feh,000h,0ffh,082h,080h,011h,000h,04ch,0aeh,004h,0feh,005h,0aeh,003h	; 5e1b  .........L......
	defb 0feh,005h,0aeh,003h,0feh,003h,0aeh,005h,0feh,003h,0aeh,005h,0feh,004h,0aeh,004h	; 5e2b  ................
	defb 0feh,004h,0aeh,004h,0feh,004h,0aeh,004h,0feh,000h,002h,000h,006h,0aeh,002h,0feh	; 5e3b  ................
	defb 006h,0aeh,002h,0feh,003h,0aeh,005h,0feh,001h,0aeh,007h,0feh,004h,0aeh,004h,0feh	; 5e4b  ................
	defb 001h,0aeh,003h,0eeh,001h,0feh,003h,0eeh,003h,0aeh,002h,0feh,003h,0eeh,006h,0aeh	; 5e5b  ................
	defb 002h,0eeh,006h,0aeh,002h,0eeh,003h,0aeh,005h,0eeh,001h,0aeh,007h,0eeh,004h,0aeh	; 5e6b  ................
	defb 004h,0eeh,001h,0aeh,003h,0feh,001h,0eeh,003h,0feh,003h,0aeh,002h,0eeh,003h,0feh	; 5e7b  ................
	defb 000h,081h,0b0h,017h,000h,008h,0a0h,000h,0ffh	; 5e8b  .........

; ======================================================================
; CODIGO 0x5e94..0x5ea2  (14 bytes)
; ======================================================================


FONDO_ETAPA_8:		; Reusa el 5 y le anade una capa
	call FONDO_ETAPA_5		;5e94
	ld de,05ea2h		;5e97
	call DESC_DOBLE		;5e9a
	ld a,0f4h		;5e9d
	jp RELLENA_FRANJA_2		;5e9f

; ----------------------------------------------------------------------
; DATOS graficos_fondo_8: Graficos comprimidos del fondo de tipo 8
;   0x5ea2..0x5ed9  (55 bytes)
DATA_graficos_fondo_8:
	defb 081h,098h,02dh,001h,004h,000h,084h,001h,003h,007h,00fh,004h,000h,09ch,001h,003h	; 5ea2  ..-.............
	defb 047h,0efh,000h,000h,001h,003h,007h,00fh,01fh,03fh,001h,003h,007h,00fh,01fh,03fh	; 5eb2  G........?.....?
	defb 07fh,0ffh,000h,006h,01ch,074h,0d4h,054h,054h,0ffh,000h,081h,098h,00dh,000h,028h	; 5ec2  .....t.TT......(
	defb 014h,020h,054h,008h,044h,000h,0ffh	; 5ed2

; ======================================================================
; CODIGO 0x5ed9..0x61bb  (738 bytes)
; ======================================================================


ARRANCA_SONIDO:		; Arranca la melodia o efecto A (con di/ei alrededor)
	di			;5ed9   ; arranca la melodia o efecto A entre di y ei
	push hl			;5eda
	push de			;5edb   ; protege los registros durante el arranque
	push bc			;5edc
	push af			;5edd
	call ARRANCA_SONIDO_INT		;5ede
	pop af			;5ee1
	pop bc			;5ee2
	pop de			;5ee3
	pop hl			;5ee4
	ei			;5ee5
	ret			;5ee6
ARRANCA_SONIDO_INT:		; Comprueba prioridad y prepara el canal desde la tabla
	ld c,a			;5ee7   ; comprueba la prioridad y prepara el canal
	ld b,001h		;5ee8
	ld hl,0e012h		;5eea
	and 03fh		;5eed   ; segun el numero elige el canal y su prioridad
	cp 001h		;5eef
	jr z,SON_COMPARA		;5ef1
	cp 004h		;5ef3
	jr c,SON_PRIO_2		;5ef5
	cp 00eh		;5ef7
	jr c,ARRANCA_SONIDO_INT_5EFF		;5ef9
	inc b			;5efb
	inc b			;5efc
	jr SON_COMPARA		;5efd
ARRANCA_SONIDO_INT_5EFF:
	inc b			;5eff
	ld hl,0e020h		;5f00
	jr SON_COMPARA		;5f03
SON_PRIO_2:
	ld hl,0e020h		;5f05
	cp 003h		;5f08
	jr z,SON_COMPARA		;5f0a
	ld hl,0e02eh		;5f0c
SON_COMPARA:
	ld a,(hl)			;5f0f   ; no pisa un sonido de mas prioridad que suena
	and 03fh		;5f10
	ld e,a			;5f12
	ld a,c			;5f13
	and 03fh		;5f14
	cp e			;5f16   ; no pisa un sonido de mas prioridad que suena
	ret c			;5f17
	ret z			;5f18
	and 03fh		;5f19
	add a,a			;5f1b
	ld de,061c5h		;5f1c   ; toma el puntero de la melodia de la tabla 0x61C5
	call DE_MAS_A		;5f1f
	dec hl			;5f22
	dec hl			;5f23
	ld iy,0e03bh		;5f24
	ld a,0e0h		;5f28
	ld (iy+001h),a		;5f2a
	ld a,0e8h		;5f2d
	ld (iy+003h),a		;5f2f
	ld a,00dh		;5f32
	ld (iy+000h),a		;5f34
	ld (iy+002h),a		;5f37
SON_COMPARA_5F3A:
	ld (hl),001h		;5f3a   ; arranca la ficha del canal en 0xE03B
	inc hl			;5f3c   ; copia el puntero de la melodia a la ficha del canal
	ld (hl),001h		;5f3d
	inc hl			;5f3f   ; avanza al puntero de datos de la melodia
	ld (hl),c			;5f40
	inc hl			;5f41
	ld a,(de)			;5f42   ; apunta al primer byte de la melodia
	ld (hl),a			;5f43
	inc hl			;5f44
	inc de			;5f45
	ld a,(de)			;5f46
	ld (hl),a			;5f47
	ld a,005h		;5f48
	call HL_MAS_A		;5f4a   ; arranca la cabecera del canal
	xor a			;5f4d
	ld (hl),a			;5f4e
	ld a,005h		;5f4f
	call HL_MAS_A		;5f51
	inc de			;5f54
	djnz SON_COMPARA_5F3A		;5f55
	ld a,c			;5f57
	cp 046h		;5f58
	jr z,SON_COMPARA_5F61		;5f5a
	cp 044h		;5f5c
	jr z,SON_COMPARA_5F61		;5f5e
	ret			;5f60
SON_COMPARA_5F61:
	and 03fh		;5f61
	ld (0e02eh),a		;5f63
	ret			;5f66
SONIDO_CTRL:		; Orden de control dentro de la melodia (0xFE)
	inc hl			;5f67   ; orden de control de la melodia (fin o repeticion)
	ld a,(ix+009h)		;5f68
	inc a			;5f6b
	cp (hl)			;5f6c
	jr z,SONIDO_CTRL_5F82		;5f6d
	jp m,SONIDO_CTRL_5F73		;5f6f
	dec a			;5f72
SONIDO_CTRL_5F73:
	ld (ix+009h),a		;5f73   ; lee el nuevo puntero de la melodia
	inc hl			;5f76
	ld a,(hl)			;5f77
	ld (ix+003h),a		;5f78
	inc hl			;5f7b
	ld a,(hl)			;5f7c
	ld (ix+004h),a		;5f7d
	jr SONIDO_CTRL_5F8B		;5f80
SONIDO_CTRL_5F82:
	inc hl			;5f82
	inc hl			;5f83
	xor a			;5f84
	ld (ix+009h),a		;5f85
	call PSG_CALCULA_TONO		;5f88
SONIDO_CTRL_5F8B:
	inc (ix+000h)		;5f8b
	jp ACTUALIZA_CANAL_6052		;5f8e
PSG_TONO:		; Escribe el tono en el par de registros del PSG
	ld a,(0e03ah)		;5f91   ; escribe el tono en el par de registros del PSG
	ld e,a			;5f94
	ld a,c			;5f95
	cp 001h		;5f96
	jr z,PSG_TONO_5F9B		;5f98
	dec a			;5f9a
PSG_TONO_5F9B:
	rlca			;5f9b   ; ajusta el bit del canal en el mezclador
	rlca			;5f9c
	rlca			;5f9d
	dec d			;5f9e
	jr z,PSG_TONO_5FA5		;5f9f
	cpl			;5fa1
	and e			;5fa2
	jr PSG_TONO_5FA6		;5fa3
PSG_TONO_5FA5:
	or e			;5fa5
PSG_TONO_5FA6:
	set 1,a		;5fa6   ; fuerza el bit del canal segun el ruido
	bit 4,a		;5fa8
	jr z,FIJA_MEZCLADOR		;5faa
	res 1,a		;5fac
FIJA_MEZCLADOR:		; Ajusta el registro 7 del PSG (mezclador) desde 0xE03A
	ld (0e03ah),a		;5fae
	ld e,a			;5fb1
	ld a,007h		;5fb2
	jp 00093h		;5fb4   ; BIOS WRTPSG - Writes data to PSG-register
ACTUALIZA_SONIDO:		; Un cuadro del reproductor: recorre los tres canales
	ld a,(0e03ah)		;5fb7   ; refresca el mezclador
	call FIJA_MEZCLADOR		;5fba
	ld c,001h		;5fbd
	ld ix,0e010h		;5fbf   ; ficha del primer canal (0xE010), 14 bytes cada una
	exx			;5fc3
	ld b,003h		;5fc4   ; tres canales
	ld de,0000eh		;5fc6
ACTUALIZA_SONIDO_5FC9:
	exx			;5fc9   ; recorre los tres canales del reproductor
	ld a,(ix+002h)		;5fca
	push af			;5fcd
	cp 001h		;5fce
	jr z,CANAL_ARPEGIO		;5fd0
	pop af			;5fd2
	or a			;5fd3
	jr nz,ACTUALIZA_SONIDO_5FDB		;5fd4
	call CANAL_SILENCIO		;5fd6
	jr ACTUALIZA_SONIDO_5FDE		;5fd9
ACTUALIZA_SONIDO_5FDB:
	call ACTUALIZA_CANAL		;5fdb
ACTUALIZA_SONIDO_5FDE:
	inc c			;5fde
	inc c			;5fdf
	exx			;5fe0
	add ix,de		;5fe1   ; pasa a la ficha del canal siguiente
	djnz ACTUALIZA_SONIDO_5FC9		;5fe3
	ret			;5fe5
CANAL_ARPEGIO:		; Canal en modo especial (efecto de barrido)
	ld iy,0e03bh		;5fe6   ; canal en modo barrido (efecto)
	ld a,(0e003h)		;5fea
	bit 0,a		;5fed   ; segun el bit, escribe o borra el barrido
	jr nz,ESCRIBE_BARRIDO		;5fef   ; salta a escribir el barrido en el PSG
	ld a,(0e086h)		;5ff1
	or a			;5ff4
	ld a,(0e085h)		;5ff5
	ld h,000h		;5ff8
	ld d,000h		;5ffa
	ld l,a			;5ffc
	ld e,a			;5ffd
	jr nz,CANAL_ARPEGIO_601E		;5ffe
	ld a,(0e00ah)		;6000
	and 010h		;6003
	or a			;6005
	jr z,CANAL_ARPEGIO_601E		;6006
	ld a,(0e085h)		;6008
	cp 060h		;600b
	jr nc,CANAL_ARPEGIO_6016		;600d
	add hl,hl			;600f
	add hl,de			;6010
	add hl,hl			;6011
	add hl,hl			;6012
	add hl,hl			;6013
	jr GUARDA_BARRIDO		;6014
CANAL_ARPEGIO_6016:
	ld de,0005fh		;6016
	sbc hl,de		;6019
	ld de,008e8h		;601b
CANAL_ARPEGIO_601E:
	add hl,hl			;601e
	add hl,hl			;601f
	add hl,hl			;6020
	add hl,de			;6021
GUARDA_BARRIDO:
	ld a,l			;6022   ; guarda el paso del barrido
	ld (0e040h),a		;6023
	ld a,h			;6026
	ld (0e03fh),a		;6027
	inc iy		;602a
	inc iy		;602c
ESCRIBE_BARRIDO:
	ld de,(0e03fh)		;602e   ; escribe el tono del barrido en el PSG
	ld a,d			;6032
	ld d,e			;6033
	ld e,a			;6034
	ld h,(iy+000h)		;6035
	ld l,(iy+001h)		;6038
	sbc hl,de		;603b
	call PSG_ESCRIBE_TONO		;603d
	ld e,00ch		;6040
	ld a,008h		;6042
	call 00093h		;6044   ; BIOS WRTPSG - Writes data to PSG-register
	pop af			;6047
	jp ACTUALIZA_SONIDO_5FDE		;6048
ACTUALIZA_CANAL:		; Avanza un canal: nota, duracion y volumen
	bit 6,a		;604b
	ld d,001h		;604d
	call z,PSG_TONO		;604f
ACTUALIZA_CANAL_6052:
	ld a,(ix+002h)		;6052
	or a			;6055
	jp m,CANAL_ESPECIAL		;6056
	dec (ix+000h)		;6059   ; baja el contador de duracion; si no llega a 0, se queda
	ret nz			;605c
CANAL_LEE_NOTA:
	ld l,(ix+003h)		;605d   ; lee la siguiente nota de la melodia
	ld h,(ix+004h)		;6060
	ld a,(hl)			;6063
	cp 0feh		;6064   ; 0xFE cierra o repite la melodia
	jp z,SONIDO_CTRL		;6066
	jr nc,CANAL_SILENCIO		;6069
	bit 7,(ix+002h)		;606b
	jp nz,CANAL_ORDEN		;606f
	and 0f0h		;6072
	cp 020h		;6074
	ld a,(hl)			;6076
	jr nz,CANAL_NOTA		;6077
	and 00fh		;6079
	ld (ix+001h),a		;607b
	inc hl			;607e
	ld a,(hl)			;607f
CANAL_NOTA:
	ld b,a			;6080   ; descompone el byte de nota en tono y duracion
	and 0f0h		;6081
	cp 010h		;6083   ; 0x1x en el nibble alto: cambia el tono base
	jr nz,CANAL_TONO		;6085
	ld a,(hl)			;6087
	and 01fh		;6088
	ld e,a			;608a
	ld a,c			;608b
	cp 003h		;608c
	jr nz,CANAL_ESCRIBE_VOL		;608e
	inc hl			;6090
	bit 4,(hl)		;6091
	ld b,(hl)			;6093
	jr nz,CANAL_NOTA_609A		;6094
	ld a,e			;6096
	sub 010h		;6097
	ld e,a			;6099
CANAL_NOTA_609A:
	res 4,b		;609a
	dec hl			;609c
CANAL_ESCRIBE_VOL:
	ld a,006h		;609d
	call 00093h		;609f   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;60a2
	call PSG_TONO		;60a4
	inc hl			;60a7
CANAL_TONO:
	bit 6,(ix+002h)		;60a8   ; saca el tono calculado por el PSG
	jr z,CANAL_TONO_60BA		;60ac
	ld a,c			;60ae
	cp 003h		;60af
	ld a,(hl)			;60b1
	jr nz,CANAL_TONO_60BA		;60b2
	call PSG_CALCULA_TONO		;60b4
	ld a,b			;60b7
	jr CANAL_FIJA_DUR		;60b8
CANAL_TONO_60BA:
	and 0f0h		;60ba   ; mezcla el nibble de duracion
	ld b,a			;60bc
	xor (hl)			;60bd   ; combina el tono con el desplazamiento
	ld d,a			;60be
	inc hl			;60bf
	ld e,(hl)			;60c0
	call PSG_CALCULA_TONO		;60c1
	ex de,hl			;60c4
	call PSG_ESCRIBE_TONO		;60c5
	ld a,b			;60c8
	rrca			;60c9
	rrca			;60ca
	rrca			;60cb
	rrca			;60cc
CANAL_FIJA_DUR:
	ld h,a			;60cd   ; fija la duracion de la nota en la ficha
	ld e,(ix+001h)		;60ce
	ld (ix+000h),e		;60d1
	ld a,(ix+00ch)		;60d4
	add a,e			;60d7
	ld (ix+008h),a		;60d8
	jr CANAL_ESPECIAL_6135		;60db
CANAL_SILENCIO:		; Apaga el canal
	ld d,001h		;60dd   ; apaga el canal (silencio)
	call PSG_TONO		;60df
	xor a			;60e2   ; pone a cero el modo del canal
	ld (ix+00bh),a		;60e3   ; y su contador de repeticion
	ld (ix+002h),a		;60e6
	ld h,a			;60e9
	call CANAL_ESPECIAL_6135		;60ea
	ld a,(0e012h)		;60ed
	cp 001h		;60f0
	ret nz			;60f2
	ld iy,0e03bh		;60f3
	ld a,070h		;60f7
	ld (iy+007h),a		;60f9
	ld a,068h		;60fc
	ld (iy+009h),a		;60fe
	ld a,009h		;6101
	ld (iy+006h),a		;6103
	ld (iy+008h),a		;6106
	ld a,001h		;6109
	ld (0e012h),a		;610b
	ret			;610e
CANAL_ESPECIAL:
	dec (ix+000h)		;610f   ; orden especial dentro de la melodia
	jp z,CANAL_LEE_NOTA		;6112
	dec (ix+008h)		;6115   ; baja el contador del efecto especial
	ld a,(ix+008h)		;6118
	cp (ix+000h)		;611b
	jr nz,CANAL_ESPECIAL_6129		;611e
	ld e,a			;6120
	ld a,(ix+00dh)		;6121
	cp e			;6124
	ld a,e			;6125
	jr nc,CANAL_ESPECIAL_612C		;6126
	ret			;6128
CANAL_ESPECIAL_6129:
	dec (ix+008h)		;6129
CANAL_ESPECIAL_612C:
	ld a,(ix+007h)		;612c
	dec a			;612f
	ret m			;6130
	ld (ix+007h),a		;6131
	ld h,a			;6134
CANAL_ESPECIAL_6135:
	ld a,c			;6135
	rrca			;6136
	add a,088h		;6137
	ld e,h			;6139
	jp 00093h		;613a   ; BIOS WRTPSG - Writes data to PSG-register
CANAL_ORDEN:
	ld a,(hl)			;613d   ; interpreta una orden de control del canal
	and 0f0h		;613e
	cp 0d0h		;6140
	ld a,(hl)			;6142
	jr nz,CANAL_ORDEN_614C		;6143
	and 00fh		;6145
	ld (ix+00ah),a		;6147
	inc hl			;614a
	ld a,(hl)			;614b
CANAL_ORDEN_614C:
	cp 0f0h		;614c   ; orden: cambia de tempo o de instrumento
	jr c,CANAL_ORDEN_6161		;614e
	and 00fh		;6150   ; el nibble bajo dice el parametro
	ld (ix+006h),a		;6152
	inc hl			;6155
	ld a,(hl)			;6156
	ld (ix+00ch),a		;6157
	inc hl			;615a
	ld a,(hl)			;615b
	ld (ix+00dh),a		;615c
	inc hl			;615f
	ld a,(hl)			;6160
CANAL_ORDEN_6161:
	cp 0e0h		;6161   ; orden: fija un parametro del canal
	jr c,CANAL_ORDEN_616C		;6163
	and 00fh		;6165
	ld (ix+005h),a		;6167
	inc hl			;616a
	ld a,(hl)			;616b
CANAL_ORDEN_616C:
	and 00fh		;616c
	ld b,a			;616e
	ld a,(ix+00ah)		;616f
	jr z,CANAL_ORDEN_6179		;6172
CANAL_ORDEN_6174:
	add a,(ix+00ah)		;6174
	djnz CANAL_ORDEN_6174		;6177
CANAL_ORDEN_6179:
	ld (ix+001h),a		;6179   ; orden: salta a otro punto de la melodia
	ld a,(hl)			;617c
	call PSG_CALCULA_TONO		;617d   ; recalcula el tono de la orden
	and 0f0h		;6180
	rrca			;6182
	rrca			;6183
	rrca			;6184
	rrca			;6185
	ld b,a			;6186
	sub 00ch		;6187
	jr z,CANAL_ORDEN_618E		;6189
	ld a,(ix+006h)		;618b
CANAL_ORDEN_618E:
	ld (ix+007h),a		;618e   ; orden: repite un tramo de la melodia
	call CANAL_FIJA_DUR		;6191
	ld a,b			;6194   ; aplica la repeticion del tramo
	ld hl,061bbh		;6195
	call HL_MAS_A		;6198
	ld l,(hl)			;619b
	ld h,000h		;619c
	ld a,(ix+005h)		;619e
	or a			;61a1
	jr z,PSG_ESCRIBE_TONO		;61a2
	ld b,a			;61a4
CANAL_ORDEN_61A5:
	add hl,hl			;61a5
	djnz CANAL_ORDEN_61A5		;61a6
PSG_ESCRIBE_TONO:		; Saca el par de bytes de tono por el PSG
	ld a,c			;61a8
	ld e,h			;61a9
	call 00093h		;61aa   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;61ad
	dec a			;61ae
	ld e,l			;61af
	jp 00093h		;61b0   ; BIOS WRTPSG - Writes data to PSG-register
PSG_CALCULA_TONO:		; Interpola el tono a partir de la nota
	inc hl			;61b3
	ld (ix+003h),l		;61b4
	ld (ix+004h),h		;61b7
	ret			;61ba

; ----------------------------------------------------------------------
; DATOS tabla_arranque_sonido: Cabecera del bloque de sonido
;   0x61bb..0x61c5  (10 bytes)
DATA_tabla_arranque_sonido:
	defb 06bh,065h,05fh,05ah,055h,050h,04ch,047h,043h,040h	; 61bb  ke_ZUPLGC@

; ----------------------------------------------------------------------
; DATOS datos_musica: Tabla de melodias (0x61C5) y las melodias/efectos
;   0x61c5..0x65b1  (1004 bytes)
DATA_datos_musica:
	defw 0393ch,0656ah,06233h,0623ah,06271h,0627dh,06291h,0629eh	; 61c5
	defw 06205h,0621ch,06255h,06263h,063eeh,06407h,062b2h,062edh	; 61d5
	defw 06328h,0656bh,06584h,0659ch,0639bh,063b3h,063c8h,06426h	; 61e5
	defw 06484h,0650ah,06342h,06364h,06382h,0656ah,0656ah,0656ah	; 61f5
	defw 0b021h,0c081h,0e081h,0e07fh,02681h,07fd0h,081c0h,07fb0h	; 6205
	defw 081a0h,07f90h,08180h,021ffh,080b1h,080c1h,080d1h,080e1h	; 6215
	defw 0d126h,0c180h,0b180h,0a180h,09180h,08180h,0ff80h,01f22h	; 6225
	defw 0f4a0h,0fed0h,022ffh,01b1fh,01d1eh,01d1bh,01f26h,00c1dh	; 6235
	defw 00a0bh,00809h,00607h,00405h,00203h,00201h,00201h,0ff01h	; 6245
	defw 0d024h,0805ch,0b060h,0605ch,09060h,0405ch,0ff60h,0c024h	; 6255
	defw 08080h,0a068h,05080h,08068h,03080h,0ff68h,01821h,00a09h	; 6265
	defw 00a08h,00b09h,00a08h,0ff09h,0b021h,0c048h,0c050h,0c04ah	; 6275
	defw 0c057h,0c053h,0c056h,0c050h,0c049h,0ff55h,01f21h,00a09h	; 6285
	defw 00a08h,00b09h,00a08h,00a09h,021ffh,058b0h,060c0h,05ac0h	; 6295
	defw 067c0h,063c0h,066c0h,061c0h,059c0h,065c0h,021ffh,0a0c6h	; 62a5
	defw 060d6h,020e6h,0e0f5h,0a0c5h,060d5h,020e5h,0a0f5h,010f6h	; 62b5
	defw 0d8f5h,000e6h,0f623h,0d620h,0c7a0h,0b720h,0b8a0h,0b820h	; 62c5
	defw 0a9a0h,0a920h,099a0h,08950h,07970h,069c6h,06af5h,05a21h	; 62d5
	defw 05a55h,04a96h,03ac8h,0fff0h,0c621h,0a680h,0e640h,0f500h	; 62e5
	defw 0f5c0h,0f580h,0f540h,0f500h,0e680h,0f620h,0f500h,023e8h	; 62f5
	defw 000f6h,080e6h,000c7h,08097h,000b8h,080b8h,0c098h,000a9h	; 6305
	defw 03589h,05589h,07b79h,0ba69h,0f569h,0365ah,0565ah,0a44ah	; 6315
	defw 0ed3ah,022ffh,000e9h,080d9h,000e9h,000d9h,000e9h,000d9h	; 6325
	defw 000c9h,079b8h,000a9h,08099h,00089h,08079h,0d6ffh,002fch	; 6335
	defw 0e205h,0b0b5h,0e1b0h,0e201h,0e1b1h,02101h,0b2e2h,020e1h	; 6345
	defw 0252bh,02020h,02131h,05131h,05022h,07051h,09770h,0d6ffh	; 6355
	defw 002fch,0e205h,02025h,04120h,04141h,02241h,0bbb0h,05055h	; 6365
	defw 07150h,07171h,05271h,020e1h,04021h,06740h,0d6ffh,002fch	; 6375
	defw 0e305h,07373h,07373h,07075h,07170h,07161h,0a391h,0a3a3h	; 6385
	defw 0a5a3h,001e2h,0ff27h,0fcd9h,00103h,0b3e2h,090b0h,05070h	; 6395
	defw 040c0h,07002h,00040h,0a0a0h,091c0h,05070h,0ff74h,0fcd9h	; 63a5
	defw 00302h,021e2h,022c1h,00001h,072e3h,0e272h,05172h,00020h	; 63b5
	defw 0b4e3h,0d9ffh,002fch,0e402h,07070h,070e3h,070e4h,07070h	; 63c5
	defw 002feh,063cfh,020e3h,070e4h,07070h,020e3h,070e4h,030e3h	; 63d5
	defw 0e430h,0e3a0h,05051h,07400h,021ffh,01e1fh,01d1fh,01d1eh	; 63e5
	defw 01b1fh,01619h,01618h,0161ch,0151eh,01b19h,0002fh,02300h	; 63f5
	defw 0ff00h,01b23h,034e1h,074e1h,0b4d1h,0c0d3h,0a0c3h,0d0c3h	; 6405
	defw 0c0b3h,0e0a3h,0b093h,0d083h,0a073h,0b063h,0d063h,0f063h	; 6415
	defw 0d6ffh,002fch,0e105h,04343h,01321h,04345h,01521h,0e225h	; 6425
	defw 0b395h,021e1h,0c111h,01121h,021c1h,04311h,02143h,07313h	; 6435
	defw 07371h,04561h,0e225h,0b395h,021e1h,0c111h,01121h,021c1h	; 6445
	defw 0fc11h,00901h,06193h,06193h,06191h,06383h,04131h,08161h	; 6455
	defw 0b191h,004feh,06465h,06385h,08191h,0fc61h,00502h,04343h	; 6465
	defw 01321h,02123h,01123h,0b5e2h,095b5h,0e1dch,0c79dh,0d6ffh	; 6475
	defw 002fch,0e205h,04191h,004feh,06489h,04171h,004feh,0648fh	; 6485
	defw 02161h,02161h,02151h,02151h,04151h,051c1h,0c141h,04151h	; 6495
	defw 04191h,004feh,064a5h,071b1h,004feh,064abh,02161h,02161h	; 64a5
	defw 02151h,02151h,04151h,051c1h,0c141h,0fd53h,00901h,011e1h	; 64b5
	defw 04131h,03111h,01141h,0e241h,0b191h,011e1h,091e2h,0e1b1h	; 64c5
	defw 03111h,01141h,04131h,03111h,01141h,0e241h,0b191h,011e1h	; 64d5
	defw 01133h,0b1e2h,0fc91h,00502h,013e1h,0e213h,093b1h,07173h	; 64e5
	defw 09173h,06575h,0e165h,0e303h,0e291h,05101h,0b1e3h,021e2h	; 64f5
	defw 02171h,0c749h,0d6ffh,002fdh,0e405h,0e391h,0fe91h,00e10h	; 6505
	defw 0e465h,0e371h,0fe91h,01610h,0fc65h,00901h,061e4h,061e3h	; 6515
	defw 06111h,002feh,06521h,0b1e4h,0b1e3h,0b161h,002feh,0652bh	; 6525
	defw 061e4h,061e3h,06111h,002feh,06535h,0b1e4h,0b1e3h,0b161h	; 6535
	defw 002feh,0653fh,002fch,0e405h,0e341h,0fe41h,04c08h,02165h	; 6545
	defw 0e291h,0e321h,04123h,05153h,0e291h,0e301h,0b171h,021e2h	; 6555
	defw 0b1e3h,019e2h,0ffc7h,0fcd6h,00502h,045e1h,04040h,02151h	; 6565
	defw 09051h,0c070h,000e0h,0e105h,051a1h,0e0a1h,00c20h,0d6ffh	; 6575
	defw 002fch,0e105h,00005h,02100h,0a1e2h,021e1h,04050h,040c0h	; 6585
	defw 05145h,05121h,04cb0h,0d6ffh,001fdh,0e308h,0fe01h,0a10bh	; 6595
	defw 0e465h,0e371h,0e421h,0e3a1h,05021h,0ff0ch	; 65a5

; ======================================================================
; CODIGO 0x65b1..0x6615  (100 bytes)
; ======================================================================


MUEVE_COCHE_X:		; Desliza el coche del jugador en horizontal y coloca sus sprites
	ld a,(0e08ch)		;65b1   ; desliza el coche en horizontal segun el volante
	or a			;65b4
	jr nz,$+106		;65b5
	ld a,(0e085h)		;65b7   ; sin partida no hace nada
	or a			;65ba
	ret z			;65bb
	ld hl,0e080h		;65bc   ; puntero al estado horizontal del coche (0xE080)
	ld a,(hl)			;65bf
	inc hl			;65c0
	add a,(hl)			;65c1   ; acumula el empuje lateral
	ld (hl),a			;65c2
	ret nc			;65c3
	inc hl			;65c4
	ld c,(hl)			;65c5
	inc hl			;65c6
	ld a,(0e061h)		;65c7   ; el derrape depende del tipo de etapa (bit1 de 0xE061)
	bit 1,a		;65ca
	jr z,COCHE_X_2		;65cc
	inc hl			;65ce
	ld a,(hl)			;65cf
	or a			;65d0
	jr z,COCHE_X_1		;65d1
	dec (hl)			;65d3   ; baja el contador del derrape
	jr nz,COCHE_DERRAPE		;65d4
	dec hl			;65d6
	ld (hl),c			;65d7
	inc hl			;65d8
COCHE_DERRAPE:
	ld de,tabla_derrape_base		;65d9
	call DE_MAS_A		;65dc
	ld a,(de)			;65df
	ld (0e080h),a		;65e0
COCHE_X_1:
	dec hl			;65e3
COCHE_X_2:
	ld a,(0e121h)		;65e4
	bit 3,(hl)		;65e7   ; mira si el coche va a izquierda o derecha
	jr nz,COCHE_X_DER		;65e9
	bit 2,(hl)		;65eb
	ret z			;65ed
COCHE_X_IZQ:
	ld c,0feh		;65ee
COCHE_LIMITE_IZQ:
	cp 020h		;65f0
	ret c			;65f2
	jr COLOCA_SPRITES_COCHE		;65f3
COCHE_X_DER:
	ld c,002h		;65f5
COCHE_LIMITE_DER:
	cp 0c0h		;65f7
	ret nc			;65f9
COLOCA_SPRITES_COCHE:		; Escribe la X en los seis sprites del coche
	ld a,(0e121h)		;65fa   ; recoloca los sprites que forman el coche (0xE121..)
	add a,c			;65fd
	ld (0e121h),a		;65fe
	ld (0e125h),a		;6601
	add a,010h		;6604
	ld (0e129h),a		;6606
	ld (0e12dh),a		;6609
	ld (0e135h),a		;660c
	sub 010h		;660f
	ld (0e131h),a		;6611
tabla_derrape_base:		; Base de la tabla de derrape (se lee desde 0x6615)
	ret			;6614

; ----------------------------------------------------------------------
; DATOS tabla_derrape: Curva de derrape lateral del coche
;   0x6615..0x661f  (10 bytes)
DATA_tabla_derrape:
	defb 080h,040h,044h,049h,04eh,054h,05ah,062h,070h,080h	; 6615  .@DINTZbp.

; ======================================================================
; CODIGO 0x661f..0x66e2  (195 bytes)
; ======================================================================


MUEVE_COCHE_Y:		; Ajusta la posicion vertical/altura del coche
	ld hl,0e08eh		;661f   ; ajusta la altura del coche en los saltos
	ld a,(hl)			;6622
	inc hl			;6623   ; pasa a la coordenada de altura
	add a,(hl)			;6624
	ld (hl),a			;6625
	ret nc			;6626
	dec hl			;6627
	ld a,(hl)			;6628
	sub 00eh		;6629
	cp 030h		;662b
	jr c,CORTA_DERRAPE		;662d
	ld (hl),a			;662f
	dec hl			;6630
	ld a,(hl)			;6631
	or a			;6632
	ld a,(0e121h)		;6633
	ld c,003h		;6636
	jr z,$-65		;6638
	ld c,0fdh		;663a
	jr $-76		;663c
CORTA_DERRAPE:		; Anula el derrape (0xE08C)
	xor a			;663e
	ld (0e08ch),a		;663f
	ret			;6642
LEE_VOLANTE:		; Toma la direccion del volante de los mandos (0xE009)
	ld hl,(0e009h)		;6643   ; toma la direccion del volante de los mandos
	ld a,h			;6646
	and 00ch		;6647
	cp 00ch		;6649
	jr nz,VOLANTE_GUARDA		;664b
	ld a,l			;664d
	or a			;664e
	ret z			;664f
VOLANTE_GUARDA:
	ld hl,0e082h		;6650   ; guarda la direccion pedida (0xE082)
	ld (hl),a			;6653
	inc hl			;6654
	ld c,a			;6655
	cp (hl)			;6656
	ret z			;6657
	ld a,(0e061h)		;6658
	bit 1,a		;665b
	jr nz,VOLANTE_SUAVE		;665d
VOLANTE_FIJA:
	ld (hl),c			;665f
	ret			;6660
VOLANTE_SUAVE:
	ld a,(0e084h)		;6661   ; en ciertas etapas suaviza el giro
	or a			;6664
	ret nz			;6665
	ld a,(hl)			;6666
	or a			;6667
	jr z,VOLANTE_FIJA		;6668
	inc hl			;666a
	ld (hl),00ah		;666b
	ret			;666d
ANIMA_RUEDAS:		; Alterna el fotograma de las ruedas segun la velocidad
	ld a,(0e072h)		;666e   ; alterna el fotograma de las ruedas por la velocidad
	dec a			;6671
	ret nz			;6672
	ld a,(0e085h)		;6673
	cp 01eh		;6676
	ld hl,0e132h		;6678
	ld a,008h		;667b
	jr c,RUEDAS_FIJA		;667d
	ld a,004h		;667f
	xor (hl)			;6681
RUEDAS_FIJA:
	ld (hl),a			;6682
	add a,010h		;6683
	ld (0e136h),a		;6685
	ret			;6688
MIRA_CHOQUE_LATERAL:		; Si el coche se sale, marca golpe y suena
	ld hl,0e08bh		;6689   ; si el coche se sale del borde, marca golpe
	ld (hl),000h		;668c
	ld a,(0e121h)		;668e   ; mira la X del primer sprite del coche (0xE121)
	sub 02ah		;6691
	cp 08ch		;6693
	ret c			;6695
	ld a,(0e085h)		;6696
	ld b,a			;6699
	or a			;669a
	ret z			;669b
	cp 018h		;669c
	jr c,CHOQUE_SACUDE		;669e
	ld (hl),001h		;66a0
CHOQUE_SACUDE:
	ld a,(0e003h)		;66a2   ; sacude el coche y hace sonar el golpe
	and 002h		;66a5
	dec a			;66a7   ; baja el contador de la sacudida
	ld c,a			;66a8
	call COLOCA_SPRITES_COCHE		;66a9
	call CORTA_DERRAPE		;66ac
	call DIBUJA_VELOCIMETRO_2		;66af
	ld a,042h		;66b2
	ld hl,0e02eh		;66b4
	cp (hl)			;66b7
	ret z			;66b8
	jp ARRANCA_SONIDO		;66b9
INSTALA_SPRITES_COCHE:		; Copia la plantilla del coche a 0xE120 y a la VRAM
	ld hl,066e2h		;66bc
	ld de,0e120h		;66bf
	ld bc,00018h		;66c2
	ldir		;66c5
	ld a,(0e061h)		;66c7   ; en ciertas etapas cambia el color de dos sprites
	and 009h		;66ca
	jr z,VUELCA_SPRITES_COCHE		;66cc
	ld a,00dh		;66ce
	ld (0e133h),a		;66d0
	ld (0e137h),a		;66d3
VUELCA_SPRITES_COCHE:		; Manda los seis sprites del coche a 0x3B10
	ld hl,03b10h		;66d6
	ld de,0e120h		;66d9
	ld bc,00018h		;66dc
	jp VUELCA_A_VRAM		;66df

; ----------------------------------------------------------------------
; DATOS plantilla_sprites_coche: Seis sprites (Y,X,patron,color) del coche
;   0x66e2..0x66fa  (24 bytes)
DATA_plantilla_sprites_coche:
	defb 0a4h,054h,000h,001h	; 66e2
	defb 0a0h,054h,004h,006h	; 66e6
	defb 0a4h,064h,010h,001h	; 66ea
	defb 0a0h,064h,014h,006h	; 66ee
	defb 0b0h,054h,008h,001h	; 66f2
	defb 0b0h,064h,018h,001h	; 66f6

; ======================================================================
; CODIGO 0x66fa..0x6757  (93 bytes)
; ======================================================================


AJUSTA_ALTURA_COCHE:		; Corrige la altura del coche segun la fase
	ld a,(0e085h)		;66fa   ; corrige la altura del coche segun la fase de salto
	ld c,a			;66fd
	or a			;66fe   ; si no hay salto en curso, se va
	ret z			;66ff
	ld hl,0e08ah		;6700
	ld a,(0e075h)		;6703
	ld b,a			;6706
	cp 008h		;6707
	jr nz,AJUSTA_ALTURA_1		;6709
	ld (hl),0ffh		;670b
	ret			;670d
AJUSTA_ALTURA_1:
	dec hl			;670e   ; ajusta la altura de la rampa
	ld a,(hl)			;670f
	inc hl			;6710
	add a,(hl)			;6711
	ld (hl),a			;6712
	ret nc			;6713
	ex de,hl			;6714
	ld hl,06758h		;6715
	ld a,c			;6718
AJUSTA_ALTURA_1_6719:
	inc hl			;6719   ; baja la altura del coche paso a paso
	sub (hl)			;671a
	inc hl			;671b
	jr nc,AJUSTA_ALTURA_1_6719		;671c
	ld a,b			;671e
	and 003h		;671f
	cp 002h		;6721
	ld a,(hl)			;6723
	jr z,AJUSTA_ALTURA_1_6728		;6724
	sub 026h		;6726
AJUSTA_ALTURA_1_6728:
	dec de			;6728   ; sube la altura del coche paso a paso
	ld (de),a			;6729
	cp 080h		;672a
	jr c,AJUSTA_ALTURA_1_674C		;672c
	ld a,b			;672e
	ld c,008h		;672f
	cp 006h		;6731
	jr nz,AJUSTA_ALTURA_1_6737		;6733
	ld c,004h		;6735
AJUSTA_ALTURA_1_6737:
	and 003h		;6737   ; fija la altura final tras el salto
	cp 002h		;6739
	jr nz,AJUSTA_ALTURA_1_674C		;673b
	ld a,(0e00ah)		;673d
	and c			;6740
	jr z,AJUSTA_ALTURA_1_674C		;6741
	ld a,(0e02ch)		;6743
	or a			;6746
	ld a,044h		;6747
	call z,ARRANCA_SONIDO		;6749
AJUSTA_ALTURA_1_674C:
	ld a,(0e121h)		;674c
	bit 2,b		;674f
	jp z,COCHE_X_IZQ		;6751
	jp COCHE_X_DER		;6754

; ----------------------------------------------------------------------
; DATOS tabla_saltos_coche: Alturas del coche en el salto (rampa)
;   0x6757..0x676b  (20 bytes)
DATA_tabla_saltos_coche:
	defb 000h,027h	; 6757
	defb 060h,027h	; 6759
	defb 040h,033h	; 675b
	defb 020h,040h	; 675d
	defb 010h,055h	; 675f
	defb 010h,066h	; 6761
	defb 004h,07ah	; 6763
	defb 004h,08eh	; 6765
	defb 004h,0a0h	; 6767
	defb 004h,0b6h	; 6769

; ======================================================================
; CODIGO 0x676b..0x6934  (457 bytes)
; ======================================================================


AVANZA_CARRERA:		; Reloj de carrera: distancia, puntos, meta y proxima fase
	ld a,(0e085h)		;676b
	or a			;676e
	ret z			;676f
	ld hl,0e072h		;6770
	dec (hl)			;6773   ; el reloj de tramo (0xE072) marca el paso
	ret nz			;6774
	push hl			;6775
	call LEE_PISTA		;6776
	pop hl			;6779
	call VELOCIDAD_A_INDICE		;677a
	ld (hl),a			;677d
	inc hl			;677e
	inc (hl)			;677f
	ld a,(0e00ah)		;6780
	and 001h		;6783
	jr nz,AVANZA_TRAMO		;6785
	exx			;6787
	ld de,00001h		;6788
	call SUMA_PUNTOS		;678b   ; sin acelerar a fondo puntua poco a poco
	exx			;678e
AVANZA_TRAMO:
	ld a,(hl)			;678f   ; avanza un tramo del recorrido
	and 00fh		;6790
	cp 00fh		;6792
	jr nz,AVANZA_TRAMO_4		;6794
	exx			;6796
	ld a,001h		;6797   ; al agotar el tramo, avanza el recorrido
	ld e,a			;6799
	ld hl,0e070h		;679a
	inc (hl)			;679d
	ld d,(hl)			;679e
	inc hl			;679f
	dec (hl)			;67a0
	jr nz,AVANZA_TRAMO_1		;67a1
	dec e			;67a3
	ld (0e062h),a		;67a4   ; al agotar el tramo marca fin (0xE062)
AVANZA_TRAMO_1:
	ld a,(hl)			;67a7   ; al cerrar el tramo, prepara la meta
	sub 006h		;67a8
	jr nz,AVANZA_TRAMO_2		;67aa
	ld l,a			;67ac
	ld h,09fh		;67ad
	ld (0e07ch),hl		;67af
AVANZA_TRAMO_2:
	ld a,d			;67b2   ; cada 32 pasos actualiza el marcador
	and 01fh		;67b3
	jr nz,AVANZA_TRAMO_3		;67b5
	ld a,e			;67b7
	ld (0e0d9h),a		;67b8
AVANZA_TRAMO_3:
	exx			;67bb
AVANZA_TRAMO_4:
	ld a,(hl)			;67bc   ; ajusta el contador de tramo
	and 003h		;67bd
	inc hl			;67bf
	ld (hl),a			;67c0
	cp 003h		;67c1
	jr nz,AVANZA_REVISA_COLISION		;67c3
	inc hl			;67c5
	inc hl			;67c6
	dec (hl)			;67c7
AVANZA_REVISA_COLISION:
	ld hl,0e079h		;67c8   ; revisa si toca redibujar por colision
	xor a			;67cb
	cp (hl)			;67cc   ; compara el segmento con el esperado (0xE073)
	jr z,AVANZA_DIBUJA		;67cd
	ld (hl),a			;67cf
	call DIBUJA_ESCENARIO		;67d0
	ld hl,0e09fh		;67d3
	ld (hl),001h		;67d6
	push hl			;67d8
	call ACTUALIZA_RIVALES		;67d9
	call DIBUJA_RIVALES		;67dc
	pop hl			;67df
	ld (hl),000h		;67e0
AVANZA_DIBUJA:
	call DIBUJA_CARRETERA		;67e2   ; dibuja coche y decorado
	call DIBUJA_CUENTAKM		;67e5
	call DIBUJA_BORDES		;67e8   ; pinta los bordes de la carretera
	call APARECEN_OBJETOS		;67eb
	ld hl,0e077h		;67ee   ; compara el tramo con el esperado
	ld a,(hl)			;67f1
	dec hl			;67f2
	cp (hl)			;67f3
	ret nz			;67f4
	ld c,001h		;67f5
	dec hl			;67f7
	bit 3,(hl)		;67f8
	jr nz,AVANZA_FIN		;67fa
	ld a,(hl)			;67fc
	inc a			;67fd
	and 003h		;67fe
	jr z,AVANZA_FIN		;6800
	inc c			;6802
AVANZA_FIN:
	ld hl,0e079h		;6803
	ld (hl),c			;6806
	ret			;6807
LEE_PISTA:		; Lee el guion de la pista (0xE07A) para el siguiente tramo
	ld hl,0e079h		;6808
	ld a,(hl)			;680b
	dec a			;680c
	ret m			;680d
	jr nz,PISTA_AVANZA		;680e
LEE_PISTA_TRAMO:
	ld hl,(0e07ah)		;6810   ; saca el byte de curva/segmento del guion de pista
	ld c,(hl)			;6813   ; saca el byte de curva del guion de pista
	inc hl			;6814
	ld (0e07ah),hl		;6815
	ld a,(0e061h)		;6818
	cp 001h		;681b
	jr nz,PISTA_GUARDA		;681d
	ld a,(hl)			;681f
	rla			;6820
	jr c,PISTA_GUARDA		;6821
	push bc			;6823
	rla			;6824
	call FONDO_ETAPA_2_589C		;6825
	pop bc			;6828
PISTA_GUARDA:
	ld hl,0e078h		;6829   ; guarda el segmento de pista leido
	ld (hl),c			;682c
	ld a,c			;682d
	dec hl			;682e
	ld (hl),000h		;682f
	dec hl			;6831
	rlc c		;6832
	jr c,PISTA_CURVA		;6834
	ld a,001h		;6836
PISTA_CURVA:
	and 03fh		;6838   ; calcula la curvatura del segmento
	rlca			;683a
	ld (hl),a			;683b   ; guarda la curvatura calculada
	dec hl			;683c
	ld a,c			;683d
	rlca			;683e
	and 003h		;683f
	add a,a			;6841
	add a,a			;6842
	ld (hl),a			;6843
	ret			;6844
PISTA_AVANZA:
	ld hl,0e075h		;6845   ; avanza al siguiente segmento de pista
	inc (hl)			;6848
	ld a,(hl)			;6849   ; lee el estado del segmento de pista
	ld hl,0e078h		;684a
	and 003h		;684d
	cp 002h		;684f
	ld a,001h		;6851
	jr nz,PISTA_AVANZA_1		;6853
	ld a,(hl)			;6855
	and 03fh		;6856
	rlca			;6858
	sub 003h		;6859
PISTA_AVANZA_1:
	dec hl			;685b
	ld (hl),000h		;685c
	dec hl			;685e
	ld (hl),a			;685f
	ret			;6860
DIBUJA_CUENTAKM:		; Pinta el cuentakilometros/rotulo lateral por tablas
	ld a,(0e061h)		;6861   ; pinta el cuentakilometros por tablas
	cp 008h		;6864
	jr z,DIBUJA_CUENTAKM_ACUA		;6866   ; la etapa acuatica usa otra variante
	ld hl,SIGUE_CUENTAKM		;6868
	push hl			;686b
	ld hl,07531h		;686c
	ld de,075d6h		;686f
	ld bc,(0e074h)		;6872
	ld a,b			;6876
	cp 004h		;6877
	jr nz,DIBUJA_CUENTAKM_687D		;6879
	xor a			;687b
	ld b,a			;687c
DIBUJA_CUENTAKM_687D:
	sub 005h		;687d
	jr nc,CUENTAKM_INDEXA		;687f
	ld hl,07521h		;6881
	ld de,07541h		;6884
	ld a,b			;6887
CUENTAKM_INDEXA:
	add a,a			;6888   ; indexa la tabla de digitos del cuentakilometros
	add a,a			;6889
	add a,c			;688a   ; suma el indice a la base de la tabla
	call HL_MAS_A		;688b
	ld l,(hl)			;688e
	ld h,000h		;688f
	ld b,h			;6891
	add hl,de			;6892
	ex de,hl			;6893
	pop hl			;6894
	ld a,(0e075h)		;6895
	ld c,a			;6898
	add hl,bc			;6899
	ld c,(hl)			;689a
	ld hl,039a0h		;689b
	add hl,bc			;689e
	jp PINTA_ROTULO		;689f
DIBUJA_CUENTAKM_ACUA:		; Variante para la etapa acuatica
	ld hl,SIGUE_CUENTAKM_ACUA		;68a2   ; variante del cuentakilometros para la etapa acuatica
	push hl			;68a5
	ld hl,07820h		;68a6   ; apunta a las tablas de la variante acuatica
	ld de,078c3h		;68a9
	ld bc,(0e074h)		;68ac
	ld a,b			;68b0
	sub 004h		;68b1
	jr nc,CUENTAKM_INDEXA		;68b3
	ld hl,07810h		;68b5
	ld de,07834h		;68b8
	ld a,b			;68bb
	jr CUENTAKM_INDEXA		;68bc
SIGUE_CUENTAKM:		; Continuacion tras pintar (retorno empujado)
	cpl			;68be   ; continua el dibujo tras pintar el rotulo
	jr nc,DIBUJA_BORDES_1		;68bf
	ld (02f2fh),a		;68c1
	dec hl			;68c4
	inc l			;68c5
	rrca			;68c6
SIGUE_CUENTAKM_ACUA:		; Continuacion de la variante acuatica
	jr nc,$+50		;68c7   ; continua el dibujo de la variante acuatica
	inc (hl)			;68c9
	ld sp,02f2fh		;68ca
	dec hl			;68cd
	dec l			;68ce
	rrca			;68cf
DIBUJA_CARRETERA:		; Dibuja el trazado de la carretera segun la curvatura 0xE074
	ld a,(0e061h)		;68d0
	cp 008h		;68d3
	ret z			;68d5
	ld hl,(0e074h)		;68d6   ; 0xE074 es la curvatura de la carretera
	ld b,000h		;68d9
	ld a,h			;68db
	add a,a			;68dc
	rr l		;68dd
	adc a,b			;68df
	add a,a			;68e0
	ld c,a			;68e1
	ld hl,0767ch		;68e2   ; indexa la tabla de formas 0x767C
	add hl,bc			;68e5
	ld e,(hl)			;68e6   ; saca el puntero de la forma
	inc hl			;68e7
	ld d,(hl)			;68e8
	jp PINTA_TIRA		;68e9
DIBUJA_BORDES:		; Pinta los bordes/rayas de la carretera
	ld a,(0e061h)		;68ec
	cp 001h		;68ef
	ret nz			;68f1
	ld de,073c7h		;68f2
DIBUJA_BORDES_1:
	ld bc,073dfh		;68f5   ; dibuja el borde con otra tabla
	ld hl,(0e074h)		;68f8
	rr l		;68fb
	jr nc,BORDES_INDEXA		;68fd
	ld de,073f7h		;68ff
	ld bc,0740fh		;6902
BORDES_INDEXA:
	rl h		;6905   ; mete la curvatura en el indice de bordes
	ld a,h			;6907
	and 00fh		;6908   ; el nibble bajo elige el trozo de borde
	add a,a			;690a
	add a,a			;690b
	ex af,af'			;690c
	call BORDES_PINTA		;690d   ; pinta la primera mitad del borde
	ex af,af'			;6910
	ld hl,074e1h		;6911
	call HL_MAS_A		;6914
	ld e,(hl)			;6917   ; y la segunda si existe
	inc hl			;6918
	ld d,(hl)			;6919
	inc hl			;691a
	ld c,(hl)			;691b
	inc hl			;691c
	ld a,(hl)			;691d
	or c			;691e
	jr z,BORDES_PINTA_2		;691f
	ld b,(hl)			;6921
BORDES_PINTA:
	push bc			;6922
	call PINTA_TIRA		;6923
	pop de			;6926
BORDES_PINTA_2:
	jp PINTA_TIRA		;6927
VELOCIDAD_A_INDICE:		; Convierte la velocidad (0xE085) en un valor de tabla
	ld a,(0e085h)		;692a
	add a,030h		;692d
	jr nc,$+8		;692f
	ld a,002h		;6931
	ret			;6933

; ----------------------------------------------------------------------
; DATOS fragmento_suelto: Tres bytes (ld a,(0xE085)) sin alcanzar
;   0x6934..0x6937  (3 bytes)
DATA_fragmento_suelto:
	defb 03ah,085h,0e0h	; 6934

; ======================================================================
; CODIGO 0x6937..0x69b1  (122 bytes)
; ======================================================================


GIRO_A_INDICE:		; Convierte el giro en un indice 0..7
	rlca			;6937   ; convierte el giro en un indice de 0 a 7
	rlca			;6938
	rlca			;6939
	and 007h		;693a
	cpl			;693c
	add a,00ah		;693d
	ret			;693f
CONTROL_ACELERADOR:		; Lee acelerador y freno y ajusta la velocidad
	call CAMBIA_MARCHA		;6940   ; lee acelerador y freno y ajusta la velocidad
	ld a,(0e00ah)		;6943
	and 001h		;6946
	jp nz,ACELERA_A_FONDO		;6948
	ld hl,(0e08bh)		;694b
	ld a,l			;694e
	or h			;694f
	ret nz			;6950
	call ACELERA		;6951
	jp DIBUJA_VELOCIMETRO		;6954
ACELERA:		; Sube la velocidad 0xE085 hasta su tope
	ld a,(0e00ah)		;6957   ; sube 0xE085 con el tope de la ficha del canal
	and 010h		;695a
	jr z,DECELERA_ROCE		;695c
	ld hl,0e085h		;695e
	ld a,(hl)			;6961   ; el tope depende de la marcha (0xE086)
	inc hl			;6962
	bit 0,(hl)		;6963
	ld c,08fh		;6965
	jr z,ACELERA_696B		;6967
	ld c,0efh		;6969
ACELERA_696B:
	cp c			;696b   ; acelera con el tope del cambio de marcha
	ret nc			;696c
	inc hl			;696d   ; apunta al tope del cambio de marcha
	ld a,(hl)			;696e   ; baja el contador entre subidas
	inc hl			;696f
	dec (hl)			;6970
	ret nz			;6971
	ld (hl),a			;6972
	ld a,001h		;6973
	ld hl,0e085h		;6975
	add a,(hl)			;6978
	ld (hl),a			;6979
	ret			;697a
DECELERA_ROCE:		; Frena poco a poco por el roce
	ld a,(0e085h)		;697b   ; frena poco a poco por el roce del suelo
	or a			;697e
	ret z			;697f
	ld a,(0e003h)		;6980
	rra			;6983
	ret nc			;6984
FRENA_2:
	ld a,002h		;6985
FRENA:		; Resta C a la velocidad, con suelo en cero
	ld hl,0e085h		;6987   ; resta C a la velocidad, con suelo en cero
	ld c,a			;698a
	ld a,(hl)			;698b
	sub c			;698c
	jr nc,FRENA_6990		;698d
	xor a			;698f
FRENA_6990:
	ld (hl),a			;6990
	ret			;6991
LEE_REVOLUCIONES:		; Devuelve el nivel de revoluciones para el sonido
	ld hl,069b1h		;6992   ; devuelve el nivel de revoluciones para el ruido del motor
	ld de,069bbh		;6995
	ld a,(0e085h)		;6998   ; el nivel sale de la velocidad actual
	rrca			;699b
	rrca			;699c
	rrca			;699d
	rrca			;699e
	and 00fh		;699f
	ld c,a			;69a1
	ld a,(0e086h)		;69a2
	or a			;69a5
	ld a,c			;69a6
	jr z,REV_INDEXA		;69a7
	ex de,hl			;69a9
	sub 005h		;69aa
REV_INDEXA:
	call HL_MAS_A		;69ac
	ld a,(hl)			;69af
	ret			;69b0

; ----------------------------------------------------------------------
; DATOS tabla_revoluciones: Nivel de motor por tramo de velocidad
;   0x69b1..0x69c6  (21 bytes)
DATA_tabla_revoluciones:
	defb 001h,001h,001h,001h,002h,002h,003h,005h,008h,0ffh,001h	; 69b1  ...........
	defb 001h,001h,002h,002h,003h,004h,005h,006h,009h,0ffh	; 69bc  ..........

; ======================================================================
; CODIGO 0x69c6..0x6a19  (83 bytes)
; ======================================================================


ACELERA_A_FONDO:		; Acelerador a tope: sube velocidad y ruge el motor
	ld a,(0e085h)		;69c6   ; acelera a fondo y hace rugir el motor
	or a			;69c9
	ret z			;69ca   ; sin velocidad no acelera
	ld a,(0e009h)		;69cb
	and 001h		;69ce
	jr nz,ACELERA_SONIDO		;69d0
	ld a,(0e02ch)		;69d2
	or a			;69d5
	jr nz,DIBUJA_VELOCIMETRO_2		;69d6
	ld a,(0e085h)		;69d8
	cp 050h		;69db
	jr c,DIBUJA_VELOCIMETRO_2		;69dd
ACELERA_SONIDO:
	ld a,046h		;69df
	call ARRANCA_SONIDO		;69e1
DIBUJA_VELOCIMETRO_2:
	call FRENA_2		;69e4
DIBUJA_VELOCIMETRO:		; Escribe la cifra de velocidad (km/h) en la VRAM
	ld a,(0e085h)		;69e7
	ld c,a			;69ea
	rrca			;69eb
	rrca			;69ec
	rrca			;69ed
	and 01eh		;69ee
	ld hl,06a19h		;69f0   ; indexa las centenas por la velocidad
	call HL_MAS_A		;69f3
	ld d,(hl)			;69f6
	inc hl			;69f7
	ld e,(hl)			;69f8
	ld a,c			;69f9
	and 00fh		;69fa
	ld hl,06a39h		;69fc   ; y las unidades
	call HL_MAS_A		;69ff
	ld a,(hl)			;6a02
	add a,e			;6a03   ; suma con ajuste decimal
	daa			;6a04
	jr nc,DIBUJA_VELOCIMETRO_6A08		;6a05
	inc d			;6a07
DIBUJA_VELOCIMETRO_6A08:
	ld hl,0382ah		;6a08
	ld b,001h		;6a0b
	push de			;6a0d
	call PINTA_MARCADOR_BUCLE_4437		;6a0e   ; parte el numero en dos digitos
	ld l,029h		;6a11
	pop af			;6a13
	add a,010h		;6a14
	jp 0004dh		;6a16   ; BIOS WRTVRM - Writes data in VRAM

; ----------------------------------------------------------------------
; DATOS tabla_velocimetro: Centenas de km/h por tramo de velocidad (BCD)
;   0x6a19..0x6a39  (32 bytes)
DATA_tabla_velocimetro:
	defb 000h,000h	; 6a19
	defb 000h,025h	; 6a1b
	defb 000h,050h	; 6a1d
	defb 000h,075h	; 6a1f
	defb 001h,000h	; 6a21
	defb 001h,025h	; 6a23
	defb 001h,050h	; 6a25
	defb 001h,075h	; 6a27
	defb 002h,000h	; 6a29
	defb 002h,025h	; 6a2b
	defb 002h,050h	; 6a2d
	defb 002h,075h	; 6a2f
	defb 003h,000h	; 6a31
	defb 003h,025h	; 6a33
	defb 003h,050h	; 6a35
	defb 003h,075h	; 6a37

; ----------------------------------------------------------------------
; DATOS tabla_velocimetro_uni: Unidades de km/h por tramo de velocidad
;   0x6a39..0x6a49  (16 bytes)
DATA_tabla_velocimetro_uni:
	defb 000h,001h,003h,005h,006h,008h,010h,011h,013h,014h,016h,018h,019h,021h,022h,024h	; 6a39  .............!"$

; ======================================================================
; CODIGO 0x6a49..0x6aa1  (88 bytes)
; ======================================================================


GASTA_GASOLINA:		; Baja el nivel de gasolina y pinta su aguja
	call AVISA_GASOLINA		;6a49   ; gasta gasolina y mueve su aguja
	ld hl,0e067h		;6a4c
	ld a,(hl)			;6a4f   ; lee el nivel de gasolina
	dec hl			;6a50
	dec (hl)			;6a51
	ret nz			;6a52
	ld (hl),a			;6a53
	ld a,(0e085h)		;6a54
	cp 010h		;6a57
	ld c,001h		;6a59
	jr nc,GASOLINA_BAJA		;6a5b
	ld c,003h		;6a5d
GASOLINA_BAJA:
	dec hl			;6a5f
	ld a,(hl)			;6a60
	sub c			;6a61
	jr nc,GASOLINA_1		;6a62
	ld a,000h		;6a64
GASOLINA_1:
	ld (hl),a			;6a66
	jr nc,GASOLINA_AGUJA		;6a67
	ld a,001h		;6a69
	ld (0e063h),a		;6a6b
GASOLINA_AGUJA:
	ld de,0e065h		;6a6e   ; coloca la aguja de la gasolina en su angulo
	ld a,(de)			;6a71
	and 07fh		;6a72   ; aisla el angulo de la aguja
	ld a,0a8h		;6a74
	jr z,GASOLINA_PINTA		;6a76
	ld a,(de)			;6a78
	rrca			;6a79
	rrca			;6a7a
	rrca			;6a7b
	and 00fh		;6a7c
	add a,0a9h		;6a7e
GASOLINA_PINTA:
	ld hl,03b01h		;6a80
	call 0004dh		;6a83   ; BIOS WRTVRM - Writes data in VRAM
	ld a,(de)			;6a86
	cp 080h		;6a87
	ld a,004h		;6a89
	jr nc,GASOLINA_PINTA_2		;6a8b
	ld a,007h		;6a8d
GASOLINA_PINTA_2:
	ld hl,03b03h		;6a8f
	jp 0004dh		;6a92   ; BIOS WRTVRM - Writes data in VRAM
INSTALA_GASOLINA:		; Coloca los sprites de la aguja de gasolina
	ld bc,00008h		;6a95
	ld de,06aa1h		;6a98
	ld hl,03b00h		;6a9b
	jp VUELCA_A_VRAM		;6a9e

; ----------------------------------------------------------------------
; DATOS sprites_gasolina: Dos sprites de la aguja de gasolina
;   0x6aa1..0x6aa9  (8 bytes)
DATA_sprites_gasolina:
	defb 007h,0b8h,0c0h,004h	; 6aa1
	defb 007h,0a8h,0c0h,004h	; 6aa5

; ======================================================================
; CODIGO 0x6aa9..0x6b0a  (97 bytes)
; ======================================================================


AVISA_GASOLINA:		; Cuando queda poca, parpadea y suena el aviso
	ld a,(0e065h)		;6aa9   ; con poca gasolina, parpadea y avisa
	cp 018h		;6aac
	ret nc			;6aae
	cp 00ch		;6aaf
	ld bc,0100fh		;6ab1
	jr nc,AVISA_GASOLINA_1		;6ab4
	ld bc,00807h		;6ab6
AVISA_GASOLINA_1:
	ld a,(0e003h)		;6ab9   ; marca el ritmo del parpadeo de aviso
	ld e,a			;6abc
	and c			;6abd   ; el patron de bits marca el ritmo del parpadeo
	ret nz			;6abe
	ld a,00ah		;6abf
	call ARRANCA_SONIDO		;6ac1
	ld hl,04c72h		;6ac4
	ld a,e			;6ac7
	and b			;6ac8
	jp z,VUELCA_GUION		;6ac9
	jp VUELCA_GUION_INV		;6acc
CAMBIA_MARCHA:		; Sube o baja de marcha (0xE086) segun la velocidad
	ld hl,0e086h		;6acf   ; sube o baja de marcha segun la velocidad
	ld a,(hl)			;6ad2
	dec hl			;6ad3   ; compara con el umbral de la marcha
	or a			;6ad4
	ld a,(hl)			;6ad5
	jr nz,MARCHA_BAJA		;6ad6
	sub 050h		;6ad8
	sub 040h		;6ada
	ret nc			;6adc
	ld a,(0e009h)		;6add
	and 010h		;6ae0
	ret z			;6ae2
	ld a,001h		;6ae3
	jr MARCHA_PINTA		;6ae5
MARCHA_BAJA:
	sub 050h		;6ae7
	ret nc			;6ae9
	ld a,000h		;6aea
MARCHA_PINTA:
	inc hl			;6aec   ; pinta el indicador de la marcha
	ld (hl),a			;6aed
	ld hl,03b0ah		;6aee
	ld a,(0e086h)		;6af1
	or a			;6af4
	ld a,0c4h		;6af5
	jr z,MARCHA_ESCRIBE		;6af7
	ld a,0c8h		;6af9
MARCHA_ESCRIBE:
	jp 0004dh		;6afb   ; BIOS WRTVRM - Writes data in VRAM
INSTALA_MARCHA:		; Coloca los sprites del indicador de marcha
	ld de,06b0ah		;6afe
	ld hl,03b08h		;6b01
	ld bc,00004h		;6b04
	jp VUELCA_A_VRAM		;6b07

; ----------------------------------------------------------------------
; DATOS sprites_marcha: Sprite del indicador de marcha
;   0x6b0a..0x6b0e  (4 bytes)
DATA_sprites_marcha:
	defb 009h,088h,0c4h,006h	; 6b0a

; ======================================================================
; CODIGO 0x6b0e..0x6b5a  (76 bytes)
; ======================================================================


AVANZA_RELOJ:		; Sube el reloj de tiempo (0xE068) en BCD
	ld a,(0e003h)		;6b0e   ; sube el reloj de tiempo en BCD
	and 00fh		;6b11
	ret nz			;6b13   ; solo sube cada 16 cuadros
	ld hl,0e068h		;6b14
	ld a,(hl)			;6b17   ; suma uno en BCD al reloj
	add a,001h		;6b18
	daa			;6b1a
	ld (hl),a			;6b1b
	cp 060h		;6b1c   ; al llegar a 0x60 (un minuto) reinicia
	jr c,RELOJ_PINTA		;6b1e
	ld (hl),000h		;6b20
	inc hl			;6b22
	ld a,(hl)			;6b23
	add a,001h		;6b24
	daa			;6b26
	ld (hl),a			;6b27
RELOJ_PINTA:
	ld de,0e069h		;6b28
	ld hl,0383ah		;6b2b
	call RELOJ_PINTA_6B32		;6b2e
	inc hl			;6b31
RELOJ_PINTA_6B32:
	ld b,001h		;6b32
	jp PINTA_MARCADOR_BUCLE		;6b34
RELOJ_PINTA_6B37:
	ld a,(0e003h)		;6b37
	rrca			;6b3a
	rrca			;6b3b
	rrca			;6b3c
	and 003h		;6b3d
	ld hl,06b5ah		;6b3f
	call HL_MAS_A		;6b42
	ld c,(hl)			;6b45
	ld hl,0e070h		;6b46
	ld a,(hl)			;6b49
	srl a		;6b4a
	add a,022h		;6b4c
	ld hl,03b0dh		;6b4e
	call 0004dh		;6b51   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;6b54
	inc hl			;6b55
	ld a,c			;6b56
	jp 0004dh		;6b57   ; BIOS WRTVRM - Writes data in VRAM

; ----------------------------------------------------------------------
; DATOS tabla_reloj: Cabecera del rotulo del reloj
;   0x6b5a..0x6b5e  (4 bytes)
DATA_tabla_reloj:
	defb 006h,008h,009h,008h	; 6b5a

; ======================================================================
; CODIGO 0x6b5e..0x6b79  (27 bytes)
; ======================================================================


ALGO_6B5E:		; Rutina auxiliar de dibujo del panel
	ld de,04c89h		;6b5e   ; dibuja una parte del panel
	call DESCOMPRIME_GUION		;6b61
	ld hl,0d000h		;6b64
	ld (0e070h),hl		;6b67
	call RIVALES_2_6BCF		;6b6a
	ld de,06b79h		;6b6d
	ld hl,03b0ch		;6b70
	ld bc,00004h		;6b73
	jp VUELCA_A_VRAM		;6b76

; ----------------------------------------------------------------------
; DATOS tabla_panel: Cabecera de un rotulo del panel
;   0x6b79..0x6b7d  (4 bytes)
DATA_tabla_panel:
	defb 0b8h,022h,0bch,008h	; 6b79

; ======================================================================
; CODIGO 0x6b7d..0x6c2e  (177 bytes)
; ======================================================================


COLOCA_RIVALES_VRAM:		; Escribe en la VRAM las X/Y de los tres rivales
	ld a,(0e000h)		;6b7d   ; escribe la posicion de los tres rivales en la VRAM
	cp 007h		;6b80
	ret nc			;6b82
	ld hl,0e090h		;6b83
	call COLOCA_RIVALES_VRAM_6B96		;6b86
	ld hl,0e093h		;6b89
	call COLOCA_RIVALES_VRAM_6B96		;6b8c
	ld hl,0e096h		;6b8f
	call COLOCA_RIVALES_VRAM_6B96		;6b92
	ret			;6b95
COLOCA_RIVALES_VRAM_6B96:
	ld a,(hl)			;6b96   ; recorre las fichas de los rivales
	ld e,a			;6b97
	inc hl			;6b98   ; avanza a la ficha del rival siguiente
	inc hl			;6b99
	or (hl)			;6b9a
	rla			;6b9b
	ret c			;6b9c
	ld bc,00000h		;6b9d
	ld a,017h		;6ba0
	cp (hl)			;6ba2
	jr nc,COLOCA_RIVALES_VRAM_6BA6		;6ba3
	inc c			;6ba5
COLOCA_RIVALES_VRAM_6BA6:
	cp e			;6ba6
	ld a,b			;6ba7
	jr nc,RIVALES_1		;6ba8
	inc a			;6baa
RIVALES_1:
	cp c			;6bab   ; coloca un rival en su casilla de la VRAM
	ret z			;6bac
	pop hl			;6bad
	ld hl,0e05ch		;6bae
	jr c,RIVALES_2		;6bb1
	jr nc,RIVALES_1_6BB5		;6bb3
RIVALES_1_6BB5:
	ld a,(hl)			;6bb5   ; avanza a la ficha del rival siguiente
	add a,001h		;6bb6
	daa			;6bb8
	ld (hl),a			;6bb9
	jr nc,RIVALES_2_6BCF		;6bba
	dec hl			;6bbc
	inc (hl)			;6bbd
	jr RIVALES_2_6BCF		;6bbe
RIVALES_2:
	ld a,(hl)			;6bc0   ; segunda pasada de colocacion de rivales
	sub 001h		;6bc1
	daa			;6bc3
	ld (hl),a			;6bc4
	jr nc,RIVALES_2_6BC9		;6bc5
	dec hl			;6bc7
	dec (hl)			;6bc8
RIVALES_2_6BC9:
	ld de,00250h		;6bc9
	call SUMA_PUNTOS		;6bcc
RIVALES_2_6BCF:
	ld hl,030d0h		;6bcf   ; ajusta la casilla del rival
	ld a,(0e05bh)		;6bd2
	call RIVALES_2_6BEA		;6bd5   ; recalcula la casilla del rival
	ld hl,030d8h		;6bd8
	ld a,(0e05ch)		;6bdb
	push af			;6bde
	rrca			;6bdf
	rrca			;6be0
	rrca			;6be1
	rrca			;6be2
	call RIVALES_2_6BEA		;6be3
	pop af			;6be6
	ld hl,030e0h		;6be7
RIVALES_2_6BEA:
	and 00fh		;6bea   ; cierra la colocacion del rival
	ld de,04defh		;6bec
	add a,a			;6bef
	add a,a			;6bf0
	add a,a			;6bf1
	call DE_MAS_A		;6bf2
	ld bc,00008h		;6bf5
	jp VUELCA_A_VRAM		;6bf8
ARRANCA_CRONO:		; Prepara el bloque del cronometro/resultado
	ld hl,04d4dh		;6bfb
	call VUELCA_GUION		;6bfe
	ld hl,038f4h		;6c01
	ld de,0e05ch		;6c04
ARRANCA_CRONO_6C07:
	call RELOJ_PINTA_6B32		;6c07   ; copia un tramo del guion del cronometro
	dec hl			;6c0a
	dec hl			;6c0b
	dec hl			;6c0c
	ld a,(de)			;6c0d
	inc a			;6c0e
	cp 001h		;6c0f
	jr z,ARRANCA_CRONO_6C15		;6c11
	add a,00fh		;6c13
ARRANCA_CRONO_6C15:
	call 0004dh		;6c15   ; BIOS WRTVRM - Writes data in VRAM
	ret			;6c18
ARRANCA_CRONO_6C19:
	ld hl,tabla_perspectiva_base		;6c19   ; arranca el bloque del cronometro
	ld a,(0e060h)		;6c1c
	call HL_MAS_A		;6c1f   ; suma el indice a la base del guion
	ld c,(hl)			;6c22
	ld hl,0e05eh		;6c23
	ld a,(hl)			;6c26
	sub c			;6c27
	daa			;6c28
	ld (hl),a			;6c29
	ret nc			;6c2a
	dec hl			;6c2b
	dec (hl)			;6c2c
tabla_perspectiva_base:
	ret			;6c2d

; ----------------------------------------------------------------------
; DATOS tabla_crono: Punteros del rotulo del cronometro
;   0x6c2e..0x6c3b  (13 bytes)
DATA_tabla_crono:
	defw 04030h,04040h,06050h,06060h,05050h,06060h	; 6c2e
	defb 080h	; 6c3a

; ======================================================================
; CODIGO 0x6c3b..0x6cd5  (154 bytes)
; ======================================================================


APARECEN_OBJETOS:		; Coloca los objetos y rivales del tramo por perspectiva
	ld hl,0e071h		;6c3b   ; coloca los objetos del tramo escalados por la distancia
	ld a,(hl)			;6c3e
	cp 007h		;6c3f   ; solo hay sitio para siete objetos a la vez
	ret nc			;6c41   ; si estan todos, no anade mas
	ld hl,06cd5h		;6c42   ; indexa las tablas de escalado por la posicion (0xE07C)
	ld de,0e07ch		;6c45   ; lee la posicion del tramo (0xE07C)
	ld a,(de)			;6c48
	ld c,a			;6c49
	call HL_MAS_A		;6c4a
	ld a,(0e073h)		;6c4d   ; solo aparece si el tramo coincide (0xE073)
	cp (hl)			;6c50
	ret nz			;6c51
	ex de,hl			;6c52
	inc (hl)			;6c53   ; marca el objeto como colocado
	ld a,c			;6c54
	cp 01ah		;6c55
	jp nc,OBJETOS_FIN		;6c57
	ld de,06d09h		;6c5a
	add a,a			;6c5d   ; dobla el indice para la tabla de posiciones (0x6D09)
	call DE_MAS_A		;6c5e
	ld hl,06cefh		;6c61
	ld b,001h		;6c64
	ld a,c			;6c66
	call HL_MAS_A		;6c67
	ld a,(hl)			;6c6a
	cp 0e0h		;6c6b   ; 0xE0 es una casilla vacia
	jr z,OBJETO_ESCALA		;6c6d
	rlca			;6c6f   ; los dos bits altos dan el ancho del objeto (1..3 sprites)
	rlca			;6c70
	and 003h		;6c71
	ld b,a			;6c73
	ld a,(hl)			;6c74
	and 03fh		;6c75
	add a,05eh		;6c77   ; el resto es el patron base
	ex af,af'			;6c79
	ld a,c			;6c7a
	ld c,0b4h		;6c7b
	cp 017h		;6c7d   ; segun el tipo, elige el color del objeto
	jr z,OBJETO_ESCALA		;6c7f
	ld c,0b0h		;6c81
	cp 004h		;6c83
	jr nc,OBJETO_ESCALA		;6c85
	ld c,0b8h		;6c87
OBJETO_ESCALA:
	ex de,hl			;6c89   ; escala el objeto segun su profundidad
	ld a,(hl)			;6c8a
	push af			;6c8b   ; guarda la Y escalada del objeto
	inc hl			;6c8c
	ld a,(hl)			;6c8d
	push af			;6c8e
	ld de,0e0e0h		;6c8f
	dec b			;6c92
	jr z,OBJETO_COLOCA		;6c93
	add a,010h		;6c95
	ld e,a			;6c97
	dec b			;6c98
	jr z,OBJETO_COLOCA		;6c99
	add a,010h		;6c9b
	ld d,a			;6c9d
OBJETO_COLOCA:
	push de			;6c9e   ; reparte las cuatro casillas del objeto
	ld d,e			;6c9f
	push de			;6ca0
	ex af,af'			;6ca1
	ld e,a			;6ca2
	ld hl,0e178h		;6ca3
	ld b,004h		;6ca6
OBJETO_BUCLE:
	dec hl			;6ca8   ; escribe los cuatro sprites del objeto
	ld (hl),00fh		;6ca9
	dec hl			;6cab   ; retrocede en la ficha del sprite
	ld (hl),c			;6cac
	dec hl			;6cad
	pop af			;6cae
	ld (hl),a			;6caf
	dec hl			;6cb0
	cp 0e0h		;6cb1
	jr z,OBJETO_ESCRIBE		;6cb3
	ld a,e			;6cb5
OBJETO_ESCRIBE:
	ld (hl),a			;6cb6
	djnz OBJETO_BUCLE		;6cb7
	ex de,hl			;6cb9
	ld hl,03b58h		;6cba   ; manda los cuatro sprites del objeto a 0x3B58
	ld bc,00010h		;6cbd
	call VUELCA_A_VRAM		;6cc0
OBJETOS_FIN:
	ld a,(0e07ch)		;6cc3
	cp 015h		;6cc6
	ret c			;6cc8
LEE_GUION_PISTA:		; Descomprime el siguiente trozo del guion de la pista
	ld de,(0e07eh)		;6cc9
	call DESCOMPRIME_GUION		;6ccd
	ld (0e07eh),de		;6cd0
	ret			;6cd4

; ----------------------------------------------------------------------
; DATOS tablas_perspectiva: Escalado por profundidad y patrones de los objetos
;   0x6cd5..0x6d74  (159 bytes)
DATA_tablas_perspectiva:
	defb 0bbh,0c7h,0d1h,0dah,0dfh,0e4h,0e8h,0ebh,0edh,0efh,0f0h,0f1h,0f2h,0f3h,0f4h,0f5h	; 6cd5  ................
	defb 0f6h,0f7h,0f8h,0f9h,0fah,0fbh,0fch,0fdh,0feh,0ffh,040h,041h,042h,043h,044h,045h	; 6ce5  ..........@ABCDE
	defb 046h,047h,048h,049h,04ah,04bh,04ch,04dh,08fh,091h,093h,096h,0d9h,0ddh,0e1h,0e6h	; 6cf5  FGHIJKLM........
	defb 0ebh,0f1h,0e0h,0e0h,0e0h,07ch,07dh,07bh,07eh,07ah,07fh,079h,0e0h,078h,079h,077h	; 6d05  .....|}{~z.y.xyw
	defb 07ah,076h,07bh,075h,07ch,074h,07dh,073h,07eh,072h,07eh,072h,07fh,071h,080h,070h	; 6d15  zv{u|t}s~r~r.q.p
	defb 082h,06eh,084h,06ch,086h,06ah,088h,068h,08bh,065h,08eh,061h,092h,05eh,097h,059h	; 6d25  .n.l.j.h.e.a.^.Y
	defb 09bh,055h,0a0h,050h,0e0h,0e0h,0e0h,0e0h,031h,03ah,002h,01eh,000h,031h,03ah,002h	; 6d35  .U.P....1:...1:.
	defb 0fdh,080h,051h,03ah,002h,01fh,000h,051h,03ah,002h,0fdh,080h,070h,03ah,004h,020h	; 6d45  ..Q:...Q:...p:. 
	defb 000h,070h,03ah,004h,021h,000h,070h,03ah,004h,0fdh,080h,089h,03ah,00eh,022h,000h	; 6d55  .p:.!.p:....:.".
	defb 089h,03ah,00eh,0fdh,080h,0c8h,03ah,010h,023h,000h,0c8h,03ah,010h,0fdh,000h	; 6d65  .:....:.#..:...

; ======================================================================
; CODIGO 0x6d74..0x6dc5  (81 bytes)
; ======================================================================


DIBUJA_HORIZONTE:		; Pinta la franja de horizonte segun el tipo de etapa
	ld hl,03860h		;6d74   ; pinta la franja del horizonte segun el tipo de etapa
	ld de,06dc5h		;6d77
	ld a,(0e061h)		;6d7a   ; el tipo de etapa (0xE061) elige el horizonte
	cp 001h		;6d7d
	jr z,HORIZONTE_RELLENA		;6d7f
	cp 008h		;6d81
	jr z,HORIZONTE_ETAPA12		;6d83
	call DESC_NOMBRES_ABRE		;6d85
	ld a,(0e061h)		;6d88
	cp 006h		;6d8b
	jr z,HORIZONTE_1		;6d8d
	cp 020h		;6d8f
	ret nz			;6d91
	ld de,06e0dh		;6d92
	jp PINTA_TIRA		;6d95
HORIZONTE_1:
	ld hl,03860h		;6d98
	ld de,06dfah		;6d9b
	jp DESC_NOMBRES_ABRE		;6d9e
HORIZONTE_RELLENA:
	ld bc,00280h		;6da1
	ld a,0fch		;6da4
	jp 00056h		;6da6   ; BIOS FILVRM - Fills VRAM with value
HORIZONTE_ETAPA12:
	call HORIZONTE_RELLENA		;6da9
	ld a,(0e060h)		;6dac
	cp 00ch		;6daf
	jp nz,ESCRIBE_ACUATICO		;6db1
	call HORIZONTE_RELLENA		;6db4
	ld hl,03860h		;6db7
	ld a,0fbh		;6dba
	ld bc,00120h		;6dbc
	call 00056h		;6dbf   ; BIOS FILVRM - Fills VRAM with value
	jp ESCRIBE_ACUATICO		;6dc2

; ----------------------------------------------------------------------
; DATOS tiras_horizonte: Tiras del horizonte y los rotulos laterales
;   0x6dc5..0x6e22  (93 bytes)
DATA_tiras_horizonte:
	defb 060h,0fch,070h,0fch,070h,0fch,060h,0ach,048h,0f6h,010h,0f5h,00fh,0f6h,001h,033h	; 6dc5  `.p.p.`.H......3
	defb 010h,0f5h,001h,044h,00ch,0f6h,082h,030h,059h,012h,0f5h,082h,067h,041h,009h,0f6h	; 6dd5  ...D...0Y...gA..
	defb 082h,031h,05ah,014h,0f5h,082h,068h,042h,007h,0f6h,082h,032h,05bh,016h,0f5h,082h	; 6de5  .1Z...hB...2[...
	defb 069h,043h,003h,0f6h,000h,020h,083h,020h,00dh,020h,084h,020h,084h,020h,085h,020h	; 6df5  iC... . . . . . 
	defb 0bah,020h,0bbh,020h,0bch,020h,0bdh,000h,069h,039h,0b3h,0b5h,00ch,0b3h,0b5h,013h	; 6e05  . . . ..i9......
	defb 0b3h,0b4h,0b6h,0b5h,0fch,0b3h,0b5h,00ch,0b3h,0b4h,0b6h,0b5h,000h	; 6e15  .............

; ======================================================================
; CODIGO 0x6e22..0x6e55  (51 bytes)
; ======================================================================


DIBUJA_ESCENARIO:		; Pinta el decorado lateral animado (0xE075)
	ld a,(0e061h)		;6e22   ; pinta el decorado lateral animado
	cp 001h		;6e25
	jr z,ESCENARIO_1		;6e27
	bit 3,a		;6e29
	jr nz,ESCENARIO_2		;6e2b
	ld hl,06e55h		;6e2d
	ld de,06e5eh		;6e30
ESCENARIO_INDEXA:
	ld a,(0e075h)		;6e33   ; indexa el guion del decorado por la fase
	ld b,000h		;6e36
	ld c,a			;6e38   ; suma la fase de animacion al puntero
	add hl,bc			;6e39
	ld a,(hl)			;6e3a
	cp 0ffh		;6e3b
	ret z			;6e3d
	ld c,a			;6e3e
	ex de,hl			;6e3f
	add hl,bc			;6e40
	ex de,hl			;6e41
	jp PINTA_TIRA		;6e42
ESCENARIO_1:
	ld hl,06f7eh		;6e45
	ld de,06f87h		;6e48
	jr ESCENARIO_INDEXA		;6e4b
ESCENARIO_2:
	ld hl,0703bh		;6e4d
	ld de,07044h		;6e50
	jr ESCENARIO_INDEXA		;6e53

; ----------------------------------------------------------------------
; DATOS escenario_lateral: Guiones del decorado lateral por tipo de etapa
;   0x6e55..0x707a  (549 bytes)
DATA_escenario_lateral:
	defb 000h,00bh,024h,054h,06fh,07ah,092h,0beh,0d9h,0aeh,039h,029h,02ah,02bh,02ch,0aeh	; 6e55  ..$Toz....9)*+,.
	defb 020h,02dh,0adh,000h,0aeh,039h,001h,005h,0ach,000h,01fh,0ach,03bh,044h,039h,03dh	; 6e65   -...9......;D9=
	defb 042h,032h,0afh,0afh,0b0h,0b0h,0b1h,0b1h,01fh,02eh,003h,0adh,000h,0ceh,039h,001h	; 6e75  B2............9.
	defb 00ch,0ach,000h,01eh,0ach,0ach,0ach,02fh,006h,041h,045h,03ah,03eh,033h,034h,035h	; 6e85  ......./.AE:>345
	defb 0b2h,0afh,0afh,0b0h,0b0h,0b1h,0b1h,018h,0f6h,0f6h,034h,00ah,0f5h,0f5h,037h,015h	; 6e95  ..........4...7.
	defb 0f6h,035h,006h,0f5h,005h,0f5h,0f5h,038h,014h,036h,007h,0f5h,000h,0b4h,039h,03fh	; 6ea5  .5.....8.6....9?
	defb 031h,01dh,02fh,048h,046h,07ah,07bh,01dh,029h,030h,006h,0adh,002h,001h,00ah,0ach	; 6eb5  1./HFz{.)0......
	defb 000h,01ah,0f5h,003h,0f5h,003h,0f6h,000h,0adh,039h,0aeh,051h,050h,04fh,04eh,023h	; 6ec5  .........9.QPON#
	defb 0adh,052h,000h,0adh,039h,001h,005h,0ach,000h,019h,0b1h,0b1h,0b0h,0b0h,0afh,0afh	; 6ed5  .R..9...........
	defb 057h,067h,062h,05eh,069h,060h,0ach,020h,00dh,053h,000h,0c6h,039h,001h,00ch,0ach	; 6ee5  Wgb^i`. .S..9...
	defb 000h,01ah,0b1h,0b1h,0b0h,0b0h,0afh,0afh,0b2h,05ah,059h,058h,063h,05fh,06ah,066h	; 6ef5  .........ZYXc_jf
	defb 010h,054h,0ach,0ach,0ach,019h,048h,0f5h,0f5h,00ah,045h,0f6h,0f6h,016h,049h,0f5h	; 6f05  .T....H...E...I.
	defb 0f5h,00ch,046h,0f6h,022h,047h,000h,0aah,039h,056h,064h,020h,087h,086h,06bh,06dh	; 6f15  ..F."G..9Vd ..km
	defb 054h,016h,001h,00ah,0ach,000h,00bh,0adh,005h,055h,04eh,019h,0f6h,003h,0f5h,003h	; 6f25  T........UN.....
	defb 0f5h,000h,0aah,039h,0ach,0ach,0ach,0ach,024h,025h,04ah,049h,0ach,0ach,0ach,0ach	; 6f35  ...9....$%JI....
	defb 020h,0ach,0ach,0ach,026h,027h,0adh,0adh,04ch,04bh,0ach,0ach,0ach,020h,0ach,0ach	; 6f45   ...&'..LK... ..
	defb 028h,004h,001h,004h,0adh,000h,005h,04dh,0ach,0ach,017h,030h,003h,001h,006h,0f5h	; 6f55  (......M...0....
	defb 000h,008h,041h,014h,031h,003h,001h,008h,0f5h,000h,00ah,042h,012h,032h,003h,0f5h	; 6f65  ..A.1......B.2..
	defb 005h,0f5h,004h,0f5h,003h,043h,019h,0f5h,000h,000h,009h,01ah,038h,04eh,057h,066h	; 6f75  .....C......8NWf
	defb 085h,09bh,08fh,039h,0c4h,0ach,0ach,020h,020h,0ach,000h,092h,039h,0ach,01dh,0c5h	; 6f85  ...9...  ...9...
	defb 0c6h,0c7h,0c7h,01fh,03bh,044h,039h,03dh,042h,021h,0ach,000h,073h,039h,0ach,0ach	; 6f95  ....;D9=B!..s9..
	defb 0ach,020h,0ach,0ach,0ach,01ch,0ach,0ach,0ach,01fh,001h,005h,0ach,000h,01fh,0ach	; 6fa5  . ..............
	defb 0ach,005h,041h,045h,03ah,03eh,018h,0ffh,09dh,06eh,090h,039h,0ach,0ach,020h,0cch	; 6fb5  ..AE:>...n.9.. .
	defb 0cdh,0ceh,0ach,03bh,0ach,022h,048h,046h,07ah,07bh,022h,0ach,01ch,0ffh,0c7h,06eh	; 6fc5  ...;."HFz{"....n
	defb 08eh,039h,0ach,0ach,0c4h,020h,01fh,0ach,000h,08dh,039h,0ach,020h,0c7h,0c7h,0c6h	; 6fd5  .9... ....9. ...
	defb 0c5h,020h,067h,062h,05eh,069h,060h,000h,06ah,039h,0ach,0ach,0ach,020h,0ach,0ach	; 6fe5  . gb^i`.j9... ..
	defb 0ach,023h,001h,004h,0ach,000h,020h,001h,005h,0ach,000h,01dh,063h,05fh,06ah,066h	; 6ff5  .#.... .....c_jf
	defb 007h,0ach,0ach,018h,0ffh,00bh,06fh,08eh,039h,0ach,0ach,01ch,0ach,060h,0ach,0ceh	; 7005  ......o.9....`..
	defb 0cdh,0cch,020h,087h,086h,06bh,06dh,021h,0ach,01eh,0ffh,031h,06fh,08eh,039h,05ah	; 7015  .. ..km!...1o.9Z
	defb 0ach,0ach,035h,01dh,001h,00ah,0ach,000h,01fh,001h,00ch,0ach,000h,020h,001h,00ch	; 7025  ..5.......... ..
	defb 0ach,000h,020h,0ffh,060h,06fh,000h,0ffh,006h,00fh,016h,0ffh,01ah,020h,027h,0cfh	; 7035  .. .`o....... '.
	defb 039h,0c7h,020h,0c7h,000h,0f0h,039h,0c7h,01fh,04ah,020h,020h,04ah,000h,0f4h,039h	; 7045  9. ...9..J  J..9
	defb 0c7h,01eh,04ah,04ah,000h,0cfh,039h,0c7h,000h,0efh,039h,0c7h,020h,04ah,000h,0ebh	; 7055  ..JJ..9...9. J..
	defb 039h,0c7h,021h,04ah,04ah,000h,0edh,039h,0c7h,0c7h,004h,0c7h,0c7h,01dh,04ah,003h	; 7065  9.!JJ..9......J.
	defb 04ah,020h,01fh,04ah,000h	; 7075

; ======================================================================
; CODIGO 0x707a..0x711e  (164 bytes)
; ======================================================================


SCROLL_CARRETERA:		; Desplaza las rayas de la carretera hacia el jugador
	ld a,(0e061h)		;707a   ; desplaza las rayas de la carretera hacia el jugador
	bit 5,a		;707d
	jp nz,DIBUJA_EYECATCH		;707f   ; la etapa acuatica va por otro camino
	rra			;7082
	ret c			;7083
	ld a,(0e075h)		;7084   ; con la fase 8 (parado) no scrollea
	cp 008h		;7087
	ret z			;7089
	ld hl,0e06ah		;708a
	dec (hl)			;708d   ; baja el contador del scroll
	ret nz			;708e
	and 003h		;708f
	cp 002h		;7091
	ld de,0719ch		;7093
	jr z,SCROLL_CARRETERA_709B		;7096
	ld de,07198h		;7098
SCROLL_CARRETERA_709B:
	ld a,(0e085h)		;709b   ; la velocidad decide cuanto se desplazan
	or a			;709e
	ret z			;709f   ; sin velocidad no desplaza
	rrca			;70a0
	rrca			;70a1
	rrca			;70a2
	rrca			;70a3
	and 00fh		;70a4
	call DE_MAS_A		;70a6
	ld a,(0e061h)		;70a9
	cp 008h		;70ac
	ld a,(de)			;70ae
	jr nz,SCROLL_1		;70af
	add a,a			;70b1
	inc a			;70b2
SCROLL_1:
	ld (hl),a			;70b3   ; guarda el patron desplazado
	ld a,(0e075h)		;70b4
	ld c,a			;70b7
	and 003h		;70b8
	cp 002h		;70ba
	jr z,SCROLL_2		;70bc
	inc (hl)			;70be
SCROLL_2:
	bit 2,c		;70bf   ; rota el buffer de la carretera
	ld bc,0002fh		;70c1
	jr nz,SCROLL_3		;70c4
	ld hl,0e181h		;70c6   ; rota el buffer de la carretera hacia un lado
	ld de,0e180h		;70c9
	ld a,(de)			;70cc
	ldir		;70cd
	ld (de),a			;70cf
	jr SCROLL_VUELCA		;70d0
SCROLL_3:
	ld hl,0e1aeh		;70d2
	ld de,0e1afh		;70d5
	ld a,(de)			;70d8
	lddr		;70d9
	ld (de),a			;70db
SCROLL_VUELCA:
	ld hl,03980h		;70dc
	ld de,0e180h		;70df
	ld bc,00020h		;70e2
	jp VUELCA_A_VRAM		;70e5
CARGA_CARRETERA:		; Copia el patron de carretera de la etapa a 0xE180
	ld a,(0e061h)		;70e8   ; copia el patron de carretera de la etapa
	rra			;70eb
	ret c			;70ec   ; fuera de las etapas con rayas, se va
	ld hl,0711ch		;70ed
	ld a,(0e060h)		;70f0
	add a,a			;70f3
	call HL_MAS_A		;70f4
	ld e,(hl)			;70f7
	inc hl			;70f8
	ld d,(hl)			;70f9
	ld hl,0e180h		;70fa
	ld b,018h		;70fd
CARGA_CARRETERA_BUCLE:
	ld a,(de)			;70ff   ; traduce cada nibble a un caracter de la VRAM
	inc de			;7100
	ld (hl),a			;7101
	xor a			;7102
	rrd		;7103
	cp 00fh		;7105
	ld c,0fch		;7107
	jr z,CARGA_CARRETERA_1		;7109
	add a,0b3h		;710b
	ld c,a			;710d
CARGA_CARRETERA_1:
	ld a,(hl)			;710e   ; y el segundo nibble de cada byte
	cp 00fh		;710f
	ld (hl),0fch		;7111
	jr z,CARGA_CARRETERA_1_7118		;7113
	add a,0b3h		;7115
	ld (hl),a			;7117
CARGA_CARRETERA_1_7118:
	inc hl			;7118
	ld (hl),c			;7119
	inc hl			;711a
	djnz CARGA_CARRETERA_BUCLE		;711b
	ret			;711d

; ----------------------------------------------------------------------
; DATOS patrones_carretera: Punteros y patrones de carretera por etapa
;   0x711e..0x71ac  (142 bytes)
DATA_patrones_carretera:
	defw 07138h,00000h,07150h,07150h,07168h,07138h,07138h,07150h	; 711e
	defw 07150h,00000h,00000h,07180h,07150h,03202h,03231h,01334h	; 712e
	defw 0ff45h,004ffh,0015fh,04134h,0ff35h,023f0h,01313h,03441h	; 713e
	defw 0ff45h,04401h,06035h,0f06fh,01460h,01435h,00256h,02535h	; 714e
	defw 01413h,02535h,04524h,02313h,05614h,0f0f0h,01300h,02312h	; 715e
	defw 02301h,0003fh,05fffh,06755h,07766h,08999h,04676h,08697h	; 716e
	defw 05f5fh,09994h,09938h,07092h,09969h,01599h,09327h,09989h	; 717e
	defw 09999h,09999h,02715h,09999h,09949h,00c0ch,00b0bh,00a0ah	; 718e
	defw 00909h,00808h,00707h,00606h,00505h,00405h,00404h	; 719e

; ======================================================================
; CODIGO 0x71ac..0x7215  (105 bytes)
; ======================================================================


SCROLL_ACUATICO:		; Anima la superficie de la etapa acuatica (0xE061=8)
	ld a,(0e061h)		;71ac   ; anima la superficie de la etapa acuatica
	cp 008h		;71af   ; solo en la etapa acuatica
	ret nz			;71b1   ; solo en la etapa acuatica (0xE061=8)
	ld a,(0e075h)		;71b2   ; el paso depende de la fase 0xE075
	cp 008h		;71b5
	ret z			;71b7
	ld hl,0e0aeh		;71b8   ; baja el contador del oleaje
	dec (hl)			;71bb
	ret nz			;71bc
	ld de,07215h		;71bd   ; indexa la tabla de fotogramas de la ola
	ld a,(0e085h)		;71c0
	or a			;71c3   ; sin velocidad, el agua no se mueve
	ret z			;71c4
	rlca			;71c5   ; la velocidad marca cuanto avanza la ola
	rlca			;71c6
	rlca			;71c7
	and 007h		;71c8
	call DE_MAS_A		;71ca
	ld a,(de)			;71cd
	ld (hl),a			;71ce   ; guarda el fotograma en la ficha
	inc hl			;71cf
	inc (hl)			;71d0
	ld a,(0e075h)		;71d1
	ld c,a			;71d4
	bit 2,a		;71d5   ; el bit 2 de la fase alterna el sentido
	jr nz,ACUATICO_1		;71d7
	dec (hl)			;71d9
	dec (hl)			;71da
ACUATICO_1:
	bit 3,(hl)		;71db   ; cierra el ciclo de la animacion acuatica
	jp z,ESCRIBE_ACUATICO		;71dd
	ld a,(hl)			;71e0
	and 007h		;71e1
	ld (hl),a			;71e3
	ld a,0fbh		;71e4
	call ESCRIBE_SPRITES_16		;71e6
	ld b,010h		;71e9
	ld hl,0e0b0h		;71eb
ACUATICO_BUCLE:
	ld e,(hl)			;71ee   ; recorre los sprites de la ola
	inc hl			;71ef
	ld d,(hl)			;71f0
	inc de			;71f1
	bit 2,c		;71f2
	jr nz,ACUATICO_BUCLE_71F8		;71f4
	dec de			;71f6
	dec de			;71f7
ACUATICO_BUCLE_71F8:
	ld (hl),d			;71f8   ; escribe la ola desplazada
	dec hl			;71f9
	ld (hl),e			;71fa
	inc hl			;71fb
	inc hl			;71fc
	djnz ACUATICO_BUCLE		;71fd
ESCRIBE_ACUATICO:
	ld a,(0e0afh)		;71ff
	add a,0f3h		;7202
ESCRIBE_SPRITES_16:
	ld b,010h		;7204
	ld hl,0e0b0h		;7206
ESCRIBE_SPRITES_BUCLE:
	ld e,(hl)			;7209
	inc hl			;720a
	ld d,(hl)			;720b
	inc hl			;720c
	ex de,hl			;720d
	call 0004dh		;720e   ; BIOS WRTVRM - Writes data in VRAM
	ex de,hl			;7211
	djnz ESCRIBE_SPRITES_BUCLE		;7212
	ret			;7214

; ----------------------------------------------------------------------
; DATOS tabla_acuatico: Patrones de la animacion acuatica
;   0x7215..0x721d  (8 bytes)
DATA_tabla_acuatico:
	defb 011h,010h,00fh,00eh,00dh,00ch,00bh,00ah	; 7215  ........

; ======================================================================
; CODIGO 0x721d..0x7229  (12 bytes)
; ======================================================================


INSTALA_ACUATICO:		; Copia la tabla de sprites acuaticos a 0xE0AE
	ld hl,07229h		;721d
	ld de,0e0aeh		;7220
	ld bc,00022h		;7223
	ldir		;7226
	ret			;7228

; ----------------------------------------------------------------------
; DATOS punteros_sprites_rival: Punteros de patron de los rivales/objetos
;   0x7229..0x724b  (34 bytes)
DATA_punteros_sprites_rival:
	defw 00401h,03884h,0388fh,03895h,03897h,038aah,038b4h,038bdh	; 7229
	defw 038c7h,038c9h,038d9h,038e1h,038eah,0390dh,03917h,03927h	; 7239
	defw 03930h	; 7249

; ======================================================================
; CODIGO 0x724b..0x72d2  (135 bytes)
; ======================================================================


FUEGOS_META:		; Fuegos artificiales al llegar a meta (0xE061=0x10)
	ld a,(0e061h)		;724b   ; fuegos artificiales al llegar a meta
	cp 010h		;724e
	ret nz			;7250   ; espera a que pase el aviso de meta
	ld hl,0e0a9h		;7251   ; contador de la secuencia de meta (0xE0A9)
	ld a,(hl)			;7254
	or a			;7255
	jp z,GIRA_ROTULO_META		;7256
	dec a			;7259
	ld (hl),a			;725a
	jp z,FUEGOS_3		;725b
	cp 001h		;725e
	jp z,FUEGOS_2		;7260
	cp 007h		;7263
	ret nz			;7265
	ld a,(0e070h)		;7266
	sub 008h		;7269
	cp 0c4h		;726b
	jr nc,FUEGOS_1		;726d
	ld a,043h		;726f
	call ARRANCA_SONIDO		;7271
	ld b,0efh		;7274
	call FIJA_BORDE		;7276
	ld de,(0e0aah)		;7279
	ld hl,(0e0ach)		;727d
	jp PINTA_ROTULO		;7280
FUEGOS_1:
	xor a			;7283
	ld (0e0a9h),a		;7284
	jr FUEGOS_COLOR		;7287
FUEGOS_2:
	ld b,0eeh		;7289
	call FIJA_BORDE		;728b
FUEGOS_COLOR:
	ld a,r		;728e   ; da un color aleatorio a los fuegos
	and 003h		;7290
	rrca			;7292
	rrca			;7293
	rrca			;7294
	add a,018h		;7295
	ld (0e0a8h),a		;7297
	ret			;729a
FUEGOS_3:
	ld de,(0e0aah)		;729b
	ld hl,(0e0ach)		;729f
	jp 0e1c0h		;72a2
GIRA_ROTULO_META:		; Rota los rotulos que se muestran en la meta
	dec hl			;72a5   ; rota el rotulo que se ensena en la meta
	dec (hl)			;72a6
	ret nz			;72a7   ; baja el contador del giro de rotulo
	inc hl			;72a8   ; rearma el contador a ocho
	ld (hl),008h		;72a9
	ld hl,072d2h		;72ab
	ld a,r		;72ae
	and 003h		;72b0
	add a,a			;72b2
	call HL_MAS_A		;72b3
	ld e,(hl)			;72b6
	inc hl			;72b7
	ld d,(hl)			;72b8
	ld (0e0aah),de		;72b9
	ld hl,03846h		;72bd
	ld a,(0e003h)		;72c0
	and 00fh		;72c3
	ld c,a			;72c5
	ld a,r		;72c6
	and 003h		;72c8
	add a,c			;72ca
	call HL_MAS_A		;72cb
	ld (0e0ach),hl		;72ce
	ret			;72d1

; ----------------------------------------------------------------------
; DATOS guiones_meta: Punteros y guiones de los rotulos de la meta
;   0x72d2..0x731d  (75 bytes)
DATA_guiones_meta:
	defb 0f5h,072h,0dah,072h,0f5h,072h,00ch,073h,08ch,086h,088h,01fh,08ch,001h,08eh,01fh	; 72d2  .r.r.r.s........
	defb 089h,001h,08bh,001h,08ah,0c2h,001h,0bbh,01fh,0c3h,001h,0c5h,001h,0bfh,0c1h,001h	; 72e2  ................
	defb 0c4h,0bch,000h,08ah,08ch,001h,08dh,021h,087h,001h,08eh,021h,08dh,08fh,001h,08eh	; 72f2  .......!...!....
	defb 0bfh,001h,0beh,021h,0bah,0bch,001h,0beh,0bah,000h,08ch,08fh,01fh,089h,001h,088h	; 7302  ...!............
	defb 08ch,001h,08eh,086h,0bah,0c1h,001h,0c0h,0bdh,0bah,000h	; 7312  ...........

; ======================================================================
; CODIGO 0x731d..0x7351  (52 bytes)
; ======================================================================


DIBUJA_EYECATCH:		; Compone una imagen simetrica espejando cada fila
	ld hl,07371h		;731d   ; compone la imagen espejando cada fila
	ld de,0e06bh		;7320
	ld a,(de)			;7323   ; lee el byte de la fila a espejar
	call HL_MAS_A		;7324
	ld a,(0e071h)		;7327
	cp (hl)			;732a
	ret nz			;732b
	ld a,(de)			;732c
	inc a			;732d
	ld (de),a			;732e
	ld de,07351h		;732f
	call DE_MAS_A		;7332
	ld bc,00010h		;7335
	push de			;7338
	ld hl,02d98h		;7339   ; vuelca la mitad izquierda
	call VUELCA_A_VRAM		;733c
	pop de			;733f
	ld hl,02da8h		;7340   ; y la derecha, espejada
	ld b,010h		;7343
EYECATCH_BUCLE:
	ld a,(de)			;7345
	call INVIERTE_BITS		;7346   ; espeja la fila con INVIERTE_BITS para la mitad derecha
	call 0004dh		;7349   ; BIOS WRTVRM - Writes data in VRAM
	inc de			;734c
	inc hl			;734d
	djnz EYECATCH_BUCLE		;734e
	ret			;7350

; ----------------------------------------------------------------------
; DATOS tablas_carretera: Datos del eyecatch y tablas de forma de la carretera
;   0x7351..0x767c  (811 bytes)
DATA_tablas_carretera:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 7351  ................
	defb 001h,003h,007h,00fh,01fh,03fh,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7361  .....?..........
	defb 034h,02ch,026h,020h,01ch,018h,014h,010h,00eh,00ch,00ah,008h,007h,006h,005h,004h	; 7371  4,& ............
	defb 0ffh,00ah,000h,018h,002h,022h,010h,01ah,026h,006h,024h,02ah,004h,014h,0a8h,030h	; 7381  ....."..&.$*...0
	defb 088h,070h,098h,018h,088h,058h,088h,038h,0a0h,060h,088h,028h,0a0h,028h,088h,048h	; 7391  .p...X.8.`.(.(.H
	defb 098h,020h,098h,058h,098h,038h,0a8h,010h,088h,058h,088h,058h,088h,060h,088h,020h	; 73a1  . .X.8...X.X.`. 
	defb 098h,070h,098h,038h,088h,060h,0a0h,018h,0a8h,078h,088h,028h,0a0h,058h,088h,010h	; 73b1  .p.8.`...x.(.X..
	defb 098h,058h,088h,058h,0bch,0bch,03dh,039h,027h,024h,01ah,02ch,0ach,02ah,0ach,0ach	; 73c1  .X.X..=9'$.,.*..
	defb 0ach,028h,025h,01fh,0ach,02dh,0ach,02bh,0ach,0ach,0ach,029h,026h,000h,021h,039h	; 73d1  .(%..-.+...)&.!9
	defb 049h,04ch,020h,04ah,04dh,0ach,0ach,0ach,04fh,0ach,051h,020h,04bh,04eh,0ach,0ach	; 73e1  IL JM...O.Q KN..
	defb 0ach,050h,0ach,052h,0ach,000h,03dh,039h,0ach,0ach,01ah,0ach,0aeh,0ach,0ach,0c2h	; 73f1  .P.R..=9........
	defb 0ach,0ach,0ach,01fh,0b0h,0ach,0afh,0ach,0ach,0c3h,0ach,0ach,0ach,000h,021h,039h	; 7401  ..............!9
	defb 0ach,0ach,020h,0ach,0ach,0ach,0c2h,0ach,0ach,0b8h,0ach,020h,0ach,0ach,0ach,0c3h	; 7411  .. ........ ....
	defb 0ach,0ach,0b9h,0ach,0bah,000h,073h,039h,032h,030h,02eh,01fh,034h,033h,031h,02fh	; 7421  ......s920..431/
	defb 000h,06ah,039h,053h,055h,057h,020h,054h,056h,058h,059h,000h,073h,039h,0b5h,0b3h	; 7431  .j9SUW TVXY.s9..
	defb 0b1h,01fh,0b7h,0b6h,0b4h,0b2h,000h,06ah,039h,0bbh,0bdh,0bfh,020h,0bch,0beh,0c0h	; 7441  .......j9... ...
	defb 0c1h,000h,073h,039h,032h,030h,02eh,020h,033h,031h,02fh,000h,06ah,039h,053h,055h	; 7451  ..s920. 31/.j9SU
	defb 057h,020h,054h,056h,058h,000h,073h,039h,0b5h,0b3h,0b1h,020h,0b6h,0b4h,0b2h,000h	; 7461  W TVX.s9... ....
	defb 06ah,039h,0bbh,0bdh,0bfh,020h,0bch,0beh,0c0h,000h,073h,039h,0d2h,0d0h,0cfh,01bh	; 7471  j9... ....s9....
	defb 0bfh,0d7h,0d6h,0d5h,0d4h,0d3h,0d1h,0bch,01ch,0dbh,0dah,0d9h,0d8h,000h,06ah,039h	; 7481  ..............j9
	defb 0cfh,0d0h,0d2h,020h,0b2h,0d1h,0d3h,0d4h,0d5h,0d6h,0d7h,0b5h,020h,008h,0d8h,0d9h	; 7491  ... ........ ...
	defb 0dah,0dbh,000h,073h,039h,0deh,0ach,0dch,01bh,0e4h,0e3h,0e2h,0e1h,0e0h,0dfh,0ach	; 74a1  ...s9...........
	defb 0ddh,01ch,0e8h,0e7h,0e6h,0e5h,000h,06ah,039h,0dch,0ach,0deh,020h,0ddh,0ach,0dfh	; 74b1  .......j9... ...
	defb 0e0h,0e1h,0e2h,0e3h,0e4h,020h,008h,0e5h,0e6h,0e7h,0e8h,000h,090h,039h,0c9h,0c8h	; 74c1  ..... .......9..
	defb 000h,08eh,039h,0c8h,0c9h,000h,090h,039h,0cbh,0cah,000h,08eh,039h,0cah,0cbh,000h	; 74d1  ..9....9....9...
	defb 032h,074h,027h,074h,048h,074h,03dh,074h,032h,074h,053h,074h,048h,074h,067h,074h	; 74e1  2t'tHt=t2tStHtgt
	defb 08fh,074h,000h,000h,0b8h,074h,000h,000h,032h,074h,0d2h,074h,048h,074h,0dch,074h	; 74f1  .t...t..2t.tHt.t
	defb 032h,074h,027h,074h,048h,074h,03dh,074h,05dh,074h,027h,074h,071h,074h,03dh,074h	; 7501  2t'tHt=t]t'tqt=t
	defb 07bh,074h,000h,000h,0a4h,074h,000h,000h,0cdh,074h,027h,074h,0d7h,074h,03dh,074h	; 7511  {t...t...t't.t=t
	defb 000h,004h,008h,00ch,010h,015h,01ah,01fh,024h,038h,04bh,05dh,070h,07ah,084h,08bh	; 7521  ........$8K]pz..
	defb 000h,004h,008h,00ch,010h,022h,033h,043h,054h,05fh,06ah,073h,07eh,088h,092h,09ch	; 7531  ....."3CT_js~...
	defb 0a8h,030h,056h,076h,0a9h,030h,060h,076h,0aah,030h,06ah,076h,0abh,030h,074h,076h	; 7541  .0Vv.0`v.0jv.0tv
	defb 07eh,01fh,030h,056h,076h,07fh,01fh,030h,060h,076h,080h,01fh,030h,06ah,076h,081h	; 7551  ~.0Vv..0`v..0jv.
	defb 01fh,030h,074h,076h,038h,01dh,07ah,001h,0e2h,001h,07dh,01fh,0f5h,001h,0ceh,0d4h	; 7561  .0tv8.z...}.....
	defb 01fh,0d9h,001h,0cdh,0f5h,0f4h,0f4h,000h,03ah,01dh,0f5h,001h,0e3h,001h,07eh,01fh	; 7571  ........:.....~.
	defb 0cbh,001h,0d2h,0cch,01fh,0aeh,001h,0d5h,0f5h,0f5h,000h,038h,01eh,0e4h,001h,07fh	; 7581  ...........8....
	defb 01eh,0d3h,001h,0cah,0f5h,01fh,0a1h,001h,0d1h,0efh,0f5h,0f5h,000h,03ah,01dh,07ah	; 7591  .............:.z
	defb 001h,0e5h,001h,080h,01fh,0cfh,001h,0f5h,0d0h,01fh,0f5h,001h,0f5h,0f4h,0f4h,000h	; 75a1  ................
	defb 095h,001h,082h,01fh,07ah,001h,07bh,030h,06ch,075h,099h,001h,083h,01fh,0f5h,001h	; 75b1  ....z.{0lu......
	defb 07ch,030h,080h,075h,095h,001h,084h,0a2h,030h,091h,075h,099h,001h,085h,01fh,07ah	; 75c1  |0.u....0.u....z
	defb 001h,0afh,030h,0a5h,075h,08ah,030h,056h,076h,08bh,030h,060h,076h,08ch,030h,06ah	; 75d1  ..0.u.0Vv.0`v.0j
	defb 076h,08dh,030h,074h,076h,05dh,021h,091h,001h,0e6h,001h,08eh,022h,0dah,001h,0f5h	; 75e1  v.0tv]!....."...
	defb 021h,0e0h,0f2h,0f5h,0f4h,0f4h,000h,05fh,021h,092h,001h,0e7h,001h,0f5h,022h,0deh	; 75f1  !......_!.....".
	defb 001h,0d7h,021h,0d8h,0efh,0f5h,0f5h,000h,05dh,021h,093h,001h,0e8h,022h,0d6h,001h	; 7601  ..!.....]!..."..
	defb 0dfh,021h,0f5h,0f3h,0f4h,0f5h,0f5h,000h,05fh,021h,094h,001h,0e9h,001h,08eh,022h	; 7611  .!......_!....."
	defb 0f5h,001h,0dbh,021h,0dch,0f5h,0f4h,0f4h,000h,08eh,001h,09dh,021h,08fh,001h,08eh	; 7621  ...!........!...
	defb 021h,030h,0eeh,075h,08fh,001h,0a1h,021h,090h,001h,0f5h,021h,030h,000h,076h,090h	; 7631  !0.u...!...!0.v.
	defb 001h,09dh,021h,0bch,021h,030h,00fh,076h,091h,001h,0a1h,021h,0c9h,001h,08eh,021h	; 7641  ..!.!0.v...!...!
	defb 030h,021h,076h,0a2h,0a3h,0ech,0f5h,0efh,0f2h,0f5h,0f4h,0f4h,000h,0a5h,0a4h,0eah	; 7651  0!v.............
	defb 0edh,0f1h,0efh,0f5h,0f5h,0f4h,000h,0a2h,0a6h,0d9h,0efh,0f5h,0f3h,0f4h,0f5h,0f5h	; 7661  ................
	defb 000h,0a5h,0a7h,0ebh,0eeh,0f0h,0f5h,0f4h,0f4h,0f5h,000h	; 7671  ...........

; ----------------------------------------------------------------------
; DATOS graficos_carretera: Formas de carretera, bordes y patrones de sprite
;   0x767c..0x796c  (752 bytes)
DATA_graficos_carretera:
	defb 0a0h,076h,0d0h,076h,000h,077h,00bh,077h,016h,077h,032h,077h,04eh,077h,06bh,077h	; 767c  .v.v.w.w.w2wNwkw
	defb 0a0h,076h,0d0h,076h,088h,077h,093h,077h,09eh,077h,0bah,077h,0d6h,077h,0f3h,077h	; 768c  .v.v.w.w.w.w.w.w
	defb 0a0h,076h,0d0h,076h,0edh,039h,06eh,005h,074h,019h,052h,096h,008h,0b0h,060h,017h	; 769c  .v.v.9n.t.R...`.
	defb 053h,0a4h,00ah,0beh,061h,015h,054h,098h,00ch,0b2h,062h,013h,05ch,099h,00eh,0b3h	; 76ac  S...a.T...b.\...
	defb 06ah,011h,06eh,06fh,010h,083h,082h,00fh,0f5h,0f5h,012h,0f5h,0f5h,00dh,072h,073h	; 76bc  j.no..........rs
	defb 014h,087h,086h,000h,0edh,039h,071h,005h,077h,019h,059h,0a3h,008h,0bdh,067h,017h	; 76cc  .....9q.w.Y...g.
	defb 05ah,097h,00ah,0b1h,068h,015h,05bh,0a5h,00ch,0bfh,069h,013h,055h,0a6h,00eh,0c0h	; 76dc  Z...h.[...i.U...
	defb 063h,011h,0f5h,0f5h,010h,0f5h,0f5h,00fh,070h,071h,012h,085h,084h,00dh,0f5h,0f5h	; 76ec  c.......pq......
	defb 014h,0f5h,0f5h,000h,0edh,039h,06fh,07ch,005h,092h,070h,019h,0ffh,0a6h,076h,0edh	; 76fc  .....9o|..p...v.
	defb 039h,072h,07dh,005h,096h,073h,019h,0ffh,0d6h,076h,0f0h,039h,043h,03ch,01dh,03ah	; 770c  9r}..s...v.9C<.:
	defb 03ch,075h,077h,008h,09bh,016h,03eh,078h,0f5h,00ah,09ch,014h,056h,09ah,074h,00ch	; 771c  <uw...>x....V.t.
	defb 0aah,05fh,013h,0ffh,0b8h,076h,0f0h,039h,047h,040h,01dh,03bh,03dh,076h,081h,008h	; 772c  ._...v.9G@.;=v..
	defb 0a8h,016h,03fh,079h,074h,00ah,0a9h,014h,05dh,0a7h,0f5h,00ch,09dh,058h,013h,0ffh	; 773c  ..?yt...]....X..
	defb 0e8h,076h,0f0h,039h,036h,093h,005h,094h,018h,040h,057h,0abh,008h,0ach,016h,03eh	; 774c  .v.96....@W....>
	defb 078h,0f5h,00ah,0adh,014h,056h,09ah,074h,00ch,0aah,05fh,013h,0ffh,0b8h,076h,0f0h	; 775c  x....V.t.._...v.
	defb 039h,037h,097h,005h,098h,018h,039h,05eh,09eh,008h,09fh,016h,03fh,079h,074h,00ah	; 776c  97....9^....?yt.
	defb 0a0h,014h,05dh,0a7h,0f5h,00ch,09dh,058h,013h,0ffh,0e8h,076h,0ech,039h,076h,09ah	; 777c  ..]....X...v.9v.
	defb 005h,088h,075h,01ah,0ffh,0a6h,076h,0ech,039h,079h,09eh,005h,089h,078h,01ah,0ffh	; 778c  ..u...v.9y...x..
	defb 0d6h,076h,0eeh,039h,061h,068h,01ch,0b5h,005h,08bh,089h,04dh,04bh,01bh,0b6h,008h	; 779c  .v.9ah.....MK...
	defb 0f5h,08ch,04fh,017h,06dh,0c4h,00bh,088h,0b4h,064h,014h,0ffh,0b8h,076h,0eeh,039h	; 77ac  ..O.m....d...v.9
	defb 065h,06ch,01ch,0c2h,005h,095h,08ah,04eh,04ch,01bh,0c3h,008h,088h,08dh,050h,017h	; 77bc  el.....NL.....P.
	defb 066h,0b7h,00bh,0f5h,0c1h,06bh,014h,0ffh,0e8h,076h,0eah,039h,09ch,004h,09bh,05bh	; 77cc  f....k...v.9...[
	defb 01ch,0c6h,006h,0c5h,065h,051h,01ah,0c7h,008h,0f5h,08ch,04fh,017h,06dh,0c4h,00bh	; 77dc  ....eQ.....O.m..
	defb 088h,0b4h,064h,014h,0ffh,0b8h,076h,0eah,039h,0a0h,004h,09fh,05ch,01ch,0b9h,006h	; 77ec  ..d...v.9...\...
	defb 0b8h,06ch,04ah,01ah,0bah,008h,088h,08dh,050h,017h,066h,0b7h,00bh,0f5h,0c1h,06bh	; 77fc  .lJ.....P.f....k
	defb 014h,0ffh,0e8h,076h,000h,005h,00ah,00fh,014h,019h,01eh,023h,028h,038h,045h,055h	; 780c  ...v.......#(8EU
	defb 065h,071h,07ch,085h,000h,004h,008h,00ch,010h,014h,018h,01ch,020h,02eh,03bh,04ah	; 781c  eq|......... .;J
	defb 057h,060h,06bh,076h,081h,08bh,095h,09fh,0c8h,01fh,030h,046h,079h,0c9h,01fh,030h	; 782c  W`kv......0Fy..0
	defb 050h,079h,0cah,01fh,030h,05ah,079h,0cbh,01fh,030h,064h,079h,0cch,01fh,030h,046h	; 783c  Py..0Zy..0dy..0F
	defb 079h,0cdh,01fh,030h,050h,079h,0ceh,01fh,030h,05ah,079h,0cfh,01fh,030h,064h,079h	; 784c  y..0Py..0Zy..0dy
	defb 0d0h,01dh,04ah,001h,067h,001h,056h,04eh,01fh,059h,01fh,04ah,04ah,04ah,04ah,000h	; 785c  ..J.g.VN.Y.JJJJ.
	defb 0d1h,01eh,069h,001h,057h,01eh,050h,001h,04fh,04ah,01fh,044h,000h,0d0h,01dh,051h	; 786c  ..i.W.P.OJ.D...Q
	defb 001h,06bh,001h,056h,01fh,052h,001h,04ah,01fh,04ah,04ah,048h,000h,0d1h,01dh,053h	; 787c  .k.V.R.J.JJH...S
	defb 001h,06dh,001h,057h,01fh,04ah,04ch,01fh,04ah,04ah,04ah,049h,000h,0d2h,001h,0cah	; 788c  .m.W.JL.JJJI....
	defb 020h,068h,01fh,04ah,001h,054h,030h,065h,078h,0d3h,001h,0d4h,06ah,01fh,055h,001h	; 789c   h.J.T0ex...j.U.
	defb 04ah,030h,075h,078h,0d2h,001h,0cah,06ch,01fh,058h,030h,084h,078h,0d3h,001h,0d4h	; 78ac  J0ux...l.X0.x...
	defb 06eh,01fh,04ah,04dh,030h,093h,078h,0d5h,030h,046h,079h,0d6h,030h,050h,079h,0d7h	; 78bc  n.JM0.x.0Fy.0Py.
	defb 030h,05ah,079h,0d8h,030h,064h,079h,0d9h,030h,046h,079h,0dah,030h,050h,079h,0dbh	; 78cc  0Zy.0dy.0Fy.0Py.
	defb 030h,05ah,079h,0dch,030h,064h,079h,0ddh,021h,064h,001h,06fh,001h,04ah,022h,05ch	; 78dc  0Zy.0dy.!d.o.J"\
	defb 021h,04bh,030h,067h,078h,0deh,021h,065h,001h,071h,022h,05dh,001h,05eh,021h,04ah	; 78ec  !K0gx.!e.q"].^!J
	defb 044h,000h,0ddh,021h,064h,001h,073h,001h,05fh,022h,04ah,001h,060h,021h,030h,085h	; 78fc  D..!d.s._"J.`!0.
	defb 078h,0deh,021h,065h,001h,075h,001h,061h,023h,04ah,05ah,030h,094h,078h,0d7h,001h	; 790c  x.!e.u.a#JZ0.x..
	defb 0dfh,021h,070h,062h,030h,0ech,078h,0e1h,001h,0e0h,021h,072h,04ah,001h,063h,030h	; 791c  .!pb0.x...!rJ.c0
	defb 0fah,078h,0d7h,001h,0dfh,021h,074h,021h,066h,04ah,030h,085h,078h,0e1h,001h,0e0h	; 792c  .x...!t!fJ0.x...
	defb 021h,076h,021h,04ah,05bh,030h,094h,078h,0c0h,0c1h,04bh,04ah,04ah,040h,04ah,04ah	; 793c  !v!J[0.x..KJJ@JJ
	defb 04ah,000h,0c2h,0c3h,04ah,041h,04ah,047h,04ah,04ah,04ah,000h,0c4h,0c5h,040h,045h	; 794c  J...JAJGJJJ...@E
	defb 04ah,04ah,048h,04ah,04ah,000h,0c0h,0c6h,043h,04ah,042h,04ah,04ah,04ah,046h,000h	; 795c  JJHJJ...CJBJJJF.

; ======================================================================
; CODIGO 0x796c..0x7b11  (421 bytes)
; ======================================================================


AGITA_RIVALES:		; Da un empujon aleatorio a los rivales y los actualiza
	ld hl,0e099h		;796c
	ld a,(hl)			;796f
	add a,055h		;7970
	ld (hl),a			;7972
	ret nc			;7973
ACTUALIZA_RIVALES:		; Mueve y dibuja los tres coches rivales; mira choques
	ld iy,0e09ah		;7974   ; mueve y dibuja los tres coches rivales
	ld hl,0e090h		;7978
	ld ix,0e138h		;797b   ; ficha de sprite del primer rival (0xE138)
	call ACTUALIZA_RIVAL		;797f   ; actualiza el primer rival
	ld hl,0e093h		;7982
	ld ix,0e148h		;7985   ; el segundo
	call ACTUALIZA_RIVAL		;7989
	ld hl,0e096h		;798c
	ld ix,0e158h		;798f   ; y el tercero
	call ACTUALIZA_RIVAL		;7993
	ld a,(0e09fh)		;7996
	or a			;7999
	ret nz			;799a
	call COLOCA_RIVALES_VRAM		;799b   ; recoloca los sprites tras el barrido
	ld hl,0e0d9h		;799e
	xor a			;79a1
	cp (hl)			;79a2
	jr z,ACTUALIZA_RIVALES_79A9		;79a3
	ld (hl),a			;79a5
	call REACCION_CHOQUE		;79a6
ACTUALIZA_RIVALES_79A9:
	ld c,0a0h		;79a9   ; elige el color aleatorio del proximo rival
	ld a,(0e060h)		;79ab
	bit 2,a		;79ae
	jr z,ACTUALIZA_RIVALES_79BB		;79b0
	ld a,(0e075h)		;79b2
	cp 008h		;79b5
	jr z,ACTUALIZA_RIVALES_79BB		;79b7
	ld c,088h		;79b9
ACTUALIZA_RIVALES_79BB:
	ld a,r		;79bb
	and 003h		;79bd
	add a,a			;79bf
	add a,a			;79c0
	add a,a			;79c1
	add a,c			;79c2
	ld (0e09ch),a		;79c3
	ld a,0c9h		;79c6
	ld (06957h),a		;79c8   ; desactiva la aceleracion tras un choque (0x6957 = ret)
	ret			;79cb
ACTUALIZA_RIVAL:		; Un rival: avanza, escala por profundidad y colisiona
	ld a,(0e09fh)		;79cc   ; avanza un rival, lo escala y mira el choque
	or a			;79cf
	jr nz,RIVAL_ESCALA		;79d0
	ld a,(hl)			;79d2
	inc hl			;79d3
	inc hl			;79d4
	ld (hl),a			;79d5
	dec hl			;79d6
	dec hl			;79d7
RIVAL_ESCALA:
	ld c,000h		;79d8   ; escala el rival por su profundidad
	add a,010h		;79da
	cp 026h		;79dc
	jr c,RIVAL_1		;79de
	inc c			;79e0
	cp 038h		;79e1
	jr c,RIVAL_1		;79e3
	inc c			;79e5
RIVAL_1:
	ld a,c			;79e6   ; coloca el rival en su banda de la pista
	ld (0e09eh),a		;79e7
	ld a,(0e071h)		;79ea
	cp 007h		;79ed
	jr nc,RIVAL_2		;79ef
	ld a,(hl)			;79f1
	add a,010h		;79f2
	cp 026h		;79f4
	ret c			;79f6
RIVAL_2:
	ld a,(0e09fh)		;79f7
	or a			;79fa
	jr nz,RIVAL_COLISION		;79fb
	call MIRA_CHOQUE_RIVAL		;79fd
RIVAL_COLISION:
	ld a,(hl)			;7a00   ; comprueba el choque contra el rival
	ld b,a			;7a01
	inc hl			;7a02   ; lee la banda del rival
	ld c,(hl)			;7a03   ; y su patron
	add a,010h		;7a04
	cp 026h		;7a06
	jp c,RIVAL_CERCA		;7a08
	cp 038h		;7a0b
	jp c,RIVAL_MEDIO		;7a0d
	ld de,07b11h		;7a10
	push de			;7a13
	push bc			;7a14
	call DETECTA_CHOQUE		;7a15
	pop af			;7a18
	rrca			;7a19
	rrca			;7a1a
	rrca			;7a1b
	and 01fh		;7a1c
	cp 012h		;7a1e
	jr nc,RIVAL_3		;7a20
	sub 005h		;7a22
	jr RIVAL_4		;7a24
RIVAL_3:
	srl a		;7a26
	add a,004h		;7a28
RIVAL_4:
	ld b,a			;7a2a   ; prepara el sprite del rival cercano
	call CHOCA_RIVAL		;7a2b
	ld hl,07f47h		;7a2e   ; indexa la tabla de sombras del rival
	ld a,(0e075h)		;7a31   ; por la fase de animacion 0xE075
	add a,a			;7a34   ; dobla el indice de la tabla de sombras
	call HL_MAS_A		;7a35
	ld e,(hl)			;7a38
	inc hl			;7a39
	ld d,(hl)			;7a3a
	ld a,b			;7a3b
	call DE_MAS_A		;7a3c
	ld a,(de)			;7a3f   ; lee el desplazamiento de la fila
	ld h,000h		;7a40
	ld l,a			;7a42
	inc a			;7a43
	ret z			;7a44
	ld a,b			;7a45
	cp 009h		;7a46
	jr nc,RIVAL_4_7A59		;7a48
	add hl,hl			;7a4a   ; triplica el indice (tres bytes por entrada)
	push hl			;7a4b
	add hl,hl			;7a4c
	pop de			;7a4d
	add hl,de			;7a4e
	ld de,07dbah		;7a4f   ; apunta a la tabla de dibujos del rival (0x7DBA)
	add hl,de			;7a52
	ld a,c			;7a53
	call HL_MAS_A		;7a54
	jr RIVAL_4_7A61		;7a57
RIVAL_4_7A59:
	rr c		;7a59
	adc hl,hl		;7a5b
	ld de,07e68h		;7a5d
	add hl,de			;7a60
RIVAL_4_7A61:
	ld d,(hl)			;7a61   ; recorre la tira del rival
	ld a,d			;7a62
	inc a			;7a63   ; al desbordar, cierra la tira
	ret z			;7a64
	ld hl,07d94h		;7a65   ; indexa la tabla de sprites del rival grande (0x7D94)
	ld a,b			;7a68
	add a,a			;7a69
	call HL_MAS_A		;7a6a
	ld a,(hl)			;7a6d
	inc hl			;7a6e
	ld e,(hl)			;7a6f
	push ix		;7a70
	pop hl			;7a72
	bit 0,a		;7a73
	res 0,a		;7a75
	jr z,RIVAL_4_7A8D		;7a77
	ld (ix+008h),0e0h		;7a79   ; esconde las casillas que no se usan (Y=0xE0)
	ld (ix+00ch),0e0h		;7a7d
	bit 1,a		;7a81
	res 1,a		;7a83
	jr z,RIVAL_4_7AB9		;7a85
	ld (ix+004h),0e0h		;7a87
	jr RIVAL_4_7AC6		;7a8b
RIVAL_4_7A8D:
	push bc			;7a8d   ; ajusta la posicion del rival grande
	call RIVAL_4_7A9C		;7a8e
	pop bc			;7a91
	ld (ix+00bh),a		;7a92
	ld a,d			;7a95
	sub 010h		;7a96
	ld (ix+00dh),a		;7a98
	ret			;7a9b
RIVAL_4_7A9C:
	ld c,(iy+001h)		;7a9c   ; escribe el rival grande en la VRAM
	ld (hl),e			;7a9f
	inc hl			;7aa0   ; escribe la parte alta del rival
	ld (hl),d			;7aa1   ; y su color
	inc hl			;7aa2
	ld (hl),a			;7aa3
	inc hl			;7aa4
	ld (hl),c			;7aa5
	inc hl			;7aa6
	add a,004h		;7aa7
	ex af,af'			;7aa9
	ld a,d			;7aaa
	add a,010h		;7aab
	ld d,a			;7aad
	ex af,af'			;7aae
	ld (hl),e			;7aaf
	inc hl			;7ab0
	ld (hl),d			;7ab1
	inc hl			;7ab2
	ld (hl),a			;7ab3
	inc hl			;7ab4
	ld (hl),c			;7ab5
	inc hl			;7ab6
	add a,004h		;7ab7
RIVAL_4_7AB9:
	ld c,(iy+001h)		;7ab9   ; cierra el dibujo del rival cercano
	ld (hl),e			;7abc
	inc hl			;7abd
	ld (hl),d			;7abe
	inc hl			;7abf
	ld (hl),a			;7ac0
	inc hl			;7ac1
	ld (hl),c			;7ac2
	inc hl			;7ac3
	add a,004h		;7ac4
RIVAL_4_7AC6:
	ld (hl),e			;7ac6   ; avanza al siguiente trozo del rival
	inc hl			;7ac7
	ld (hl),d			;7ac8
	inc hl			;7ac9
	ld (hl),a			;7aca
	inc hl			;7acb
	ld a,(iy+000h)		;7acc
	ld (hl),a			;7acf
	ret			;7ad0
RIVAL_MEDIO:
	ld de,07b1bh		;7ad1   ; dibuja el rival a media distancia
	push de			;7ad4
	ld a,b			;7ad5
	ld b,000h		;7ad6
	cp 020h		;7ad8
	jr nc,RIVAL_MEDIO_7AE2		;7ada
	inc b			;7adc
	cp 018h		;7add
	jr nc,RIVAL_MEDIO_7AE2		;7adf
	inc b			;7ae1
RIVAL_MEDIO_7AE2:
	ld a,c			;7ae2   ; escribe el rival mediano
	and 00eh		;7ae3
	add a,a			;7ae5   ; dobla el indice del rival mediano
	add a,b			;7ae6
	ld de,07b30h		;7ae7
	call DE_MAS_A		;7aea
	ld a,(de)			;7aed
	ld de,0e200h		;7aee
	call DE_MAS_A		;7af1
	ld a,c			;7af4
	ld hl,07b3ch		;7af5
	call HL_MAS_A		;7af8
	ld l,(hl)			;7afb
	ld h,03ah		;7afc
	jp PINTA_TIRA_1		;7afe
RIVAL_CERCA:
	ld a,b			;7b01   ; dibuja el rival lejano (pequeno)
	cp 016h		;7b02
	call c,DETECTA_CHOQUE_7D02		;7b04
	ld a,(0e09eh)		;7b07
	or a			;7b0a
	ret z			;7b0b
	dec a			;7b0c
	jr z,$+10		;7b0d
	jr $+18		;7b0f

; ----------------------------------------------------------------------
; DATOS tabla_rival_a: Cabecera de sprite de rival
;   0x7b11..0x7b17  (6 bytes)
DATA_tabla_rival_a:
	defb 03ah,09eh,0e0h	; 7b11
	defb 0feh,001h,0c0h	; 7b14

; ======================================================================
; CODIGO 0x7b17..0x7b1b  (4 bytes)
; ======================================================================


DATA_tabla_rival_a_7B17:
	ld b,003h		;7b17
	jr $-55		;7b19

; ----------------------------------------------------------------------
; DATOS tabla_rival_b: Cabecera de sprite de rival
;   0x7b1b..0x7b21  (6 bytes)
DATA_tabla_rival_b:
	defb 03ah,09eh,0e0h	; 7b1b
	defb 0feh,002h,0c0h	; 7b1e

; ======================================================================
; CODIGO 0x7b21..0x7b30  (15 bytes)
; ======================================================================


CHOCA_RIVAL:		; Resuelve el choque contra un rival
	ld a,0e0h		;7b21   ; resuelve el choque contra el rival
	ld (ix+000h),a		;7b23
	ld (ix+004h),a		;7b26
	ld (ix+008h),a		;7b29
	ld (ix+00ch),a		;7b2c
	ret			;7b2f

; ----------------------------------------------------------------------
; DATOS tabla_rival_c: Sprites de rival por posicion
;   0x7b30..0x7b42  (18 bytes)
DATA_tabla_rival_c:
	defb 000h,014h	; 7b30
	defb 028h,03ch	; 7b32
	defb 050h,068h	; 7b34
	defb 080h,098h	; 7b36
	defb 0b0h,0c8h	; 7b38
	defb 0e0h,0f8h	; 7b3a
	defb 071h,06bh	; 7b3c
	defb 071h,072h	; 7b3e
	defb 06ah,06bh	; 7b40

; ======================================================================
; CODIGO 0x7b42..0x7b59  (23 bytes)
; ======================================================================


CHOCA_RIVAL_2:
	ld hl,07b59h		;7b42   ; coloca el rival tras el choque
	ld de,0e090h		;7b45
	ld bc,0000eh		;7b48
	ldir		;7b4b
	ld a,(0e061h)		;7b4d
	and 009h		;7b50
	ret z			;7b52
	ld a,004h		;7b53
	ld (0e09bh),a		;7b55
	ret			;7b58

; ----------------------------------------------------------------------
; DATOS tabla_rival_d: Sprites de rival por posicion
;   0x7b59..0x7b67  (14 bytes)
DATA_tabla_rival_d:
	defb 002h,000h	; 7b59
	defb 000h,004h	; 7b5b
	defb 001h,000h	; 7b5d
	defb 006h,000h	; 7b5f
	defb 000h,0ffh	; 7b61
	defb 004h,001h	; 7b63
	defb 0b8h,01fh	; 7b65

; ======================================================================
; CODIGO 0x7b67..0x7bb9  (82 bytes)
; ======================================================================


PREPARA_RIVALES:		; Coloca los tres rivales al empezar la etapa
	ld hl,0e200h		;7b67   ; coloca los tres rivales al empezar la etapa
	ld de,0e201h		;7b6a
	ld (hl),0fdh		;7b6d
	ld bc,0010fh		;7b6f
	ldir		;7b72
	ld hl,0e1ffh		;7b74
	ld de,07bb9h		;7b77
	ld b,003h		;7b7a
PREPARA_RIVALES_7B7C:
	push bc			;7b7c
	ld c,004h		;7b7d
PREPARA_RIVALES_7B7F:
	push de			;7b7f
	ld b,004h		;7b80
PREPARA_RIVALES_7B82:
	ld a,(de)			;7b82   ; fija la posicion de salida de cada rival
	call HL_MAS_A		;7b83
	inc de			;7b86   ; avanza en la tabla de posiciones de salida
	ld a,(de)			;7b87
	ld (hl),a			;7b88
	inc de			;7b89
	djnz PREPARA_RIVALES_7B82		;7b8a
	pop de			;7b8c
	dec c			;7b8d
	jr nz,PREPARA_RIVALES_7B7F		;7b8e
	pop bc			;7b90
	ld a,008h		;7b91
	call DE_MAS_A		;7b93
	djnz PREPARA_RIVALES_7B7C		;7b96
	ld bc,07bd1h		;7b98
	ld hl,0e200h		;7b9b
PREPARA_RIVALES_7B9E:
	ld a,(bc)			;7b9e   ; reparte los rivales por la pista
	inc bc			;7b9f
	cp 0feh		;7ba0
	ret z			;7ba2
	jr c,PREPARA_RIVALES_7BAA		;7ba3
	ld de,07bf3h		;7ba5
	jr PREPARA_RIVALES_7B9E		;7ba8
PREPARA_RIVALES_7BAA:
	call HL_MAS_A		;7baa
	push bc			;7bad
	ld b,004h		;7bae
PREPARA_RIVALES_7BB0:
	ld a,(de)			;7bb0   ; cierra la colocacion inicial
	ld (hl),a			;7bb1
	inc de			;7bb2
	inc hl			;7bb3
	djnz PREPARA_RIVALES_7BB0		;7bb4
	pop bc			;7bb6
	jr PREPARA_RIVALES_7B9E		;7bb7

; ----------------------------------------------------------------------
; DATOS tabla_rival_e: Alturas/patrones de los rivales
;   0x7bb9..0x7bff  (70 bytes)
DATA_tabla_rival_e:
	defb 005h,020h,005h,020h,005h,020h,005h,000h,005h,020h,006h,020h,007h,021h,006h,000h	; 7bb9  . . . ... . .!..
	defb 005h,01fh,006h,01fh,007h,020h,006h,000h,0ffh,000h,001h,001h,0ffh,00bh,001h,001h	; 7bc9  ..... ..........
	defb 0ffh,00bh,001h,0ffh,015h,001h,002h,0ffh,00fh,002h,002h,0ffh,00fh,002h,0ffh,019h	; 7bd9  ................
	defb 002h,003h,0ffh,00ch,003h,003h,0ffh,00ch,003h,0feh,024h,027h,02dh,02ah,025h,028h	; 7be9  ..........$'-*%(
	defb 02eh,02bh,026h,029h,029h,02ch	; 7bf9

; ======================================================================
; CODIGO 0x7bff..0x7d64  (357 bytes)
; ======================================================================


DIBUJA_RIVALES:		; Vuelca los tres rivales a la VRAM ordenados por profundidad
	call ORDENA_RIVALES		;7bff   ; los ordena por cercania antes de dibujar
	ld a,l			;7c02   ; elige el bloque de sprites segun la cercania
	ld bc,03000h		;7c03
	ld de,0e138h		;7c06
	cp 090h		;7c09
	jr z,RIVALES_ESCRIBE		;7c0b
	ld bc,02010h		;7c0d
	ld e,048h		;7c10
	cp 093h		;7c12
	jr z,RIVALES_ESCRIBE		;7c14
	ld bc,01020h		;7c16
	ld e,058h		;7c19
RIVALES_ESCRIBE:
	ld hl,03b28h		;7c1b
	call FIJA_ESCRITURA		;7c1e
RIVALES_ESCRIBE_1:
	di			;7c21
RIVALES_ESCRIBE_BUCLE:
	ld a,(de)			;7c22   ; saca el sprite del rival por el puerto
	inc de			;7c23
	exx			;7c24   ; saca cada byte del rival por el puerto
	out (c),a		;7c25
	exx			;7c27
	djnz RIVALES_ESCRIBE_BUCLE		;7c28
	ei			;7c2a
	ld a,c			;7c2b
	cp b			;7c2c
	ret z			;7c2d
	ld c,b			;7c2e
	ld b,a			;7c2f
	ld e,038h		;7c30
	jr RIVALES_ESCRIBE_1		;7c32
ORDENA_RIVALES:		; Deja en HL/DE el rival mas cercano de los tres
	ld hl,0e090h		;7c34   ; deja el rival mas cercano de los tres
	ld a,(0e093h)		;7c37
	ld de,0e096h		;7c3a   ; compara con la Y del tercer rival
	cp (hl)			;7c3d
	ld a,(de)			;7c3e
	jr nc,ORDENA_RIVALES_1		;7c3f
	ld l,093h		;7c41
	cp (hl)			;7c43
	ret nc			;7c44
	ex de,hl			;7c45
	ret			;7c46
ORDENA_RIVALES_1:
	cp (hl)			;7c47
	ret nc			;7c48
	ex de,hl			;7c49
	ret			;7c4a
MIRA_CHOQUE_RIVAL:		; Compara la posicion del jugador con la del rival
	ld a,(0e070h)		;7c4b   ; compara la posicion del jugador con la del rival
	or a			;7c4e
	ret z			;7c4f   ; coches en la misma banda: choque posible
	ld d,000h		;7c50
	ld a,(0e05bh)		;7c52
	or a			;7c55
	jr nz,CHOQUE_RIVAL_1		;7c56
	ld a,(0e05ch)		;7c58
	cp 004h		;7c5b
	jr nc,CHOQUE_RIVAL_1		;7c5d
	inc d			;7c5f
CHOQUE_RIVAL_1:
	exx			;7c60   ; mide la distancia al rival
	ld hl,0e09dh		;7c61
	exx			;7c64   ; guarda la banda del rival
	ld a,(0e09ch)		;7c65
	ld c,a			;7c68
	ld a,(0e085h)		;7c69
	sub c			;7c6c
	ld b,(hl)			;7c6d
	jr nc,CHOQUE_RIVAL_4		;7c6e
	push hl			;7c70
	ld a,l			;7c71
	add a,003h		;7c72
	ld l,a			;7c74
	cp 097h		;7c75
	jr c,CHOQUE_RIVAL_2		;7c77
	ld l,090h		;7c79
CHOQUE_RIVAL_2:
	ld a,(hl)			;7c7b   ; mira si el jugador lo pisa por detras
	pop hl			;7c7c
	sub b			;7c7d   ; resta la anchura del rival
	ld e,a			;7c7e
	ld a,b			;7c7f
	cp 016h		;7c80
	jr nc,CHOQUE_RIVAL_3		;7c82
	ld a,e			;7c84
	cp 078h		;7c85
	jr nc,IMPACTO		;7c87
	ret			;7c89
CHOQUE_RIVAL_3:
	cp 0f0h		;7c8a   ; mira el solape lateral
	jr c,IMPACTO		;7c8c
	ld a,e			;7c8e
	cp 020h		;7c8f
	jr nc,IMPACTO		;7c91
	ret			;7c93
CHOQUE_RIVAL_4:
	push hl			;7c94   ; compara las bandas de los dos coches
	ld a,l			;7c95
	sub 003h		;7c96
	ld l,a			;7c98
	cp 08fh		;7c99
	jr nc,CHOQUE_RIVAL_5		;7c9b
	ld l,096h		;7c9d
CHOQUE_RIVAL_5:
	ld e,(hl)			;7c9f   ; lee la banda del rival
	pop hl			;7ca0
	ld a,b			;7ca1   ; mira si el jugador viene por detras
	cp 0f0h		;7ca2
	jr c,CHOQUE_RIVAL_6		;7ca4
	ld a,d			;7ca6
	or a			;7ca7
	ret nz			;7ca8
	ld a,b			;7ca9
	sub e			;7caa
	jr c,IMPACTO		;7cab
	exx			;7cad
	cp (hl)			;7cae
	exx			;7caf
	jr nc,IMPACTO		;7cb0
	ret			;7cb2
CHOQUE_RIVAL_6:
	cp 016h		;7cb3   ; caso de choque de frente
	jr nc,IMPACTO		;7cb5
	ld a,d			;7cb7
	or a			;7cb8
	jr nz,CHOQUE_RIVAL_7		;7cb9
	ld a,e			;7cbb
	cp 0f0h		;7cbc
	jr c,IMPACTO		;7cbe
	ret			;7cc0
CHOQUE_RIVAL_7:
	ld a,b			;7cc1   ; empuja al rival al chocar
	cp e			;7cc2
	inc e			;7cc3
	inc e			;7cc4
	jr nc,CHOQUE_RIVAL_7_7CC9		;7cc5
	ld e,001h		;7cc7
CHOQUE_RIVAL_7_7CC9:
	ld (hl),e			;7cc9
	ret			;7cca
IMPACTO:		; Frena de golpe segun la velocidad relativa del choque
	ld a,(0e085h)		;7ccb   ; frena de golpe segun la velocidad del choque
	sub c			;7cce
	jr c,IMPACTO_NEG		;7ccf
	rrca			;7cd1
	rrca			;7cd2
	rrca			;7cd3
	rrca			;7cd4
	and 00fh		;7cd5
	jr IMPACTO_APLICA		;7cd7
IMPACTO_NEG:
	neg		;7cd9   ; rebote con velocidad negativa
	rrca			;7cdb
	rrca			;7cdc
	rrca			;7cdd
	rrca			;7cde
	and 00fh		;7cdf
	neg		;7ce1
IMPACTO_APLICA:
	ld c,a			;7ce3
	ld a,(hl)			;7ce4
	sub c			;7ce5
	ld (hl),a			;7ce6
	ret			;7ce7
DETECTA_CHOQUE:		; Comprueba si el jugador ha alcanzado a un rival
	inc hl			;7ce8   ; comprueba si el jugador alcanza al rival
	ld a,(hl)			;7ce9
	dec hl			;7cea   ; lee la banda del rival alcanzado
	cp 0f0h		;7ceb
	ret c			;7ced
	ld de,(0e0deh)		;7cee
	ld a,e			;7cf2
	cp 0e7h		;7cf3
	ld a,(de)			;7cf5
	jr nz,DETECTA_CHOQUE_7CFA		;7cf6
	ld e,0dfh		;7cf8
DETECTA_CHOQUE_7CFA:
	inc de			;7cfa
	ld (0e0deh),de		;7cfb
	ld (hl),a			;7cff
	ld c,a			;7d00
	ret			;7d01
DETECTA_CHOQUE_7D02:
	ld e,000h		;7d02   ; mide el solape con el rival alcanzado
	ld a,(0e121h)		;7d04
	cp 059h		;7d07   ; fuera del margen no hay choque
	jr c,DETECTA_CHOQUE_7D17		;7d09
	inc e			;7d0b
	cp 099h		;7d0c
	jr nc,DETECTA_CHOQUE_7D17		;7d0e
	ld e,003h		;7d10
	cp 071h		;7d12
	jr c,DETECTA_CHOQUE_7D17		;7d14
	inc e			;7d16
DETECTA_CHOQUE_7D17:
	ld (hl),e			;7d17
	ret			;7d18
SONIDO_ETAPA:		; Arranca las melodias/efectos de fondo de la etapa
	ld hl,tablas_choque_base		;7d19   ; arranca las melodias de fondo de la etapa
	ld a,(0e060h)		;7d1c
	call HL_MAS_A		;7d1f
	ld a,(hl)			;7d22
	ld hl,07d71h		;7d23
	call HL_MAS_A		;7d26
	ld (0e0dch),hl		;7d29
	ld hl,0e0e0h		;7d2c
	ld (0e0deh),hl		;7d2f
REACCION_CHOQUE:		; Sacude el coche tras un impacto
	ld hl,0e0dbh		;7d32   ; sacude el coche tras el impacto
	ld a,(hl)			;7d35
	xor 001h		;7d36   ; alterna el sentido de la sacudida
	ld (hl),a			;7d38
	ld hl,(0e0dch)		;7d39
	ld a,(hl)			;7d3c
	jr z,REACCION_CHOQUE_7D45		;7d3d
	rrca			;7d3f
	rrca			;7d40
	rrca			;7d41
	rrca			;7d42
	jr REACCION_CHOQUE_7D49		;7d43
REACCION_CHOQUE_7D45:
	inc hl			;7d45
	ld (0e0dch),hl		;7d46
REACCION_CHOQUE_7D49:
	ld de,07d7ch		;7d49   ; recoloca los sprites del coche sacudido
	and 00fh		;7d4c
	add a,a			;7d4e
	add a,a			;7d4f
	call DE_MAS_A		;7d50
	ld hl,0e0e0h		;7d53
	ld b,004h		;7d56
REACCION_CHOQUE_7D58:
	ld a,(de)			;7d58   ; cierra la reaccion al choque
	ld (hl),a			;7d59
	xor a			;7d5a
	rrd		;7d5b
	inc hl			;7d5d
	ld (hl),a			;7d5e
	inc hl			;7d5f
	inc de			;7d60
	djnz REACCION_CHOQUE_7D58		;7d61
tablas_choque_base:
	ret			;7d63

; ----------------------------------------------------------------------
; DATOS tablas_choque: Tablas de la animacion y los rotulos del choque
;   0x7d64..0x7f65  (513 bytes)
DATA_tablas_choque:
	defb 000h,002h,001h,002h,003h,005h,006h,002h,001h,006h,007h,005h,007h,000h,000h,020h	; 7d64  ............... 
	defb 012h,012h,002h,023h,045h,043h,025h,040h,010h,010h,010h,010h,034h,031h,004h,034h	; 7d74  ...#EC%@....41.4
	defb 010h,013h,040h,013h,034h,012h,012h,050h,025h,005h,035h,031h,004h,052h,040h,013h	; 7d84  ..@.4..P%.51.R@.
	defb 0a0h,092h,090h,08dh,080h,08ah,070h,087h,060h,084h,059h,081h,051h,07eh,049h,07ch	; 7d94  ......p.`.Y.Q~I|
	defb 041h,07bh,039h,07ah,031h,079h,029h,078h,029h,077h,029h,076h,027h,068h,027h,067h	; 7da4  A{9z1y)x)w)v'h'g
	defb 027h,066h,023h,065h,023h,064h,088h,05bh,082h,088h,05bh,061h,088h,05eh,07eh,081h	; 7db4  'f#e#d.[..[a.^~.
	defb 065h,068h,087h,062h,07ah,07dh,06ch,06fh,087h,065h,079h,079h,073h,073h,086h,067h	; 7dc4  eh.bz}lo.eyyss.g
	defb 079h,075h,078h,074h,086h,06ah,07bh,073h,07dh,075h,085h,06dh,07dh,072h,080h,075h	; 7dd4  yuxt.j{s}u.m}r.u
	defb 085h,06fh,080h,071h,083h,074h,084h,071h,082h,071h,084h,073h,089h,05fh,07eh,084h	; 7de4  .o.q.t.q.q.s._~.
	defb 064h,06ch,08ah,063h,07ch,081h,06ch,075h,08ch,068h,07dh,080h,075h,07ch,08eh,06ch	; 7df4  dl.c|.lu.h}.u|.l
	defb 080h,07fh,07ch,07fh,092h,074h,085h,07fh,086h,083h,096h,07bh,08bh,080h,08fh,084h	; 7e04  ..|..t.....{....
	defb 09bh,083h,094h,083h,099h,087h,0a1h,08ah,09dh,08ah,0a0h,08ah,099h,081h,093h,082h	; 7e14  ................
	defb 095h,085h,09bh,086h,098h,086h,099h,087h,087h,05dh,07ah,082h,062h,068h,086h,05fh	; 7e24  .........]z.bh._
	defb 074h,07dh,068h,06dh,084h,060h,070h,077h,06ch,06fh,081h,05fh,06eh,071h,06eh,06dh	; 7e34  t}hm.`pwlo._nqnm
	defb 07ch,05eh,06dh,06ah,071h,06bh,077h,05ch,06eh,063h,072h,067h,071h,059h,06dh,05bh	; 7e44  |^mjqkw\ncrgqYm[
	defb 071h,060h,06bh,054h,06bh,055h,06bh,058h,073h,05bh,06fh,05fh,071h,061h,06fh,05ah	; 7e54  q`kTkUkXs[o_qaoZ
	defb 06eh,05ch,06fh,05dh,084h,073h,084h,074h,084h,076h,083h,077h,083h,078h,082h,079h	; 7e64  n\o].s.t.v.w.x.y
	defb 082h,07ah,085h,075h,087h,079h,088h,07ah,08ah,07ch,08ch,07eh,08eh,080h,090h,082h	; 7e74  .z.u.y.z.|.~....
	defb 093h,086h,0a5h,092h,0ffh,09ah,0ffh,0a7h,09dh,08bh,09fh,08fh,0a2h,093h,0a2h,095h	; 7e84  ................
	defb 0a3h,096h,0a4h,098h,0a4h,099h,0a5h,09bh,083h,073h,081h,073h,080h,072h,07eh,070h	; 7e94  .........s.s.r~p
	defb 07dh,06fh,07bh,06dh,079h,06bh,076h,069h,065h,052h,05eh,0ffh,053h,0ffh,06ch,05ah	; 7ea4  }o{mykvieR^.S.lZ
	defb 069h,059h,067h,058h,065h,058h,064h,057h,063h,057h,062h,057h,060h,056h,000h,001h	; 7eb4  iYgXeXdWcWbW`V..
	defb 002h,003h,004h,005h,006h,007h,008h,000h,001h,002h,002h,003h,004h,004h,005h,006h	; 7ec4  ................
	defb 006h,000h,001h,002h,003h,004h,005h,006h,007h,008h,000h,007h,008h,009h,00ah,00bh	; 7ed4  ................
	defb 00ch,00dh,00eh,0ffh,000h,009h,00ah,00bh,00ch,00dh,00eh,00fh,010h,00fh,010h,011h	; 7ee4  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,009h,00ah,00bh,00ch,00dh,00eh,011h,012h	; 7ef4  ................
	defb 012h,013h,014h,015h,016h,017h,018h,019h,0ffh,0ffh,000h,001h,002h,003h,004h,005h	; 7f04  ................
	defb 006h,007h,008h,000h,01ah,01bh,01ch,01dh,01eh,01fh,020h,021h,0ffh,000h,013h,014h	; 7f14  .......... !....
	defb 015h,016h,017h,018h,019h,01ah,022h,023h,024h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f24  ......"#$.......
	defb 000h,013h,014h,015h,016h,017h,018h,019h,01ah,025h,026h,027h,028h,029h,02ah,02bh	; 7f34  .........%&'()*+
	defb 02ch,0ffh,0ffh,0c2h,07eh,0d5h,07eh,0e8h,07eh,0fbh,07eh,0c2h,07eh,00eh,07fh,021h	; 7f44  ,...~.~.~.~.~..!
	defb 07fh,034h,07fh,0c2h,07eh,000h,016h,02ch,03dh,053h,069h,07ah,092h,0ach,0bfh,0d7h	; 7f54  .4..~..,=Siz....
	defb 0f1h	; 7f64

; ======================================================================
; CODIGO 0x7f65..0x7fee  (137 bytes)
; ======================================================================


FIJA_SPAWN_RIVAL:		; Elige donde aparece el proximo rival (0xE09D)
	ld a,(0e003h)		;7f65   ; elige donde aparece el proximo rival
	or a			;7f68
	ret nz			;7f69   ; solo decide en la fase 0
	ld c,01fh		;7f6a   ; por defecto, a la derecha
	ld a,r		;7f6c
	rra			;7f6e
	jr c,SPAWN_1		;7f6f
	ld a,(0e060h)		;7f71
	dec a			;7f74
	and 003h		;7f75
	add a,a			;7f77
	inc a			;7f78
	rlca			;7f79
	rlca			;7f7a
	rlca			;7f7b
	rlca			;7f7c
	and 070h		;7f7d
	ld c,a			;7f7f
	ld a,08fh		;7f80
	sub c			;7f82
	ld c,a			;7f83
SPAWN_1:
	ld a,c			;7f84
	ld (0e09dh),a		;7f85
	ret			;7f88
CHOQUE_OBSTACULO:		; Mira si el jugador toca un obstaculo y frena
	ld de,0e08eh		;7f89
	ld b,003h		;7f8c
OBSTACULO_BUCLE:
	inc de			;7f8e   ; recorre los tres obstaculos posibles
	inc de			;7f8f
	ld a,(de)			;7f90
	inc de			;7f91
	sub 016h		;7f92
	sub 00ah		;7f94
	jr nc,OBSTACULO_1		;7f96
	ld a,(de)			;7f98
	ld hl,07feeh		;7f99   ; el ancho del obstaculo sale de la tabla 0x7FEE
	call HL_MAS_A		;7f9c
	ld c,(hl)			;7f9f
	ld a,(0e125h)		;7fa0
	ld l,a			;7fa3
	sub c			;7fa4
	sub 03eh		;7fa5
	jr c,OBSTACULO_CHOCA		;7fa7
OBSTACULO_1:
	djnz OBSTACULO_BUCLE		;7fa9
	ret			;7fab
OBSTACULO_CHOCA:
	ld b,l			;7fac   ; frena a la mitad al tocar un obstaculo
	ld hl,0e085h		;7fad
	srl (hl)		;7fb0   ; parte la velocidad por la mitad
	ld hl,0e08ch		;7fb2
	ld a,(hl)			;7fb5
	or a			;7fb6
	jr nz,OBSTACULO_CHOCA_7FE8		;7fb7
	ld e,a			;7fb9
	ld a,c			;7fba
	add a,01fh		;7fbb
	cp b			;7fbd
	jr c,OBSTACULO_CHOCA_7FC1		;7fbe
	inc e			;7fc0
OBSTACULO_CHOCA_7FC1:
	ld (hl),001h		;7fc1   ; marca el golpe contra el obstaculo
	inc hl			;7fc3
	ld (hl),e			;7fc4   ; guarda la posicion del golpe
	inc hl			;7fc5
	ld (hl),0ffh		;7fc6
	inc hl			;7fc8
	ld (hl),0ffh		;7fc9
	ld c,008h		;7fcb
	ld a,(0e00bh)		;7fcd
	cp 03fh		;7fd0
	jr nz,OBSTACULO_CHOCA_7FD6		;7fd2
	ld c,00ch		;7fd4
OBSTACULO_CHOCA_7FD6:
	ld hl,0e065h		;7fd6
	ld a,(hl)			;7fd9
	sub c			;7fda
	jr nc,OBSTACULO_CHOCA_7FDF		;7fdb
	ld a,003h		;7fdd
OBSTACULO_CHOCA_7FDF:
	ld (hl),a			;7fdf   ; cierra la reaccion al obstaculo
	inc hl			;7fe0
	inc hl			;7fe1
	dec (hl)			;7fe2
	ld a,04ch		;7fe3
	call ARRANCA_SONIDO		;7fe5
OBSTACULO_CHOCA_7FE8:
	call CAMBIA_MARCHA		;7fe8
	jp DIBUJA_VELOCIMETRO		;7feb

; ----------------------------------------------------------------------
; DATOS tabla_ancho_choque: Ancho de golpe de cada obstaculo (cierra en 0xFF)
;   0x7fee..0x7ff5  (7 bytes)
DATA_tabla_ancho_choque:
	defb 069h,039h,071h,079h,029h,031h,0ffh	; 7fee

; ----------------------------------------------------------------------
; DATOS marca_konami: La marca oculta de Konami: RC-718 en katakana (la hallo
;   Manuel Pazos)
;   0x7ff5..0x8000  (11 bytes)
DATA_marca_konami:
	defb 0bah,0a7h,0a6h,0bah,0b8h,099h,081h,099h,008h,018h,0aah	; 7ff5  ...........
