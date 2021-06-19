.include "macros.asm"
.include "globals.asm"
.include "constants.asm"

.importzp update_flags, draw_flags

.import enable_one_entity_component
.import disable_one_entity_component
.import update_movement_direction
.import update_projectile_position

.export create_actor_component
.export init_actor_components
.export process_controller_input
.export update_actor_components

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; manages player input/movement
;
;   analyzes movement
;   sets properties of player movement component
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;    lda shoot_cooldown
;    cmp #$00
;    bcs :+
;    dec shoot_cooldown
;:


.segment "BSS"
; container for 25 actor components
num_actor_components:                   .res 1
current_actor_component_container_size: .res 1
actor_component_container:              .res 30

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT CODE .. reset all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc init_actor_components
    lda #$00
    sta num_actor_components
    sta current_actor_component_container_size
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; create actor components
; ARGS:
;   var_1               - type of actor
;   address_1           - owner

; OPT ARGS:
;   [PLAYER_ROLE]
;   address_3           - joystick address
;   address_4           - flame address

;
; RETURN:
;   address_2           - address of actor_component
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc create_actor_component
    ; use address_2 as address_3 is return address
    calc_address_with_offset actor_component_container, current_actor_component_container_size, address_2

    ; common for all actor components, store the owner as first arguments
    ldy #$00                                ; owner lo
    lda address_1
    sta (address_2), y
    iny

    lda address_1 + 1                       ; owner hi
    sta (address_2), y
    iny

    lda var_1
    sta (address_2), Y                      ; type of actor role
    iny

    iny                                     ; safe this byte for the size of THIS actor component

    ; check what kind of component we want to create
    lda var_1
    cmp #PLAYER_ROLE
    bcc :+
    ; CREATE PLAYER_ROLE_CMP
    ; store addresses of joypad id, accessoires (flame, shield)
    ldy #$42
    ldy #$04
    lda address_3                           ; joystick address
    sta (address_2), y
    iny

    lda address_3 + 1
    sta (address_2), y
    iny

    lda address_4                           ; flame address
    sta (address_2), y
    iny

    lda address_4 + 1
    sta (address_2), y
    iny

    ; add the size of the currently created compnent to the offset counter
    ; (should be 8 for player role, 2 for dummy role, ... )
 :  tya
    sta (address_2), Y                      ; store size of current actor component at fourth byte

    lda #$33
    lda current_actor_component_container_size
    clc
    adc var_2
    sta current_actor_component_container_size

    inc num_actor_components

    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; processes controller input and calculates player position, direction
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc update_actor_components
    ; update player actor components

    lda #<actor_component_container
    sta address_1

    lda #>actor_component_container
    sta address_1 + 1

    ldy #$00                                ; reset y

    lda num_actor_components
    cmp #$00
    bne @process_actor_component           ; early out if list is empty
    rts

@process_actor_component:
    lda (address_1), y                      ; Get entity address lo byte
    sta address_2
    iny
    lda (address_1), y                      ; Get entity address hi byte
    sta address_2 + 1
    iny

    ; get type of actor role
    lda (address_1), y                      ; type of actor role
    iny
    iny

    ; check what kind of component we want to update
    cmp #PLAYER_ROLE
    bne @end_of_process

    ; first check the current input, therefore fetch the joystick address in a temp variable
    ldy #$34
    ldy #$04
    lda (address_1), Y
    sta address_3
    iny

    lda (address_1), Y
    sta address_3 + 1
    jsr process_controller_input            ; return player direction vector

    ; ARGS:
    ;  address_1:       - component address, offsetted
    ;  address_2:       - player entity
    ;  var_2:           - player direction vector
    jsr update_player_role

@end_of_process:
    ; get size of actor role
    ldy #$03
    lda (address_1), y                      ; size of actor component
    iny
    sec
    sbc #$02
    sta var_10

    ; now offset the buffer to the next component (add offsize to current one)
    tya
    clc
    adc var_10
    tay

    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; processes controller input and calculates player position, direction
;
; ARGS:
;   address_3       - joystick_address

; RETURN:
;   var_2           - player_direction_vector
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc process_controller_input
    ldy #$00
    ; first latch buttons to be able to poll input
    lda #$01            ; fill input from buttons currently held
    sta (address_3), y
    lda #$00            ; return to serial mode wait for bits to be read out
    sta (address_3), y

    ldx #$00
    ; we don't process those yet, need to be executed in correct order
    ; check if magic flag is set for this button and store direction indicator


    lda (address_3), y         ; Player 1 - A
    and #$01
    beq :+
    txa
    ora #PRESS_A
    tax

