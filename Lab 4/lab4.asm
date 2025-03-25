	.include "display_2254_0205.asm"
	.include "lab4_graphics.asm"
	
	# maximum number of particles that can be around at one time
	.eqv MAX_PARTICLES 100
	
	# limits on particle positions
	.eqv PARTICLE_X_MIN -700 # "-7.00"
	.eqv PARTICLE_X_MAX 12799 # "127.99"
	.eqv PARTICLE_Y_MIN -700 # " -7.00"
	.eqv PARTICLE_Y_MAX 12799 # "127.99"
	
	# gravitational constant
	.eqv GRAVITY 7 # "0.07"
	
	# velocity randomization constants
	.eqv VEL_RANDOM_MAX 200 # "2.00"
	.eqv VEL_RANDOM_MAX_OVER_2 100 # "1.00"
	# some assemblers let you do calculations on constants, but not the one in MARS! : / 
	# hence the awkward OVER_2 constant here
	
	.data
	# position of the emitter (which the user has control over)
emitter_x: .word 64
emitter_y: .word 10
	
	# parallel arrays of particle properties
particle_active: .byte 0:MAX_PARTICLES # "boolean" (0 or 1)
particle_x: .half 0:MAX_PARTICLES # signed
particle_y: .half 0:MAX_PARTICLES # signed
particle_vx: .half 0:MAX_PARTICLES # signed
particle_vy: .half 0:MAX_PARTICLES # signed

	.text
	.globl main
main:
	# initialize display
	li a0, 15 # ms / frame
	li a1, 1 # enable framebuffer (not using it for this lab tho)
	li a2, 0 # disable tilemap
	jal display_init
	
	jal load_graphics
	
_loop:
	jal display_clear_auto_sprites
	
	jal check_input
	jal update_particles
	jal draw_particles
	jal draw_emitter
	
	jal display_finish_frame

	j _loop
	
	# exit (should never get here, but I'm superstitious okay)
	li v0, 10
	syscall
	
	#============================================ 
	
update_particles:
	push ra
	push s0
	
	li s0, 0
	
_update_particles_loop:
	bge s0, MAX_PARTICLES, _update_particles_end
	
	la t0, particle_active
	add t0, t0, s0
	lb t1, 0(t0)
	beq t1, zero, _update_particles_next 
	
	la t2, particle_vy
	mul t3, s0, 2 
	add t2, t2, t3
	lh t4, 0(t2) 
	add t4, t4, GRAVITY
	sh t4, 0(t2) 
	
	la t2, particle_x
	mul t3, s0, 2
	add t2, t2, t3
	lh t4, 0(t2) 
	la t5, particle_vx
	add t5, t5, t3
	lh t6, 0(t5) 
	add t4, t4, t6 
	sh t4, 0(t2) 
	
	la t2, particle_y
	mul t3, s0, 2
	add t2, t2, t3
	lh t4, 0(t2)
	la t5, particle_vy
	add t5, t5, t3
	lh t6, 0(t5) 
	add t4, t4, t6 
	sh t4, 0(t2) 
	
	la t2, particle_x
	mul t3, s0, 2
	add t2, t2, t3
	lh t4, 0(t2) 
	blt t4, PARTICLE_X_MIN, _update_particles_despawn
	bgt t4, PARTICLE_X_MAX, _update_particles_despawn
	
	la t2, particle_y
	mul t3, s0, 2
	add t2, t2, t3
	lh t4, 0(t2)
	blt t4, PARTICLE_Y_MIN, _update_particles_despawn
	bgt t4, PARTICLE_Y_MAX, _update_particles_despawn
	
_update_particles_next:
	addi s0, s0, 1
	j _update_particles_loop
	
_update_particles_despawn:
	la t0, particle_active 
	add t0, t0, s0
	sb zero, 0(t0)
	j _update_particles_next
	
_update_particles_end:
	pop s0
	pop ra
	jr ra
	
	#============================================ 
	
draw_particles:
	push ra
	push s0
	
	li s0, 0
	
