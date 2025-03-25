	.include "display_2254_0205.asm"
	.include "proj1_constants.asm"
	.include "proj1_graphics.asm"
	.include "proj1_levels.asm"
	.include "proj1_nesfont.asm"
	.include "proj1_sincos.asm"
	
	.data
debug_framemode: .word 0
game_over: .word 0
	
paddle_x: .word 0
	.eqv PADDLE_Y 10000
	
ball_y: .word 0
ball_x: .word 0
ball_old_y: .word 0
ball_old_x: .word 0
ball_vx: .word 0
ball_vy: .word 0
	
ball_state: .word STATE_ON_PADDLE
	
blocks: .byte
	# feel free to change these for testing.
	0 0 0 0 0 0 0 1
	0 0 0 0 0 0 0 1
	0 0 0 0 0 0 0 1
	1 1 1 1 1 1 1 1
	1 0 0 0 0 0 0 1
	1 0 0 0 0 0 0 1
	1 0 0 0 0 0 0 1
	1 1 1 1 1 1 1 1
	1 0 0 0 0 0 0 1
	1 0 0 0 0 0 0 1

	.text
	.globl main
main:
	# initialize display
	li a0, 15 # ms / frame
	li a1, 1 # enable framebuffer
	li a2, 1 # enable tilemap
	jal display_init
	
	jal load_graphics
	
	# change this to whatever color you want for the background.
	# alternatively, draw something on the framebuffer if you want
	# something more interesting than a plain color background!
	li t0, 0x335577
	sw t0, display_palette_ram
	
	# uncomment these lines to load another level.
	# change the la line to one of the levels from proj1_levels.asm.
	#la a0, test_level
	#jal load_blocks
	
	jal draw_blocks
	
_loop:
	jal update_paddle
	jal update_ball
	
	jal draw_paddle
	jal draw_ball
	jal draw_hud
	
	jal display_finish_frame
	
	# comment this out to disable the single - frame stepping mode.
	jal debug_do_framemode
	
	jal display_clear_auto_sprites
	jal display_clear_text_sprites

	lw t0, game_over
	beq t0, 0, _loop
	
	jal show_game_over_message
	# exit
	li v0, 10
	syscall
	
	#============================================
	
load_graphics:
	push ra

	jal load_game_graphics
	jal load_nes_font_sprite
	
	# text sprites will be 0 - 63 (so they're on top)
	li a0, 0
	li a1, 64
	jal display_set_text_sprites
	
	# normal sprites will be 64 - 255
	li a0, 64
	li a1, 255
	jal display_set_auto_sprites

	pop ra
	jr ra
	
	#============================================
	
	# you can absolutely change this function to show whatever you want.
show_game_over_message:
	push ra

	li a0, 2
	li a1, 60
	lstr a2, "congratulations!"
	jal display_draw_text_sprites
	
	jal display_finish_frame

	pop ra
	jr ra
	
	#============================================

debug_do_framemode:
	push ra

	lw t0, debug_framemode
	beq t0, 0, _normal

_wait:
	jal display_finish_frame
	display_is_key_pressed t0, KEY_R
	beq t0, 0, _endif_r

	sw zero, debug_framemode
	j _endif

_endif_r:
	display_is_key_pressed t0, KEY_F
	beq t0, 0, _wait

	j _endif

_normal:
	display_is_key_pressed t0, KEY_R
	beq t0, 0, _endif

	li t0, 1
	sw t0, debug_framemode
	j _wait

_endif:
	pop ra
	jr ra
	
	#============================================
	# Blocks
	#============================================
	
	# a0 = address of level data
load_blocks:
	push ra

	# dead simple, just loop for N_BLOCKS bytes and copy over
	li t0, 0

_loop:
	lb t1, (a0)
	sb t1, blocks(t0)
	add a0, a0, 1

	add t0, t0, 1
	blt t0, N_BLOCKS, _loop
	
	# then draw em
	jal draw_blocks

	pop ra
	jr ra
	
	#============================================
	# Paddle
	#============================================
	
update_paddle:
	push ra
	
	lw t0, display_mouse_x 

	bltz t0, _end_paddle_update
	
	mul t0, t0, SCALE 
	
	blt t0, PADDLE_MIN_X, _case_min
	bgt t0, PADDLE_MAX_X, _case_max
	
	j _set_paddle
	
