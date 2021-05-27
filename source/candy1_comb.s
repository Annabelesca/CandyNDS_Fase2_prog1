@;=                                                               		=
@;=== candy1_combi.s: rutinas para detectar y sugerir combinaciones   ===
@;=                                                               		=
@;=== Programador tarea 1G: oriol.villaro@estudiants.urv.cat		  ===
@;=== Programador tarea 1H: oriol.villaro@estudiants.urv.cat		  ===
@;=                                                             	 	=



.include "../include/candy1_incl.i"



@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm



@;TAREA 1G;
@; hay_combinacion(*matriz): rutina para detectar si existe, por lo menos, una
@;	combinación entre dos elementos (diferentes) consecutivos que provoquen
@;	una secuencia válida, incluyendo elementos en gelatinas simples y dobles.
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 si hay una secuencia, 0 en otro caso
	.global hay_combinacion
hay_combinacion:
		push {r1-r9,r11,lr}
		
		mov r11,r0		@;fem una copia de la direcció base
		mov r3, #ROWS
		mov r4, #COLUMNS
		mov r1, #0 		@;índex de les files
		
		.LFila:
		mov r2, #0 		@;índex de les columnes
		
		.LColumna:
		mla r5,r1,r4,r2 @;r5 serà el punter fent fila*COLUMNS+columna
		
		ldrb r6,[r11,r5] @;carreguem a r6 el contingut de la posició de la matriu
		cmp r6,#0		@;Comprovarem que la posició actual no sigui
		beq .LSeguent	@;ni un forat, ni un espai buit ni un bloc sòlid,
		cmp r6,#0x07	@;en el cas que ho sigui saltarem a la següent posició
		beq .LSeguent
		cmp r6,#0x0F
		beq .LSeguent
		
		@;Comprovació canviant l'element de la dreta
		
		mov r7,r2
		add r7,#1 		@;Ens interessa saber el contingut de la casella a la dreta 
		mla r8,r1,r4,r7	@;de la matriu per comprovar que no siguin el mateix element
		ldrb r9,[r11,r8]
		cmp r9,r6
		beq .LBaix 	@;Si són el mateix element passem a la següent posició
		
		cmp r9,#0		@;Realitzem les mateixes comprovacions que abans
		beq .LBaix	
		cmp r9,#0x07	
		beq .LBaix
		cmp r9,#0x0F
		beq .LBaix		@;Si ha passat totes les comprovacions canviarem les posicions
		strb r9,[r11,r5]	@;per comprovar una possible combinació. R10 serà l'auxiliar
		strb r6,[r11,r8]
		
		push {r4}
		mov r4,r11
		
		bl detectar_orientacion @;r4=direccio_base,r1=fila,r2=columna
		
		strb r9,[r11,r8]
		strb r6,[r11,r5]
		
		pop {r4}
		
		cmp r0,#0x06	@;Si l'output de detectar__orientacion és diferent a 6 és que
		movne r0,#1
		cmp r0,#1
		beq .LFi
		
		push {r2,r4}
		
		mov r2,r7
		mov r4,r11
		
		strb r9,[r11,r5]	@;per comprovar una possible combinació. R10 serà l'auxiliar
		strb r6,[r11,r8]
		
		bl detectar_orientacion
		
		pop {r2,r4}			@;Desfem els canvis realitzats
		
		strb r9,[r11,r8]
		strb r6,[r11,r5]
		
		cmp r0,#0x06	@;Si l'output de detectar__orientacion és diferent a 6 és que
		movne r0,#1
		cmp r0,#1
		beq .LFi		@;s'ha trobat una combinació
		
		@;Comprovació canviant l'element de baix
		
		.LBaix:
		
		mov r7,r1
		add r7,#1
		mla r8,r7,r4,r2
		ldrb r9,[r11,r8]
		cmp r9,r6
		beq .LSeguent
		
		cmp r9,#0		@;Realitzem les mateixes comprovacions que abans
		beq .LSeguent	
		cmp r9,#0x07	
		beq .LSeguent
		cmp r9,#0x0F
		beq .LSeguent
		
		strb r9,[r11,r5]	@;per comprovar una possible combinació. 
		strb r6,[r11,r8]
		
		push {r4}
		mov r4,r11
		
		bl detectar_orientacion @;r4=direccio_base,r1=fila,r2=columna
		
		strb r9,[r11,r8]
		strb r6,[r11,r5]
		
		pop {r4}
		
		cmp r0,#0x06	@;Si l'output de detectar__orientacion és diferent a 6 és que
		movne r0,#1
		cmp r0,#1
		beq .LFi
		
		push {r1,r4}
		mov r1,r7
		mov r4,r11
		
		strb r9,[r11,r5]	@;per comprovar una possible combinació. R10 serà l'auxiliar
		strb r6,[r11,r8]
		
		bl detectar_orientacion
		
		pop {r1,r4}			@;Desfem els canvis realitzats
		
		strb r9,[r11,r8]
		strb r6,[r11,r5]
		
		cmp r0,#0x06	@;Si l'output de detectar__orientacion és diferent a 6 és que
		movne r0,#1
		cmp r0,#1
		beq .LFi		@;s'ha trobat una combinació
		
		.LSeguent:
		add r2,#1
		cmp r2,#COLUMNS
		blt .LColumna
		
		add r1,#1
		cmp r1,#ROWS
		blt .LFila
		
		.LFi:
		cmp r0,#0x1
		movne r0,#0
		
		pop {r1-r9,r11,pc}



