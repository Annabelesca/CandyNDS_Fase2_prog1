/*------------------------------------------------------------------------------

	$ candy2_main.c $

	Programa principal para la práctica de Computadores: candy-crash para NDS
	(2º curso de Grado de Ingeniería Informática - ETSE - URV)
	
	Analista-programador: santiago.romani@urv.cat
	Programador 1: annabel.pizarro@estudiants.urv.cat
	Programador 2: yyy.yyy@estudiants.urv.cat
	Programador 3: zzz.zzz@estudiants.urv.cat
	Programador 4: uuu.uuu@estudiants.urv.cat

------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdio.h>
#include <time.h>
#include <candy2_incl.h>


/* variables globales */
char matrix[ROWS][COLUMNS];		// matriz global de juego
int seed32;						// semilla de números aleatorios
int level = 0;					// nivel del juego (nivel inicial = 0)
int points;						// contador global de puntos
int movements;					// número de movimientos restantes
int gelees;						// número de gelatinas restantes
extern char mat_recomb1[ROWS][COLUMNS];	// mapas de configuración
extern char mat_recomb2[ROWS][COLUMNS];	// mapas de configuración
extern elemento vect_elem[ROWS*COLUMNS];// vector de elementos

/* actualizar_contadores(code): actualiza los contadores que se indican con el
	parámetro 'code', que es una combinación binaria de booleanos, con el
	siguiente significado para cada bit:
		bit 0:	nivel
		bit 1:	puntos
		bit 2:	movimientos
		bit 3:	gelatinas  */
void actualizar_contadores(int code)
{
	if (code & 1) printf("\x1b[39m\x1b[10;22H %d", level);
	//if (code & 2) printf("\x1b[39m\x1b[2;8H %d  ", points);
	//if (code & 4) printf("\x1b[38m\x1b[1;28H %d ", movements);
	//if (code & 8) printf("\x1b[37m\x1b[2;28H %d ", gelees);
}


/* inicializa_interrupciones(): configura las direcciones de las RSI y los bits
	de habilitación (enable) del controlador de interrupciones para que se
	puedan generar las interrupciones requeridas.*/ 
void inicializa_interrupciones()
{
	irqSet(IRQ_VBLANK, rsi_vblank);
	TIMER0_CR = 0x00;  		// inicialmente los timers no generan interrupciones
	irqSet(IRQ_TIMER0, rsi_timer0);		// cargar direcciones de las RSI
	irqEnable(IRQ_TIMER0);				// habilitar la IRQ correspondiente
	TIMER1_CR = 0x00;
	irqSet(IRQ_TIMER1, rsi_timer1);
	irqEnable(IRQ_TIMER1);
	TIMER2_CR = 0x00;
	irqSet(IRQ_TIMER2, rsi_timer2);
	irqEnable(IRQ_TIMER2);
	TIMER3_CR = 0x00;
	irqSet(IRQ_TIMER3, rsi_timer3);
	irqEnable(IRQ_TIMER3);
}

/* imprimirInfo(void): imprime por pantalla la configuracion de botones
	disponibles para interactuar con el programa asi como tambien
	las direcciones de memoria donde se encuentra informacion de interes*/
void imprimirInfo()
{
	//informacion
	printf("\x1b[43m\x1b[2;0H ** Test bloque 2A, 2E y 2Ia **");
	printf("\x1b[39m\x1b[10;17H Lvl: ");
	
	//teclas
	printf("\x1b[39m\x1b[13;16H  A: New lvl");
	printf("\x1b[39m\x1b[15;16H  B: Reset lvl");
	printf("\x1b[39m\x1b[17;16H  L: conf/game");
	printf("\x1b[39m\x1b[19;16H  R: recombina");
	printf("\x1b[39m\x1b[21;16H  SELECT: Copy");
	printf("\x1b[39m\x1b[22;16H  mapa config");
	
	//direcciones de memoria
	printf("\x1b[43m\x1b[10;0H Matriz juego:   ");
	printf("\x1b[45m\x1b[4;0H @recomb1: %p", &mat_recomb1);
	printf("\x1b[46m\x1b[5;0H @recomb2: %p", &mat_recomb2);
	printf("\x1b[42m\x1b[6;0H @matriz: %p", &matrix);	
	printf("\x1b[47m\x1b[7;0H @vElem: %p", &vect_elem);
}


