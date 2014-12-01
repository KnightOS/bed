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

handle_character:
    or a
    ret z
    kcall(insert_character)
    kcall(erase_caret)
    cp 0x08 ; Backspace
    jr z, .handle_bksp
    kld(hl, char)
    ld (hl), a
    kld(de, (cursor_y))
    ld bc, 94 << 8 | 64
    ld a, 2
    pcall(wrapStr)
    kld((cursor_y), de)
    ret
.handle_bksp:
    kcall(get_previous_char_width)
    or a
    ret z
    kcall(delete_character)
    kld(de, (cursor_y))
    push af
        neg
        add a, d
        ld l, e ; y
        ld e, a ; x
    pop af
    ld c, a
    ld b, 5
    push af
        pcall(rectAND)
    pop af
    kld(de, (cursor_y))
    neg
    add a, d
    ld d, a
    kld((cursor_y), de)
    ld a, 2
    cp d
    kcall(c, end_of_previous_line)
    ret

end_of_previous_line:
    ; TODO
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
char:
    .db 0, 0
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
