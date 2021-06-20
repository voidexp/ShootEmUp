def test_code_execution(cpu):
    cpu.compile_and_run('''
    .code
        lda #$ff
        clc
        adc #1
    ''')

    assert cpu.a == 0
    assert cpu.p & cpu.CARRY


def test_zeropage_vars(cpu):
    cpu.compile_and_run('''
    .zeropage
        foo: .res 1
        bar: .res 1

    .code
        lda #$aa
        sta foo
        lda #$bb
        sta bar
    ''')

    assert cpu.memory[0] == 0xaa
    assert cpu.memory[1] == 0xbb


def test_bss_memory(cpu):
    cpu.compile_and_run('''
    .bss
        foo: .res 10

    .code
        lda #$78
        ldy #(.sizeof(foo))
    :   dey
        sta foo,y
        bne :-
    ''')

    assert bytes(cpu.memory[cpu.bss:cpu.bss + 10]) == b'x' * 10


def test_rom_memory(cpu):
    cpu.compile_and_run('''
    .data
        msg: .byte "Hello world!", $00

    .code
        ldy #0
    @copy:
        lda msg,y
        sta $00,y
        beq @end
        iny
        jmp @copy
    @end:
    ''')

    assert bytes(cpu.memory[0:12]) == b'Hello world!'
