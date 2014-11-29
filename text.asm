; Creates a new file and destroys the current one, if loaded
load_new_file:
    ; Free the old file name
    kld(hl, (file_name))
    ld bc, 0
    pcall(cpHLBC)
    jr z, _
    push hl \ pop ix
    pcall(free)
_:  ; Allocate a new (NULL) file name
    ld hl, 0
    kld((file_name), hl)
    ; Free the old file buffer
    kld(hl, (file_buffer))
    pcall(cpHLBC)
    jr z, _
    push hl \ pop ix
    pcall(free)
_:  ld bc, 0x100
    pcall(malloc)
    kld((file_buffer), ix)
    ret

insert_character:
    cp 0x08 ; Backspace
    ret z ; TODO
    kld(hl, (file_buffer))
    kld(de, (index))
    add hl, de
    ld (hl), a
    kld(hl, (index))
    inc hl
    kld((index), hl)
    ; TODO: Move stuff around
    ; TODO: Expand buffer if need be
    ret

delete_character:
    kld(hl, (index))
    dec hl
    kld((index), hl)
    ; TODO: Move stuff around
    ret

get_previous_char_width:
    kld(hl, (index))
    ld bc, 0
    pcall(cpHLBC)
    jr nz, _
    ; Start of file
    xor a
    ret
_:  kld(ix, (file_buffer))
    push ix \ pop bc
    add hl, bc
    dec hl
    ld a, (hl)
    pcall(measureChar)
    ret

index:
    .dw 0
file_buffer:
    .dw 0
file_name:
    .dw 0
file_length:
    .dw 0