/* Programa principal: control general del juego */
int main(void)
{
	int mapActual = 1;
	int initializing = 1;		// =1 indica que hay que inicializar un juego
	int mX, mY, dX, dY;			// variables de detección de pulsaciones

	seed32 = time(NULL);		// fijar semilla de números aleatorios
	init_grafA();
	inicializa_interrupciones();

	consoleDemoInit();			// inicialización de pantalla de texto
	imprimirInfo();

	do{
		////////////////////////	SECCIÓN DE INICIALIZACION	////////////////////////
		if (initializing){
			//copia_mapa(matrix, level);
			inicializa_matriz(matrix, level);
			genera_sprites(matrix);
			escribe_matriz(matrix);
			retardo(5);
			initializing = 0;
			actualizar_contadores(1);
			if(hay_secuencia(matrix)){
				elimina_secuencias(matrix, mat_mar);
				genera_sprites(matrix);
				escribe_matriz(matrix);					// visualiza eliminaciones
			}
		}
		
		
		////////////////////////	SECCIÓN DE JUGADAS	////////////////////////
		if (procesar_touchscreen(matrix, &mX, &mY, &dX, &dY)){
			intercambia_posiciones(matrix, mX, mY, dX, dY);
			escribe_matriz(matrix);	  // muestra el movimiento por pantalla
			
			if (hay_secuencia(matrix))	{	// si el movimiento es posible
				elimina_secuencias(matrix, mat_mar);	
				genera_sprites(matrix);		//Actualizamos matriz con elementos eliminados
			}else intercambia_posiciones(matrix, mX, mY, dX, dY); // si no es posible,deshacer el cambio
			
			escribe_matriz(matrix);	// muetra las eliminaciones o el retorno
		}
		while (keysHeld() & KEY_TOUCH){		// esperar a liberar la
			swiWaitForVBlank();				// pantalla t?ctil
			scanKeys();
		}
		
		
		////////////////////////	SECCIÓN DE DEPURACIÓN	////////////////////////
		if (!initializing){
		
	 		swiWaitForVBlank();
	 		scanKeys();
			
			if (keysHeld() & (KEY_A | KEY_B)) {	//Si pulsa 'A' o 'B'
				//Si pulsa A, se actualizará el mapa para el siguiente nivel, en caso contrario, reinicializara el mismo nivel
				if (keysHeld() & (KEY_A)){	
					level = (level + 1) % MAXLEVEL;
					actualizar_contadores(1);
				}
				initializing=1;
			}
			
			if (keysHeld() & KEY_L){	// si pulsa 'L',
			// alternamos entre mapa juego y mapa configuracion
				if (mapActual==1) {
					printf("\x1b[43m\x1b[10;0H Matriz juego:   ");
					genera_sprites(matrix);
					escribe_matriz(matrix);
					retardo(2);
				}else{
					printf("\x1b[43m\x1b[10;0H Mapa config:    ");
					genera_sprites(mapas[level]);
					escribe_matriz(mapas[level]);
					retardo(2);
				}
				mapActual=!mapActual;
			}
			
			if (keysHeld() & KEY_R){	// si pulsa 'R',
				// Llamamos a la funcion para recombinar la matriz 
				printf("\x1b[43m\x1b[10;0H Recombinando! ");
				recombina_elementos(matrix);
				activa_timer0(1);		// activar timer de movimientos
				while (timer0_on) swiWaitForVBlank();	// espera final
				escribe_matriz(matrix);
				printf("\x1b[43m\x1b[10;0H Matriz juego:   ");
				retardo(2);
			}
			
			if (keysHeld() & KEY_SELECT){	//Si pulsa 'SELECT'
				printf("\x1b[43m\x1b[10;0H Mapa config:    ");
				copia_mapa(matrix, level);	
				swiWaitForVBlank();
				escribe_matriz(matrix);
				genera_sprites(matrix);
				retardo(2);
			}
		}
		
	}while(1);
	
	return(0);					// nunca retornará del main
}

