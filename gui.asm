draw_ui:
    pcall(clearBuffer)
    kld(hl, window_title)
    ld a, 0b00000100
    corelib(drawWindow)
    ret

draw_caret:
    push hl
    push de
    push bc
        kld(hl, caret_state)
        inc (hl)
        kld(de, (cursor_y))
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
        ld b, 5
        bit 7, (hl)
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
