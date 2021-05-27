@;=                                                         	      	=
@;=== candy1_move: rutinas para contar repeticiones y bajar elementos ===
@;=                                                          			=
@;=== Programador tarea 1E: lluc.gavalda@estudiants.urv.cat				  ===
@;=== Programador tarea 1F: lluc.gavalda@estudiants.urv.cat				  ===
@;=                                                         	      	=



.include "../include/candy1_incl.i"



@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm



@;TAREA 1E;
@; cuenta_repeticiones(*matriz,f,c,ori): rutina para contar el número de
@;	repeticiones del elemento situado en la posición (f,c) de la matriz, 
@;	visitando las siguientes posiciones según indique el parámetro de
@;	orientación 'ori'.
@;	Restricciones:
@;		* sólo se tendrán en cuenta los 3 bits de menor peso de los códigos
@;			almacenados en las posiciones de la matriz, de modo que se ignorarán
@;			las marcas de gelatina (+8, +16)
@;		* la primera posición también se tiene en cuenta, de modo que el número
@;			mínimo de repeticiones será 1, es decir, el propio elemento de la
@;			posición inicial
@;	Parámetros:
@;		R0 = dirección base de la matriz
@;		R1 = fila 'f'
@;		R2 = columna 'c'
@;		R3 = orientación 'ori' (0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte)
@;	Resultado:
@;		R0 = número de repeticiones detectadas (mínimo 1)
	.global cuenta_repeticiones
cuenta_repeticiones:
		push {r1-r12, lr}
		
		
		mov r5, #COLUMNS
		mla r6, r1, r5, r2
		mov r4, r0
		ldrb r5, [r4, r6]
		and r5, #7
		mov r0, #1				@;R0 = número de repeticiones
		
		cmp r3, #0
		beq .Lconrep_este
		cmp r3, #1
		beq .Lconrep_sur
		cmp r3, #2
		beq .Lconrep_oeste
		cmp r3, #3
		beq .Lconrep_norte
		b .Lconrep_fin
		
		.Lconrep_este:
		cmp r2, #COLUMNS-1
		bge .Lconrep_fin
		add r2, #1
		add r6, #1
		ldrb r7, [r4, r6]
		and r7, #7
		cmp r5, r7
		bne .Lconrep_fin
		add r0, #1
		b .Lconrep_este
		
		.Lconrep_sur:
		cmp r1, #ROWS-1
		bge .Lconrep_fin
		add r1, #1
		add r6, #COLUMNS
		ldrb r7, [r4, r6]
		and r7, #7
		cmp r5, r7
		bne .Lconrep_fin
		add r0, #1
		b .Lconrep_sur

		.Lconrep_oeste:
		cmp r2, #0
		ble .Lconrep_fin
		sub r2, #1
		sub r6, #1
		ldrb r7, [r4, r6]
		and r7, #7
		cmp r5, r7
		bne .Lconrep_fin
		add r0, #1
		b .Lconrep_oeste

		.Lconrep_norte:
		cmp r1, #0
		ble .Lconrep_fin
		sub r1, #1
		add r6, #-COLUMNS
		ldrb r7, [r4, r6]
		and r7, #7
		cmp r5, r7
		bne .Lconrep_fin
		add r0, #1
		b .Lconrep_norte
		
		.Lconrep_fin:
		
		pop {r1-r12, pc}


@;TAREA 1F;
@; baja_elementos(*matriz): rutina para bajar elementos hacia las posiciones
@;	vacías, primero en vertical y después en sentido inclinado; cada llamada a
@;	la función sólo baja elementos una posición y devuelve cierto (1) si se ha
@;	realizado algún movimiento, o falso (0) si está todo quieto.
@;	Restricciones:
@;		* para las casillas vacías de la primera fila se generarán nuevos
@;			elementos, invocando la rutina 'mod_random' (ver fichero
@;			"candy1_init.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica se ha realizado algún movimiento, de modo que puede que
@;				queden movimientos pendientes. 
	.global baja_elementos
baja_elementos:
		push {lr}
		
		
		pop {pc}



@;:::RUTINAS DE SOPORTE:::



@; baja_verticales(mat): rutina para bajar elementos hacia las posiciones vacías
@;	en vertical; cada llamada a la función sólo baja elementos una posición y
@;	devuelve cierto (1) si se ha realizado algún movimiento.
@;	Parámetros:
@;		R4 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica que se ha realizado algún movimiento. 
baja_verticales:
		push {lr}
		
		
		pop {pc}



@; baja_laterales(mat): rutina para bajar elementos hacia las posiciones vacías
@;	en diagonal; cada llamada a la función sólo baja elementos una posición y
@;	devuelve cierto (1) si se ha realizado algún movimiento.
@;	Parámetros:
@;		R4 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica que se ha realizado algún movimiento. 
baja_laterales:
		push {lr}
		
		
		pop {pc}



.end
