.model small
.stack 100h

.data
    window_width dw 140h
    window_height dw 0c8h
    window_bound dw 06h

    snake_x dw 20h
    snake_y dw 20h
    snake_x_size dw 0ah
    snake_y_size dw 06h

    frog_x dw 2ah
    frog_y dw 2ah
    frog_size dw 06h
    frog_offset dw 0ffh

    snake_original_x dw 20h
    snake_original_y dw 20h
    snake_original_velocity_x dw 05h
    snake_original_velocity_y dw 00h
    snake_original_size_x dw 0ah
    snake_original_size_y dw 06h

    frog_original_x dw 2ah
    frog_original_y dw 2ah

    snake_max_velocity_x dw 08h
    snake_max_velocity_y dw 08h

    snake_velocity_x dw 05h
    snake_velocity_y dw 00h

    player_points db 00h
    text_player_points db 3 dup(?)

    ui_row db 01h
    ui_col db 01h

    time_aux db 00h

    game_mode db 01h  ; to check if game is over or not
    text_game_over db "Game Over",'$'
    text_game_restart db "Press R to restart the game",'$'
    text_your_score db "your score:",'$'
    text_exit_game db "Press E to exit",'$'

    exit_game_status db 00h  ;to check if we pressed 'e' in game over menu

    highscore_file_loc db "C:\SCORE.TXT"
    file_handler dw 0

    text_highscore db "High Score:",'$'

    text_highscore_value db "00",'$'
    highscore_value db 00h
    hex_text_highscore_value db "00","$"

