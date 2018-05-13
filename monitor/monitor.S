
.set noreorder
.set noat

.section .data
    .global helloString
helloString:
    .asciz "MONITOR for recc - interrupt on"

.section .text
    .global START
START:
    lui $t9 0xffff
    addiu $t9 $t9 0xffff
    #set t9 to 0xffffffff

    lui $t0 0x30
    addiu $t1 $ZR IRQ_Handler
    sto $t1 0x20($t0)
    #save interrupt entrance

    lui $SP 0x8000
    addiu $t1 $ZR 0x5a
    or $FR $FR $t1
    #interrupt open

    addiu $t8 $ZR helloString
    addiu $ra $pc 0x8
    beq $ZR $ZR DoWrite

loop:
    addiu $ZR $ZR 0x0
    addiu $ZR $ZR 0x0
    beq $ZR $ZR loop


ReadSerial:
## only 1 charactor, save in v0
    lui $t0 0x3
    loa $v0 0x10($t0)
    # get v0

    addiu $a0 $a0 0x1
    # add count

    addiu $t1 $ZR 0x500
    xor $t1 $t1 $ZR
    and $FR $FR $t1
    # clear bit 8 and bit 10 in FR

    jr $ra

WriteSerial:
## only 1 charactor, save in v1
    lui $t0 0x3
    sto $v1 0x0($t0)
    # save v1

    addiu $t1 $ZR 0x240
    xor $t1 $t1 $ZR
    and $FR $FR $t1
    # clear bit 6 and bit 9 in FR

    jr $ra

WriteNext:
    lb $v1 0x0($a1)
    beq $v1 $ZR WriteFinish
    
    subu $SP $SP $WR
    sto $ra 0x0($SP)
    addiu $ra $pc 0x8
    beq $ZR $ZR WriteSerial
    loa $ra 0x0($SP)
    addu $SP $SP $WR

    addiu $a1 $a1 0x1
    jr $ra
WriteFinish:
    xor $a1 $a1 $a1
    jr $ra

DoWrite:
## try to write a string to serial
    beq $a1 $ZR DoWriteReturn
    addiu $a1 $t8 0x0
    # save the position of string waiting to write

    addiu $t0 $ZR 0x200
    and $t0 $t0 $FR
    beq $t0 $ZR DoWriteReturn
    # check if the serial is avaliable

    subu $SP $SP $WR
    sto $ra 0x0($SP)
    addiu $ra $pc 0x8
    beq $ZR $ZR WriteNext
    loa $ra 0x0($SP)
    addu $SP $SP $WR
DoWriteReturn:
    jr $ra

WriteHandler:
## handle UART1_out interrupt
    beq $a1 $ZR WriteHandlerReturn
    addiu $t0 $ZR 0x200
    and $t0 $t0 $FR
    beq $t0 $ZR WriteHandlerReturn
    subu $SP $SP $WR
    sto $ra 0x0($SP)
    addiu $ra $pc 0x8
    beq $ZR $ZR WriteNext
    loa $ra 0x0($SP)
    addu $SP $SP $WR
WriteHandlerReturn:
    jr $ra

IRQ_Handler:
## handle any interrupts
    sto $ra -0x4($SP)
    sto $t0 -0x8($SP)
    sto $t1 -0xc($SP)
    sto $t2 -0x10($SP)
    sto $t3 -0x14($SP)
    sto $t4 -0x18($SP)
    sto $t5 -0x1c($SP)
    sto $t6 -0x20($SP)
    sto $t7 -0x24($SP)
    sto $t8 -0x28($SP)
    #sto $t9 -0x2c($SP)
    #sto $a0 -0x30($SP)
    #sto $a1 -0x34($SP)
    #sto $v0 -0x38($SP)
    #sto $v1 -0x3c($SP)
    addiu $t0 $ZR 0x28
    subu $SP $SP $t0
    # save registers
    # note: we don't save a0 a1 v0 v1 here
    # because they are "global variables" for UART

Try_TIMER:
    addiu $t0 $ZR 0x10
    and $t0 $t0 $FR
    beq $t0 $ZR Try_UART_OUT

    subu $SP $SP $WR
    sto $ra 0x0($SP)
    addiu $ra $pc 0x8
    #beq $ZR $ZR TimerHandler
    loa $ra 0x0($SP)
    addu $SP $SP $WR

Try_UART_OUT:
    addiu $t0 $ZR 0x40
    and $t0 $t0 $FR
    beq $t0 $ZR Try_UART_IN

    subu $SP $SP $WR
    sto $ra 0x0($SP)
    addiu $ra $pc 0x8
    beq $ZR $ZR WriteHandler
    loa $ra 0x0($SP)
    addu $SP $SP $WR

Try_UART_IN:
    addiu $t0 $ZR 0x100
    and $t0 $t0 $FR
    beq $t0 $ZR IRQ_return

    subu $SP $SP $WR
    sto $ra 0x0($SP)
    addiu $ra $pc 0x8
    #beq $ZR $ZR ReadHandler
    loa $ra 0x0($SP)
    addu $SP $SP $WR

IRQ_return:
    addiu $SP $SP 0x28
    #loa $v1 -0x3c($SP)
    #loa $v0 -0x38($SP)
    #loa $a1 -0x34($SP)
    #loa $a0 -0x30($SP)
    #loa $t9 -0x2c($SP)
    loa $t8 -0x28($SP)
    loa $t7 -0x24($SP)
    loa $t6 -0x20($SP)
    loa $t5 -0x1c($SP)
    loa $t4 -0x18($SP)
    loa $t3 -0x14($SP)
    loa $t2 -0x10($SP)
    loa $t1 -0xc($SP)
    loa $t0 -0x8($SP)
    loa $ra -0x4($SP)
    addiu $FR $FR 0x4
    #this is equal to eret
