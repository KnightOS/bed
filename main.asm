#include "kernel.inc"
#include "corelib.inc"
    .db "KEXC"
    .db KEXC_ENTRY_POINT
    .dw start
    .db KEXC_STACK_SIZE
    .dw 40
    .db KEXC_NAME
    .dw name
    .db KEXC_HEADER_END
name:
    .db "bed", 0
#include "gui.asm"
#include "text.asm"
start:
    pcall(getLcdLock)
    pcall(getKeypadLock)
    pcall(allocScreenBuffer)
    kld(de, corelib_path)
    pcall(loadLibrary)
    xor a
    corelib(setCharSet)
    kcall(load_new_file)

draw_loop:
    kcall(draw_ui)
main_loop:
    kcall(draw_caret)
    pcall(fastCopy)
    corelib(getCharacterInput)
    push bc
        kcall(handle_character)
    pop bc
    ld a, b
    cp kMODE
    ret z
    or a
    pcall(nz, flushKeys)
    jr main_loop

corelib_path:
    .db "/lib/core", 0
