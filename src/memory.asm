.include "structs.asm"
.include "constants.asm"

;
; Zero-page RAM layout.
;
.zeropage
    ; temporary variables, for subroutine internal use, unprotected, may be
    ; changed at will by nested calls
    tmp1:               .res 1
    tmp2:               .res 1
    tmp3:               .res 1
    tmp4:               .res 1
    tmp5:               .res 1
    tmp6:               .res 1
    tmp7:               .res 1
    tmp8:               .res 1
    tmp9:               .res 1
    tmp10:              .res 1

    ; variables for passing data in and out from subroutines, protected, unless
    ; explicitly stated otherwise
    var1:               .res 1
    var2:               .res 1
    var3:               .res 1
    var4:               .res 1
    var5:               .res 1
    var6:               .res 1
    var7:               .res 1
    var8:               .res 1
    var9:               .res 1
    var10:              .res 1

    ; pointers for passing addresses in and out from subroutines, protected,
    ; unless explicitly stated otherwise
    ptr1:               .res 2
    ptr2:               .res 2
    ptr3:               .res 2
    ptr4:               .res 2
    ptr5:               .res 2
    ptr6:               .res 2
    ptr7:               .res 2
    ptr8:               .res 2
    ptr9:               .res 2
    ptr10:              .res 2

    scroll_y:           .res 1  ; background vertical scroll offset
    sleeping:           .res 1  ; is waiting for vblank?
    pad1:               .res 1  ; joypad 1 state
    pad2:               .res 1  ; joypad 2 state


;
; Main RAM layout.
;
.bss
    ;
    ; Array of enemy objects.
    ;
    .align 16
    enemies: .res .sizeof(Enemy) * NUM_ENEMIES
    enemies_end:

    ;
    ; Array of sprite objects.
    ;
    .align 16
    sprites: .res (.sizeof(Sprite) * 8)
    sprites_end:

    ;
    ; Array of projectile objects.
    ;
    .align 16
    projectiles: .res (.sizeof(Projectile) * 8)
    projectiles_end:

    ;
    ; Array of players.
    ;
    .align 16
    players: .res (.sizeof(Player) * 2)
    players_end:


;
; PPU Object Attribute Memory - shadow RAM which holds rendering attributes
; of up to 64 sprites.
;
.segment "OAM"
    oam: .res 256


.exportzp tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8, tmp9, tmp10
.exportzp var1, var2, var3, var4, var5, var6, var7, var8, var9, var10
.exportzp ptr1, ptr2, ptr3, ptr4, ptr5, ptr6, ptr7, ptr8, ptr9, ptr10
.exportzp scroll_y, sleeping, pad1, pad2
.export enemies, enemies_end
.export sprites, sprites_end
.export projectiles, projectiles_end
.export players, players_end
.export oam
