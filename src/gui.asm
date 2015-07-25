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

; Buffer index of the character in the top left
file_top:
    .dw 0
; Characters scrolled out of view on the left
scroll_x:
    .db 0 ; TODO: Support scrolling further than 256 pixels right

draw_file:
    kld(ix, (file_buffer))
    kld(bc, (file_top))
    add ix, bc
    ld de, 0x0008 ; X: 0, Y: 8
.line_loop:
    kcall(draw_line)
    ld a, (ix)
    or a
    ret z
    ld a, 64 - 8
    cp e
    ret z
    jr .line_loop

; TODO: horizontal scrolling
; This should skip characters until we encounter one that'll show on-screen
draw_line:
.loop:
    ld a, (ix)
    or a
    ret z
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
    ; Skip to newline/end
    ld a, (ix)
    inc ix
    or a
    jr z, .newline
    cp '\n'
    jr nz, .overflow
    jr .newline
.mark:
    .db 0b00000000
    .db 0b00100000
    .db 0b11100000
    .db 0b00100000
    .db 0b00000000

draw_caret:
    ; TODO
    ret
