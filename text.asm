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
    kld((index), hl)
    ld bc, 0x100
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

insert_character:
    cp 0x08 ; Backspace
    ret z
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
