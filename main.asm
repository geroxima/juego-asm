.model small
.stack 256h
CR equ 13d

.data
charset      db '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', 0 ; tabla de caracteres
resp1        db 10d dup (0)                               ; respuesta del usuario
random_index dw 0                                         ; índice aleatorio
char_count   dw 5                                         ; contador para el bucle
random_chars db 10d dup('?')                              ; espacio para almacenar 10 caracteres aleatorios
user_points  dw 0
points_msg   db 'Puntos: ', '$'
level_msg    db 'Nivel: ', '$'
level        dw 1   
memorize_msg db 'Memoriza la Secuencia: ','$'
input_msg db 'Ingresa la Secuencia: ','$'
next_msg db 'Correcto!Siguiente ronda: ','$'
win_msg      db '¡Ganaste! ¿Que deseas hacer?', 13d, 10d, '0. Reiniciar Juego', 13d, 10d, '1. Salir del juego', 13d, 10d, '? $'	

.code
start:
    mov ax, @data                                         ; inicializa el segmento de datos
    mov ds, ax

    ; Generar 4 caracteres aleatorios
    mov cx, char_count                                    ; número de caracteres a generar
    lea di, random_chars                                  ; dirección de almacenamiento en random_chars
    call level_message                                    ; mostrar el mensaje de nivel
generate_loop:
    call get_random_index                                 ; generar índice aleatorio
                                                          ; Extraer el carácter basado en el índice aleatorio
    mov  al,   byte ptr random_index                      ; corregido para acceder al byte bajo
    mov  ah,   0                                          ; limpiar el registro alto
    lea  si,   charset                                    ; cargar la dirección de la tabla
    add  si,   ax                                         ; sumar el índice para apuntar al carácter
    mov  al,   [si]                                       ; cargar el carácter
    mov  [di], al                                         ; almacenar el carácter en random_chars
    inc  di                                               ; mover al siguiente espacio en random_chars
    loop generate_loop                                    ; repetir hasta generar 4 caracteres

                                                          ; Imprimir los caracteres generados
    lea si, random_chars                                  ; cargar la dirección de los caracteres generados
    mov cx, char_count                                    ; número de caracteres a imprimir
print_loop:
    mov  dl, [si]                                         ; cargar el carácter en DL
    mov  ah, 02h                                          ; función para imprimir un carácter
    int  21h                                              ; llamar a la interrupción de DOS
    inc  si                                               ; mover al siguiente carácter
    loop print_loop                                       ; repetir hasta imprimir todos los caracteres
    call sleep_time                                       ; esperamos un segundo                       
                                                          ; limpiar pantalla luego de mostrar
    call fill_line_with_spaces
    mov  ax, offset resp1                                 ; guardamos la direccion de inicio de la variable resp1 en ax
    call get_str                                          ; subrutina getstring
    call fill_line_with_spaces                                 ; limpiamos la pantalla
    mov  si, 0                                            ; seteamos el contador de indices
    call comparar                                         ; comparamos
                                                          ; Finalizar el programa
    call end_program
comparar:
    mov bh, random_chars[SI]                              ; Cargar el carácter actual de la secuencia
    mov al, bh                                            ; Cargar el carácter en AL
    call putc                                             ; Mostrar el carácter para retroalimentación

    cmp resp1[SI], bh                                     ; Comparar la entrada del usuario con el carácter actual
    jne end_program                                       ; Si no son iguales, saltar a end_program

incrementar:
    inc SI                                                ; Mover al siguiente carácter en la secuencia
    cmp SI, char_count                                    ; Verificar si todos los caracteres han sido comparados
    jl comparar                                           ; Si no, continuar comparando

                                                          ; Si todos los caracteres coinciden:
    call limpiar_pantalla                                 ; Limpiar la pantalla
    mov ax, user_points
    add ax, char_count                                    ; Sumar el valor actual de char_count a user_points
    mov user_points, ax                                   ; Actualizar user_points

    cmp char_count, 10                                    ; Verificar si char_count ha alcanzado el límite máximo (10)
    jge win_message                                       ; Si char_count >= 10, mostrar el mensaje de victoria

    inc char_count                                        ; De lo contrario, aumentar la longitud de la secuencia
    inc level                                             ; Aumentar el nivel
    jmp start                                             ; Reiniciar el juego

                                                          ; Subrutina para generar un índice aleatorio entre 0 y 35
get_random_index:
    push cx                                               ; guardar cx en la pila
    mov  ah, 0h                                           ; interrumpir para obtener la hora en tiempo real del sistema
    int  1ah                                              ; la hora se guardará en dx
    pop  cx                                               ; recuperar el valor original de cx
    mov  ax, dx                                           ; mover la hora a ax
    xor  dx, dx                                           ; limpiar dx
    mov  bx, 36                                           ; divisor para generar un número entre 0 y 35
    div  bx                                               ; divide ax por bx
    mov  random_index, dx                                 ; almacenar el índice aleatorio en random_index
    ret
limpiar_pantalla:                                         ; limpia la pantalla del MS-DOS
    push ax                                               ; save ax
    push bx                                               ; save bx
    push cx                                               ; save cx
    push dx                                               ; save dx
    mov  ah, 00h
    mov  al, 03h
    int  10h
    pop  dx                                               ; restore dx
    pop  cx                                               ; restore cx
    pop  bx                                               ; restore bx
    pop  ax                                               ; restore ax
    ret
