action_exit:
    pcall(exitThread)
action_save:
    ; TODO: Prepopulate this with existing file name
    kld(hl, save_prompt)
    ld bc, 0x100
    pcall(malloc)
    ld (ix), 0
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
