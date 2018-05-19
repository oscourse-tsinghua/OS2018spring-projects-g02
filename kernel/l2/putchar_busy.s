	.text
	.section .mdebug.abiO32
	.previous

	.globl	putchar_busy
	.p2align	2
	.type	putchar_busy,@function
	.ent	putchar_busy                    # @putchar_busy
putchar_busy:
	.frame	$fp,32,$lr
	.mask 	0x00006084,-4
	.set	noreorder
	.set	nomacro

# prologue
	addiu	$sp, $sp, -24
	sto	$lr, 20($sp)            # 4-byte Folded Spill
	sto	$fp, 16($sp)            # 4-byte Folded Spill
	sto	$s0, 12($sp)            # 4-byte Folded Spill
	sto	$s1, 8($sp)             # 4-byte Folded Spill

# loop while ((FR & UART_OUT_READY) == 0)
  addiu $t0, $zr, 0x200
$eval_fr_uart_out_ready_bit:
  and $t1, $fr, $t0
  beq $t1, $zr, $eval_fr_uart_out_ready_bit

# unset UART_OUT_READY
  addiu $t1, $zr, -1
  xor $t0, $t1, $t0
  and $fr, $fr, $t0

# write arg to UART_OUT_PORT
  lui $t0, 0x30               # t0=0x300000=UART_OUT_PORT
  sto $a0, 0($t0)

# epilogue
	loa	$s1, 8($sp)             # 4-byte Folded Reload
	loa	$s0, 12($sp)            # 4-byte Folded Reload
	loa	$fp, 16($sp)            # 4-byte Folded Reload
	loa	$lr, 20($sp)            # 4-byte Folded Reload
	addiu	$sp, $sp, 24
	ret	$lr
	.set	macro
	.set	reorder
	.end	putchar_busy
$putchar_busy_end:
	.size	putchar_busy, ($putchar_busy_end)-putchar_busy
