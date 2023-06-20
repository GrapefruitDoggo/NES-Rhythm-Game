; this will get filled up more eventually, but i figured a maths library will come in handy :3

.macro divide_acc_by_16
    lsr
    lsr
    lsr
    lsr
.endmacro

.macro multiply_acc_by_8
    asl
    asl
    asl
.endmacro