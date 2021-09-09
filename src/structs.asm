;
; Enemy.
;
.struct Enemy
    pos     .word   ; X,Y position
    kind    .byte   ; kind of enemy: determines appearance and behavior
    sprite  .addr   ; address of enemy's ship sprite
    hits    .byte   ; counter of hits received since last tick, modified by projectiles
.endstruct


;
; Enemy kind
;
.enum EnemyKind
    NONE
    SPACETOPUS
    UFO
.endenum


;
; Sprite instance.
;
.struct Sprite
    pos     .word   ; X,Y coordinates
    anim    .addr   ; animation descriptor
    frame   .byte   ; current animation frame index
    elapsed .byte   ; number of frames elapsed since last frame advance
.endstruct


;
; Animation descriptor (read-only).
;
.struct Animation
    length  .byte   ; length in frames
    speed   .byte   ; playback speed
    tile0   .byte   ; starting tile ID
    attr    .byte   ; attribute set
    size    .byte   ; frame size in tiles
.endstruct