_case_min:
	li t0, PADDLE_MIN_X
	j _set_paddle
	
_case_max:
	li t0, PADDLE_MAX_X 
	j _set_paddle
	
_set_paddle:
	sw t0, paddle_x
	
_end_paddle_update:
	pop ra
	jr ra
	
	#============================================
	# Ball
	#============================================
	
update_ball:
	push ra
	
	lw t0, ball_state 
	beq t0, STATE_ON_PADDLE, _ball_on_paddle
	
	lw t0, ball_x 
	sw t0, ball_old_x
	lw t1, ball_vx 
	add t0, t0, t1 
	sw t0, ball_x 
	
	jal check_horizontal_collisions
	
	lw t0, ball_y
	sw t0, ball_old_y
	lw t1, ball_vy
	add t0, t0, t1
	sw t0, ball_y
	
	jal check_vertical_collisions
	
	j _end_update_ball
	
_ball_on_paddle:
	lw t0, paddle_x
	sw t0, ball_x 
	
	li t0, PADDLE_Y
	sub t0, t0, BALL_HALFHEIGHT
	sw t0, ball_y 
	
	sw zero, ball_vx 
	sw zero, ball_vy 
	
	lw t0, display_mouse_pressed
	li t1, MOUSE_LBUTTON
	and t0, t0, t1
	bnez t0, _start_ball_move 
	
	j _end_update_ball
	
_start_ball_move:
	li t0, STATE_MOVING
	sw t0, ball_state
	
	li t0, BALL_INITIAL_VX
	sw t0, ball_vx
	
	li t0, BALL_INITIAL_VY
	sw t0, ball_vy 
	
_end_update_ball:
	pop ra
	jr ra
	
	#============================================

ball_bounce_x:
	push ra
	
	sw a0, ball_x
	
	neg a1, a1
	sw a1, ball_vx
	
	pop ra
	jr ra
	
	#============================================

ball_get_block_horizontal:
    push ra

    lw t0, ball_vx 
    blt t0, zero, _moving_left 

    lw a0, ball_x   
    add a0, a0, BALL_HALFWIDTH  
    subi a0, a0, 100    

    j _call_get_block

_moving_left:
    lw t1, ball_x   
    sub a0, t1, BALL_HALFWIDTH    

    j _call_get_block

_call_get_block:
    lw t2, ball_y 

    div a0, a0, SCALE
    div a1, t2, SCALE

    jal get_block

    pop ra
    jr ra 

	#============================================

check_horizontal_collisions:
	push ra
	
	lw t0, ball_x
	blt t0, BALL_MIN_X, _bounce_h 
	
	bgt t0, BALL_MAX_X, _bounce_h

	jal ball_get_block_horizontal  

    bne v0, BLOCK_EMPTY, _block_collision_detected_h 

	j _end_check_horizontal

_block_collision_detected_h:
    move a0, v1  
    jal destroy_block

	j _bounce_h
	
_bounce_h:
	lw a0, ball_old_x 
	lw a1, ball_vx
	
	jal ball_bounce_x 
	
	j _end_check_horizontal
	
_end_check_horizontal:
	pop ra
	jr ra
	
	#============================================

ball_bounce_y:
	push ra
	
	sw a0, ball_y
	
	neg a1, a1
	sw a1, ball_vy
	
	pop ra
	jr ra
	
	#============================================

ball_check_paddle:
	push ra
	
	lw t0, ball_vy 
	lw t1, ball_y 
	lw t2, ball_x 
	lw t3, paddle_x
	
	li t7, PADDLE_Y 
	
	bltz t0, _return_zero 

	bgt t1, PADDLE_Y, _return_zero

	sub t4, t7, BALL_HALFHEIGHT 
	ble t1, t4, _return_zero
	
	sub t5, t3, PADDLE_HALFWIDTH 
	blt t2, t5, _return_zero 
	
	add t6, t3, PADDLE_HALFWIDTH 
	bgt t2, t6, _return_zero 
	
	li v0, 1
	j _end_ball_check_paddle
	
_return_zero:
	li v0, 0
	
_end_ball_check_paddle:
	pop ra
	jr ra

	#============================================

