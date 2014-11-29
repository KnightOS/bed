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
    or a
    jr z, run_new_file
    ; TODO: Open existing files
    ret

run_new_file:
    kcall(initialize)
    kcall(load_new_file)
    kjp(draw_loop)

initialize:
    pcall(getLcdLock)
    pcall(getKeypadLock)
    pcall(allocScreenBuffer)
    kld(de, corelib_path)
    pcall(loadLibrary)
    xor a
    corelib(setCharSet)
    pcall(flushKeys) ; To avoid setting the wrong character set right off the bat
    ret

draw_loop:
    kcall(draw_ui)
main_loop:
    kcall(draw_caret)
    pcall(fastCopy)
    corelib(getCharacterInput)
    pcall(nz, flushKeys) ; Flush keys if we lost focus
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
