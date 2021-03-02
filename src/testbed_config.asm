.rodata
test_data: 
    .byte $00, $01
    .byte $02, $03
    .byte $04, $05
    .byte $06, $07
    .byte $08, $09
    .byte $10, $11

LOOPS = 3
BYTES_PER_LOOP = 4

.segment "RAM"
test_data_copy:     .res 12

.code
execute_test:
    jsr memcpy_test
    rts

memcpy_test:
    ; load address of test_data to address_1

    lda #<test_data
    sta address_1

    lda #>test_data 
    sta address_1 + 1

    ; load address of test_data_copy to address_2
    lda #<test_data_copy
    sta address_2

    lda #>test_data_copy 
    sta address_2 + 1
    
    lda #BYTES_PER_LOOP
    sta temp_2

    lda #LOOPS
    sta temp_1

    lda #$00
    sta temp_3
    sta temp_4

@perform_loop:

    ; src, src_offset, dst, dst_offset, numbytes
    copy_x_bytes_zp address_1, temp_3, address_2, temp_4, temp_2

    lda temp_3
    clc
    adc temp_2
    sta temp_3

    lda temp_4
    clc
    adc temp_2
    sta temp_4
    
    lda #$ff
    ldy temp_4
    sta (address_2), y
    inc temp_4

    dec temp_1
    lda temp_1
    cmp #$00
    bne @perform_loop

    rts