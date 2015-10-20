action_exit:
    pcall(exitThread)
action_save:
    kld(hl, save_prompt)
    ld bc, 0x100
    pcall(malloc)
    ld (ix), 0
    push hl
        kld(hl, (file_name))
        ld bc, 0
        pcall(cpHLBC)
        jr z, _
        pcall(strlen)
        inc bc
        push ix \ pop de
        ldir
_:  pop hl
    corelib(promptString)
    or a
    kjp(z, draw_loop)
    push ix \ pop de
    pcall(openFileWrite)
    pcall(free) ; Free file name
    kld(bc, (file_length))
    kld(ix, (file_buffer))
    pcall(streamWriteBuffer)
    pcall(closeStream)
    kjp(draw_loop)

save_prompt:
    .db "Full path to file:", 0
