;collision_component_container:
; list of all collision components


; updates collision components
; -> stores collisions
; -> notifies components
; 

collision_component:
    .byte collision_mask
    .byte collision_layer