ball_get_block_vertical:
    push ra

    lw t0, ball_vy
    blt t0, zero, _moving_up 

    lw a1, ball_y    
    add a1, a1, BALL_HALFWIDTH 
    subi a1, a1, 100     

    j _call_get_block_v

_moving_up:
    lw t1, ball_y
    sub a1, t1, BALL_HALFWIDTH   

    j _call_get_block_v

_call_get_block_v:
    lw t2, ball_x 

    div a0, t2, SCALE
    div a1, a1, SCALE

    jal get_block

    pop ra
    jr ra 
	
	#============================================

ball_bounce_paddle:
    push ra

	lw t0, ball_old_y
	sw t0, ball_y

	lw t0, ball_x
	lw t1, paddle_x
	sub t2, t0, t1
	abs t2, t2

	mul t2, t2, 75
	div a0, t2, PADDLE_HALFWIDTH 
	
	jal sin_cos

	mul v0, v0, 14142
	mul v1, v1, -14142

	div v0, v0, 1000000
	div v1, v1, 1000000

	lw t0, ball_x
	lw t1, paddle_x
	blt t0, t1, _negate_x

	j _end_of_computation

_negate_x:	
	neg v0, v0
	j _end_of_computation

_end_of_computation:
	sw v0, ball_vx
	sw v1, ball_vy

	pop ra
	jr ra

	#============================================

check_vertical_collisions:
	push ra
	
	lw t0, ball_y
	blt t0, BALL_MIN_Y, _bounce_v 

	li t1, BALL_HALFWIDTH
	mul t1, t1, 2
	
	li t2, BALL_MAX_Y
	sub t2, t2, t1
	
	bgt t0, t2, _kill_ball 
	
	jal ball_check_paddle 
	bne v0, zero, _freaky_bounce 
		
	jal ball_get_block_vertical 

    bne v0, BLOCK_EMPTY, _block_collision_detected_v 

	j _end_check_vertical

_block_collision_detected_v:
    move a0, v1 
    jal destroy_block

	j _bounce_v
	
_bounce_v:
	lw a0, ball_old_y 
	lw a1, ball_vy 
	
	jal ball_bounce_y
	
	j _end_check_vertical
	
_kill_ball:
	li t0, STATE_ON_PADDLE
	sw t0, ball_state 
	j _end_check_vertical

_freaky_bounce:
	jal ball_bounce_paddle
	j _end_check_vertical
	
_end_check_vertical:
	pop ra
	jr ra

	#============================================
	# Blocks and Blockbreaking
	#============================================

get_block:
	push ra
	
	beq a0, -1, _out_of_bounds
	beq a1, -1, _out_of_bounds
	
	div a0, a0, BLOCK_W 
	div a1, a1, BLOCK_H 
	
	mul t0, a1, BLOCK_COLS 
	add t0, t0, a0 
	
	bge t0, N_BLOCKS, _out_of_bounds
	
	move v1, t0 
	
	lb v0, blocks(t0) 
	j _end_get_block
	
_out_of_bounds:
	li v0, BLOCK_EMPTY
	li v1, -1
	
_end_get_block:
	pop ra
	jr ra
	
	#============================================

destroy_block:
    push ra  

    beq a0, -1, _end_destroy_block 

    li t1, BLOCK_EMPTY
    sb t1, blocks(a0)

    jal draw_blocks

    jal check_all_blocks_destroyed

_end_destroy_block:
    pop ra
    jr ra 

	#============================================

check_all_blocks_destroyed:
    push ra

    li t0, 0  

_loop_check_blocks:
    bge t0, N_BLOCKS, _all_blocks_destroyed 

    lb t1, blocks(t0)
    bne t1, BLOCK_EMPTY, _end_check_blocks 

    addi t0, t0, 1
    j _loop_check_blocks

_all_blocks_destroyed:
    li t2, 1
    sw t2, game_over

_end_check_blocks:
    pop ra
    jr ra 
	
	#============================================
	# Drawing
	#============================================
	
draw_blocks:
	push ra
	push s0
	push s1
	
	li s0, 0 
	
_row_loop:
	li t1, BLOCK_ROWS
	bge s0, t1, _end_row_loop 
	
	li s1, 0 
	
