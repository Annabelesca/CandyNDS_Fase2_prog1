@;=                                                          	     	=
@;=== RSI_timer0.s: rutinas para mover los elementos (sprites)		  ===
@;=                                                           	    	=
@;=== Programador tarea 2E: annabel.pizarro@estudiants.urv.cat				  ===
@;=== Programador tarea 2G: yyy.yyy@estudiants.urv.cat				  ===
@;=== Programador tarea 2H: zzz.zzz@estudiants.urv.cat				  ===
@;=                                                       	        	=

.include "../include/candy2_incl.i"


@;-- .data. variables (globales) inicializadas ---
.data
		.align 2
		.global update_spr
	update_spr:	.hword	0			@;1 -> actualizar sprites
		.global timer0_on
	timer0_on:	.hword	0 			@;1 -> timer0 en marcha, 0 -> apagado
	divFreq0: .hword	-5727			@; DivFrec= -((FB/64)/91.42) = -5727-1.432
	@; Mover un elemento en 0'35s -> 32 tics en 0'35s -> Frec Salida: (32/0'35)=91.42 DivFrec= -((FB/64)/91.42) = -5727

@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
	divF0: .space	2				@;divisor de frecuencia actual


@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm

@;TAREAS 2Ea,2Ga,2Ha;
@;rsi_vblank(void); Rutina de Servicio de Interrupciones del retrazado vertical;
@;Tareas 2E,2F: actualiza la posición y forma de todos los sprites
@;Tarea 2G: actualiza las metabaldosas de todas las gelatinas
@;Tarea 2H: actualiza el desplazamiento del fondo 3
	.global rsi_vblank
rsi_vblank:
		push {r0-r3, lr}
		
		@;Tareas 2Ea
			ldr r2, =update_spr
			ldrh r3, [r2]
			cmp r3, #0				@; Miramos variable update_spr para comprobar si ha habido algun cambio
			beq .LNoUpdate			
			
			ldr r0, =0x07000000		@; 0x07000000 = @OAM
			ldr r1, =n_sprites		@; Si ha habido cambio, actualizamos sprites
			ldr r1, [r1]
			bl SPR_actualizarSprites @;r0 - @OAM / r1 - n_sprites
			mov r1, #0
			strh r1, [r2]			
			
		.LNoUpdate:

@;Tarea 2Ga


@;Tarea 2Ha

		
		pop {r0-r3,pc}



@; 0400 0100 TIMER0_DATA: Valor del contador, divisor de frecuencia

@;@ 0x0400 0102 TIMER0_CR
@; bits 1..0 Prescaler selection: indica frec entrada requerida
@;			00 -> F/1, 01-> F/64, 10 -> F/256, 11 -> F/1.024
@; bit 2 Count-upTiming indica si hay que enlazar el contador con el timer anterior
@; bit 6 Timter IRQ Enable indica si las interrupciones estan activadas
@; bit 7 Timer Start/Stop indica si el timer esta en marcha

@;TAREA 2Eb;
@;activa_timer0(init); rutina para activar el timer 0, inicializando o no el
@;	divisor de frecuencia según el parámetro init.
@;	Parámetros:
@;		R0 = init; si 1, restablecer divisor de frecuencia original divFreq0
	.global activa_timer0
activa_timer0:
		push {r0-r2, lr}
			
			cmp r0, #0
			beq .LNoModificar
			@; Si init=1, copianmos divFreq en divF0 y en el registro de datos del timer 0
			
			ldr r1, =divFreq0
			ldsh r1, [r1]
			ldr r2, =divF0
			strh r1, [r2]
			ldr r2, =0x04000100
			strh r1, [r2]
			
		.LNoModificar:	
			@; tanto si modificamos el divisor de frecuencia como si no, activamos timer0
			ldr r0, =0x04000102
			mov r1, #0xC1	@; 1100 0001
			strh r1, [r0]
			@; Actualizamos variable que marca que el timer esta en marcha
			ldr r0, =timer0_on
			mov r1, #1
			strh r1, [r0]
			
		pop {r0-r2,pc}


@;TAREA 2Ec;
@;desactiva_timer0(); rutina para desactivar el timer 0.
	.global desactiva_timer0
desactiva_timer0:
		push {r0-r1, lr}
			ldr r0, =0x04000102
			mov r1, #0			@; Ponemos el registro a 0
			strh r1, [r0]
			
			@; Actualizamos variable que marca que el timer esta en marcha
			ldr r0, =timer0_on
			mov r1, #0
			strh r1, [r0]
		
		pop {r0-r1, pc}


@; ELE_II = 0
@; ELE_PX = 2
@; ELE_PY = 4
@; ELE_VX = 6
@; ELE_VY = 8
@; ELE_TAM = 10
@;TAREA 2Ed;
@;rsi_timer0(); rutina de Servicio de Interrupciones del timer 0: recorre todas
@;	las posiciones del vector vect_elem y, en el caso que el código de
@;	activación (ii) sea mayor o igual a 0, decrementa dicho código y actualiza
@;	la posición del elemento (px, py) de acuerdo con su velocidad (vx,vy),
@;	además de mover el sprite correspondiente a las nuevas coordenadas.
@;	Si no se ha movido ningún elemento, se desactivará el timer 0. En caso
@;	contrario, el valor del divisor de frecuencia se reducirá para simular
@;  el efecto de aceleración (con un límite).
	.global rsi_timer0
rsi_timer0:
		push {r0-r6, lr}
			mov r3, #0 				@; Booleano que marcará si se ha movido algun sprite
			ldr r4, =vect_elem
			mov r0, #0				@; r0 = indice
			
		.LBucle:			
			ldsh r5, [r4, #ELE_II]		@; r5 = vect_elem[r0].ii
			cmp r5, #0
			ble .LAvanza			@; Si esta desactivado (ii <= 0), saltamos al siguiente
			
			@; Si elemento esta activado, debemos actualizar posicion del sprite acorde a la velocidad
			sub r5, #1		
			strh r5, [r4, #ELE_II]		@; Actualizamos vect_elem[r0].ii
			
			ldsh r1, [r4, #ELE_PX]	    @; r1 = px
			ldsh r2, [r4, #ELE_PY]		@; r2 = py
			ldsh r5, [r4, #ELE_VX]		@; r5 = vx
			ldsh r6, [r4, #ELE_VY]		@; r6 = vy
			
			add r1, r5 				@; r1 = px + vx
			add r2, r6				@; r2 = py + vy
			
			bl SPR_moverSprite
			strh r1, [r4, #ELE_PX]	@; px = r1
			strh r2, [r4, #ELE_PY]	@; py = r2
			
			mov r3, #1				@; Indicamos que se ha movido 1 sprite
			
		.LAvanza:
			add r4, #ELE_TAM
			add r0, #1
			cmp r0, #ROWS*COLUMNS
			blo .LBucle
			
			@; Una vez recorrido todo el vector, comprobamos si se ha movido algun sprite
			cmp r3, #1				
			blne desactiva_timer0	@; Si no se ha movido nada, desactivamos timer
			bne .LFin
			
			@; Si se ha movido sprite, actualizamos upd_sprite y divisor de frecuencia
			ldr r0, =update_spr		@; r0 = @update_spr
			mov r1, #1
			strh r1, [r0]			@; update_spr = 1
			
			ldr r0, =divF0
			ldsh r1, [r0]			@; r1 = divisor de frecuencia actual
			add r1, #1
			strh r1, [r0]			@; Actualizamos divF0
			ldr r0, =0x04000100
			strh r1, [r0]			@; Actualizamos datos del timer0
			
		.LFin:	
			
		pop {r0-r6, pc}



.end
