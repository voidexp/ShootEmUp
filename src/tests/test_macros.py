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

def test_add_constant_to_address_macro(cpu):
    cpu.compile_and_run('''
    .include "macros.asm"

    .zeropage
        ptr:       .res 2
        ptr_2:     .res 2
        ptr_3:     .res 2

    .code
        lda #$02
        sta ptr
        lda #$04
        sta ptr + 1

        add_constant_to_address ptr, #24, ptr_2
        add_constant_to_address ptr, #255, ptr_3
    ''')

    assert cpu.memory[0] == 2
    assert cpu.memory[1] == 4
    assert cpu.memory[2] == cpu.memory[0] + 24      # ptr_2
    assert cpu.memory[3] == cpu.memory[1]
    assert cpu.memory[4] == 1                       # ptr_3
    assert cpu.memory[5] == cpu.memory[1] + 1