_col_loop:
	li t3, BLOCK_COLS
	bge s1, t3, _end_col_loop 
	
	mul t4, s0, t3
	add t4, t4, s1 
	lb t5, blocks(t4)
	
	li t6, BLOCK_EMPTY
	beq t5, t6, _empty_block 
	
	sub t7, t5, 1
	lb t7, block_palette_starts(t7)
	
	mul t0, s1, 2 
	move a0, t0 
	move a1, s0 
	li a2, BLOCK_TILE
	move a3, t7 
	jal display_set_tile
	
	add t0, t0, 1 
	move a0, t0 
	move a1, s0 
	li a2, BLOCK_TILE 
	add a2, a2, 1 
	move a3, t7
	jal display_set_tile
	
	j _next_col
	
_empty_block:
	mul t0, s1, 2 
	move a0, t0
	move a1, s0
	li a2, EMPTY_TILE 
	li a3, 0 
	jal display_set_tile
	
	add t0, t0, 1 
	move a0, t0 
	move a1, s0 
	li a2, EMPTY_TILE 
	li a3, 0 
	jal display_set_tile
	
_next_col:
	add s1, s1, 1
	j _col_loop
	
_end_col_loop:
	add s0, s0, 1
	j _row_loop
	
_end_row_loop:
	pop s1
	pop s0
	pop ra
	jr ra
	
	#============================================
	
draw_paddle:
	push ra
	
	# The provided instructions for positioning the paddle sprites was incorrect. 
	# Specifically, setting the middle of the paddle to the leftmost edge due to a half-width value of 1200 resulted in an inaccurate placement. 
	# I have adjusted the calculation from 1200 to 600, and vice versa, accordingly to ensure the paddle is positioned correctly.
	
	lw t0, paddle_x 
	li t1, PADDLE_HALFWIDTH
	sub t1, t0, t1 
	div a0, t1, SCALE
	
	li a1, PADDLE_Y
	div a1, a1, SCALE
	
	li a2, PADDLE_TILE_LEFT
	li a3, PADDLE_FLAGS
	jal display_draw_sprite
	
	lw t0, paddle_x
	sub t1, t0, 400 
	div a0, t1, SCALE 
	
	li a2, PADDLE_TILE_MID
	jal display_draw_sprite
	
	lw t0, paddle_x
	addi t1, t0, 400 
	div a0, t1, SCALE 
	
	li a2, PADDLE_TILE_RIGHT
	jal display_draw_sprite
	
	pop ra
	jr ra
	
	#============================================
	
draw_ball:
	push ra
	
	lw t0, ball_x
	sub t0, t0, BALL_HALFWIDTH 
	div a0, t0, SCALE
	
	lw t0, ball_y
	sub t0, t0, BALL_HALFHEIGHT 
	div a1, t0, SCALE 
	
	li a2, BALL_TILE 
	li a3, BALL_FLAGS
	jal display_draw_sprite 
	
	pop ra
	jr ra
	
	#============================================

draw_hud:
	push ra

	pop ra
	jr ra

	# -- Test code for the "destroy_block" function --
	#
	# draw_hud:
	#     push ra
	# 	  push s1
	# 
	#     lw a0, display_mouse_x  
	#     lw a1, display_mouse_y  
	#     jal get_block 
	# 
	#     move s1, v1 
	# 
	#     blt s1, zero, _end_draw_hud 
	# 
	#     display_is_key_pressed t0, KEY_D  
	#     beq t0, zero, _end_draw_hud  
	# 
	#     move a0, s1  
	#     jal destroy_block  
	# 
	# _end_draw_hud:
	#     pop s1
	#     pop ra
	#     jr ra 


	# -- Test code for the "get_block" function --
	#
	# draw_hud:
	# 	push ra
	# 	push s0
	# 	push s1
	# 	
	# 	lw a0, display_mouse_x 
	# 	lw a1, display_mouse_y 
	# 	
	# 	jal get_block 
	# 	
	# 	move s0, v0 
	# 	move s1, v1 
	# 	
	# 	li a0, 1 
	# 	li a1, 1 
	# 	move a2, s0 
	# 	jal display_draw_int_sprites 
	# 	
	# 	li a0, 1 
	# 	li a1, 10
	# 	move a2, s1 
	# 	jal display_draw_int_sprites
	# 
	# 	pop s1
	# 	pop s0
	# 	pop ra
	# 	jr ra
