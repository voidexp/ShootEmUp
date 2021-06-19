;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; COMPONENT_MASK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 0         - MOVEMENT
; 1         - SPRITE
; 2         - COLLISION
; 3         - HEALTH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVEMENT_CMP        = 1
SPRITE_CMP          = 2
COLLISION_CMP       = 4
HEALTH_CMP          = 8
ENEMY_CMP           = 16
ACTOR_CMP           = 32


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; COLLISION_LAYER:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENEMY_LYR           = 1
PROJECTILE_LYR      = 2
PLAYER_LYR          = 4
TBD_1_LYR           = 8
TBD_2_LYR           = 16
TBD_3_LYR           = 32

;
; Different actor roles
;
PLAYER_ROLE         = 1
DUMMY_ROLE          = 2

; Input handling (each using a separate bit)
MOVE_UP =     1
MOVE_RIGHT =  2
MOVE_DOWN =   4
MOVE_LEFT =   8
PRESS_A = 16
PRESS_B = 32

;
; Universal background color
;
BG_COLOR = $0d
