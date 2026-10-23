.data
cadena: .asciz "Seleccione el nivel (1, 2 o 3): \n"
nivelElegido: .byte 0, 0

mapa1: .asciz "#######\n#  .  #\n#  $  #\n#  @  #\n#######\n"
mapa2: .asciz "########\n#  #   #\n# $ .  #\n# @  $ #\n#   .  #\n########\n"
mapa3: .asciz "##########\n#   ..   #\n#  $$$$  #\n#   @    #\n#   ..   #\n##########\n"

jugador_pos: .word 0
matriz_activa: .word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
ancho_actual: .word 0
tamano_actual: .word 0 
mapa_origen: .word 0
movimientos: .word 0
hubo_fail: .byte 0
tecla_ingresada: .byte 0, 0
buffer_ascii: .byte 0,0,0,0,0,0,0,0,0,0,0,0
cls: .asciz "\x1b[H\x1b[2J"
lencls = . - cls
msg_movimientos: .asciz "Movimientos: "
msg_pedir_tecla: .asciz "\nMovimiento (W/A/S/D, R reinicia, Q sale): "
msg_fail:        .asciz "\nFail\n"

.text
.global main

main:
        //muestra mensaje en pantalla para elegir nivel
        mov r0, #1
        ldr r1, =cadena
        mov r2, #33
        mov r7, #4
        swi #0

        //lee y guarda el nivel elegido por el usuario
        mov r0, #0
        ldr r1, =nivelElegido
        mov r2, #2
        mov r7, #3
        swi #0

        //Interpretacion del dato ingresado por el usuario
        ldr r1, =nivelElegido
        ldr r2, [r1]
        and r2, r2, #255

        //Comparacion de los datos guardados con los numeros dados
        cmp r2, #'1'
        beq nivel_1
        cmp r2, #'2'
        beq nivel_2
        cmp r2, #'3'
        beq nivel_3

	bal main

//Le asignamos a cada mapa su valor para despues imprimirlos
nivel_1:
        ldr r1, =mapa1
        mov r2, #40
        mov r7, #4

	ldr r0, =mapa1
	ldr r1, =mapa_origen
	str r0, [r1]

	mov r1, #40
	ldr r2, =tamano_actual
	str r1, [r2]

	mov r1, #8
	ldr r2, =ancho_actual
	str r1, [r2]
        // SALTAR A iniciar_partida (reemplazará a 'bal fin' cuando implementen el loop)
        bal iniciar_partida

nivel_2:
        ldr r1, =mapa2
        mov r2, #54
        mov r7, #4

        ldr r0, =mapa2
        ldr r1, =mapa_origen
        str r0, [r1]

	mov r1, #54
        ldr r2, =tamano_actual
        str r1, [r2]

        mov r1, #9
        ldr r2, =ancho_actual
        str r1, [r2]

        bal iniciar_partida

nivel_3:
        ldr r1, =mapa3
        mov r2, #66
        mov r7, #4

        ldr r0, =mapa3
        ldr r1, =mapa_origen
        str r0, [r1]

        mov r1, #66
        ldr r2, =tamano_actual
        str r1, [r2]

        mov r1, #11
        ldr r2, =ancho_actual
        str r1, [r2]

        bal iniciar_partida

iniciar_partida:
    bl cargar_mapa          // Copia el mapa origen a matriz_activa y localiza al jugador
    			    // Inicializar movimientos y fail en 0
    mov r3, #0
    ldr r4, =movimientos
    str r3, [r4]
    ldr r4, =hubo_fail
    strb r3, [r4]

loop_juego:
    bl mostrar_mapa         // Dibuja el mapa activo
    bl pedir_movimiento     // Pide la tecla al usuario (devuelve la letra validada en r0)

    // Si la tecla es 'Q', salir del programa
    cmp r0, #'Q'
    beq fin

    // Si la tecla es 'R', reiniciar el nivel
    cmp r0, #'R'
    beq iniciar_partida

    bl obtener_posicion_siguiente
    bl verificar_y_mover

    // Si es W, A, S o D, por ahora volvemos al loop (hasta que agregues verificar_y_mover)
    bal loop_juego

        //cierre exitoso
        mov r0, #0
fin:
        mov r7, #1
        swi 0

// SUBRUTINAS

//SUBRUTINA 1 LIMPIAR__MAPA
limpiar_pantalla:
	PUSH {r7, lr}
 	mov r0, #1
	ldr r1, =cls
	ldr r2, =lencls
	mov r7, #4 
	swi 0
	POP {r7, pc}