:   lda (address_3), y        ; Player 1 - B
    and #$01
    beq :+
    txa
    ora #PRESS_B
    tax

:   lda (address_3), y         ; Player 1 - Select
    lda (address_3), y         ; Player 1 - Start

    lda (address_3), y         ; Player 1 - Up
    and #$01
    beq :+
    txa
    ora #MOVE_UP
    tax

 :  lda (address_3), y         ; Player 1 - Down
    and #$01
    beq :+
    txa
    ora #MOVE_DOWN
    tax

:   lda (address_3), y         ; Player 1 - Left
    and #$01
    beq :+
    txa
    ora #MOVE_LEFT
    tax

:   lda (address_3), y         ; Player 1 - Right
    and #$01
    beq :+
    txa
    ora #MOVE_RIGHT
    tax

:   txa
    sta var_2
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; processes controller input and calculates player position, direction
;
; ARGS:
;  address_1:       - component address, offsetted
;  address_2:       - player entity
;  var_2:           - player direction vector - ?????
;
; RETURN:
;   var_1           - xDir
;   var_2           - yDir
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc update_player_role
    ; reset draw flags, set them one by one for the elements
    lda #$00
    sta draw_flags

    ; reset x and y direction variables
    lda #$00
    sta var_3
    sta var_4

    lda var_2                               ; check if the player direction vector is anything than zero .. if yes => move it
    cmp #$01
    bcc @end_of_player_move                 ; if no bit is set no movement happened => end update
@move_up:
    lda #MOVE_UP
    bit var_2
    beq @move_down
    ; move up
    lda #$01                                ; yDir
    clc
    eor #$ff
    adc #$01
    sta var_4
@move_down:
    lda #MOVE_DOWN
    bit var_2
    beq @move_left
    ; move down
    lda #$01
    sta var_4
@move_left:
    lda #MOVE_LEFT
    bit var_2
    beq @move_right
    ; move left
    lda #$01                                ; - xDir
    clc
    eor #$ff
    adc #$01
    sta var_3
@move_right:
    lda #MOVE_RIGHT
    bit var_2
    beq @shoot
    ; move right
    lda #$01
    sta var_3                                ; + xDir

@shoot:
    lda #PRESS_A
    bit var_2
    beq @end_of_player_move

    ; if no direction was set in this frame .. take default direction -> upwards -y
    lda var_4
    pha                                     ; push y direction to stack

    ; lda var_3
    ; clc
    lda var_4
    cmp #$00
    bne :+                                  ; if a direction is set go forward and spawn the projectile

    lda #$01                                ; yDir
    clc
    eor #$ff
    adc #$01
    sta var_4
:
    ldy #$00                                ; get x, y position from the entity and offset it a bit
    lda (address_2), y
    clc
    adc #$04
    sta var_1                               ; xPos

    iny
    lda (address_2), y
    sec
    sbc #$08
    sta var_7                               ; yPos

    lda var_7
    sec
    sbc #$04
    sta var_2

    lda var_3
    pha

    ; lda #$01
    ; sta var_5

    ; requires var_1, var_2 (entity position), var_3, var_4 (projectile_direction)
    jsr update_projectile_position

    pla
    sta var_3

    ; restore y direction
    pla
    sta var_4

@end_of_player_move:
    lda var_3
    sta temp_1

    lda var_4
    sta temp_2

    ; store player direction in the movement component
    lda address_2                           ; address_2 player entity
    sta address_10

    lda address_2 + 1
    sta address_10 + 1

    jsr update_movement_direction

    ; store flame direction in the movement component
    ldy #$06
    lda (address_1), y
    sta address_10
    iny

    lda (address_1), y
    sta address_10 + 1                       ; address_5 contains flame entity

    jsr update_movement_direction

    ; check if there was some active movement -> show the flame
    lda #SPRITE_CMP
    sta temp_1
    lda var_2
    cmp #$01
    bcs :+
    jmp disable_one_entity_component
:
    lda var_2
    cmp #$01
    bcc :+
    jmp enable_one_entity_component
    ; reset frame counter and player direction and update the position in the next second
    ; so that the next time
:   lda #$00
    sta update_flags
    rts
.endproc