_draw_particles_loop:
	bge s0, MAX_PARTICLES, _draw_particles_end
	
	la t0, particle_active
	add t0, t0, s0 
	lb t1, 0(t0)  
	beq t1, zero, _draw_particles_next 
	
	la t2, particle_x
	mul t3, s0, 2 
	add t2, t2, t3 
	lh t4, 0(t2) 
	
	la t5, particle_y
	mul t3, s0, 2
	add t5, t5, t3
	lh t6, 0(t5)
	
	div t4, t4, 100
	div t6, t6, 100
	
	subi a0, t4, 7 
	subi a1, t6, 7 
	
	li a2, 161
	li a3, 0x88
	
	jal display_draw_sprite
	
_draw_particles_next:
	addi s0, s0, 1
	j _draw_particles_loop
	
_draw_particles_end:
	pop s0
	pop ra
	jr ra
	
	#============================================ 
	
draw_emitter:
	push ra
	
	la t0, emitter_x
	lw t0, 0(t0)
	la t1, emitter_y
	lw t1, 0(t1)
	
	subi a0, t0, 3
	subi a1, t1, 3
	
	li a2, EMITTER_TILE
	li a3, 0x40
	
	jal display_draw_sprite
	
	pop ra
	jr ra
	
	#============================================ 
	
check_input:
	push ra
	push s0
	
	la t0, display_mouse_x
	lw t0, 0(t0)
	la t1, display_mouse_y
	lw t1, 0(t1)
	
	li t2, -1
	beq t0, t2, _return
	
	la t3, emitter_x
	sw t0, 0(t3) 
	la t4, emitter_y
	sw t1, 0(t4) 
	
	la t5, display_mouse_held
	lw t5, 0(t5)
	and t5, t5, MOUSE_LBUTTON 
	beq t5, 0, _return 
	
	jal spawn_particle
	
_return:
	pop s0
	pop ra
	jr ra
	
	#============================================ 
	
spawn_particle:
	push ra
	push s0
	
	jal find_free_particle
	move s0, v0

	li t0, -1
	beq s0, t0, _return
	
	la t1, particle_active
	add t1, t1, s0
	li t2, 1
	sb t2, 0(t1) 
	
	la t3, emitter_x
	lw t3, 0(t3) 
	mul t3, t3, 100 
	la t4, particle_x
	mul t5, s0, 2 
	add t4, t4, t5 

	sh t3, 0(t4) 
	
	la t3, emitter_y
	lw t3, 0(t3)
	mul t3, t3, 100
	la t4, particle_y
	mul t5, s0, 2
	add t4, t4, t5
	sh t3, 0(t4)
	
	la t4, particle_vx
	mul t5, s0, 2
	add t4, t4, t5 
	
	li a0, 0 
	li a1, VEL_RANDOM_MAX 
	li v0, 42
	syscall

	sub v0, v0, VEL_RANDOM_MAX_OVER_2 
	sh v0, 0(t4)
	
	la t4, particle_vy
	mul t5, s0, 2
	add t4, t4, t5
	li a0, 0
	li a1, VEL_RANDOM_MAX
	li v0, 42
	syscall
	sub v0, v0, VEL_RANDOM_MAX_OVER_2
	sub v0, v0, GRAVITY 
	sh v0, 0(t4)
	
_return:
	pop s0
	pop ra
	jr ra
	
	#============================================ 
	
load_graphics:
	push ra
	la a0, emitter_gfx
	li a1, EMITTER_TILE
	li a2, N_EMITTER_TILES
	jal display_load_sprite_gfx
	
	la a0, particle_gfx
	li a1, PARTICLE_TILE
	li a2, N_PARTICLE_TILES
	jal display_load_sprite_gfx
	
	la a0, particle_palette
	li a1, PARTICLE_PALETTE_OFFSET
	li a2, PARTICLE_PALETTE_SIZE
	jal display_load_palette
	pop ra
	jr ra
	
	#============================================ 
	
	# returns the array index of the first free particle slot, 
	# or -1 if there are no free slots.
find_free_particle:
	push ra
	# use v0 as the loop index; loop until the particle at that index is not active
	li v0, 0

_loop:
	lb t0, particle_active(v0)
	beq t0, 0, _return
	add v0, v0, 1
	blt v0, MAX_PARTICLES, _loop
	
	# no free particles found!
	li v0, -1

_return:
	pop ra
	jr ra
	
	#============================================ 
