;
; Enemy.
;
.struct Enemy
    pos     .word   ; X,Y position
    kind    .byte   ; kind of enemy: determines appearance and behavior
    sprite  .addr   ; address of enemy's ship sprite
.endstruct


;
; Enemy kind
;
.enum EnemyKind
    NONE
    SPACETOPUS
    UFO
.endenum
