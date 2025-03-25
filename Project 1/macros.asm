
# puts a string literal into the .data segment and loads its address
# into a register. use like:
#   lstr a0, "hello, world"
.macro lstr %rd, %str
	.data
	lstr_message: .asciiz %str
	.text
	la %rd, lstr_message
.end_macro

# print a string to the console. PRESERVES A0 AND V0.
.macro print_str %str
	push a0
	push v0
	lstr a0, %str
	li v0, 4
	syscall
	pop v0
	pop a0
.end_macro

# print a newline to the console. PRESERVES A0 AND V0.
.macro newline
	push a0
	push v0
	li a0, '\n'
	li v0, 11
	syscall
	pop v0
	pop a0
.end_macro

# print a string to the console, followed by a newline. PRESERVES A0 AND V0.
.macro println_str %str
	print_str %str
	newline
.end_macro

# increment the value in a register by 1.
.macro inc %reg
	addi %reg, %reg, 1
.end_macro

# decrement the value in a register by 1.
.macro dec %reg
	addi %reg, %reg, -1
.end_macro

# set rd to the minimum of register rs and register rt.
.macro min %rd, %rs, %rt
	move %rd, %rs
	blt  %rs, %rt, _end
	move %rd, %rt
_end:
.end_macro

# set rd to the minimum of register rs and immediate imm.
.macro mini %rd, %rs, %imm
	move %rd, %rs
	blt  %rs, %imm, _end
	li   %rd, %imm
_end:
.end_macro

# set rd to the maximum of register rs and register rt.
.macro max %rd, %rs, %rt
	move %rd, %rs
	bgt  %rs, %rt, _end
	move %rd, %rt
_end:
.end_macro

# set rd to the maximum of register rs and immediate imm.
.macro maxi %rd, %rs, %imm
	move %rd, %rs
	bgt  %rs, %imm, _end
	li   %rd, %imm
_end:
.end_macro