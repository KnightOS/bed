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
    kld(de, test_path)
    jr run_open_file
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
    cp kDown
    kjp(z, handle_down)
    cp kUp
    kjp(z, handle_up)
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
    kld(hl, (buffer_index))
    ld bc, 0
    pcall(cpHLBC)
    kjp(z, main_loop)
    dec hl
    kld((buffer_index), hl)
    kjp(draw_loop)

handle_right:
    kld(hl, (buffer_index))
    push hl
        kld(bc, (file_buffer))
        add hl, bc
        inc hl
        ld a, (hl)
    pop hl
    or a
    kjp(z, main_loop)
    inc hl
    kld((buffer_index), hl)
    kjp(draw_loop)

find_sol:
    push hl
        ld a, (hl)
        cp '\n'
        jr nz, _
        dec hl
_:  
        ; Find the start of this line
.sol_loop:
        pcall(cpHLDE)
        jr z, .sol
        ld a, (hl)
        dec hl
        cp '\n'
        jr nz, .sol_loop
        inc hl \ inc hl
.sol:
        ; HL is at first character of this line
        ld b, h \ ld c, l
    pop hl
    cp a
    sbc hl, bc
    ; HL is characters from start of line we WERE at
    kld((old_index), hl)
    ret

old_index:
    .dw 0

handle_down:
    kld(hl, (file_buffer))
    kld(de, (file_buffer))
    kld(bc, (buffer_index))
    add hl, bc
    kcall(find_sol)

    ld h, b \ ld l, c
    ld a, '\n'
    push hl
        kld(hl, (file_length))
        kld(bc, (buffer_index))
        scf \ ccf
        sbc hl, bc
        kld(bc, (old_index))
        add hl, bc
        ld b, h \ ld c, l ; BC is remainder of file
    pop hl
    cpir ; To start of next line
    ld a, (hl)
    or a
    kjp(z, main_loop) ; eof

    ex de, hl
    ld bc, 0
    kld(hl, (old_index))
    pcall(cpHLBC)
    push af
        kcall(z, .done)
    pop af
    kcall(nz, .index_loop)

    kld(a, (caret_y))
    cp 0x32
    kcall(z, scroll_down)

    kjp(draw_loop)

.index_loop:
    ld a, (de)
    or a
    jr z, .done
    cp '\n'
    jr z, .done
    inc de
    kld(hl, (old_index))
    dec hl
    kld((old_index), hl)
    pcall(cpHLBC)
    jr nz, .index_loop
.done:
    ex de, hl
    ; HL is pointer to new cursor
    kld(bc, (file_buffer))
    cp a
    sbc hl, bc
    kld((buffer_index), hl)
    ret

handle_up:
    kld(hl, (file_buffer))
    kld(de, (file_buffer))
    kld(bc, (buffer_index))
    add hl, bc
    pcall(cpHLBC)
    kjp(z, main_loop)
    kcall(find_sol)

    kld(de, (file_buffer))
    ld h, b \ ld l, c
    push hl
        kld(hl, (buffer_index))
        kld(bc, (old_index))
        scf \ ccf
        sbc hl, bc
        ld b, h \ ld c, l
    pop hl

    pcall(cpHLDE)
    kjp(c, main_loop)
    kjp(z, main_loop)

    ld a, '\n'
    cpdr ; To start of this line
    ld de, 0
    pcall(cpBCDE)
    jr z, .found_line
    cpdr ; To start of previous line
    pcall(cpBCDE)
    jr z, .found_line
    inc hl \ inc hl

.found_line:
    ld bc, 0
    ex de, hl
    kld(hl, (old_index))
    pcall(cpHLBC)
    push af
        kcall(z, done@handle_down)
    pop af
    kcall(nz, index_loop@handle_down)

    kld(a, (caret_y))
    cp 8
    kcall(z, scroll_up)

    kjp(draw_loop)

scroll_down:
    kld(hl, (file_buffer))
    kld(de, (file_top))
    add hl, de
.loop:
    ld a, (hl)
    inc hl
    inc de
    or a
    kjp(z, draw_loop) ; abort
    cp '\n'
    jr nz, .loop
    kld((file_top), de)
    kjp(draw_loop)

scroll_up:
    kld(hl, (file_buffer))
    kld(bc, (file_buffer))
    kld(de, (file_top))
    add hl, de
.first_loop: ; find the previous newline
    pcall(cpHLBC)
    kjp(z, draw_loop) ; abort
    ld a, (hl)
    dec hl
    dec de
    cp '\n'
    jr nz, .first_loop
.loop: ; find the next one
    pcall(cpHLBC)
    jr z, .end
    ld a, (hl)
    dec hl
    dec de
    cp '\n'
    jr nz, .loop
    inc de \ inc de
.end:
    kld((file_top), de)
    kjp(draw_loop)

scroll_left:
    kld(a, (scroll_x))
    or a
    kjp(z, main_loop)
    dec a
    kld((scroll_x), a)
    ret

scroll_right:
    kld(a, (scroll_x))
    inc a
    kld((scroll_x), a)
    ret

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
