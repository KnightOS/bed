#include "kernel.inc"
#include "corelib.inc"
    .db "KEXC"
    .db KEXC_ENTRY_POINT
    .dw start
    .db KEXC_STACK_SIZE
    .dw 40
    .db KEXC_NAME
name_ptr:
    .dw name
    .db KEXC_HEADER_END
name:
    .db "bed", 0
#include "src/gui.asm"
#include "src/text.asm"
#include "src/actions.asm"
start:
    or a
    jr z, run_new_file
    cp 1
    jr z, run_open_file
    ret
test_path:
    .db "/var/applications/bed.app", 0

run_new_file:
    kcall(initialize)
    kcall(load_new_file)
    kjp(draw_loop)

run_open_file:
    push de
        kcall(initialize)
    pop de
    kcall(load_existing_file)
    kjp(draw_loop)

initialize:
    pcall(getLcdLock)
    pcall(getKeypadLock)
    pcall(allocScreenBuffer)
    kld(de, corelib_path)
    pcall(loadLibrary)
    xor a
    corelib(setCharSet)
    ret

draw_loop:
    pcall(flushKeys)
    kcall(redraw_ui)
main_loop:
    kcall(draw_caret)
    pcall(fastCopy)
    corelib(getCharacterInput)
    pcall(nz, flushKeys) ; Flush keys if we lost focus
    push bc
        kcall(handle_character)
    pop bc
    ld a, b
    cp kLeft
    kjp(z, handle_left)
    cp kRight
    kjp(z, handle_right)
    cp kF3
    kjp(z, main_menu)
    or a
    pcall(nz, flushKeys)
    jr main_loop

handle_character:
    or a
    ret z
    kcall(insert_character)
    kjp(draw_loop)

handle_left:
    kld(a, (scroll_x))
    or a
    jr z, main_loop
    dec a
    kld((scroll_x), a)
    kjp(draw_loop)

handle_right:
    kld(a, (scroll_x))
    inc a
    kld((scroll_x), a)
    kjp(draw_loop)

get_window_title:
    kld(hl, (file_name))
    ld bc, 0
    pcall(cpHLBC)
    jr z, .new_file
    ld b, '/'
    pcall(strchr)
    jr nz, .no_slash
    ; basename
    xor a
    cpir
    ld a, '/'
    cpdr
    inc hl \ inc hl
    ret
.new_file:
    kld(hl, window_title)
    ret
.no_slash:
    kld(hl, (file_name))
    ret
window_title:
    .db "New file", 0

main_menu:
    ld c, 40
    kld(hl, menu)
    corelib(showMenu)
    cp 0xFF
    kjp(z, draw_loop)
    add a, a ; A *= 2
    kld(hl, menu_functions)
    add a, l \ ld l, a \ jr nc, $+3 \ inc h
    ld e, (hl) \ inc hl \ ld d, (hl)
    ex de, hl
    push hl
        pcall(getCurrentThreadId)
        pcall(getEntryPoint)
    pop bc
    add hl, bc
    kld((.menu_smc + 1), hl)
.menu_smc:
    jp 0
menu_functions:
    .dw action_save
    .dw draw_loop
    .dw action_exit

menu:
    .db 3
    .db "Save", 0
    .db "Open", 0
    .db "Exit", 0

corelib_path:
    .db "/lib/core", 0
