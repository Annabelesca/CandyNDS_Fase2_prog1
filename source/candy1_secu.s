@;=                                                               		=
@;=== candy1_secu.s: rutinas para detectar y elimnar secuencias 	  ===
@;=                                                             	  	=
@;=== Programador tarea 1C: nuria.cardiel@estudiants.urv.cat				  ===
@;=== Programador tarea 1D: nuria.cardiel@estudiants.urv.cat				  ===
@;=                                                           		   	=



.include "../include/candy1_incl.i"



@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
@; número de secuencia: se utiliza para generar números de secuencia únicos,
@;	(ver rutinas 'marcar_horizontales' y 'marcar_verticales') 
	num_sec:	.space 1



@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm



@;TAREA 1C;
@; hay_secuencia(*matriz): rutina para detectar si existe, por lo menos, una
@;	secuencia de tres elementos iguales consecutivos, en horizontal o en
@;	vertical, incluyendo elementos en gelatinas simples y dobles.
@;	Restricciones:
@;		* para detectar secuencias se invocará la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 si hay una secuencia, 0 en otro caso
	.global hay_secuencia
hay_secuencia:
		push {r1-r8, lr}
		mov r4, #0					@;puntero
		mov r1, #0					@;filas
		mov r2, #0					@;columnas
		mov r6, r0	
		mov r7, #COLUMNS*ROWS-1		@;Tamaño total tabla
	.Lbucle1:
		cmp r4, r7
		bhs .Lnosecu				@;sale del bucle si el contador supera tamaño tabla
		ldrb r5, [r6,r4]			@;cargo el valor de la matriz de juego al que apunta el puntero
		and r8, r5, #7
		cmp r8, #7					@;Nos quedamos con los 3 bits de menor peso y descartamos si es bloque o hueco
		beq .Lendif1
		cmp r8, #0
		beq .Lendif1				@;ignoro vacío y gelatina vacía porque solo nos interesa el valor de los últimos 3 bits
		cmp r1, #ROWS-2				@;miramos si hay combinacion de filas
		bhs .Lendif2				@;hemos acabado de mirar repes de filas
		mov r3, #1					@;determina orientacion
		bl cuenta_repeticiones		@;cuenta repeticiones sur (fila<maxfila-1)
		cmp r0, #3
		bhs .Lsisecu				@;salimos bucle porque hay una secuencia 
	.Lendif2:
		cmp r2, #COLUMNS-2			@;miramos si hay combinacion de columnas
		bhs .Lendif1				@;hemos acabado de mirar repes de columnas
		mov r3, #0					@;determina orientacion
		mov r0, r6					@;vuelve a tener la direccion de la matriz en r0 para invocar al cuenta repes
		bl cuenta_repeticiones 		@;cuenta repeticiones este (columna<maxcol)
		cmp r0, #3
		bhs .Lsisecu				@;salimos bucle porque hay una secuencia
	.Lendif1:
		cmp r2, #COLUMNS-1			@;miramos en que columna estamos
		blo .Lsiguientepos
		mov r2, #-1					
		add r1, #1					@;saltamos de fila porque ya no hay mas columnas
	.Lsiguientepos:
		mov r0, r6
		add r4, #1					@;sumamos contadores y vamos a la siguiente pos
		add r2, #1
		b .Lbucle1
	.Lsisecu:						
		mov r0, #1
		b .Lfibucle1				@;sale del bucle porque hay secuencia
	.Lnosecu:
		mov r0, #0					@;sale del bucle porque no hay secuencia
	.Lfibucle1:
		
		pop {r1-r8, pc}



@;TAREA 1D;
@; elimina_secuencias(*matriz, *marcas): rutina para eliminar todas las
@;	secuencias de 3 o más elementos repetidos consecutivamente en horizontal,
@;	vertical o combinaciones, así como de reducir el nivel de gelatina en caso
@;	de que alguna casilla se encuentre en dicho modo; 
@;	además, la rutina marca todos los conjuntos de secuencias sobre una matriz
@;	de marcas que se pasa por referencia, utilizando un identificador único para
@;	cada conjunto de secuencias (el resto de las posiciones se inicializan a 0). 
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;		R1 = dirección de la matriz de marcas 

	.global elimina_secuencias