//SUBRUTINA CARGAR_MAPA
cargar_mapa:
	PUSH {r4-r6, lr}
        ldr r0, =mapa_origen
        ldr r0, [r0]
        ldr r1, =matriz_activa
        ldr r2, =tamano_actual
        ldr r2, [r2]
        mov r3, #0

bucle_copia:
        cmp r3, r2
        beq fin_cargar_mapa

        ldrb r4, [r0,r3]
        strb r4, [r1,r3]

        cmp r4, #'@'
        bne siguiente_byte
        ldr r5, =jugador_pos
        str r3, [r5]

siguiente_byte:
        add r3,r3, #1
        bal bucle_copia

fin_cargar_mapa:
        POP {r4-r6, pc}


//SUBRUTINA 3 MOSTRA_MAPA
mostrar_mapa:
    PUSH {r4-r7, lr}
    bl limpiar_pantalla
    mov r0, #1                   //salida #1 para mostrar en pantalla
    ldr r1, =matriz_activa       //cargamos la dirrecion de matriz actica en r1
    ldr r2, =tamano_actual       //cargamos la dirrecion de tamañano actual en r2
    ldr r2, [r2]                 //se carga el contenido de la dirrecion tamaño actual
    mov r7, #4                   //instruccion para dibujar en pantalla
    swi #0                       // interrupcion para leer el codigo anterior
fin_mostrar_mapa:
    POP {r4-r7, pc}

//SUBRUTINA 4 PASAR NUMERO A ASCII
pasar_numero_a_ascii:
	PUSH {r4-r6, lr} // Guarda temp. en la RAM los registros r4 a r6 y lr
	cmp r0, #0
	bne convertir // si no es 0 salta a convertir
	mov r4, #48 // si es, carga el codigo ASCII de 0 en r4
	strb r4, [r1]
	mov r2, #1  // define la longitud de la cadena
	bal fin_conversion
convertir:
	mov r4, #0  // Inicia el contador de digitos en 0
convertir_division:
	cmp r0, #0
	beq apilar	//si r0 llego a 0, termina de dividir

	mov r5, #0	//inicia el cociente en 0
	mov r6, r0	//copia el valor actual de r0 en r6
convertir_resta:
	cmp r6, #10
	blt guardar_resto // BLT  Salta si es menor
	sub r6, r6, #10	//resta 10 a r6
	add r5, r5, #1	//aumenta el cociente en 1 por cada resta
	bal convertir_resta
guardar_resto:
	add r6, r6, #48
	PUSH {r6}
	add r4, r4, #1
	mov r0, r5
	bal convertir_division
apilar:
	mov r2, r4
escribir:
	cmp r4, #0
	beq fin_conversion
	POP {r6}
	strb r6, [r1]
	add r1, r1, #1
	sub r4, r4, #1
	bal escribir
fin_conversion:
	POP {r4-r6, pc}

//SUBRUTINA 5 PEDIR MOVIMIENTO
pedir_movimiento:
	PUSH {r4-r7, lr}
pedir_tecla:
	// Muestra en pantalla un mensaje pidiendo la tecla
	mov r0, #1
	ldr r1, =msg_pedir_tecla
	mov r2, #43
	mov r7, #4
	swi 0

	// Lee la tecla ingresada por el usuario
	mov r0, #0
	ldr r1, =tecla_ingresada
	mov r2, #2
	mov r7, #3
	swi 0

	// Extrae y limpia el byte leido
	ldr r1, =tecla_ingresada
	ldr r0, [r1]
	and r0, r0, #255                 // Aplica una mascara AND para quedarse con el primer byte

	// Convertir letras minusculas a mayusculas
	cmp r0, #'a'
	blt verificar_teclas            //si es menor que a no es minuscula
	cmp r0, #'z'
	bgt verificar_teclas // si es mayor que z no es minuscula
	sub r0, r0, #32	// si esta entre a y z le resta 32 para su equivalente en mayuscula
verificar_teclas:
	// Verifica si la tecla esta permitida
	cmp r0, #'W'              // Compara el carácter con 'W'
	beq tecla_valida          // Si es igual, la tecla es válida y salta
	cmp r0, #'A'
    	beq tecla_valida
    	cmp r0, #'S'
    	beq tecla_valida
    	cmp r0, #'D'
    	beq tecla_valida
    	cmp r0, #'R'
    	beq tecla_valida
    	cmp r0, #'Q'
    	beq tecla_valida

	// si no coincide con ninguna
	bal pedir_tecla
tecla_valida:
	POP {r4-r7, pc} // Restaura los registros originales y retorna al programa principal

