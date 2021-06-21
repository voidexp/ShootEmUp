def test_iter_ptr(cpu):
    cpu.compile_and_run('''
    .include "macros.asm"

    .zeropage
        ptr: .res 2

    .bss
        array: .res 10
        array_end:

    .code
        lda #<array
        sta ptr
        lda #>array
        sta ptr + 1

        ; iterate over an array
        .mac block
            lda #$78
            ldy #00
            sta (ptr),y
        .endmac
        iter_ptr ptr, array_end, 1, block
    ''')

    assert bytes(cpu.memory[cpu.bss:cpu.bss + 10]) == b'x' * 10


def test_find_ptr(cpu):
    cpu.compile_and_run('''
    .include "macros.asm"

    .zeropage
        ptr: .res 2

    .data
        msg: .byte "Hello NES!"
        end_msg:

    .code
        ; set iterator to first byte of msg
        lda #<msg
        sta ptr
        lda #>msg
        sta ptr + 1

        .mac check_char
            ldy #0
            lda (ptr),y
            cmp #$4e  ; 'N' character
        .endmac
        find_ptr ptr, end_msg, 1, check_char
    ''')

    assert cpu.a == ord('N')
    assert cpu.memory[0] == 6
