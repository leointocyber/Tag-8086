; Tag Game - DOS Assembly Implementation
; Version: 1.0.0
; Author: leointocyber
; Target: 8086/8088 Real Mode (DOSBox compatible)
; Graphics: VGA Mode 13h (320x200, 256 colors)

;==============================================================================
; GAME DESCRIPTION
;==============================================================================
; Two-player tag game where the Runner (Player 1) collects grapes for points
; while avoiding the Chaser (Player 2). Each grape collected awards 100 points.
; Game ends when the Chaser catches the Runner.

;==============================================================================
; CONTROLS
;==============================================================================
; Runner (Player 1):  W/A/S/D  - Up/Left/Down/Right
; Chaser (Player 2):  Arrow Keys - Up/Left/Down/Right
; Menu:               Y/N        - Yes/No
;                     C          - Show Controls
;                     ESC        - Return to Menu / Exit

;==============================================================================
; BUILD INSTRUCTIONS
;==============================================================================
; MASM:   masm Tag.asm && link Tag.obj && Tag.exe
; TASM:   tasm Tag.asm && tlink Tag.obj && Tag.exe
; DOSBox: mount c . && c: && Tag.exe

;==============================================================================

data segment
    ; --- Menu Strings ---
    msg_welcome       db "Welcome to Tag$"
    msg_play          db "Do you wish to play?$"
    msg_choice        db "Press Y / N$"
    msg_controls      db "Press C for Controls$"
    msg_speed         db "Use Ctrl+F11 to control speed in DOSBox$"

    ; --- Controls Screen Strings ---
    msg_runner        db "Runner:$"
    msg_w_s           db "W - Up,  S - Down$"
    msg_a_d           db "A - Left,  D - Right$"
    msg_chaser        db "Chaser:$"
    msg_up_down       db "UpArrow - Up,  DownArrow - Down$"
    msg_left_right    db "LeftArrow - Left,  RightArrow - Right$"
    msg_esc           db "Esc - Return to main menu$"

    ; --- Game Over Strings ---
    msg_gameover      db "GAME OVER!$"
    msg_score         db "Your score: $"

    ; --- Game State ---
    runner_x          dw 50          ; Runner X position
    runner_y          dw 100         ; Runner Y position
    runner_width      dw 5           ; Runner sprite width/height (square)

    chaser_x          dw 250         ; Chaser X position
    chaser_y          dw 100         ; Chaser Y position
    chaser_width      dw 5           ; Chaser sprite width/height (square)

    runner_dir        db 255         ; Runner direction (0=R,1=L,2=U,3=D, 255=none)
    chaser_dir        db 255         ; Chaser direction (0=R,1=L,2=U,3=D, 255=none)
    draw_color        db 0           ; Current drawing color

    grape_x           dw 50          ; Grape X position
    grape_y           dw 50          ; Grape Y position
    grape_size        dw 2           ; Grape sprite size (2x2 pixels)

    score             dw 0           ; Current score
    random            dw 12345       ; RNG seed for grape spawning
ends

stack segment
    dw 128 dup(0)
ends

code segment
start:
    mov ax, data
    mov ds, ax
    mov es, ax

;==============================================================================
; MAIN MENU
;==============================================================================
main_menu:
    ; Clear screen to text mode (80x25)
    mov ah, 00h
    mov al, 03h
    int 10h

    ; Display welcome message
    mov ah, 02h
    mov bh, 00h
    mov dh, 8
    mov dl, 33
    int 10h
    lea dx, msg_welcome
    mov ah, 09h
    int 21h

    ; Display play prompt
    mov ah, 02h
    mov dh, 10
    mov dl, 30
    int 10h
    lea dx, msg_play
    mov ah, 09h
    int 21h

    ; Display choice hint
    mov ah, 02h
    mov dh, 12
    mov dl, 34
    int 10h
    lea dx, msg_choice
    mov ah, 09h
    int 21h

    ; Display controls hint
    mov ah, 02h
    mov dh, 15
    mov dl, 30
    int 10h
    lea dx, msg_controls
    mov ah, 09h
    int 21h

wait_for_input:
    mov ah, 00h
    int 16h
    cmp al, 'Y'
    je start_game
    cmp al, 'y'
    je start_game
    cmp al, 'N'
    je exit_program
    cmp al, 'n'
    je exit_program
    cmp al, 'C'
    je show_controls
    cmp al, 'c'
    je show_controls
    jmp wait_for_input

