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
    ld bc, 0x100
    corelib(promptString)
    or a
    kjp(z, draw_loop)
    push ix
        push ix \ pop de
        pcall(deleteFile)
        pcall(openFileWrite)
        kld(bc, (file_length))
        kld(ix, (file_buffer))
        pcall(streamWriteBuffer)
        pcall(closeStream)

        kld(hl, (file_name))
        ld bc, 0
        pcall(cpHLBC)
        pcall(nz, free) ; Free file name
    pop hl
    kld((file_name), hl)
    kjp(draw_loop)

save_prompt:
    .db "Full path to file:", 0