@;TAREA 1H;
@; sugiere_combinacion(*matriz, *sug): rutina para detectar una combinación
@;	entre dos elementos (diferentes) consecutivos que provoquen una secuencia
@;	válida, incluyendo elementos en gelatinas simples y dobles, y devolver
@;	las coordenadas de las tres posiciones de la combinación (por referencia).
@;	Restricciones:
@;		* se supone que existe por lo menos una combinación en la matriz
@;			 (se debe verificar antes con la rutina 'hay_combinacion')
@;		* la combinación sugerida tiene que ser escogida aleatoriamente de
@;			 entre todas las posibles, es decir, no tiene que ser siempre
@;			 la primera empezando por el principio de la matriz (o por el final)
@;		* para obtener posiciones aleatorias, se invocará la rutina 'mod_random'
@;			 (ver fichero "candy1_init.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;		R1 = dirección del vector de posiciones (char *), donde la rutina
@;				guardará las coordenadas (x1,y1,x2,y2,x3,y3), consecutivamente.
	.global sugiere_combinacion
sugiere_combinacion:
		push {r0-r12,lr}
		
		mov r10, r0		@;fem copia de la direcció base de la matriu		
		mov r12, r1		@;fem copia de la direcció base del vector
		mov r3,#ROWS
		mov r4,#COLUMNS
		mov r0,r3
		bl mod_random
		mov r1,r0		@;índex d'una fila aleatòria per començar
		
		.LRow:
		mov r2,#0		@;índex de les columnes
		
		.LCol:
		mla r5,r1,r4,r2	@;punter al principi d'una fila aleatòria
		
		ldrb r6,[r10,r5] @;carreguem a r6 el contingut de la posició de la matriu
		cmp r6,#0		@;Comprovarem que la posició actual no sigui
		beq .LNext	@;ni un forat, ni un espai buit ni un bloc sòlid,
		cmp r6,#0x07	@;en el cas que ho sigui saltarem a la següent posició
		beq .LNext
		cmp r6,#0x0F
		beq .LNext
		
		@;Canvi amb l'element de la dreta
		
		mov r7,r2
		add r7,#1 		@;Ens interessa saber el contingut de la casella a la dreta 
		mla r8,r1,r4,r7	@;de la matriu per comprovar que no siguin el mateix element
		ldrb r9,[r10,r8]
		cmp r9,r6
		beq .LDown 	@;Si són el mateix element passem a la següent posició
		
		cmp r9,#0		@;Realitzem les mateixes comprovacions que abans
		beq .LDown	
		cmp r9,#0x07	
		beq .LDown
		cmp r9,#0x0F
		beq .LDown		@;Si ha passat totes les comprovacions canviarem les posicions
		strb r9,[r10,r5]	@;per comprovar una possible combinació. R10 serà l'auxiliar
		strb r6,[r10,r8]
		
		push {r4}
		mov r4,r10
		
		bl detectar_orientacion @;r4=direccio_base,r1=fila,r2=columna
		
		strb r9,[r10,r8]
		strb r6,[r10,r5]
		
		pop {r4}
		
		cmp r0,#0x06	@;Si l'output de detectar__orientacion és diferent a 6 és que
		movne r4,#0	@;r4 serà el cpi
		cmp r0,#0x06
		movne r3,r0
		cmp r0,#0x06
		beq .LNoComb1
		
		push {r0}
		mov r0,r12
		bl generar_posiciones
		pop {r0}
		bl .LEnd
		
		.LNoComb1:
		push {r2,r4}
		
		mov r2,r7
		mov r4,r10
		
		strb r9,[r10,r5]	@;per comprovar una possible combinació. R10 serà l'auxiliar
		strb r6,[r10,r8]
		
		bl detectar_orientacion
		
		pop {r2,r4}			@;Desfem els canvis realitzats
		
		strb r9,[r10,r8]
		strb r6,[r10,r5]
		
		cmp r0,#0x06	@;Si l'output de detectar__orientacion és diferent a 6 és que
		movne r4,#1
		cmp r0,#0x06
		movne r3,r0
		cmp r0,#0x06
		beq .LNoComb2
		
		push {r0,r2}
		mov r0,r12
		mov r2,r7
		bl generar_posiciones
		pop {r0,r2}
		bl .LEnd		@;s'ha trobat una combinació
		
		.LNoComb2:
		@;Canvi amb l'element de baix
		
		.LDown:
		
		mov r4,#COLUMNS
		mov r7,r1
		add r7,#1 		@;Ens interessa saber el contingut de la casella a la dreta 
		mla r8,r7,r4,r2	@;de la matriu per comprovar que no siguin el mateix element
		ldrb r9,[r10,r8]
		cmp r9,r6
		beq .LNext
		cmp r9,#0		@;Realitzem les mateixes comprovacions que abans
		beq .LNext	
		cmp r9,#0x07	
		beq .LNext
		cmp r9,#0x0F
		beq .LNext		@;Si ha passat totes les comprovacions canviarem les posicions
		strb r9,[r10,r5]	@;per comprovar una possible combinació. R10 serà l'auxiliar
		strb r6,[r10,r8]
		
		push {r4}
		mov r4,r10
		
		bl detectar_orientacion @;r4=direccio_base,r1=fila,r2=columna
		
		strb r9,[r10,r8]
		strb r6,[r10,r5]
		
		pop {r4}
		
		cmp r0,#0x06	@;Si l'output de detectar__orientacion és diferent a 6 és que
		movne r4,#2	@;r4 serà el cpi
		cmp r0,#0x06
		movne r3,r0
		cmp r0,#0x06
		beq .LNoComb3
		
		push {r0}
		mov r0,r12
		bl generar_posiciones
		pop {r0}
		bl .LEnd
		
		.LNoComb3:
		mov r7,r1
		add r7,#1
		
		push {r1,r4}
		mov r1,r7		@;Comprovem l'altra posició
		mov r4,r10
		
		strb r9,[r10,r5]	@;per comprovar una possible combinació. R10 serà l'auxiliar
		strb r6,[r10,r8]
		
		bl detectar_orientacion
		
		pop {r1,r4}			@;Desfem els canvis realitzats
		
		strb r9,[r10,r8]
		strb r6,[r10,r5]
		
		cmp r0,#0x06	@;Si l'output de detectar__orientacion és diferent a 6 és que
		movne r4,#3
		cmp r0,#0x06
		movne r3,r0
		cmp r0,#0x06
	
		beq .LNext
		
		push {r0,r1}
		mov r0,r12
		mov r1,r7
		bl generar_posiciones
		pop {r0,r1}
		bl .LEnd		@;s'ha trobat una combinació
		
		.LNext:
		add r2,#1
		cmp r2,#COLUMNS
		blt .LCol
		
		add r1,#1
		cmp r1,#ROWS
		blt .LRow
		cmp r1,#ROWS
		moveq r1,#0
		bl .LRow
		
		.LEnd:
		
		pop {r0-r12,pc}




@;:::RUTINAS DE SOPORTE:::



@; generar_posiciones(vect_pos,f,c,ori,cpi): genera las posiciones de sugerencia
@;	de combinación, a partir de la posición inicial (f,c), el código de
@;	orientación 'ori' y el código de posición inicial 'cpi', dejando las
@;	coordenadas en el vector 'vect_pos'.
@;	Restricciones:
@;		* se supone que la posición y orientación pasadas por parámetro se
@;			corresponden con una disposición de posiciones dentro de los límites
@;			de la matriz de juego
@;	Parámetros:
@;		R0 = dirección del vector de posiciones 'vect_pos'
@;		R1 = fila inicial 'f'
@;		R2 = columna inicial 'c'
@;		R3 = código de orientación;
@;				inicio de secuencia: 0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte
@;				en medio de secuencia: 4 -> horizontal, 5 -> vertical
@;		R4 = código de posición inicial:
@;				0 -> izquierda, 1 -> derecha, 2 -> arriba, 3 -> abajo
@;	Resultado:
@;		vector de posiciones (x1,y1,x2,y2,x3,y3), devuelto por referencia
generar_posiciones:
		push {r5,lr}
		
		cmp r4,#0
		beq .LPI_zero
		cmp r4,#0x01
		beq .LPI_u
		cmp r4,#0x02
		beq .LPI_dos
		cmp r4,#0x03
		beq .LPI_tres
		
		.LPI_zero:
		add r5,r2,#1
		strb r5,[r0]
		strb r1,[r0,#1]
		bl .LBaixa
		
		.LPI_u:
		sub r5,r2,#1
		strb r5,[r0]
		strb r1,[r0,#1]
		bl .LBaixa
		
		.LPI_dos:
		add r5,r1,#1
		strb r2,[r0]
		strb r5,[r0,#1]
		bl .LBaixa
		
		.LPI_tres:
		sub r5,r1,#1
		strb r2,[r0]
		strb r5,[r0,#1]
		bl .LBaixa
		
		.LBaixa:
		
		cmp r3,#0
		beq .LORI_zero
		cmp r3,#0x01
		beq .LORI_u
		cmp r3,#0x02
		beq .LORI_dos
		cmp r3,#0x03
		beq .LORI_tres
		cmp r3,#0x04
		beq .LORI_quatre
		cmp r3,#0x05
		beq .LORI_cinc
		
		.LORI_zero:
		add r5,r2,#1
		strb r5,[r0,#2]
		strb r1,[r0,#3]
		add r5,#1
		strb r5,[r0,#4]
		strb r1,[r0,#5]
		
		bl .LFinal
		
		.LORI_u:
		add r5,r1,#1
		strb r2,[r0,#2]
		strb r5,[r0,#3]
		add r5,#1
		strb r2,[r0,#4]
		strb r5,[r0,#5]
		
		bl .LFinal
		
		.LORI_dos:
		sub r5,r2,#1
		strb r5,[r0,#2]
		strb r1,[r0,#3]
		sub r5,#1
		strb r5,[r0,#4]
		strb r1,[r0,#5]
		
		bl .LFinal
		
		.LORI_tres:
		sub r5,r1,#1
		strb r2,[r0,#2]
		strb r5,[r0,#3]
		sub r5,#1
		strb r2,[r0,#4]
		strb r5,[r0,#5]
		
		bl .LFinal
		
		.LORI_quatre:
		sub r5,r2,#1
		strb r5,[r0,#2]
		strb r1,[r0,#3]
		add r5,#2
		strb r5,[r0,#4]
		strb r1,[r0,#5]
		
		bl .LFinal
		
		.LORI_cinc:
		sub r5,r1,#1
		strb r2,[r0,#2]
		strb r5,[r0,#3]
		add r5,#2
		strb r2,[r0,#4]
		strb r5,[r0,#5]
		
		
		
		.LFinal:
		
		pop {r5,pc}



@; detectar_orientacion(f,c,mat): devuelve el código de la primera orientación
@;	en la que detecta una secuencia de 3 o más repeticiones del elemento de la
@;	matriz situado en la posición (f,c).
@;	Restricciones:
@;		* para proporcionar aleatoriedad a la detección de orientaciones en las
@;			que se detectan secuencias, se invocará la rutina 'mod_random'
@;			(ver fichero "candy1_init.s")
@;		* para detectar secuencias se invocará la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;		* sólo se tendrán en cuenta los 3 bits de menor peso de los códigos
@;			almacenados en las posiciones de la matriz, de modo que se ignorarán
@;			las marcas de gelatina (+8, +16)
@;	Parámetros:
@;		R1 = fila 'f'
@;		R2 = columna 'c'
@;		R4 = dirección base de la matriz
@;	Resultado:
@;		R0 = código de orientación;
@;				inicio de secuencia: 0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte
@;				en medio de secuencia: 4 -> horizontal, 5 -> vertical
@;				sin secuencia: 6 
detectar_orientacion:
		push {r3, r5, lr}
		
		mov r5, #0				@;R5 = índice bucle de orientaciones
		mov r0, #4
		bl mod_random
		mov r3, r0				@;R3 = orientación aleatoria (0..3)
	.Ldetori_for:
		mov r0, r4
		bl cuenta_repeticiones
		cmp r0, #1
		beq .Ldetori_cont		@;no hay inicio de secuencia
		cmp r0, #3
		bhs .Ldetori_fin		@;hay inicio de secuencia
		add r3, #2
		and r3, #3				@;R3 = salta dos orientaciones (módulo 4)
		mov r0, r4
		bl cuenta_repeticiones
		add r3, #2
		and r3, #3				@;restituye orientación (módulo 4)
		cmp r0, #1
		beq .Ldetori_cont		@;no hay continuación de secuencia
		tst r3, #1
		bne .Ldetori_vert
		mov r3, #4				@;detección secuencia horizontal
		b .Ldetori_fin
	.Ldetori_vert:
		mov r3, #5				@;detección secuencia vertical
		b .Ldetori_fin
	.Ldetori_cont:
		add r3, #1
		and r3, #3				@;R3 = siguiente orientación (módulo 4)
		add r5, #1
		cmp r5, #4
		blo .Ldetori_for		@;repetir 4 veces
		
		mov r3, #6				@;marca de no encontrada
		
	.Ldetori_fin:
		mov r0, r3				@;devuelve orientación o marca de no encontrada
		
		pop {r3, r5, pc}



.end
