;
; Enemy.
;
.struct Enemy
    sprite  .addr   ; address of enemy's ship sprite
    kind    .byte   ; kind of enemy: determines appearance and behavior
    hits    .byte   ; counter of hits received since last tick; modified by projectiles
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


;
; Projectile.
;
; Attribute field bits:
;   Bit 0: Owner/Direction.
;       0 = player / goes up
;       1 = enemy / goes down
;
;   Bit 1: Kind.
;       00  - disabled (the value of the whole attribute should be 0)
;       01  - bullet
;       10  - missile   (TODO)
;       11  - laser     (TODO)
;
.struct Projectile
    sprite  .addr   ; sprite address
    attr    .byte   ; attribute bits, 0 = projectile disabled
.endstruct


;
; Player.
;
.struct Player
    ship        .addr   ; ship sprite address
    flame       .addr   ; flame sprite address
    cooldown    .byte   ; shot cooldown
    hits        .byte   ; damage hits since last tick
    score       .word   ; player's score
.endstruct
