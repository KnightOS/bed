redraw_ui:
    pcall(clearBuffer)
    kld(hl, window_title)
    ld a, 0b00000100
    corelib(drawWindow)
    kld(hl, (index))
    kcall(redraw_entire_file)
    ret

redraw_file:
    kld(de, (file_buffer))
    add hl, de
    kld(de, (cursor_y))
    ld bc, 94 << 8 | 56
    ld a, 2
    pcall(wrapStr)
    ret

redraw_entire_file:
    kld(hl, (file_buffer))
    ld de, 0x0208
    ld bc, 94 << 8 | 56
    ld a, 2
    pcall(wrapStr)
    ret

draw_caret:
    push hl
    push de
    push bc
        kld(hl, caret_state)
        inc (hl)
        kld(de, (cursor_y))
        dec d
        ld b, 5
        bit 7, (hl)
        kld(hl, caret)
        pcall(z, putSpriteOR)
        pcall(nz, putSpriteAND)
    pop bc
    pop de
    pop hl
    ret

erase_caret:
    push hl
    push de
    push bc
    push af
        kld(hl, caret_state)
        xor a
        ld (hl), a
        kld(de, (cursor_y))
        dec d
        ld b, 5
        kld(hl, caret)
        pcall(putSpriteAND)
    pop af
    pop bc
    pop de
    pop hl
    ret

handle_left:
    kcall(get_previous_char_width)
    or a
    kjp(z, main_loop)
    cp -1
    jr z, .newline
    kcall(erase_caret)
    kld(de, (cursor_y))
    neg
    add a, d
    ld d, a
    kld((cursor_y), de)
    kcall(nc, move_end_of_previous_line)
    kcall(seek_back_one)
    pcall(flushKeys)
    kjp(main_loop)
.newline:
    kcall(erase_caret)
    kcall(move_end_of_previous_line)
    kcall(seek_back_one)
    pcall(flushKeys)
    kjp(main_loop)

handle_right:
    kcall(get_next_char_width)
    or a
    kjp(z, main_loop)
    cp -1
    jr z, .newline
    kcall(erase_caret)
    kld(de, (cursor_y))
    add a, d
    ld d, a
    kld((cursor_y), de)
    ld a, 94
    cp d
    kcall(c, move_start_of_next_line)
    kcall(seek_forward_one)
    pcall(flushKeys)
    kjp(main_loop)
.newline:
    kcall(erase_caret)
    kcall(move_start_of_next_line)
    kcall(seek_forward_one)
    pcall(flushKeys)
    kjp(main_loop)

handle_character:
    or a
    ret z
    kcall(insert_character)
    kcall(erase_caret)
    kcall(clear_from_cursor)
    cp 0x08 ; Backspace
    jr z, .handle_bksp
    cp '\n'
    jr z, .handle_newline
    kld(hl, (file_buffer))
    kld(bc, (index))
    add hl, bc
    dec hl
    kld(de, (cursor_y))
    ld bc, 94 << 8 | 64
    push af
    push de
        ld a, 2
        pcall(wrapStr)
    pop de
    pop af
    pcall(measureChar)
    ld l, a
    add a, d
    ld d, a
    cp 94
    jr c, _
    ld a, 6
    add e, a
    ld e, a
    ld d, l
    inc d \ inc d
_:  kld((cursor_y), de)
    ret
.handle_newline:
    kld(de, (cursor_y))
    ld b, 2
    pcall(newline)
    kld((cursor_y), de)
    ret
.handle_bksp:
    kcall(get_previous_char_width)
    or a
    ret z
    kcall(delete_character)
    cp 0xFF ; i.e. \n
    jr z, .handle_bksp_newline
    kld(de, (cursor_y))
    neg
    add a, d
    ld d, a
    kld((cursor_y), de)
    kcall(clear_from_cursor)

    ; Redraw
    kld(hl, (file_buffer))
    kld(bc, (index))
    add hl, bc
    ld bc, 94 << 8 | 64
    push af
    push de
        ld a, 2
        pcall(wrapStr)
    pop de
    pop af
    ret
.handle_bksp_newline:
    kjp(z, move_end_of_previous_line)

move_end_of_previous_line:
    kcall(move_start_of_previous_line)
    ; Fallthrough
