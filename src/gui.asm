redraw_ui:
    pcall(clearBuffer)
    kld(hl, window_title)
    ld a, 0b00000100
    corelib(drawWindow)
    ld e, 0
    ld l, 7
    ld c, 96
    ld b, 49
    pcall(rectAND) ; Clear the area for text
    kld(hl, (buffer_index))
    kcall(draw_file)
    ret

caret:
    .db 0b10000000
    .db 0b10000000
    .db 0b10000000
    .db 0b10000000
    .db 0b10000000

file_top:
    .dw 0 ; Buffer index of the character in the top left

scroll_x:
    .db 0 ; Characters scrolled out of view on the left

end_visible:
    .db 0 ; 1 if the end of the file is on-screen

draw_file:
    xor a
    kld((end_visible), a)
    kld(ix, (file_buffer))
    kld(bc, (file_top))
    add ix, bc
    ld de, 0x0008 ; X: 0, Y: 8
.line_loop:
    kcall(draw_line)
    ld a, (ix)
    or a
    jr z, .eof
    ld a, 64 - 8
    cp e
    ret z
    jr .line_loop
.eof:
    inc a
    kld((end_visible), a)
    ret

; This should skip characters until we encounter one that'll show on-screen
draw_line:
    ; Early exit (avoids drawing continuation mark on left)
    ld a, (ix)
    or a
    ret z
    cp '\n'
    jr z, .newline

    kld(a, (scroll_x))
    or a
    jr z, .loop
    ld b, a
.scroll_loop:
    ld a, (ix)
    or a
    ret z
    inc ix
    cp '\n'
    jr z, .newline
    djnz .scroll_loop
.loop:
    ld a, (ix)
    or a
    jr z, .left_margin_mark
    inc ix
    cp '\n'
    jr z, .newline
    pcall(drawChar)
    ld a, 96
    cp d
    jr z, .finish
    jr c, .overflow
    jr .loop
.newline:
    kcall(.left_margin_mark)
    ld b, 0
    pcall(newline)
    ret
.overflow:
    ; Draw continuation mark
    push de
        ld l, e
        ld e, 92
        ld c, 4
        ld b, 6
        pcall(rectAND)
    pop de \ push de
        ld b, 5
        ld d, 93
        kld(hl, .mark)
        pcall(putSpriteOR)
    pop de
.finish:
    kcall(.left_margin_mark)
    ; Skip to newline/end
    ld a, (ix)
    inc ix
    or a
    jr z, .newline
    cp '\n'
    jr nz, .overflow
    jr .newline
.left_margin_mark:
    kld(a, (scroll_x))
    or a
    ret z
    push de
        ld c, 4
        ld b, 6
        ld l, e
        ld e, 0
        pcall(rectAND)
    pop de \ push de
        kld(hl, .mark_left)
        ld b, 5
        ld d, 0
        pcall(putSpriteOR)
    pop de
    ret
.mark:
    .db 0b00000000
    .db 0b00100000
    .db 0b11100000
    .db 0b00100000
    .db 0b00000000
.mark_left:
    .db 0b00000000
    .db 0b10000000
    .db 0b11100000
    .db 0b10000000
    .db 0b00000000

draw_caret:
    ; TODO
    ret
