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