;==============================================================================
; CONTROLS SCREEN
;==============================================================================
show_controls:
    mov ah, 00h
    mov al, 03h
    int 10h

    mov ah, 02h
    mov bh, 00h
    mov dh, 4
    mov dl, 18
    int 10h
    lea dx, msg_speed
    mov ah, 09h
    int 21h

    mov ah, 02h
    mov dh, 8
    mov dl, 25
    int 10h
    lea dx, msg_runner
    mov ah, 09h
    int 21h

    mov ah, 02h
    mov dh, 10
    mov dl, 25
    int 10h
    lea dx, msg_w_s
    mov ah, 09h
    int 21h

    mov ah, 02h
    mov dh, 12
    mov dl, 25
    int 10h
    lea dx, msg_a_d
    mov ah, 09h
    int 21h

    mov ah, 02h
    mov dh, 14
    mov dl, 25
    int 10h
    lea dx, msg_chaser
    mov ah, 09h
    int 21h

    mov ah, 02h
    mov dh, 16
    mov dl, 25
    int 10h
    lea dx, msg_up_down
    mov ah, 09h
    int 21h

    mov ah, 02h
    mov dh, 18
    mov dl, 25
    int 10h
    lea dx, msg_left_right
    mov ah, 09h
    int 21h

    mov ah, 02h
    mov dh, 20
    mov dl, 25
    int 10h
    lea dx, msg_esc
    mov ah, 09h
    int 21h

wait_for_esc:
    mov ah, 00h
    int 16h
    cmp al, 27
    je main_menu
    jmp wait_for_esc

;==============================================================================
; GAME INITIALIZATION
;==============================================================================
start_game:
    ; Reset player positions
    mov [runner_x], 50
    mov [runner_y], 100
    mov [runner_width], 5
    mov [runner_dir], 255

    mov [chaser_x], 250
    mov [chaser_y], 100
    mov [chaser_width], 5
    mov [chaser_dir], 255

    mov [score], 0

    ; Switch to VGA Mode 13h (320x200, 256 colors)
    mov ah, 00h
    mov al, 13h
    int 10h

    ; Draw cyan background (color 0Bh)
    mov si, 0
bg_row:
    mov di, 0
bg_col:
    mov cx, di
    mov dx, si
    mov ah, 0Ch
    mov al, 0Bh
    mov bh, 00h
    int 10h
    inc di
    cmp di, 320
    jl bg_col
    inc si
    cmp si, 200
    jl bg_row

    ; Draw initial runner (blue, color 01h)
    mov cx, [runner_x]
    mov dx, [runner_y]
    mov al, 01h
    call draw_block_proc

    ; Draw initial chaser (red, color 04h)
    mov cx, [chaser_x]
    mov dx, [chaser_y]
    mov al, 04h
    call draw_block_proc

    ; Spawn first grape
    call spawn_grape_proc

;==============================================================================
; MAIN GAME LOOP
;==============================================================================
game_loop:
    ; --- Erase runner at old position ---
    mov cx, [runner_x]
    mov dx, [runner_y]
    mov al, 0Bh
    call draw_block_proc

    ; --- Check/redraw grape if under runner ---
    mov ax, [grape_y]
    cmp ax, [runner_y]
    jl no_erase_r
    mov bx, [runner_y]
    add bx, [runner_width]
    cmp ax, bx
    jge no_erase_r
check_grape_col_r:
    mov ax, [grape_x]
    cmp ax, [runner_x]
    jl no_erase_r
    mov bx, [runner_x]
    add bx, [runner_width]
    cmp ax, bx
    jge no_erase_r
    mov cx, [grape_x]
    mov dx, [grape_y]
    mov al, 05h
    call draw_grape_proc
no_erase_r:

    ; --- Erase chaser at old position ---
    mov cx, [chaser_x]
    mov dx, [chaser_y]
    mov al, 0Bh
    call draw_block_proc

    ; --- Check/redraw grape if under chaser ---
    mov ax, [grape_y]
    cmp ax, [chaser_y]
    jl no_erase_c
    mov bx, [chaser_y]
    add bx, [chaser_width]
    cmp ax, bx
    jge no_erase_c
check_grape_col_c:
    mov ax, [grape_x]
    cmp ax, [chaser_x]
    jl no_erase_c
    mov bx, [chaser_x]
    add bx, [chaser_width]
    cmp ax, bx
    jge no_erase_c
    mov cx, [grape_x]
    mov dx, [grape_y]
    mov al, 05h
    call draw_grape_proc
no_erase_c:

    ; --- Input Handling ---
    mov ah, 01h
    int 16h
    jz skip_input
    mov ah, 00h
    int 16h

    cmp al, 27
    je exit_program

    ; Runner controls (WASD)
    cmp al, 'W'
    je try_up_r
    cmp al, 'w'
    je try_up_r
    cmp al, 'S'
    je try_down_r
    cmp al, 's'
    je try_down_r
    cmp al, 'A'
    je try_left_r
    cmp al, 'a'
    je try_left_r
    cmp al, 'D'
    je try_right_r
    cmp al, 'd'
    je try_right_r

    ; Chaser controls (Arrow keys - scan codes in AH)
    cmp al, 0
    jne skip_input
    cmp ah, 48h
    je try_up_c
    cmp ah, 50h
    je try_down_c
    cmp ah, 4Bh
    je try_left_c
    cmp ah, 4Dh
    je try_right_c
    jmp skip_input

