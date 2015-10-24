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
    kld((buffer_index), hl)
    ld bc, 0x100
    kld((buffer_length), bc)
    ld a, 1
    pcall(calloc)
    kld((file_buffer), ix)
    ret

load_existing_file:
    kld((file_name), de)
    pcall(openFileRead)
    pcall(getStreamInfo)
    kld((file_length), bc)
    inc bc
    kld((buffer_length), bc)
    pcall(malloc) ; TODO: Don't load entire file into memory
    pcall(streamReadToEnd)
    push ix
        add ix, bc
        ld (ix + -1), 0 ; Delimiter
    pop ix
    kld((file_buffer), ix)
    ld hl, 0
    kld((buffer_index), hl)
    ret

expand_buffer:
    kld(ix, (file_buffer))
    kld(hl, (buffer_length))
    ld bc, 0x100
    add hl, bc
    ld b, h \ ld c, l
    pcall(realloc)
    corelib(nz, showError)
    kld((file_buffer), ix)
    kld((buffer_length), bc)
    push hl
    push de
    push bc
    push af
        push ix \ pop hl
        kld(bc, (file_length))
        add hl, bc
        push hl
            kld(hl, (buffer_length))
            kld(bc, (file_length))
            sbc hl, bc
            ld b, h \ ld c, l
        pop hl
        ld d, h \ ld e, l
        inc de
        xor a
        ld (hl), a
        dec bc
        ldir
    pop af
    pop bc
    pop de
    pop hl
    scf
    ret
    ; TODO: shrink_buffer? Is that necessary?

overwrite_character:
    cp 0x08 ; Backspace
    ret z
    kld(hl, (file_buffer))
    kld(de, (buffer_index))
    add hl, de
    ld (hl), a
    kld(hl, (buffer_index))
    inc hl
    kld((buffer_index), hl)
    kld(bc, (file_length))
    inc bc
    kld((file_length), bc)
    ret

insert_character:
    cp 0x08 ; Backspace
    jr z, backspace
    ; Check if we need to expand the buffer
    kld(hl, (file_length))
    inc hl ; Null terminator
    kld(bc, (buffer_length))
    pcall(cpHLBC)
    kcall(z, expand_buffer)
    kcall(nc, expand_buffer)

    kld(hl, (file_length))
    kld(bc, (buffer_index))
    scf \ ccf
    sbc hl, bc
    ld b, h \ ld c, l ; BC == length of buffer ahead of caret
    ld hl, 0
    pcall(cpHLBC)
    jr z, .do_insertion

    ; Shift characters to make room
    ; lddr:
    ; HL: last character
    ; DE: next character
    ; BC: Already set
    push bc
        kld(hl, (file_buffer))
        kld(bc, (file_length))
        inc bc ; null terminator
        add hl, bc
        ld e, l \ ld d, h
        inc de
    pop bc
    inc bc \ inc bc ; Include null terminator
    lddr
.do_insertion:
    ; Insert character
    kld(hl, (file_buffer))
    kld(bc, (buffer_index))
    add hl, bc
    ld (hl), a
    ; Increment caret
    kld(hl, (buffer_index))
    inc hl
    kld((buffer_index), hl)
    ; Increment file length
    kld(bc, (file_length))
    inc bc
    kld((file_length), bc)
    ret

backspace:
    kld(hl, (buffer_index))
    dec hl
    kld((buffer_index), hl)
    kld(de, (file_buffer))
    add hl, de
    ld d, h \ ld e, l
    inc hl
    push hl
        kld(hl, (file_length))
        kld(bc, (buffer_index))
        scf \ ccf
        sbc hl, bc
        ld b, h \ ld c, l
    pop hl
    ldir
    kld(bc, (file_length))
    dec bc
    kld((file_length), bc)
    ret

get_previous_char_width:
    kld(hl, (buffer_index))
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
    kld(hl, (buffer_index))
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
    kld(hl, (buffer_index))
    dec hl
    kld((buffer_index), hl)
    ret

seek_forward_one:
    kld(hl, (buffer_index))
    inc hl
    kld((buffer_index), hl)
    ret

buffer_index:
    .dw 0
file_buffer:
    .dw 0
buffer_length:
    .dw 0
file_name:
    .dw 0
file_length:
    .dw 0
