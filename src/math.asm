.include "globals.asm"

.export check_rect_intersection


;
; Evaluate an intersection between two axis-aligned rectangles.
;
; Arguments:
;   var1    - First rectangle left side X coord (L1)
;   var2    - First rectangle top side Y coord (T1)
;   var3    - First rectangle right side X coord (R1)
;   var4    - First rectangle bottom side Y coord (B1)
;   var5    - Second rectangle left side X coord (L2)
;   var6    - Second rectangle top side Y coord (T2)
;   var7    - Second rectangle right side X coord (R2)
;   var8    - Second rectangle bottom side Y coord (B2)
;
; Returns:
;   C flag  - set if there's intersection, clear otherwise
;
.proc check_rect_intersection
            lda var7
            cmp var1        ; R2 < L1? First's left edge is to the right of second's right edge?
            bcc @nooverlap
            lda var3
            cmp var5        ; R1 < L2? First's right edge is to the left of second's left edge?
            bcc @nooverlap
            lda var8
            cmp var2        ; B2 < T1? First's top edge is below second's bottom edge?
            bcc @nooverlap
            lda var4
            cmp var6        ; B1 < T2? First's bottom edge is above second's top edge?
            bcc @nooverlap
            sec             ; the rectangles intersect, set carry flag
@nooverlap: rts             ; carry propagated from instructions above
.endproc
