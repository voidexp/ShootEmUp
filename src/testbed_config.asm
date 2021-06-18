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

.segment "BSS"
test_data_copy:     .res 12

test_data_address = $0330


.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MICROPHONE CHECK 1, 2
; TIME FOR SOME TESTING
; INITIALIZE SETTINGS FOR THE TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initialize_test:
    jsr initialize_entities
    jsr test_spawn_projectile
    jsr test_spawn_squady
    ; jsr spawn_squady
    ; jsr spawn_spacetopus
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MICROPHONE CHECK 1, 2
; TIME FOR SOME TESTING
; TRIGGER THE TESTS
; y . oam offset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
execute_test:
    ; jsr test_mult_macro
    ; jsr test_mult_constant_macro
    ; jsr test_num_bits_set_in_mask_macro
    ; jsr test_address_offset_macro
    ; jsr test_memcpy_macro
    ;jsr spawn_projectile_test
    jsr test_update_components
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UPDATE ALL THE COMPONENTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
test_update_components:
    lda #%00000001
    cmp update_flags  ; check if the last frame was drawn then update the position for the next one
    bne :+
    jsr update_movement_components
    jsr update_collision_components
    lda #$00
    sta update_flags
:   lda update_animations
    cmp #ANIMATION_SPEED
    bne :+
    jsr update_sprite_components
    lda #$00
    sta update_animations
:   ldy #$00
    jsr draw_sprite_components
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; spawn a squad enemy
; ARGS:
;   var_1           - xPos
;   var_2           - yPos     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                          
test_spawn_squady:
    lda #$40                                ; xPos
    sta var_1
    lda #$10                                ; yPos
    sta var_2

    jsr spawn_static_squad_enemy

    ;rts
    lda #$62                                ; xPos
    sta var_1
    lda #$ab                                ; yPos
    sta var_2

    jsr spawn_static_squad_enemy

    lda #$c0                                ; xPos
    sta var_1
    lda #$50                                ; yPos
    sta var_2

    jsr spawn_static_squad_enemy

    lda #$a8
    sta var_1
    lda #$36
    sta var_2
    lda #$c4                                ; xPos
    sta var_1
    lda #$50                                ; yPos
    sta var_2

    jsr spawn_static_squad_enemy
    rts

test_spawn_projectile:
    lda #$58                                ; xPos
    sta var_1
    lda #$32                                ; yPos
    sta var_2
    lda #$00                                ; xDir
    sta var_3
    lda #$00                                ; yDir
    clc
    eor #$ff
    adc #$01
    sta var_4

    jsr spawn_projectile

    ;rts    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; RETURN
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #$64
    sta var_1
    lda #$ab
    sta var_2
    lda #$00
    sta var_3
    lda #$00
    sta var_4

    jsr spawn_projectile

    lda #$a8
    sta var_1
    lda #$32
    sta var_2
    lda #$00
    sta var_3
    lda #$00
    sta var_4

    jsr spawn_projectile


    lda #$c4                                ; xPos
    sta var_1
    lda #$50                                ; yPos
    sta var_2

    lda #$00
    sta var_3
    lda #$00
    sta var_4

    jsr spawn_projectile


    rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TEST MULT_WITH_CONSTANT MACRO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
test_mult_constant_macro:
    lda #$00
    sta var_1
    mult_with_constant var_1, #$02, var_2
    lda var_2
    sta var_3
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TEST MULT_WITH_CONSTANT MACRO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
test_mult_macro:
    lda #$04
    sta var_1
    lda #$03
    sta var_2
    mult_variables var_1, var_2, var_3
    lda var_3
    sta var_4
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TEST ADDRESS_OFFSETING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
test_address_offset_macro:
    lda #$f1
    sta var_1
    calc_address_with_offset test_data_address, var_1, address_2
    lda address_2 + 1
    sta address_3
    lda address_2 
    sta address_3 + 1
    ; result 0421
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TEST GET NUM BITS SET IN MACRO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
test_num_bits_set_in_mask_macro:
    lda #$07
    sta var_1
    get_num_of_bits_set_in_mask var_1, var_2
    lda var_2
    sta var_3
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TEST PROJECTILE SPAWN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
test_movement_component_creation:
    lda #$c0             ; posX
    sta var_1
    lda #$10             ; posY
    sta var_2
    lda #$00             ; dirX
    sta var_3
    lda #$00             ; dirY -> check with still standing object first
    sta var_4
    lda #$01            ; speed
    sta var_5

    lda #<test_data_address
    sta address_1
    lda #>test_data_address
    sta address_1 + 1

    jsr test_movement_component_creation

    ; save resulting address
    lda address_2 + 1
    sta address_3
    lda address_2 
    sta address_3 + 1

    jsr test_movement_component_creation

    ; save resulting address
    lda address_2 + 1
    sta address_4
    lda address_4 
    sta address_3 + 1
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TEST PROJECTILE SPAWN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
test_projectile_spawn:
    lda $c0             ; posX
    sta var_1
    lda $10             ; posY
    sta var_2
    lda $00             ; dirX
    sta var_3
    lda $00             ; dirY -> check with still standing object first
    sta var_4

    ;jsr spawn_projectile
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TEST MEMCPY MACRO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
test_memcpy_macro:
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