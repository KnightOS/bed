unload_current_file:
    kld(hl, (file_name))
    ld bc, 0
    pcall(cpHLBC)
    jr z, _
    push hl \ pop ix
    pcall(free)
_:  kld(hl, (file_buffer))
    pcall(cpHLBC)
    ret z
    push hl \ pop ix
    pcall(free)
    ret

load_new_file:
    kcall(unload_current_file)
    ld hl, 0
    kld((file_name), hl)
    kld((file_length), hl)
    kld((index), hl)
    ld bc, 0x100
    kld((file_buffer_length), bc)
    ld a, 1
    pcall(calloc)
    kld((file_buffer), ix)
    ret

load_existing_file:
    kld((file_name), de)
    pcall(openFileRead)
    pcall(getStreamInfo)
    kld((file_length), bc)
    ; TODO: Don't just edit files in memory
    inc bc
    kld((file_buffer_length), bc)
    pcall(malloc)
    pcall(streamReadToEnd)
    push ix
        pcall(memSeekToEnd)
        ld (ix), 0 ; Delimiter
    pop ix
    kld((file_buffer), ix)
    ld hl, 0
    kld((index), hl)
    ret

expand_buffer:
    ; TODO
    ret

overwrite_character:
    cp 0x08 ; Backspace
    ret z
    kld(hl, (file_buffer))
    kld(de, (index))
    add hl, de
    ld (hl), a
    kld(hl, (index))
    inc hl
    kld((index), hl)
    kld(bc, (file_length))
    inc bc
    kld((file_length), bc)
    ret

insert_character:
    cp 0x08 ; Backspace
    ret z
    kld(hl, (index))
    inc hl ; New character
    inc hl ; Null terminator
    kld(bc, (file_buffer_length))
    pcall(cpHLBC)
    kcall(z, expand_buffer)
    ; Shift all text forward a character
    kld(hl, (file_length))
    kld(bc, (index))
    scf \ ccf
    sbc hl, bc
    ld b, h \ ld c, l
    ld hl, 0
    pcall(cpHLBC)
    jr z, _ ; Skip if we don't need to shift
    kld(hl, (file_buffer))
    kld(de, (file_length))
    add hl, de
    ex de, hl
    scf \ ccf
    sbc hl, bc
    ex de, hl
    ld d, h \ ld e, l \ dec de
    inc bc ; null terminator
    ex de, hl
    lddr
    ; Write new character into file :D
_:  kld(hl, (file_buffer))
    kld(de, (index))
    add hl, de
    ld (hl), a
    kld(hl, (index))
    inc hl
    kld((index), hl)
    kld(bc, (file_length))
    inc bc
    kld((file_length), bc)
    ret

delete_character:
    kld(hl, (index))
    dec hl
    kld((index), hl)
    kld(de, (file_buffer))
    add hl, de
    ld d, h \ ld e, l
    inc hl
    push hl
        kld(bc, (index))
        kld(hl, (file_length))
        add hl, bc
        ld b, h \ ld c, l
    pop hl
    ldir
    kld(bc, (file_length))
    dec bc
    kld((file_length), bc)
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
    cp '\n'
    jr z, .newline
    pcall(measureChar)
    ret
.newline:
    ld a, -1
    ret

get_next_char_width:
    kld(hl, (index))
    kld(bc, (file_length))
    pcall(cpHLBC)
    jr nz, _
    ; Start of file
    xor a
    ret
_:  kld(ix, (file_buffer))
    push ix \ pop bc
    add hl, bc
    ld a, (hl)
    cp '\n'
    jr z, .newline
    pcall(measureChar)
    ret
.newline:
    ld a, -1
    ret

seek_back_one:
    kld(hl, (index))
    dec hl
    kld((index), hl)
    ret

seek_forward_one:
    kld(hl, (index))
    inc hl
    kld((index), hl)
    ret

index:
    .dw 0
file_buffer:
    .dw 0
file_buffer_length:
    .dw 0
file_name:
    .dw 0
file_length:
    .dw 0