// SUBRUTINA 6: obtener_posicion_siguiente
obtener_posicion_siguiente:
	PUSH {r4-r5, lr}
	ldr r3,=jugador_pos
	ldr r3, [r3]

	ldr r4,=ancho_actual
	ldr r4,[r4]
	
	cmp r0, #'W'
	beq des_arriba
	cmp r0, #'S'
	beq des_abajo
	cmp r0, #'A'
	beq des_izquierda
	cmp r0, #'D'
	beq des_derecha

des_arriba:
	rsb r5, r4, #0
	bal calcular_direcciones 
des_abajo:
	mov r5, r4
	bal calcular_direcciones
des_derecha:
	mov r5, #1
	bal calcular_direcciones
des_izquierda:
	mov r5, #-1
	bal calcular_direcciones

calcular_direcciones:
	ldr r1,=matriz_activa
	add r1, r1, r3
	add r1, r1, r5
	add r2, r1, r5
	POP {r4-r5, pc}


verificar_y_mover:
    PUSH {r4-r7, lr}          // Guarda los registros utilizados en la pila

    ldr r3, =jugador_pos      
    ldr r3, [r3]              // r3 = offset actual del jugador
    ldr r4, =matriz_activa    
    add r4, r4, r3            // r4 = dirección exacta de la celda origen del jugador

    ldrb r5, [r4]             // r5 = carácter de origen ('@' o '+')
    ldrb r6, [r1]             // r6 = carácter de la celda siguiente

    // CASO 1: Choca contra una pared ('#')
    cmp r6, #'#'
    beq es_fail

    // CASO 2: La celda siguiente está libre (' ' o '.')
    cmp r6, #' '
    beq mover_jugador_libre
    cmp r6, #'.'
    beq mover_jugador_libre

    // CASO 3: Hay una caja ('$' o '*')
    cmp r6, #'$'
    beq evaluar_caja
    cmp r6, #'*'
    beq evaluar_caja

    b fin_mover               // Por seguridad, si hay otro carácter inesperado

es_fail:
    mov r5, #1
    ldr r6, =hubo_fail
    strb r5, [r6]             // hubo_fail = 1
    b fin_mover

evaluar_caja:
    // Mirar qué hay detrás de la caja ([r2])
    ldrb r7, [r2]
    cmp r7, #'#'              // Si detrás hay pared -> Fail
    beq es_fail
    cmp r7, #'$'                // (Otras cajas detrás tampoco se pueden empujar)
    beq es_fail
    cmp r7, #'*'
    beq es_fail

    // Si detrás hay espacio (' ') o destino ('.'), empujamos la caja:
    cmp r7, #'.'
    beq caja_sobre_destino_atras
    mov r7, #'$'                // Pone caja normal '$' atrás
    b escribir_caja_atras

caja_sobre_destino_atras:
    mov r7, #'*'              // Pone caja sobre destino '*' atrás

escribir_caja_atras:
    strb r7, [r2]             // Guarda la caja en la celda de atrás

    // Ahora movemos al jugador a la celda siguiente ([r1])
    cmp r6, #'*'              // Si la caja estaba sobre un destino
    beq jugador_sobre_destino_sig
    mov r6, #'@'              // Jugador normal '@'
    b escribir_jugador_sig

jugador_sobre_destino_sig:
    mov r6, #'+'              // Jugador sobre destino '+'

escribir_jugador_sig:
    strb r6, [r1]
    b actualizar_origen_y_movs

mover_jugador_libre:
    cmp r6, #'.'              // Si entra a un destino
    beq entra_a_destino
    mov r6, #'@'              // Entra a piso vacío
    b escribe_destino_libre

entra_a_destino:
    mov r6, #'+'              // Entra a destino con jugador

escribe_destino_libre:
    strb r6, [r1]

actualizar_origen_y_movs:
    // Limpiar la celda que abandona el jugador ([r4])
    cmp r5, #'+'              // Si el jugador estaba sobre un destino
    beq origen_era_destino
    mov r5, #' '              // Deja espacio vacío
    b guardar_origen

origen_era_destino:
    mov r5, #'.'              // Deja un punto de destino visible

guardar_origen:
    strb r5, [r4]

// Actualizar la variable jugador_pos con el nuevo offset
    ldr r5, =matriz_activa
    sub r6, r1, r5            // Calcula el nuevo offset restando la base
    ldr r7, =jugador_pos
    str r6, [r7]

    // Incrementar el contador de movimientos en 1
    ldr r5, =movimientos
    ldr r6, [r5]
    add r6, r6, #1
    str r6, [r5]

fin_mover:
    POP {r4-r7, pc}
