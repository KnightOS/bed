draw_ui:
    pcall(clearBuffer)
    kld(hl, window_title)
    xor a
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
        ld a, 0x80
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
    ret z
    kld(hl, char)
    ld (hl), a
    kld(de, (cursor_y))
    ld bc, 94 << 8 | 64
    ld a, 2
    pcall(wrapStr)
    kld((cursor_y), de)
    ret

window_title:
    .db "bed", 0

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
