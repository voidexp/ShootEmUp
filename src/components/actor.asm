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
;   var1               - type of actor
;   ptr1           - owner

; OPT ARGS:
;   [PLAYER_ROLE]
;   ptr3           - joystick address
;   ptr4           - flame address

;
; RETURN:
;   ptr2           - address of actor_component
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc create_actor_component
    ; use ptr2 as ptr3 is return address
    calc_address_with_offset actor_component_container, current_actor_component_container_size, ptr2

    ; common for all actor components, store the owner as first arguments
    ldy #$00                                ; owner lo
    lda ptr1
    sta (ptr2), y
    iny

    lda ptr1 + 1                       ; owner hi
    sta (ptr2), y
    iny

    lda var1
    sta (ptr2), Y                      ; type of actor role
    iny

    iny                                     ; safe this byte for the size of THIS actor component

    ; check what kind of component we want to create
    lda var1
    cmp #PLAYER_ROLE
    bcc :+
    ; CREATE PLAYER_ROLE_CMP
    ; store addresses of joypad id, accessoires (flame, shield)
    ldy #$42
    ldy #$04
    lda ptr3                           ; joystick address
    sta (ptr2), y
    iny

    lda ptr3 + 1
    sta (ptr2), y
    iny

    lda ptr4                           ; flame address
    sta (ptr2), y
    iny

    lda ptr4 + 1
    sta (ptr2), y
    iny

    ; add the size of the currently created compnent to the offset counter
    ; (should be 8 for player role, 2 for dummy role, ... )
 :  tya
    sta (ptr2), Y                      ; store size of current actor component at fourth byte

    lda #$33
    lda current_actor_component_container_size
    clc
    adc var2
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
    sta ptr1

    lda #>actor_component_container
    sta ptr1 + 1

    ldy #$00                                ; reset y

    lda num_actor_components
    cmp #$00
    bne @process_actor_component           ; early out if list is empty
    rts

@process_actor_component:
    lda (ptr1), y                      ; Get entity address lo byte
    sta ptr2
    iny
    lda (ptr1), y                      ; Get entity address hi byte
    sta ptr2 + 1
    iny

    ; get type of actor role
    lda (ptr1), y                      ; type of actor role
    iny
    iny

    ; check what kind of component we want to update
    cmp #PLAYER_ROLE
    bne @end_of_process

    ; first check the current input, therefore fetch the joystick address in a temp variable
    ldy #$34
    ldy #$04
    lda (ptr1), Y
    sta ptr3
    iny

    lda (ptr1), Y
    sta ptr3 + 1
    jsr process_controller_input            ; return player direction vector

    ; ARGS:
    ;  ptr1:       - component address, offsetted
    ;  ptr2:       - player entity
    ;  var2:           - player direction vector
    jsr update_player_role

@end_of_process:
    ; get size of actor role
    ldy #$03
    lda (ptr1), y                      ; size of actor component
    iny
    sec
    sbc #$02
    sta var10

    ; now offset the buffer to the next component (add offsize to current one)
    tya
    clc
    adc var10
    tay

    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; processes controller input and calculates player position, direction
;
; ARGS:
;   ptr3       - joystick_address

; RETURN:
;   var2           - player_direction_vector
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc process_controller_input
    ldy #$00
    ; first latch buttons to be able to poll input
    lda #$01            ; fill input from buttons currently held
    sta (ptr3), y
    lda #$00            ; return to serial mode wait for bits to be read out
    sta (ptr3), y

    ldx #$00
    ; we don't process those yet, need to be executed in correct order
    ; check if magic flag is set for this button and store direction indicator


    lda (ptr3), y         ; Player 1 - A
    and #$01
    beq :+
    txa
    ora #PRESS_A
    tax

:   lda (ptr3), y        ; Player 1 - B
    and #$01
    beq :+
    txa
    ora #PRESS_B
    tax