move_end_of_current_line:
    push af
    push de
    push hl
    push bc
        kld(bc, (index))
        kld(hl, (file_buffer))
        add hl, bc
        dec hl
        kld(de, (cursor_y))
.loop:
        ld a, (hl)
        or a
        jr z, .done
        cp '\n'
        jr z, .done
        pcall(measureChar)
        add a, d
        cp 94
        jr z, .done
        jr nc, .done
        ld d, a
        kld((cursor_y), de)
        inc bc
        kld((index), bc)
        inc hl
        jr .loop
.done:
    pop bc
    pop hl
    pop de
    pop af
    ret

move_start_of_previous_line:
    ; This works by seeking backwards until it finds the start of the previous line, and then measuring forwards.
    ; The start of the previous line has been found when:
    ;   1. We have reached the start of the file
    ;   2. We have reached a \n (TODO: \r isn't really supported here)
    ;   3. We have measured enough characters to fill an entire line
    ; When we reached the start, we measure forwards until we would have hit a new line, and then there we are.
    ; NOTE: This also handles seeking in the file, but leaves the index one too far ahead. Call seek_back_one to fix.
    ; TODO: Scrolling up
    push af
    push de
    push hl
    push bc
        kld(bc, (index)) ; Cannot go further back than BC
        kld(hl, (file_buffer))
        add hl, bc \ dec hl \ dec bc
        ld d, 94 - 2 ; X. Subtracting 2 lets us use the carry flag to determine when we've hit the edge
        ld a, (hl)
        cp '\n'
        jr nz, .loop
        dec hl ; Skip the first \n if present, otherwise we're just moving back to our own line
        dec bc
.loop:
        ld a, (hl)
        dec hl
        cp '\n'
        jr z, .found
        kcall(.temp)
        neg \ add d, a \ ld d, a
        kjp(m, .found)
        ; Loop back
        kld((index), bc)
        dec bc ; Intentionally out of order.
        xor a
        cp c
        jr nz, .loop
        cp b
        jr nz, .loop
.found:
        kld(de, (cursor_y))
        ld d, 2
        ld a, -6
        add a, e
        ld e, a
        kld((cursor_y), de)
    pop bc
    pop hl
    pop de
    pop af
    ret
.temp:
    pcall(measureChar)
    ret

move_start_of_next_line:
    push de
    push af
        kld(de, (cursor_y))
        ld d, 2
        ld a, 6
        add a, e
        ld e, a
        ; TODO: Scrolling down
        kld((cursor_y), de)
    pop af
    pop de
    ret

clear_from_cursor:
    push de
    push bc
    push hl
    push af
        ; Clear current line
        kld(de, (cursor_y))
        ld l, e ; y
        ld e, d ; x
        ld a, 92
        sub a, d
        ld c, a
        ld b, 6
        pcall(rectAND)
        ; Clear rest of screen
        kld(de, (cursor_y))
        ld a, 48
        sub a, e
        ld b, a
        ld c, 92

        ld l, e ; y
        ld e, 2 ; x
        ld a, 6 \ add l, a \ ld l, a ; correct y
        pcall(rectAND)
    pop af
    pop hl
    pop bc
    pop de
    ret

main_menu:
    ld c, 40
    kld(hl, menu)
    corelib(showMenu)
    cp 0xFF
    kjp(z, draw_loop)
    add a, a ; A *= 2
    kld(hl, menu_functions)
    add a, l \ ld l, a \ jr nc, $+3 \ inc h
    ld e, (hl) \ inc hl \ ld d, (hl)
    ex de, hl
    push hl
        pcall(getCurrentThreadId)
        pcall(getEntryPoint)
    pop bc
    add hl, bc
    kld((.menu_smc + 1), hl)
.menu_smc:
    jp 0
menu_functions:
    .dw action_save
    .dw draw_loop
    .dw action_exit

window_title:
    .db "bed - New file", 0

cursor_y:
    .db 8
cursor_x:
    .db 2
caret:
    .db 0b10000000
    .db 0b10000000
    .db 0b10000000
    .db 0b10000000
    .db 0b10000000
caret_state:
    .db 0
menu:
    .db 3
    .db "Save", 0
    .db "Open", 0
    .db "Exit", 0
