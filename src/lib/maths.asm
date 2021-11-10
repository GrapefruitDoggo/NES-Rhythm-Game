; this will get filled up more eventually, but i figured a maths library will come in handy :3

; this and the one below feel *super* janky, i should figure out a better solution i think
.macro double_accumulator
    asl
    and #%11111110
.endmacro

.macro quadruple_accumulator
    asl
    asl
    and #%11111100
.endmacro