.code
start:
    main proc
        mov ax, @data
        mov ds, ax

        call handle_file
        call read_file
        ;call close_file ;close the file otherwise while writing the file it will append the res
                        ;instead of overwriting it

        ;call handle_file

        call clear_screen

        check_time:
            mov ah, 2ch
            int 21h

            cmp dl, time_aux
            je check_time

        mov time_aux, dl

        cmp exit_game_status, 01h
        je exit_game

        cmp game_mode, 00h
        je game_over_screen

        call clear_screen

        call draw_border

        call draw_ui

        call snake_auto_move
        call snake_key_press
        call snake_body

        call frog_body

        jmp check_time

        game_over_screen:
            call reset_position
            call game_over_ui
            jmp check_time

        exit_game:
            mov ah, 00h
            mov al, 02h
            int 10h

            mov ax, 4c00h
            int 21h
            ret
    main endp

    clear_screen proc
        mov ah, 00h
        mov al, 13h
        int 10h

        mov ah, 0bh
        mov bh, 00h
        mov bl, 00h
        int 10h
        ret
    clear_screen endp

    draw_border proc
        mov cx, 00h
        mov dx, 00h

        left_border:
            mov ah, 0ch
            mov al, 0fh
            int 10h

            inc cx
            mov ax, cx
            cmp ax, window_bound
            jng left_border

            mov cx, 00h
            inc dx
            mov ax, dx
            cmp ax, window_height
            jng left_border

        mov cx, window_width
        sub cx, window_bound
        mov dx, 00h

        right_border:
            mov ah, 0ch
            mov al, 0fh
            int 10h

            inc cx
            mov ax, cx
            cmp ax, window_width
            jng right_border

            mov cx, window_width
            sub cx, window_bound
            inc dx
            mov ax, dx
            cmp ax, window_height
            jng right_border

        mov cx, 00h
        mov dx, 00h

        up_border:
            mov ah, 0ch
            mov al, 0fh
            int 10h

            inc cx
            mov ax, cx
            cmp ax, window_width
            jng up_border

            mov cx, 00h
            inc dx
            mov ax, dx
            cmp ax, window_bound
            jng up_border

        mov cx, 00h
        mov dx, window_height
        sub dx, window_bound

        bottom_border:
            mov ah, 0ch
            mov al, 0fh
            int 10h

            inc cx
            mov ax, cx
            cmp ax, window_width
            jng bottom_border

            mov cx, 00h
            inc dx
            mov ax, dx
            cmp ax, window_height
            jng bottom_border
        ret
    draw_border endp

    draw_ui proc
        mov ah, 02h
        mov bh, 00h
        mov dh, ui_row
        mov dl, ui_col
        int 10h

        xor ax, ax
        xor dx, dx
        mov al, player_points
        mov bl, 0ah
        div bl

        add ah, 30h
        add al, 30h
        mov si, offset text_player_points

        mov [si], al
        inc si
        mov [si], ah
        inc si
        mov byte ptr [si], '$' ; as compiler does not know '$' data type so specify it
        xor ax, ax

        mov ah, 09h
        lea dx, text_player_points
        int 21h

        ret
    draw_ui endp

    snake_body proc

        mov cx, snake_x
        mov dx, snake_y

        snake_draw:
            mov ah, 0ch
            mov al, 0fh
            int 10h

            inc cx
            mov ax, cx
            sub ax, snake_x
            cmp ax, snake_x_size
            jng snake_draw

            mov cx, snake_x
            inc dx
            mov ax, dx
            sub ax, snake_y
            cmp ax, snake_y_size
            jng snake_draw
        ret
    snake_body endp

    frog_body proc
        mov cx, frog_x
        mov dx, frog_y

        frog_draw:
            mov ah, 0ch
            mov al, 0fh
            int 10h

            inc cx
            mov ax, cx
            sub ax, frog_x
            cmp ax, frog_size
            jng frog_draw

            mov cx, frog_x
            inc dx
            mov ax, dx
            sub ax, frog_y
            cmp ax, frog_size
            jng frog_draw
        ret
    frog_body endp

    snake_auto_move proc
        mov ax, snake_velocity_x
        add snake_x, ax

        mov ax, snake_x
        cmp ax, window_bound
        jl reset_call

        mov ax, window_width
        sub ax, snake_x_size
        sub ax, window_bound
        cmp snake_x, ax
        jg reset_call

        mov ax, snake_velocity_y
        add snake_y, ax

        mov ax, snake_y
        cmp ax, window_bound
        jl reset_call

        mov ax, window_height
        sub ax, snake_y_size
        sub ax, window_bound
        cmp snake_y, ax
        jg reset_call

        call check_collision

        ret

        reset_call:
            mov game_mode, 00h
            ret
    snake_auto_move endp

    reset_position proc
        mov ax, snake_original_x
        mov snake_x, ax

        mov ax, snake_original_y
        mov snake_y, ax
        
        mov ax, snake_original_velocity_x
        mov snake_velocity_x, ax

        mov ax, snake_original_velocity_y
        mov snake_velocity_y, ax

        mov ax, snake_original_size_x
        mov snake_x_size, ax

        mov ax, snake_original_size_y
        mov snake_y_size, ax

        mov ax, frog_original_x
        mov frog_x, ax

        mov ax, frog_original_y
        mov frog_y, ax

        call update_highscore

        mov player_points, 00h
        ret
    reset_position endp

    update_highscore proc
        mov ah, player_points
        cmp ah, highscore_value
        jg change_highscore
        ret

        change_highscore:
            mov highscore_value, ah
            ret
    update_highscore endp

    check_collision proc
        mov ax, snake_x
        add ax, snake_x_size
        cmp ax, frog_x
        jng no_collision

        mov ax, frog_x
        add ax, frog_size
        cmp ax, snake_x
        jng no_collision

        mov ax, snake_y
        add ax, snake_y_size
        cmp ax, frog_y
        jng no_collision

        mov ax, frog_y
        add ax, frog_size
        cmp ax, snake_y
        jng no_collision

        call random_frog_loc

        inc player_points
        ;call update_points

        no_collision:
            ret

    check_collision endp

    random_frog_loc proc
        check_row:
            sub ax, ax
            mov ah, 2ch
            int 21h

            sub dh, dh
            mov ax, frog_offset
            mul dx

            mov bx, window_width
            sub bx, window_bound
            sub bx, frog_size

            div bx

            mov frog_x, dx

            cmp dx, window_bound
            jg check_column

        jmp check_row

        check_column:
            sub ax, ax
            mov ah, 2ch
            int 21h

            sub dh, dh
            mov ax, frog_offset
            mul dx

            mov bx, window_height
            sub bx, window_bound
            sub bx, frog_size

            div bx

            mov frog_y, dx

            cmp dx, window_bound
            jg done
        jmp check_column

        done:
            ret
    random_frog_loc endp

    ;update_points proc
        ;xor ax, ax
        ;mov al, player_points

        ;add al, 30h

        ;mov [text_player_points], al

        ;ret

    ;update_points endp

    snake_key_press proc

        ; check if key is being pressed
        mov ah, 01h
        int 16h
        jz key_not_pressed

        ; check which key pressed(AL=Ascii character) (AL = ASCII character)
        mov ah, 00h
        int 16h

        ;if it is 'w' move up
        up:
            cmp al, 77h ;'w'
            jne down

            mov ax, snake_max_velocity_y
            neg ax
            mov snake_velocity_y, ax

            ;mov ax, snake_original_velocity_x
            mov snake_velocity_x, 00h

            call flip_snake_v
            ret

        ; if it is 's' move down
        down:
            cmp al, 73h ;'s'
            jne left

            mov ax, snake_max_velocity_y
            mov snake_velocity_y, ax

            ;mov ax, snake_original_velocity_x
            mov snake_velocity_x, 00h

            call flip_snake_v
            ret

        ; if it is 'a' move left
        left:
            cmp al, 61h ;'a'
            jne right

            mov ax, snake_max_velocity_x
            neg ax
            mov snake_velocity_x, ax

            ;mov ax, snake_original_velocity_y
            mov snake_velocity_y, 00h

            call flip_snake_h
            ret

        ; if it is 'd' or 'D' move right
        right:
            cmp al, 64h ;'d'
            jne key_not_pressed

            mov ax, snake_max_velocity_x
            mov snake_velocity_x, ax

            ;mov ax, snake_original_velocity_y
            mov snake_velocity_y, 00h

            call flip_snake_h
            ret

        key_not_pressed:
            ret
    snake_key_press endp

    flip_snake_v proc
        mov ax, snake_y_size
        cmp ax, snake_original_size_x
        jne flip_v
        ret

        flip_v:
            mov bx, snake_x_size
            mov snake_x_size, ax
            mov snake_y_size, bx
            ret
    flip_snake_v endp

    flip_snake_h proc
        mov ax, snake_x_size
        cmp ax, snake_original_size_x
        jne flip_h
        ret

        flip_h:
            mov bx, snake_y_size
            mov snake_y_size, ax
            mov snake_x_size, bx
            ret
    flip_snake_h endp

    game_over_ui proc

        call clear_screen

        ; show game over text
        mov ah, 02h
        mov bh, 00h
        mov dh, 04h
        mov dl, 05h
        int 10h

        mov ah, 09h
        lea dx, text_game_over
        int 21h

        ;show your score text
        mov ah, 02h
        mov bh, 00h
        mov dh, 05h
        mov dl, 05h
        int 10h

        mov ah, 09h
        lea dx, text_your_score;
        int 21h

        ; show player points
        mov ah, 02h
        mov bh, 00h
        mov dh, 05h
        mov dl, 10h
        int 10h

        mov ah, 09h
        lea dx, text_player_points
        int 21h

        ;show highscore text
        mov ah, 02h
        mov bh, 00h
        mov dh, 06h
        mov dl, 05h
        int 10h

        mov ah, 09h
        lea dx, text_highscore
        int 21h

        ;show highscore value
        mov ah, 02h
        mov bh, 00h
        mov dh, 06h
        mov dl, 10h
        int 10h

        xor ax, ax
        xor dx, dx
        mov al, highscore_value
        mov bl, 0ah
        div bl

        add ah, 30h
        add al, 30h
        mov si, offset text_highscore_value

        mov [si], al
        inc si
        mov [si], ah
        ;inc si
        ;mov byte ptr [si], '$' ; as compiler does not know '$' data type so specify it
        xor ax, ax

        mov ah, 09h
        lea dx, text_highscore_value
        int 21h

        ;show restart game
        mov ah, 02h
        mov bh, 00h
        mov dh, 07h
        mov dl, 05h
        int 10h

        mov ah, 09h
        lea dx, text_game_restart
        int 21h

        ;show exit game text
        mov ah, 02h
        mov bh, 00h
        mov dh, 08h
        mov dl, 05h
        int 10h

        mov ah, 09h
        lea dx, text_exit_game
        int 21h

        ;check if r or e is pressed
        mov ah, 00h
        int 16h

        cmp al, 72h  ;ascii of 'r'
        je restart_game
        jmp check_pressed_e

        restart_game:
            mov game_mode, 01h
            mov exit_game_status, 00h  ;exit game status reset
            ret

        ; check if e is pressed
        check_pressed_e:
            cmp al, 65h  ;ascii of 'e'
            je pressed_e
            ret

        pressed_e:
            call write_file
            call close_file
            mov exit_game_status, 01h
            ret

    game_over_ui endp

    handle_file proc
        mov ah, 3dh
        mov al, 02h
        mov dx, offset highscore_file_loc
        int 21h

        mov file_handler, ax

        ret
    handle_file endp

    write_file proc
        ;convert hex number to hex text
        xor ax, ax
        xor dx, dx
        mov al, highscore_value
        mov bh, 10h
        div bh  ; ah store remainder and al store quotient

        add ah, 30h ; to store as ascii
        add al, 30h ; to store as ascii

        mov si, offset hex_text_highscore_value

        mov [si], al
        mov [si+1], ah

        ; first set the file pointer to begining of file
        mov ah, 42h
        mov al, 00h
        mov bx, file_handler
        xor cx, cx
        xor dx, dx
        int 21h
        ; write to file
        mov bx, file_handler
        mov cx, 02h
        mov dx, offset hex_text_highscore_value
        mov ah, 40h
        int 21h
        ret
    write_file endp

    read_file proc
        ; read first two characters in file and storing it in text_highscore_value
        mov bx, file_handler
        mov ah, 3fh
        mov cx, 02h
        mov dx, offset text_highscore_value
        int 21h

        mov si, offset text_highscore_value

        xor ax, ax

        mov al, [si]
        sub al, 30h
        mov bh, 10h
        mul bh
        mov ah, al

        mov al, [si+1]
        sub al, 30h

        add ah, al
        
        mov highscore_value, ah

        ret
    read_file endp

    close_file proc
        mov ah, 3eh
        mov bx, file_handler
        int 21h
        ret
    close_file endp

end start

