@;=                                                          	     	=
@;=== candy1_init.s: rutinas para inicializar la matriz de juego	  ===
@;=                                                           	    	=
@;=== Programador tarea 1A: annabel.pizarro@estudiants.urv.cat				  ===
@;=== Programador tarea 1B: annabel.pizarro@estudiants.urv.cat				  ===
@;=                                                       	        	=



.include "../include/candy1_incl.i"



@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
		.global mat_recomb1
		.global mat_recomb2
@; matrices de recombinación: matrices de soporte para generar una nueva matriz
@;	de juego recombinando los elementos de la matriz original.
	mat_recomb1:	.space ROWS*COLUMNS
	mat_recomb2:	.space ROWS*COLUMNS



@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm



@;TAREA 1A;
@; inicializa_matriz(*matriz, num_mapa): rutina para inicializar la matriz de
@;	juego, primero cargando el mapa de configuración indicado por parámetro (a
@;	obtener de la variable global 'mapas'), y después cargando las posiciones
@;	libres (valor 0) o las posiciones de gelatina (valores 8 o 16) con valores
@;	aleatorios entre 1 y 6 (+8 o +16, para gelatinas)
@;	Restricciones:
@;		* para obtener elementos de forma aleatoria se invocará la rutina
@;			'mod_random'
@;		* para evitar generar secuencias se invocará la rutina
@;			'cuenta_repeticiones' (ver fichero "candy1_move.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;		R1 = número de mapa de configuración
	.global inicializa_matriz
inicializa_matriz:
		push {r0-r9,lr}		@;guardar registros utilizados
		
			@; Cargamos el mapa de configuracion
			ldr r4, =mapas
			mov r2, #ROWS
			mov r3, #COLUMNS
			mul r5, r2, r3
			mul r5, r1	@; r5= ROWS*COLUMNAS*NIVEL -> Desplazamiento para mapa de configuracion correspondiente al nivel
			add r4,r5	@; Puntero al mapa de configuracion
			mov r8, r0 @; Backup de la dirección base de la matriz de juego
			
			@; Recorremos mapa de configuracion
			mov r1, #0 @; Fila actual
			mov r2, #0 @; Columna actual
			mov r9, #COLUMNS
			
		.LFila:
			mov r2, #0
			
		.LColumna:
			mla r5, r1, r9, r2 @; r5 sera el puntero: fila*COLUMNS + columna
			ldrb r6, [r4, r5] @; r6 contiene el valor de la posicion
			tst r6, #0x07
			bne .LAvanza	@; Si los bits 2..0 no son 000, tenemos que copiar el valor tal cual en la matriz de juego
			
		.LValorAleatorio:
			@; Si los 3 bits de menos peso son 0, significa que tenemos que buscar un numero aleatorio y vigilar que no se forme secuencia
			mov r0, #6
			bl mod_random	@; Recibiremos por r0 un valor entre 0 y 5
			add r0,  #1
			strb r0, [r8, r5]
			mov r7, r0		@; Hacemos backup del numero aleatorio generado
			
			@; Comprobamos direccion norte
			mov r0, r8
			mov r3, #3
			bl cuenta_repeticiones @; cuenta_repeticiones(@matriz, fila, columna,orientacion)
			cmp r0, #3
			bhs .LValorAleatorio
			
			@; Comprobamos direccion oeste
			mov r0, r8
			mov r3, #2 
			bl cuenta_repeticiones	@; cuenta_repeticiones(@matriz, fila, columna,orientacion)
			cmp r0, #3
			bhs .LValorAleatorio
			
			add r6,r7	@; Convertimos el valor simple en gelatina si es necesario
			
		.LAvanza:
			strb r6, [r8, r5]		@; Guardamos el valor en la matriz de juego
			
			add r2, #1
			cmp r2, #COLUMNS
			blt .LColumna	@;Si no hemos recorrido todas las columnas, pasamos a la columna siguiente de la fila
			
			add r1, #1
			cmp r1, #ROWS
			blt .LFila		@; Si no hemos recorrido todas las filas, saltamos a la siguiente
		
		pop {r0-r9,pc}			@;recuperar registros y volver



@;TAREA 1B;
@; recombina_elementos(*matriz): rutina para generar una nueva matriz de juego
@;	mediante la reubicación de los elementos de la matriz original, para crear
@;	nuevas jugadas.
@;	Inicialmente se copiará la matriz original en 'mat_recomb1', para luego ir
@;	escogiendo elementos de forma aleatoria y colocandolos en 'mat_recomb2',
@;	conservando las marcas de gelatina.
@;	Restricciones:
@;		* para obtener elementos de forma aleatoria se invocará la rutina
@;			'mod_random'
@;		* para evitar generar secuencias se invocará la rutina
@;			'cuenta_repeticiones' (ver fichero "candy1_move.s")
@;		* para determinar si existen combinaciones en la nueva matriz, se
@;			invocará la rutina 'hay_combinacion' (ver fichero "candy1_comb.s")
@;		* se supondrá que siempre existirá una recombinación sin secuencias y
@;			con combinaciones
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
	.global recombina_elementos
recombina_elementos:
		push {r0-r12, lr}
			
			ldr r4, =mat_recomb1
			ldr r5, =mat_recomb2
			mov r9, #COLUMNS
			
		.LRecombina:
			mov r1, #0 @; Fila actual
			mov r2, #0 @; Columna actual
			mov r10, #0 @; Contador bucle infinito
			
		.LFiles:
			mov r2, #0
			
		.LColumnes:
			mla r8, r1, r9, r2 @; r8 sera el puntero: fila*COLUMNS + columna
			ldrb r6, [r0, r8] @; r6 contiene el valor de la posicion de la matriz de juego
			
			and r7, r6, #0x07	@; and con 3 los bits de menos peso para saber si se trata de un bloque solido o hueco
			cmp r7, #7			
			bne .LNumero				
			
			mov r7, #0			@; Si es bloque solido o hueco, guardamos 0 en mat_recomb1 y su valor en mat_recomb2
			strb r7, [r4, r8]
			orr r6, #0x20		@; Marcamos bit 5 de los 7 y 15's
			strb r6, [r5, r8]
			bl .LSiguiente
			
			
		@; En este punto, el valor de la matriz puede ser 0-6, 8-14 o 16-22	
		.LNumero:			
			
			@; Guardamos valor simple en mat_recomb1
			strb r7, [r4, r8]
			@; Si valor simple es 0 -> Valor real es un 0, 8 o 16, lo "marcamos" activando un bit extra antes de guardarlo en mat_recomb2
			cmp r7, #0
			beq .LMarca
			
			and r7, r6, #0x18	@; and con 11000 para obtener valor gelatina y lo guardamos en mat_recomb2
			strb r7, [r5, r8]
			bl .LSiguiente
			
		.LMarca:
			orr r6, #0x20 @; or con 100000 para "marcar" bit 5
			strb r6, [r5, r8]
			
		.LSiguiente:		
			add r2, #1
			cmp r2, #COLUMNS
			blt .LColumnes	@;Si no hemos recorrido todas las columnas, pasamos a la columna siguiente de la fila
			
			add r1, #1
			cmp r1, #ROWS
			blt .LFiles		@; Si no hemos recorrido todas las filas, saltamos a la siguiente
			
			@; Una vez llegado a este punto, mat_recomb1 y 2 inicializados.
			mov r1, #0 @; Fila actual
			mov r2, #0 @; Columna actual
			mov r12, r0	
			
		.LFilMR2:
			mov r2, #0
			
		.LColMR2:
			mla r8, r1, r9, r2 @; r8 sera el puntero: fila*COLUMNS + columna
			ldrb r6, [r5, r8] @; r6 contiene el valor de la posicion de la mat_recomb2
			
			and r7,r6,#0x020	@; And para saber si valor tiene bit 5 a 1 (0, 8 o 16 "originales" o 7 y 15)
			cmp r7, #0
			bne .LQuitarMarca	@; Si es uno de esos valores saltamosa quitar marca
			@; Si no lo es, buscamos posicion aleatoria de mat_recomb1
			
		.LPosAleatoria:
			mov r0, #COLUMNS*ROWS
			bl mod_random	@; Recibiremos por r0 un valor entre 0 y COLUMNS*ROWS (puntero matriz COLUMNS*ROWS)
			mov r11, r0	
			ldrb r7, [r4, r11]@; r7 contiene el valor de posicion aleatoria de mat_recomb1
			cmp r7, #0
			beq .LPosAleatoria
			
			add r7, r6			@; Añadimos el valor de la posicion aleatoria
			strb r7, [r5, r8]		@; Guardamos en mat_recomb2
			add r10, #1
			cmp r10, #100
			beq .LRecombina
			
			@; Comprobamos direccion norte
			mov r0, r5
			mov r3, #3
			bl cuenta_repeticiones @; cuenta_repeticiones(@matriz, fila, columna,orientacion)
			cmp r0, #3
			bhs .LPosAleatoria
			
			@; Comprobamos direccion oeste
			mov r0, r5
			mov r3, #2
			bl cuenta_repeticiones @; cuenta_repeticiones(@matriz, fila, columna,orientacion)
			cmp r0, #3
			bhs .LPosAleatoria
			
			@; En este punto sabemos que no se han formado secuencias
			mov r7, #0
			strb r7, [r4, r11]
			
			
			@; ====================================== SPRITES ======================================
			@; Una vez hemos movido el elemento, activamos la animacion del sprite
			push {r0-r3}
			mov r3, r2		@; r3 = columna destino			
			mov r2, r1 		@; r2 = fila destino
			
			@; r11 contiene el puntero del valor de origen -> necesitamos fila y columna
			mov r0, r11
			bl buscarFilayColumna @; buscarFilayColumna(indice); r0: fila origen, r1: columna origen
			bl activa_elemento    @; activa_elemento(int fil, int col, int f2, int c2)
			
			pop {r0-r3}
			@; ====================================== FIN SPRITES ======================================
			
			b .LSiguientePosicion

		.LQuitarMarca:
			and r6, #0x01F
			strb r6, [r5, r8]
			
		.LSiguientePosicion:
			add r2, #1
			cmp r2, #COLUMNS
			blt .LColMR2	@;Si no hemos recorrido todas las columnas, pasamos a la columna siguiente de la fila
			
			add r1, #1
			cmp r1, #ROWS
			blt .LFilMR2		@; Si no hemos recorrido todas las filas, saltamos a la siguiente
			
			@; Una vez llegado este punto, tenemos en mat_recomb2 la matriz de juego, procedemos a copiarla	
			mov r1, #0	 @; Fila actual
			mov r0, r12		@; Recuperamos puntero matriz
			
		.LFilCopy:
			mov r2, #0	@; Columna actual
			
		.LColCopy:
			mla r8, r1, r9, r2 @; r8 sera el puntero: fila*COLUMNS + columna
			ldrb r4, [r5, r8]
			strb r4, [r0,r8]
			
			add r2, #1
			cmp r2, #COLUMNS
			blt .LColCopy	@;Si no hemos recorrido todas las columnas, pasamos a la columna siguiente de la fila
			
			add r1, #1
			cmp r1, #ROWS
			blt .LFilCopy		@; Si no hemos recorrido todas las filas, saltamos a la siguiente
			
		pop {r0-r12, pc}

@;:::RUTINAS DE SOPORTE:::


@; buscarFilayColumna(): rutina auxiliar para encontrar la fila y columna 
@;  dado un indice
@;	Parámetros:
@;		R0 = Indice
@;	Resultado:
@;		R0 = Fila
@;		R1 = Columna
buscarFilayColumna:
	push {r2-r4, lr}
		mov r2, r0				@; r2 = Indice de interes
		mov r0, #0				@; r0 = fila de interes
		mov r4, #COLUMNS
	.LFilaPuntero:
		mov r1, #0				@; r1 = columna de interes
	.LColumnaPuntero:	
		mla r3, r0, r4, r1			@; r3 sera el puntero: fila*COLUMNS + columna
		cmp r3, r2					@; Si r3 = r4, hemos encontrado fila y columna 
		beq .LFinPuntero	
		
		@; Si aun no lo encontramos, incrementamos indices
		add r1, #1
		cmp r1, #COLUMNS
		blt .LColumnaPuntero	@;Si no hemos recorrido todas las columnas, pasamos a la columna siguiente de la fila
		
		add r0, #1
		cmp r0, #ROWS
		blt .LFilaPuntero		@; Si no hemos recorrido todas las filas, saltamos a la siguiente
	.LFinPuntero:	
	pop {r2-r4, pc}

@; mod_random(n): rutina para obtener un número aleatorio entre 0 y n-1,
@;	utilizando la rutina 'random'
@;	Restricciones:
@;		* el parámetro 'n' tiene que ser un valor entre 2 y 255, de otro modo,
@;		  la rutina lo ajustará automáticamente a estos valores mínimo y máximo
@;	Parámetros:
@;		R0 = el rango del número aleatorio (n)
@;	Resultado:
@;		R0 = el número aleatorio dentro del rango especificado (0..n-1)
	.global mod_random
mod_random:
		push {r1-r4, lr}
		
		cmp r0, #2				@;compara el rango de entrada con el mínimo
		bge .Lmodran_cont
		mov r0, #2				@;si menor, fija el rango mínimo
	.Lmodran_cont:
		and r0, #0xff			@;filtra los 8 bits de menos peso
		sub r2, r0, #1			@;R2 = R0-1 (número más alto permitido)
		mov r3, #1				@;R3 = máscara de bits
	.Lmodran_forbits:
		cmp r3, r2				@;genera una máscara superior al rango requerido
		bhs .Lmodran_loop
		mov r3, r3, lsl #1
		orr r3, #1				@;inyecta otro bit
		b .Lmodran_forbits
		
	.Lmodran_loop:
		bl random				@;R0 = número aleatorio de 32 bits
		and r4, r0, r3			@;filtra los bits de menos peso según máscara
		cmp r4, r2				@;si resultado superior al permitido,
		bhi .Lmodran_loop		@; repite el proceso
		mov r0, r4			@; R0 devuelve número aleatorio restringido a rango
		
		pop {r1-r4, pc}


@; random(): rutina para obtener un número aleatorio de 32 bits, a partir de
@;	otro valor aleatorio almacenado en la variable global 'seed32' (declarada
@;	externamente)
@;	Restricciones:
@;		* el valor anterior de 'seed32' no puede ser 0
@;	Resultado:
@;		R0 = el nuevo valor aleatorio (también se almacena en 'seed32')
random:
	push {r1-r5, lr}
		
	ldr r0, =seed32				@;R0 = dirección de la variable 'seed32'
	ldr r1, [r0]				@;R1 = valor actual de 'seed32'
	ldr r2, =0x0019660D
	ldr r3, =0x3C6EF35F
	umull r4, r5, r1, r2
	add r4, r3					@;R5:R4 = nuevo valor aleatorio (64 bits)
	str r4, [r0]				@;guarda los 32 bits bajos en 'seed32'
	mov r0, r5					@;devuelve los 32 bits altos como resultado
		
	pop {r1-r5, pc}	

.end