try_up_r:
    cmp [runner_dir], 3
    je skip_input
    mov [runner_dir], 2
    jmp skip_input
try_down_r:
    cmp [runner_dir], 2
    je skip_input
    mov [runner_dir], 3
    jmp skip_input
try_left_r:
    cmp [runner_dir], 0
    je skip_input
    mov [runner_dir], 1
    jmp skip_input
try_right_r:
    cmp [runner_dir], 1
    je skip_input
    mov [runner_dir], 0
    jmp skip_input

try_up_c:
    cmp [chaser_dir], 3
    je skip_input
    mov [chaser_dir], 2
    jmp skip_input
try_down_c:
    cmp [chaser_dir], 2
    je skip_input
    mov [chaser_dir], 3
    jmp skip_input
try_left_c:
    cmp [chaser_dir], 0
    je skip_input
    mov [chaser_dir], 1
    jmp skip_input
try_right_c:
    cmp [chaser_dir], 1
    je skip_input
    mov [chaser_dir], 0

skip_input:

    ; --- Move Runner ---
    cmp [runner_dir], 0
    je runner_right
    cmp [runner_dir], 1
    je runner_left
    cmp [runner_dir], 2
    je runner_up
    cmp [runner_dir], 3
    je runner_down
    jmp runner_done

runner_down:
    add [runner_y], 5
    jmp runner_done
runner_up:
    sub [runner_y], 5
    jmp runner_done
runner_left:
    sub [runner_x], 5
    jmp runner_done
runner_right:
    add [runner_x], 5
runner_done:

    ; --- Runner Bounds Checking (320x200 screen, 5x5 sprite) ---
    mov ax, [runner_x]
    cmp ax, 0
    jge runner_bounds_right
    mov [runner_x], 0
runner_bounds_right:
    mov ax, [runner_x]
    cmp ax, 315
    jle runner_bounds_top
    mov [runner_x], 315
runner_bounds_top:
    mov ax, [runner_y]
    cmp ax, 0
    jge runner_bounds_bottom
    mov [runner_y], 0
runner_bounds_bottom:
    mov ax, [runner_y]
    cmp ax, 195
    jle runner_bounds_done
    mov [runner_y], 195
runner_bounds_done:

    ; --- Move Chaser ---
    cmp [chaser_dir], 0
    je chaser_right
    cmp [chaser_dir], 1
    je chaser_left
    cmp [chaser_dir], 2
    je chaser_up
    cmp [chaser_dir], 3
    je chaser_down
    jmp chaser_done

chaser_down:
    add [chaser_y], 5
    jmp chaser_done
chaser_up:
    sub [chaser_y], 5
    jmp chaser_done
chaser_left:
    sub [chaser_x], 5
    jmp chaser_done
chaser_right:
    add [chaser_x], 5
chaser_done:

    ; --- Chaser Bounds Checking ---
    mov ax, [chaser_x]
    cmp ax, 0
    jge chaser_bounds_right
    mov [chaser_x], 0
chaser_bounds_right:
    mov ax, [chaser_x]
    cmp ax, 315
    jle chaser_bounds_top
    mov [chaser_x], 315
chaser_bounds_top:
    mov ax, [chaser_y]
    cmp ax, 0
    jge chaser_bounds_bottom
    mov [chaser_y], 0
chaser_bounds_bottom:
    mov ax, [chaser_y]
    cmp ax, 195
    jle chaser_bounds_done
    mov [chaser_y], 195
chaser_bounds_done:

    ; --- Collision Detection (Runner vs Chaser) ---
    ; AABB collision: 5x5 squares
    mov ax, [chaser_x]
    add ax, 5
    cmp [runner_x], ax
    jge no_collision
    mov ax, [runner_x]
    add ax, 5
    cmp [chaser_x], ax
    jge no_collision
    mov ax, [chaser_y]
    add ax, 5
    cmp [runner_y], ax
    jge no_collision
    mov ax, [runner_y]
    add ax, 5
    cmp [chaser_y], ax
    jge no_collision
    jmp game_over

no_collision:

    ; --- Grape Collection (Runner only) ---
    mov ax, [grape_x]
    add ax, 2
    cmp [runner_x], ax
    jge no_grape
    mov ax, [runner_x]
    add ax, 5
    cmp [grape_x], ax
    jge no_grape
    mov ax, [grape_y]
    add ax, 2
    cmp [runner_y], ax
    jge no_grape
    mov ax, [runner_y]
    add ax, 5
    cmp [grape_y], ax
    jge no_grape
    add [score], 100
    call spawn_grape_proc
