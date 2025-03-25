	.include "lab2_include.asm"
	.data
input_buffer: .space 10
	
x_coord: .word 0
y_coord: .word 0
	
color: .word COLOR_WHITE
	
width: .word 0
height: .word 0
	
	.text
	.globl main
main:
	jal display_init
	
_loop:
lstr a0, "Command ([c]olor, [p]ixel, [l]ine, [r]ectangle, [q]uit): "
	li v0, 4
	syscall
	
	la a0, input_buffer
	li a1, 10
	li v0, 8
	syscall
	
	lb t0, input_buffer
	
	beq t0, 'c', _color
	beq t0, 'p', _pixel
	beq t0, 'l', _line
	beq t0, 'r', _rectangle
	beq t0, 'q', _quit
	
	j _loop
	
	#============================================
	
_color:
lstr a0, "Enter a color in the range [0, 15]: "
	li v0, 4
	syscall
	
_color_input:
	li v0, 5
	syscall
	
	blt v0, 0, _color_retry
	bgt v0, 15, _color_retry
	
	add v0, v0, COLOR_BLACK
	sw v0, color
	
	j _loop
	
_color_retry:
lstr a0, "Enter a color in the range [0, 15]: "
	li v0, 4
	syscall
	j _color_input
	
	#============================================
	
_pixel:
lstr a0, "Enter X coordinate: "
	li v0, 4
	syscall
	
	li v0, 5
	syscall
	sw v0, x_coord
	
lstr a0, "Enter Y coordinate: "
	li v0, 4
	syscall
	
	li v0, 5
	syscall
	sw v0, y_coord
	
	lw a0, x_coord
	lw a1, y_coord
	lw a2, color
	
	jal display_set_pixel
	jal display_finish_frame
	
	j _loop
	
	#============================================
	
_line:
lstr a0, "Enter X coordinate: "
	li v0, 4
	syscall
	
	li v0, 5
	syscall
	sw v0, x_coord
	
lstr a0, "Enter Y coordinate: "
	li v0, 4
	syscall
	
	li v0, 5
	syscall
	sw v0, y_coord
	
lstr a0, "Enter width: "
	li v0, 4
	syscall
	
	li v0, 5
	syscall
	sw v0, width
	
	lw a0, x_coord
	lw a1, y_coord
	lw a2, color
	lw s0, width
	
_line_loop:
	beqz s0, _line_done
	
	jal display_set_pixel
	
	addi a0, a0, 1
	subi s0, s0, 1
	
	j _line_loop
	
_line_done:
	jal display_finish_frame
	j _loop
	
	#============================================
	
_rectangle:
lstr a0, "Enter X coordinate: "
	li v0, 4
	syscall
	
	li v0, 5
	syscall
	sw v0, x_coord
	
lstr a0, "Enter Y coordinate: "
	li v0, 4
	syscall
	
	li v0, 5
	syscall
	sw v0, y_coord
	
lstr a0, "Enter width: "
	li v0, 4
	syscall
	
	li v0, 5
	syscall
	sw v0, width
	
lstr a0, "Enter height: "
	li v0, 4
	syscall
	
	li v0, 5
	syscall
	sw v0, height
	
	lw a0, x_coord
	lw a1, y_coord
	lw a2, color
	
	lw s0, width
	lw s1, height
	
_rectangle_outer_loop:
	beqz s1, _rectangle_done
	
	lw a0, x_coord
	
	move s3, s0
	
_rectangle_inner_loop:
	beqz s3, _rectangle_inner_done
	
	jal display_set_pixel
	
	addi a0, a0, 1
	subi s3, s3, 1
	
	j _rectangle_inner_loop
	
_rectangle_inner_done:
	addi a1, a1, 1
	subi s1, s1, 1
	
	j _rectangle_outer_loop
	
_rectangle_done:
	jal display_finish_frame
	j _loop
	
	#============================================
	
_quit:
	li v0, 10
	syscall
