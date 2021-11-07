.macro double_accumulator
    asl
    and #%11111110
.endmacro

.macro quadruple_accumulator
    asl
    asl
    and #%11111100
.endmacro
