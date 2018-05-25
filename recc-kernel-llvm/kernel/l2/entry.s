  .text

	.globl	main
	.p2align	2
	.type	main,@function
	.ent	main										# @main
main:
	.set	noreorder
	.set	nomacro
# BB#0:

	lui	$v0, %hi(g_kernel_sp)
	ori	$v0, $v0, %lo(g_kernel_sp)
	lui	$v1, %hi(kernel_stack)
	ori	$v1, $v1, %lo(kernel_stack)
	addiu	$v1, $v1, 4092
	sto	$v1, 0($v0)
	# g_kernel_sp = &(kernel_stack[STACK_SIZE-1])

	lui	$sp, %hi(init_stack)
	ori	$sp, $sp, %lo(init_stack)
	addiu $sp, $sp, 1020
	# using init stack

	lui	$t0, %hi(kernel_init)
	ori	$t0, $t0, %lo(kernel_init)
	jalr $t0

	# never here, raise errno -1
	addiu $a0, $zr, -1
	addiu $t0, $zr, 1
	or $fr, $fr, $t0
	.set	macro
	.set	reorder
	.end	main
$func_end0:
	.size	main, ($func_end0)-main