no_grape:

    ; --- Draw Runner ---
    mov cx, [runner_x]
    mov dx, [runner_y]
    mov al, 01h
    call draw_block_proc

    ; --- Draw Chaser ---
    mov cx, [chaser_x]
    mov dx, [chaser_y]
    mov al, 04h
    call draw_block_proc

    ; --- Frame Delay ---
    mov cx, 0FFFFh
delay_loop:
    dec cx
    jnz delay_loop

    jmp game_loop

;==============================================================================
; GAME OVER
;==============================================================================
game_over:
    ; Return to text mode
    mov ah, 00h
    mov al, 03h
    int 10h

    mov ah, 02h
    mov bh, 00h
    mov dh, 10
    mov dl, 32
    int 10h
    lea dx, msg_gameover
    mov ah, 09h
    int 21h

    mov ah, 02h
    mov dh, 12
    mov dl, 30
    int 10h
    lea dx, msg_score
    mov ah, 09h
    int 21h

    mov ax, [score]
    call print_number_proc

    mov ah, 00h
    int 16h
    jmp main_menu

;==============================================================================
; PROCEDURES
;==============================================================================

; Draw 5x5 block at (CX, DX) in color AL
draw_block_proc proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov si, cx
    mov [draw_color], al
    mov bx, 0

draw_next_row:
    mov cx, si
    push bx
    mov bx, 0
draw_one_row:
    mov al, [draw_color]
    mov ah, 0Ch
    mov bh, 00h
    int 10h
    inc cx
    inc bx
    cmp bx, 5
    jl draw_one_row
    pop bx
    inc dx
    inc bx
    cmp bx, 5
    jl draw_next_row

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_block_proc endp

; Draw 2x2 grape at (CX, DX) in color AL
draw_grape_proc proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov si, cx
    mov [draw_color], al
    mov bx, 0

grape_next_row:
    mov cx, si
    push bx
    mov bx, 0
grape_one_row:
    mov al, [draw_color]
    mov ah, 0Ch
    mov bh, 00h
    int 10h
    inc cx
    inc bx
    cmp bx, 2
    jl grape_one_row
    pop bx
    inc dx
    inc bx
    cmp bx, 2
    jl grape_next_row

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_grape_proc endp

; Spawn grape at random position using LCG
; Linear Congruential Generator: X_{n+1} = (a * X_n + c) mod m
spawn_grape_proc proc
    push ax
    push bx
    push cx
    push dx

    ; Erase old grape
    mov cx, [grape_x]
    mov dx, [grape_y]
    mov al, 0Bh
    call draw_grape_proc

try_new_position:
    ; Generate random X (5-314)
    mov ax, [random]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov [random], ax
    mov bx, 309
    xor dx, dx
    div bx
    add dx, 5
    mov [grape_x], dx

    ; Generate random Y (5-193)
    mov ax, [random]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov [random], ax
    mov bx, 189
    xor dx, dx
    div bx
    add dx, 5
    mov [grape_y], dx

    ; Validate position within bounds
    mov ax, [grape_x]
    cmp ax, 5
    jl try_new_position
    cmp ax, 312
    jg try_new_position
    mov ax, [grape_y]
    cmp ax, 5
    jl try_new_position
    cmp ax, 192
    jg try_new_position

    ; Ensure grape doesn't spawn on runner
    mov ax, [grape_y]
    cmp ax, [runner_y]
    jl position_ok
    mov bx, [runner_y]
    add bx, 5
    cmp ax, bx
    jge position_ok
    mov ax, [grape_x]
    cmp ax, [runner_x]
    jl position_ok
    mov bx, [runner_x]
    add bx, 5
    cmp ax, bx
    jl try_new_position

position_ok:
    ; Draw new grape (magenta, color 05h)
    mov cx, [grape_x]
    mov dx, [grape_y]
    mov al, 05h
    call draw_grape_proc

    pop dx
    pop cx
    pop bx
    pop ax
    ret
spawn_grape_proc endp

; Print number in AX to stdout
print_number_proc proc
    push ax
    push bx
    push cx
    push dx

    mov bx, 10
    mov cx, 0

    cmp ax, 0
    jne divide_loop
    mov ah, 02h
    mov dl, '0'
    int 21h
    jmp print_done

divide_loop:
    cmp ax, 0
    je print_digits
    xor dx, dx
    div bx
    push dx
    inc cx
    jmp divide_loop

print_digits:
    cmp cx, 0
    je print_done
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    dec cx
    jmp print_digits

print_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number_proc endp

;==============================================================================
; EXIT PROGRAM
;==============================================================================
exit_program:
    mov ah, 00h
    mov al, 03h
    int 10h
    mov ax, 4c00h
    int 21h
ends
end start