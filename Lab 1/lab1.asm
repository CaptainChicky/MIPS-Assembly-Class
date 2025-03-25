	.data
hello_message: .asciiz "Hello, world!\n"
	
precur: .asciiz "Hello, "
	
input_buffer: .space 50
	
	.text
	.globl main
main:
	li t0, 1
	li t1, 2
	li t2, 3
	
	#=========================
	
	move a0, t0
	move v0, t1
	move t2, zero
	
	#=========================
	
	li a0, 123
	li v0, 1
	syscall
	
	li a0, '\n'
	li v0, 11
	syscall
	
	li a0, 456
	li v0, 1
	syscall
	
	li a0, '\n'
	li v0, 11
	syscall
	
	#=========================
	
	li v0, 5
	syscall
	move s0, v0
	
	li v0, 5
	syscall
	move s1, v0
	
	add a0, s0, s1
	
	li v0, 1
	syscall
	
	#=========================
	
	li a0, '\n'
	li v0, 11
	syscall
	
	la a0, hello_message
	li v0, 4
	syscall
	
	#=========================
	
	la a0, input_buffer
	li a1, 50
	li v0, 8
	syscall
	
	la a0, precur
	li v0, 4
	syscall
	
	la a0, input_buffer
	li v0, 4
	syscall
	
	#=========================
	
	li v0, 10
	syscall
