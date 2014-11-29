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
    ex de, hl
    ld (hl), a
    ; TODO: Move other stuff
    ret

index:
    .dw 0
file_buffer:
    .dw 0
file_name:
    .dw 0