fill_line_with_spaces:
    mov ah, 02h                                            ; Interrupcion para imprimir en pantalla
    mov dl, 13                                             ; Codigo ASCII para Carriadge return
    int 21h                                                ; Mostrar carriage return
    mov cx, char_count                                     ; Definir el contado igual que la cantidad de caracteres
fill_loop:
    mov dl, 95                                             ; Codigo ASCII para '_'
    int 21h                                                ; Imprimir caracter '_'
    loop fill_loop                                         ; Decrementar CX y repetir hasta que CX = 0
    mov dl, 13                                             ; Volver al principio de línea
    int 21h
    ret

    ; subrutina para mantener el tiempo entre operaciones
sleep_time:
    push cx
    push dx
    mov  ah, 86h                                          ; la func que hace esperar
    mov  cx, 000Fh                                        ; en este caso un millon de micro segundos
    mov  dx, 4240h
    int  15h
    pop  dx
    pop  cx
    ret
get_str:                                                  ; lee el string terminado por CR dentro del arreglo cuya direccion esta en ax
    push ax                                               ; guarda registros
    push bx
    push cx
    push dx
    mov  bx,            ax
    call getc                                             ; lee el primer caracter
    mov  byte ptr [bx], al                                ; En C: str[i] = al
get_loop:
    cmp  al,            13                                ; al == CR ?
    je   get_fin                                          ; mientras al != CR
    inc  bx                                               ; bx = bx + 1
    call getc                                             ; lee el siguiente caracter
    mov  byte ptr [bx], al                                ; In C: str[i] = al

    jmp get_loop                                          ; repite la prueba del bucle
get_fin: mov byte ptr [bx], 0                             ; string terminado con 0
    pop dx
    pop cx
    pop bx
    pop ax
    ret
getc:                                                     ; lee caracter dentro de al
    push bx                                               ; guarda bx
    push cx                                               ; guarda cx
    push dx                                               ; guarda dx
    mov  ah, 1h
    int  21h
    pop  dx                                               ; repone dx
    pop  cx                                               ; repone cx
    pop  bx                                               ; repone bx
    ret
putc:                                                     ; exhibe caracter en al
    push ax                                               ; guarda ax
    push bx                                               ; guarda bx
    push cx                                               ; guarda cx
    push dx                                               ; guarda dx
    mov  dl, al
    mov  ah, 2h
    int  21h
    pop  dx                                               ; repone dx
    pop  cx                                               ; repone cx
    pop  bx                                               ; repone bx
    pop  ax                                               ; repone ax
    ret
print_number:
    push ax
    push bx
    push cx
    push dx
    xor cx, cx                                            ; Limpiar CX (contador de dígitos)
    mov bx, 10                                            ; Base decimal
convert_loop:
    xor dx, dx                                            ; Limpiar DX
    div bx                                                ; AX / BX, cociente en AX, resto en DX
    push dx                                               ; Almacenar el dígito en la pila
    inc cx                                                ; Incrementar el contador de dígitos
    test ax, ax                                           ; Verificar si AX es 0
    jnz convert_loop                                      ; Si no, continuar dividiendo
print_digits:
    pop dx                                                ; Recuperar el dígito de la pila
    add dl, '0'                                           ; Convertir el dígito en carácter ASCII
    mov ah, 02h                                           ; Función de impresión de carácter
    int 21h                                               ; Imprimir el carácter
    loop print_digits                                     ; Repetir para todos los dígitos
    pop dx
    pop cx
    pop bx
    pop ax
    ret
level_message:
    lea dx, level_msg                                    ; Cargar el mensaje de nivel
    call put_str                                             ; Imprimir el mensaje
    mov ax, level                                        ; Cargar el nivel actual
    call print_number                                    ; Llamar a una subrutina para imprimir el número
    mov dl, 13d                                          ; Código ASCII de retorno de carro
    mov ah, 02h                                          ; Función de impresión de carácter
    int 21h                                              ; Llamar a la interrupción de DOS
    mov dl, 10d                                          ; Código ASCII de nueva línea
    mov ah, 02h                                          ; Función de impresión de carácter
    int 21h                                              ; Llamar a la interrupción de DOS
    ret
win_message:
    lea dx, win_msg                                      ; Cargo el mensaje de victoria
    call put_str; Función de impresión de cadena
                                                 ; Imprimir el mensaje
    mov ah, 01h                                          ; Leer un carácter del teclado
    int 21h                                              ; Leer el carácter
    cmp al, '0'                                          ; Comparar el carácter con '0'
    jne end_program                                      ; Si no es '0', finalizar el programa
restart_game:
    call limpiar_pantalla
    mov char_count, 5                                    ; Restablecer la longitud de la secuencia a 4
    mov user_points, 0                                   ; Restablecer los puntos del usuario a 0
    mov level, 1                                         ; Restablecer el nivel a 1
    jmp start                                            ; Reiniciar el juego
end_program:
    call limpiar_pantalla
    lea dx, points_msg   
    call put_str
    ; Convertir user_points a cadena para imprimir
    mov ax, user_points
    call print_number                                     ; Llamar a una subrutina para imprimir el número
    mov ax, 4c00h
    int 21h                                               ; terminar y volver a DOS   
put_str:   
push dx
mov ah,09h
int 21h
pop dx
ret
end start