elimina_secuencias:
		push {r2-r8, lr}
		mov r6, #0
		mov r8, #0					@;R8 es desplazamiento posiciones matriz
	.Lelisec_for0:
		strb r6, [r1, r8]			@;poner matriz de marcas a cero
		add r8, #1
		cmp r8, #ROWS*COLUMNS-1
		blo .Lelisec_for0
		
		bl marcar_horizontales
		bl marcar_verticales
		
		mov r3, #COLUMNS*ROWS-1		@;Tamaño total matriz
		mov r7, #0
	.Lelimina:		
		cmp r7, r3					@;usamos r7 como puntero
		bhi .Lfibucle2				@;si salimos de la tabla, acaba el bucle
		ldrb r5, [r1,r7]			@;cargamos en la posición del puntero el valor de la matriz de marcas
		cmp r5, #0 					@;Buscamos elementos marcados
		beq .Lendif5				@;siguiente pos
		ldrb r4, [r0, r7]			@;posición marcada en matriz juego
		cmp r4, #16					@;comprobamos que el elemento en el juego es una gelatina simple o nula
		bhi .Lendif4
		mov r6, #0
		strb r6, [r0, r7]			@;pasamos la posición de la matriz de marcas a cero en la matriz de juego
		b .Lendif5					@;siguiente pos
	.Lendif4:						@;reducimos nivel de gelatina
		mov r6, #8
		strb r6, [r0, r7]
	.Lendif5:						@;avanzamos posicion
		add r7, r7, #1
		b .Lelimina
	.Lfibucle2:
		pop {r2-r8, pc}




	
@;:::RUTINAS DE SOPORTE:::



@; marcar_horizontales(mat): rutina para marcar todas las secuencias de 3 o más
@;	elementos repetidos consecutivamente en horizontal, con un número identifi-
@;	cativo diferente para cada secuencia, que empezará siempre por 1 y se irá
@;	incrementando para cada nueva secuencia, y cuyo último valor se guardará en
@;	la variable global 'num_sec'; las marcas se guardarán en la matriz que se
@;	pasa por parámetro 'mat' (por referencia).
@;	Restricciones:
@;		* se supone que la matriz 'mat' está toda a ceros
@;		* para detectar secuencias se invocará la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;		R1 = dirección de la matriz de marcas
marcar_horizontales:
		push {r0-r12, lr}
		mov r4, r1					@;marcas	
		mov r9, r0					@;juego
		mov r1, #0 					@;Filas
		mov r2, #0					@;Columnas
		mov r3, #0					@;Orientacion
		mov r5, #0					@;Contador
		mov r6, #0					@;Cont Secu
		mov r7, #COLUMNS*ROWS-1		@;tamaño total
	.Lbucle3:
		mov r0, r9					@;nos aseguramos de que en r0 este la matriz de juego
		cmp r5, r7
		bhs .Lfibucle3				@;salimos del bucle si superamos el tamaño de la tabla
		ldrb r8, [r9, r5]			@;carga el valor del puntero en la matriz de juego
		and r11, r8, #7				@; Nos quedamos con los 3 bits de menos peso y descartamos huecos y bloques.
		cmp r11, #7
		beq .Lsumacont2
		cmp r11, #0
		beq .Lsumacont2				@;Ignoramos si es 0 o gelatina vacía		
		cmp r2, #COLUMNS-2
		bhs .Lsumacont2				
		bl cuenta_repeticiones
		mov r10, r0					@;guardamos el numero para usar r0 como contador	
		cmp r10, #3
		blo .Lsumacont1				@;siguiente pos SIN contador sumado para siguiente pos
		add r6, r6, #1				@;sumamos 1 al numero de secuencias
	.Lminibucle1:
		cmp r0, #0
		beq .Lendif6				@;siguiente pos CON contador sumado
		strb r6, [r4, r5]			@;marcamos en la matriz
		sub r0, r0, #1				@;una posicion a marcar menos
		add r5, r5, #1				@;una posicion del contador mas
		b .Lminibucle1
	.Lsumacont2:
		add r5, #1					@;sumamos 1 al contador despues de un espacio vacio, hueco, bloque, etc
		cmp r2, #COLUMNS-1			@;sumamos 1 a la columna si se puede, sino saltamos fila
		blo .Lendif7
		mov r2, #-1
		add r1, r1, #1
		b .Lendif7
	.Lsumacont1:
		add r5, r5, r10				@;sumamos, en el caso de que no haya minimo 3 elems, el numero de veces que se repite MAS el contador para siguiente pos
	.Lendif6:						@;se encarga de actualizar num columns y de sumarle 1 para la siguiente pos
		sub r10, r10, #1			@;restamos para aumentar hasta la columna con el ultimo elemento igual
		add r2, r2, r10	
		cmp r2, #COLUMNS-1			@;sumamos 1 a la columna si se puede
		blo .Lendif7
		mov r2, #-1					@;saltamos a la fila siguiente
		add r1, r1, #1
	.Lendif7:						@;siguiente pos sumando columna
		add r2, r2, #1
		b .Lbucle3
	.Lfibucle3:
		ldrb r11, =num_sec			@;guardamos el valor final del numero de secuencias en la var global
		strb r6, [r11]
		pop {r0-r12, pc}



