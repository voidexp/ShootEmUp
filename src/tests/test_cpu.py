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
        foo:    .res 1
        bar:    .res 1

    .code
        lda #$aa
        sta foo
        lda #$bb
        sta bar
    ''')

    assert cpu.memory[0] == 0xaa
    assert cpu.memory[1] == 0xbb
