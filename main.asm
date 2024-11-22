.model small
.stack 256h
CR equ 13d

.data
charset      db '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', 0 ; tabla de caracteres
resp1        db 10d dup (0)                               ; respuesta del usuario
random_index dw 0                                         ; índice aleatorio
char_count   dw 4                                         ; contador para el bucle
random_chars db 10d dup('?')                              ; espacio para almacenar 4 caracteres aleatorios
user_points  dw 0
points_msg   db 'Puntos: ', '$'

.code
start:
    mov ax, @data                                         ; inicializa el segmento de datos
    mov ds, ax

    ; Generar 4 caracteres aleatorios
    mov cx, char_count                                    ; número de caracteres a generar
    lea di, random_chars                                  ; dirección de almacenamiento en random_chars
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
    call limpiar_pantalla                                 ; limpiar pantalla luego de mostrar
    mov  ax, offset resp1                                 ; guardamos la direccion de inicio de la variable resp1 en ax
    call get_str                                          ; subrutina getstring
    call limpiar_pantalla                                 ; limpiamos la pantalla
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
    jge end_program                                       ; Si char_count >= 10, terminar el programa

    inc char_count                                        ; De lo contrario, aumentar la longitud de la secuencia
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
end_program:
    call limpiar_pantalla
    lea dx, points_msg
    mov ah, 09h
    int 21h
    ; Convertir user_points a cadena para imprimir
    mov ax, user_points
    call print_number                                     ; Llamar a una subrutina para imprimir el número
    mov ax, 4c00h
    int 21h                                               ; terminar y volver a DOS
end start
