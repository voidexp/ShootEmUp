; movement component
; size -> 5 byte

.rodata
MOVE_COMP_SIZE = 5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; movement_component:
;    .addr owner                     ; entity -> contains x and y position
;    .byte speed
;    .byte dirX, dirY
; movement rule
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; update all movements

; container for 25 movement components
; addresses or data? -> addresses

.segment "RAM"
movement_component_container: .res 50

num_movement_components: .res 1


.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT CODE .. reset all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_movement_components:
    lda #$00
    sta num_movement_components
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; create movement components
; ARGS:
;   var_1               - xPosition
;   var_2               - yPosition
;   var_3               - xDir
;   var_4               - yDir, now one byte will be reduced
;   var_5               - speed

;   address_1           - owner
;
; RETURN:
;   address_2           - address of movement_component
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
create_movement_component:
    ; calculate offset in current component buffer
    mult_with_constant num_movement_components, #MOVE_COMP_SIZE, var_5

    calc_address_with_offset movement_component_container, var_5, address_2 ; use address_2 as address_3 is return address

    ldy #$00                                ; owner lo
    lda address_1
    sta (address_2), y

    iny
    lda address_1 + 1                       ; owner hi
    sta (address_2), y
    iny

    lda var_5                               ; speed
    sta (address_2), y
    iny

    lda var_3                               ; dirX
    sta (address_2), y
    iny

    lda var_4                               ; dirY
    sta (address_2), y
    iny

    inc num_movement_components
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; update movement components
; ARGS:
;
; RETURN:
;   address_1             - updated movement component
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_movement_components:
    ; calculate max value and store it in var_1
    mult_with_constant num_movement_components, #MOVE_COMP_SIZE, var_1

    lda num_movement_components
    sta var_1

    lda #<movement_component_container
    sta address_1

    lda #>movement_component_container
    sta address_1 + 1
    
    ldy #$00

    lda num_movement_components
    cmp #$00
    bne @update_mov_comp                    ; early out if list is empty
    rts
@update_mov_comp:
    lda (address_1), y                      ; Get entity address lo byte
	sta address_2
    iny

    lda (address_1), y                      ; Get entity address hi byte
	sta address_2 + 1
    iny

    tya                                     ; push y to stack 
    pha

    ldy #$00                                ; get x, y position from the entity
    lda (address_2), y
    sta var_2
    iny

    lda (address_2), y
    sta var_3

    pla                                     ; get y offset from stack again
    tay

    lda (address_1), y                      
    sta var_4                               ; speed
    iny

    lda (address_1), Y
    sta var_5                               ; dirX
    iny 

    lda (address_1), Y
    sta var_6                               ; dirY
    iny 

    tya
    pha

    ; mult_variables var_5, var_4, var_7      ; calculate offset in x direction

    ldy #$00
    lda var_2
    clc
    adc var_5
    ;lda var_7
    sta (address_2), y                      ; store new x pos

    ;mult_variables var_6, var_4, var_7      ; calculate offset in y direction
    
    iny
    lda var_3
    clc
    adc var_6
    ;lda var_7
    sta (address_2), y                     ; store new y pos

    pla
    tay

    dec var_1
    lda var_1
    cmp #$00
    bne @update_mov_comp
    rts
