    .model small
    .stack 256h
    CR equ 13d

    .data
    LV           dw 5d
    charset      db '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', 0      ; tabla de caracteres
    resp1        db 10d dup (0)
    random_index dw 0                                              ; índice aleatorio
    char_count   dw 9                                              ; contador para el bucle
    random_chars db 10d dup('?')                                   ; espacio para almacenar 4 caracteres aleatorios
    count        db 0                                              ; contador para el bucle

    .code
    start:
        mov ax, @data                                              ; inicializa el segmento de datos
        mov ds, ax

        ; Generar 4 caracteres aleatorios
        mov cx, char_count                                         ; número de caracteres a generar
        lea di, random_chars                                       ; dirección de almacenamiento en random_chars
    generate_loop:
        call get_random_index                                      ; generar índice aleatorio
                                                                   ; Extraer el carácter basado en el índice aleatorio
        mov  al,   byte ptr random_index                           ; corregido para acceder al byte bajo
        mov  ah,   0                                               ; limpiar el registro alto
        lea  si,   charset                                         ; cargar la dirección de la tabla
        add  si,   ax                                              ; sumar el índice para apuntar al carácter
        mov  al,   [si]                                            ; cargar el carácter
        mov  [di], al                                              ; almacenar el carácter en random_chars
        inc  di                                                    ; mover al siguiente espacio en random_chars
        loop generate_loop                                         ; repetir hasta generar 4 caracteres

                                                                   ; Imprimir los caracteres generados
        lea si, random_chars                                       ; cargar la dirección de los caracteres generados
        mov cx, char_count                                         ; número de caracteres a imprimir
    print_loop:
        mov  dl, [si]                                              ; cargar el carácter en DL
        mov  ah, 02h                                               ; función para imprimir un carácter
        int  21h                                                   ; llamar a la interrupción de DOS
        inc  si                                                    ; mover al siguiente carácter
        loop print_loop                                            ; repetir hasta imprimir todos los caracteres
        call sleep_time                                            ; esperamos un segundo
        call limpiar_pantalla                                      ; limpiar pantalla luego de mostrar
        mov  ax, offset resp1                                      ; guardamos la direccion de inicio de la variable resp1 en ax
        call get_str                                               ; subrutina getstring
        call limpiar_pantalla                                      ; limpiamos la pantalla
        mov  si, 0                                                 ; seteamos el contador de indices
        call comparar                                              ; comparamos
                                                                   ; Finalizar el programa
        call end_program
    comparar:
    mov bh, random_chars[SI]                                       ; Load the current character from the sequence
    mov al, bh
    call putc                                                      ; Display the character for feedback

    cmp resp1[SI], bh                                              ; Compare user input with the current character
    jne end_program                                                ; If not equal, jump to end_program

incrementar:
    inc SI                                                         ; Move to the next character in the sequence
    cmp SI, char_count                                             ; Check if all characters have been compared
    jl comparar                                                    ; If not, continue comparing

                                                                   ; If all characters match:
    call limpiar_pantalla                                          ; Clear the screen
    cmp char_count, 10                                             ; Check if char_count has reached the maximum limit (10)
    jge end_program                                                      ; If char_count >= 10, restart without incrementing
    inc char_count                                                 ; Otherwise, increase the sequence length
    jmp start                                                      ; Restart the game
                                                                   ; Restart the game

                                                                   ; Subrutina para generar un índice aleatorio entre 0 y 35
    get_random_index:
        push cx                                                    ; guardar cx en la pila
        mov  ah,           0h                                      ; interrumpir para obtener la hora en tiempo real del sistema
        int  1ah                                                   ; la hora se guardará en dx
        pop  cx                                                    ; recuperar el valor original de cx
        mov  ax,           dx                                      ; mover la hora a ax
        xor  dx,           dx                                      ; limpiar dx
        mov  bx,           36                                      ; divisor para generar un número entre 0 y 35
        div  bx                                                    ; divide ax por bx
        mov  random_index, dx                                      ; almacenar el índice aleatorio en random_index
        ret
    limpiar_pantalla:                                              ; limpia la pantalla del MS-DOS
            push ax                                                ; save ax
            push bx                                                ; save bx
            push cx                                                ; save cx
            push dx                                                ; save dx
            mov  ah, 00h
            mov  al, 03h
            int  10h
            pop  dx                                                ; restore dx
            pop  cx                                                ; restore cx
            pop  bx                                                ; restore bx
            pop  ax                                                ; restore ax
            ret
            ; subrutina para mantener el tiempo entre operaciones
    sleep_time:
        push cx
        push dx
        mov  ah, 86h                                               ; la func que hace esperar
        mov  cx, 000Fh                                             ; en este caso un millon de micro segundos
        mov  dx, 4240h
        int  15h
        pop  dx
        pop  cx
        ret
        ; Finalizar el programa
    get_str:                                                       ; lee el string terminado por CR dentro del arreglo cuya direccion esta en ax
            push ax                                                ; guarda registros
            push bx
            push cx
            push dx
            mov  bx,            ax
            call getc                                              ; lee el primer caracter
            mov  byte ptr [bx], al                                 ; En C: str[i] = al
    get_loop:
            cmp  al,            13                                 ; al == CR ?
            je   get_fin                                           ; mientras al != CR
            inc  bx                                                ; bx = bx + 1
            call getc                                              ; lee el siguiente caracter
            mov  byte ptr [bx], al                                 ; In C: str[i] = al

            jmp get_loop                                           ; repite la prueba del bucle
    get_fin: mov byte ptr [bx], 0                                  ; string terminado con 0
            pop dx
            pop cx
            pop bx
            pop ax
            ret

    getc:                                                          ; lee caracter dentro de al
            push bx                                                ; guarda bx
            push cx                                                ; guarda cx
            push dx                                                ; guarda dx
            mov  ah, 1h
            int  21h
            pop  dx                                                ; repone dx
            pop  cx                                                ; repone cx
            pop  bx                                                ; repone bx
            ret
    putc:                                                          ; exhibe caracter en al
            push ax                                                ; guarda ax
            push bx                                                ; guarda bx
            push cx                                                ; guarda cx
            push dx                                                ; guarda dx
            mov  dl, al
            mov  ah, 2h
            int  21h
            pop  dx                                                ; repone dx
            pop  cx                                                ; repone cx
            pop  bx                                                ; repone bx
            pop  ax                                                ; repone ax
            ret
    end_program:
        mov ax, 4c00h
        int 21h                                                    ; terminar y volver a DOS

    end start