@; marcar_verticales(mat): rutina para marcar todas las secuencias de 3 o más
@;	elementos repetidos consecutivamente en vertical, con un número identifi-
@;	cativo diferente para cada secuencia, que seguirá al último valor almacenado
@;	en la variable global 'num_sec'; las marcas se guardarán en la matriz que se
@;	pasa por parámetro 'mat' (por referencia);
@;	sin embargo, habrá que preservar los identificadores de las secuencias
@;	horizontales que intersecten con las secuencias verticales, que se habrán
@;	almacenado en en la matriz de referencia con la rutina anterior.
@;	Restricciones:
@;		* se supone que la matriz 'mat' está marcada con los identificadores
@;			de las secuencias horizontales
@;		* la variable 'num_sec' contendrá el siguiente indentificador (>1)
@;		* para detectar secuencias se invocará la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;		R1 = dirección de la matriz de marcas
marcar_verticales:
		push {r0-r12,lr}
		mov r4, r1					@;marcas
		mov r9, r0					@;juego
		mov r1, #0 					@;Filas
		mov r2, #0					@;Columnas
		mov r3, #1					@;orientación
		mov r5, #0					@;Contador
		ldrb r7, =num_sec			@;Cont Secu
		ldrb r6, [r7]			
		mov r7, #COLUMNS*ROWS-1		@;tamaño total
	.Lbucle4:
		cmp r5, r7
		bhs .Lfibucle4				@;si el contador supera el tamaño total se va del bucle
		ldrb r8, [r9, r5]			@;carga en r8 el valor del contador en la matriz de juego
		mov r0, r9
		cmp r8, #0
		beq .Lsumacont4	
		cmp r8, #8
		beq .Lsumacont4
		cmp r8, #16
		beq .Lsumacont4
		cmp r8, #7
		beq .Lsumacont4
		cmp r8, #15
		beq .Lsumacont4				@;comprobamos que no sea un espacio vacío, hueco, bloque, etc
		mov r10, #ROWS-1			@;cargamos en r10 el numero de filas menos 1
		mov r12, #COLUMNS			@;cargamos en r12 el numero de columnas
		mul r8, r10, r12			@;multiplicamos r10 y r12 para tener r8 apuntando a la primera posicion de la ultima fila
		bl cuenta_repeticiones
		mov r10, r0					@;guardamos el numero para utilizar r0 como contador
		cmp r10, #3
		blo .Lsumacont3				@;siguiente pos SIN contador sumador
		add r6, r6, #1				@;en r6 suma 1 al numero de secuencias totales
		mov r12, r5					@;contador auxiliar
	.Lminibucle3:					@;miramos si ya hay algun numero en la combinacion
		cmp r0, #0
		beq .Lfiminibucle			@;sale del bucle cuando acaba de mirar todas las posiciones
		sub r0, r0, #1				
		ldrb r11, [r4, r12]			@;carga en r11 el valor del contador de la matriz de marcas
	    cmp r12, r8					@;sale del bucle si estamos en la ultima fila ya que no queremos que actualice contador
		bhs .Lfiminibucle
		add r12, r12, #COLUMNS		@;sumamos el numero de columns para pasar a la siguiente 
		cmp r11, #0					@;si el valor encontrado en la matriz de marcas es 0, siguiente posicion del bucle
		beq .Lminibucle3
	.Lfiminibucle:
		mov r0, r10					@;volvemos a poner el valor original de r0 en r0
		cmp r11, #0					@;miramos si el ultimo numero que se ha mirado en el bucle anterior es 0
		beq .LguardaNouNumSec		@;si es 0, se trata de una nueva secuencia
		mov r6, r11					@;si hemos encontrado un numero en la secuencia, ponemos ese en la matriz de marcas
		b .Lminibucle2
	.LguardaNouNumSec:
		ldrb r11, =num_sec			@;guarda el nuevo numero de secuencias en el caso de que haya una nueva
		strb r6, [r11]
	.Lminibucle2:
		cmp r0, #0					
		beq .Lendif8				@;siguiente pos CON contador sumado
		strb r6, [r4, r5]			@;guardamos el valor de r6 (el numero de secuencia) en la matriz de marcas
		sub r0, r0, #1
	    cmp r5, r8					@;salimos del bucle si nos encontramos en la ultima fila ya que no queremos que sume el contador
		bhs .Lendif8
		add r5, r5, #COLUMNS		@;siguiente posicion del bucle
		b .Lminibucle2
	.Lsumacont4:
		add r5, #COLUMNS			@;sumamos num columns al contador despues de un espacio vacio, hueco, bloque, etc
		cmp r1, #ROWS-1				@;sumamos 1 a la fila si se puede, sino saltamos columna
		blo .Lendif9
		mov r1, #-1
		add r2, r2, #1				@;saltamos columna
		mov r5, r2					@;cambiamos de columna
		b .Lendif9
	.Lsumacont3:
		mov r11, #COLUMNS			@;movemos a r11 el numero de columnas
		mul r0, r10, r11			@;en r0 guardamos el numero de posiciones que tiene que avanzar el contador (num sec * columnas)
		add r5, r5, r0				@;sumamos contador
		mov r0, r10					@;devolvemos a r0 el valor original del cuenta repeticiones
	.Lendif8:
		sub r10, r10, #1			@;restamos para aumentar hasta la fila con el ultimo elemento igual
		add r1, r1, r10				@;tenemos la posición actual de la fila
		cmp r1, #ROWS-1				@;si se puede, sumamos 1 a la fila para la siguiente posición
		blo .Lendif9
		mov r1, #-1					@;saltamos a la siguiente columna porque no hay mas filas
		add r2, r2, #1
		mov r5, r2					@;ponemos el contador al principio de la columna
	.Lendif9:						@;avanzar posición bucle general
		add r1, r1, #1				@;avanzamos fila
		ldrb r11, =num_sec			@;cargamos de nuevo en r6 el numero de secuencias totales
		ldrb r6, [r11]
		b .Lbucle4
	.Lfibucle4:
		ldrb r11, =num_sec			@;guardamos finalmente el numero total de secuencias encontradas en la variable global
		strb r6, [r11]		
		pop {r0-r12,pc}



.end
