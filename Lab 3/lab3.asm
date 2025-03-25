	.include "lab3_include.asm"
	
	.data
running: .word 1
	
cursor_x: .word 0
cursor_y: .word 0
	
	.eqv KEYS_LEN 4
keys_to_check: .word KEY_Z KEY_X KEY_C KEY_V
keys_to_tiles: .word TILE_GRASS TILE_SAND TILE_BRICK TILE_WATER
	
map_data: .ascii
	"######          "
	"#    #          "
	"#..........     "
	"#..........     "
	"#    #   ..     "
	"######   ..     "
	"         ..     "
	"         ..     "
	"         ..     "
	"         ..   .."
	"         ..  .~~"
	"         ....~~~"
	"        .~~~~~~~"
	"       .~~~~~~~~"
	"       .~~~~~~~~"
	"       .~~~~~~~~"	
	
	.text
	.globl main
main:
	jal display_init
	jal load_graphics
	jal load_map
	
main_loop:
	jal check_input
	jal draw_cursor
	jal display_finish_frame
	
	lw t0, running
	bne t0, zero, main_loop
	
exit:
	li v0, 10
	syscall
	
	#============================================
	
load_graphics:
	push ra
	
	la a0, tilemap_gfx
	li a1, 0
	li a2, 4
	jal display_load_tm_gfx
	
	la a0, sprite_gfx
	li a1, 0
	li a2, 1
	jal display_load_sprite_gfx
	
	pop ra
	jr ra
	
	#============================================
	
draw_cursor:
	push ra
	
	la t2, display_spr_table
	
	lw t0, cursor_x
	mul t0, t0, 8
	sb t0, 0(t2)
	
	lw t0, cursor_y
	mul t0, t0, 8
	sb t0, 1(t2)
	
	sb zero, 2(t2)
	
	li t0, 0x41
	sb t0, 3(t2)
	
	pop ra
	jr ra
	
	#============================================
	
check_input:
	push ra
	push s0
	
	li t0, KEY_ESCAPE
	sw t0, display_key_pressed
	lw t0, display_key_pressed
	
	beq t0, zero, _endif_Escape
	
	sw zero, running
	
_endif_Escape:
	li t0, KEY_LEFT
	sw t0, display_key_pressed
	lw t0, display_key_pressed
	
	beq t0, zero, _endif_L
	
	lw t0, cursor_x
	subi t0, t0, 1
	remu t0, t0, 16
	sw t0, cursor_x
	
_endif_L:
	li t0, KEY_RIGHT
	sw t0, display_key_pressed
	lw t0, display_key_pressed
	
	beq t0, zero, _endif_R
	
	lw t0, cursor_x
	addi t0, t0, 1
	remu t0, t0, 16
	sw t0, cursor_x
	
_endif_R:
	li t0, KEY_UP
	sw t0, display_key_pressed
	lw t0, display_key_pressed
	
	beq t0, zero, _endif_U
	
	lw t0, cursor_y
	subi t0, t0, 1
	remu t0, t0, 16
	sw t0, cursor_y
	
_endif_U:
	li t0, KEY_DOWN
	sw t0, display_key_pressed
	lw t0, display_key_pressed
	
	beq t0, zero, _endif_D
	
	lw t0, cursor_y
	addi t0, t0, 1
	remu t0, t0, 16
	sw t0, cursor_y
	
_endif_D:
	li s0, 0
	
_loop_tile_check:
	bge s0, KEYS_LEN, _end_tile_check
	
	la t1, keys_to_check
	mul t2, s0, 4
	add t1, t1, t2
	lw t0, 0(t1)
	
	sw t0, display_key_held
	lw t0, display_key_held
	
	beq t0, zero, _next_tile
	
	la t1, keys_to_tiles
	mul t2, s0, 4
	add t1, t1, t2
	lw a2, 0(t1)
	
	lw a0, cursor_x
	lw a1, cursor_y
	
	jal place_tile
	
_next_tile:
	addi s0, s0, 1
	j _loop_tile_check
	
_end_tile_check:
	pop s0
	pop ra
	jr ra
	
	#============================================
	
place_tile:
	push ra
	
	mul t0, a1, 64
	mul t1, a0, 2
	add t0, t0, t1
	
	la t2, display_tm_table
	add t2, t2, t0
	sb a2, 0(t2)
	
	pop ra
	jr ra
	
	#============================================
	
load_map:
	push ra
	push s0
	push s1
	
	li s0, 0
	
_row_loop:
	li s1, 0
	
_col_loop:
	mul t0, s0, 16
	add t0, t0, s1
	
	la t1, map_data
	add t1, t1, t0
	lb a0, 0(t1)
	
	jal char_to_tile_type
	
	move a0, s1
	move a1, s0
	
	jal place_tile
	
	addi s1, s1, 1
	bne s1, 16, _col_loop
	
	addi s0, s0, 1
	bne s0, 16, _row_loop
	
	pop s1
	pop s0
	pop ra
	jr ra
	
	#============================================
	
char_to_tile_type:
	push ra
	
	li t0, ' '
	beq a0, t0, _TILE_GRASS
	
	li t0, '.'
	beq a0, t0, _TILE_SAND
	
	li t0, '#'
	beq a0, t0, _TILE_BRICK
	
	li t0, '~'
	beq a0, t0, _TILE_WATER
	
	print_str "invalid character!\n"
	
	li v0, 10
	syscall
	
_TILE_GRASS:
	li a2, TILE_GRASS
	pop ra
	jr ra
	
_TILE_SAND:
	li a2, TILE_SAND
	pop ra
	jr ra
	
_TILE_BRICK:
	li a2, TILE_BRICK
	pop ra
	jr ra
	
_TILE_WATER:
	li a2, TILE_WATER
	pop ra
	jr ra