:   lda (ptr3), y         ; Player 1 - Select
    lda (ptr3), y         ; Player 1 - Start

    lda (ptr3), y         ; Player 1 - Up
    and #$01
    beq :+
    txa
    ora #MOVE_UP
    tax

 :  lda (ptr3), y         ; Player 1 - Down
    and #$01
    beq :+
    txa
    ora #MOVE_DOWN
    tax

:   lda (ptr3), y         ; Player 1 - Left
    and #$01
    beq :+
    txa
    ora #MOVE_LEFT
    tax

:   lda (ptr3), y         ; Player 1 - Right
    and #$01
    beq :+
    txa
    ora #MOVE_RIGHT
    tax

:   txa
    sta var2
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; processes controller input and calculates player position, direction
;
; ARGS:
;  ptr1:       - component address, offsetted
;  ptr2:       - player entity
;  var2:           - player direction vector - ?????
;
; RETURN:
;   var1           - xDir
;   var2           - yDir
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc update_player_role
    ; reset draw flags, set them one by one for the elements
    lda #$00
    sta draw_flags

    ; reset x and y direction variables
    lda #$00
    sta var3
    sta var4

    lda var2                               ; check if the player direction vector is anything than zero .. if yes => move it
    cmp #$01
    bcc @end_of_player_move                 ; if no bit is set no movement happened => end update
@move_up:
    lda #MOVE_UP
    bit var2
    beq @move_down
    ; move up
    lda #$01                                ; yDir
    clc
    eor #$ff
    adc #$01
    sta var4
@move_down:
    lda #MOVE_DOWN
    bit var2
    beq @move_left
    ; move down
    lda #$01
    sta var4
@move_left:
    lda #MOVE_LEFT
    bit var2
    beq @move_right
    ; move left
    lda #$01                                ; - xDir
    clc
    eor #$ff
    adc #$01
    sta var3
@move_right:
    lda #MOVE_RIGHT
    bit var2
    beq @shoot
    ; move right
    lda #$01
    sta var3                                ; + xDir

@shoot:
    lda #PRESS_A
    bit var2
    beq @end_of_player_move

    ; if no direction was set in this frame .. take default direction -> upwards -y
    lda var4
    pha                                     ; push y direction to stack

    ; lda var3
    ; clc
    lda var4
    cmp #$00
    bne :+                                  ; if a direction is set go forward and spawn the projectile

    lda #$01                                ; yDir
    clc
    eor #$ff
    adc #$01
    sta var4
:
    ldy #$00                                ; get x, y position from the entity and offset it a bit
    lda (ptr2), y
    clc
    adc #$04
    sta var1                               ; xPos

    iny
    lda (ptr2), y
    sec
    sbc #$08
    sta var7                               ; yPos

    lda var7
    sec
    sbc #$04
    sta var2

    lda var3
    pha

    ; lda #$01
    ; sta var5

    ; requires var1, var2 (entity position), var3, var4 (projectile_direction)
    jsr update_projectile_position

    pla
    sta var3

    ; restore y direction
    pla
    sta var4

@end_of_player_move:
    lda var3
    sta tmp1

    lda var4
    sta tmp2

    ; store player direction in the movement component
    lda ptr2                           ; ptr2 player entity
    sta ptr10

    lda ptr2 + 1
    sta ptr10 + 1

    jsr update_movement_direction

    ; store flame direction in the movement component
    ldy #$06
    lda (ptr1), y
    sta ptr10
    iny

    lda (ptr1), y
    sta ptr10 + 1                       ; ptr5 contains flame entity

    jsr update_movement_direction

    ; check if there was some active movement -> show the flame
    lda #SPRITE_CMP
    sta tmp1
    lda var2
    cmp #$01
    bcs :+
    jmp disable_one_entity_component
:
    lda var2
    cmp #$01
    bcc :+
    jmp enable_one_entity_component
    ; reset frame counter and player direction and update the position in the next second
    ; so that the next time
:   lda #$00
    sta update_flags
    rts
.endproc
