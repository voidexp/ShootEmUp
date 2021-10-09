.export game_over_mode


.rodata
game_over_mode:
    .addr game_over_init
    .addr game_over_fini
    .addr game_over_tick


.code
.proc game_over_init
            rts
.endproc


.proc game_over_fini
            rts
.endproc


.proc game_over_tick
            rts
.endproc
