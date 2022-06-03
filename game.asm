#####################################################################
#
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
#
# Bitmap display configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
# 1, 2, and 3.
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Lose Condition
# 2. Win condition
# 3. Health
# 4. Different levels
# 5. Double jump (wall jump)
# 6. Animated Sprites
#
# Link to video demonstration for final submission:

# https://youtu.be/wf6ElfqlKdU
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know?
# -
#
#####################################################################

.eqv	BASE_ADDRESS	0x10008000
.eqv	WAIT		40
.eqv	KEYSTROKE_EVENT	0xffff0000
.eqv	DARK_YELLOW	0xB59300
.eqv	YELLOW		0xDEB500
.eqv	RED		0xFF0000
.eqv	LIGHT_RED	0xFF5C5C
.eqv	WHITE		0xFFFFFF
.eqv	BLACK		0x000000
.eqv	BROWN		0x964B00
.eqv 	GREEN		0x7CFC00
.eqv	mousepx_length	20
.eqv	delmouse_len	24

.data
mouse1_pixels:	.word	0, 4, 12, 16, 256, 260, 264, 268, 272, 516, 520, 524, 768, 772, 776, 780, 784, 1032, 1284, 1292
mouse2_pixels:	.word	0, 4, 12, 16, 256, 260, 264, 268, 272, 516, 520, 524, 772, 776, 780, 1024, 1032, 1040, 1284, 1292
del_pixels:	.word	0, 4, 12, 16, 256, 260, 264, 268, 272, 516, 520, 524, 768, 772, 776, 780, 784, 1024, 1028, 1032, 1036, 1040, 1284, 1292


.text
main:
	li $s1, 3
	li $a1, 1

startlevelone:
	jal clear_board
	jal level_two
	li $t9, KEYSTROKE_EVENT # t9 stores address of keystroke event
	j loop
startleveltwo:
	li $a1, 2
	jal clear_board
	jal level_one
	li $t9, KEYSTROKE_EVENT # t9 stores address of keystroke event
	j loop
startlevelthree:
	li $a1, 3
	jal clear_board
	jal level_three
	li $t9, KEYSTROKE_EVENT # t9 stores address of keystroke event
	j loop
loop:	
	# check for if touching healthpack
	li $t0, 1
	bne $t0, $a3, nohealthpack
	addi $t0, $s0, 256
	bne $t0, $a2, nohealthpack
	li $a3, 0
	addi $s1, $s1, 1
	li $t1, BLACK
	move $t0, $a2
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, -4($t0)
	sw $t1, -8($t0)
	sw $t1, -264($t0)
	sw $t1, -260($t0)
	sw $t1, -256($t0)
	sw $t1, -252($t0)
	sw $t1, -248($t0)
	sw $t1, -508($t0)
	sw $t1, -516($t0)
	sw $t1, 256($t0)
	sw $t1, 252($t0)
	sw $t1, 260($t0)
	sw $t1, 512($t0)
	addi $sp, $sp, -4
	li $t0, GREEN
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	jal draw_mouse
	li $t1, BLACK
	sw $t1, 504($s0)
	sw $t1, 520($s0)
nohealthpack:
	bne $s0, $s7, notatcheese
	li $s3, 1
notatcheese:
	jal checktouchgroundstate
	bgez $s5, endfall # s5 > 0, cannot be -1 thus can not fall
	jal gravityfalls
	j dontjump
endfall:
	beqz $s5, dontjump # s5 = 0 thus velocity should be 0
	jal jump
dontjump:
	addi $t0, $gp, 15360
	bgt $s0, $t0, deathhandler # if character hits bottom, branch to deathhandler
		
	# Refresh syscall
	li $v0, 32
	li $a0, WAIT
	syscall
	
	# check for keypress
	lw $t8, 0($t9)
	beq $t8, 1, onclick
	
	# check for win condition: cheese is obtained and  door coord == mouse coord
	
	bne $s0, $s6, roundnotpassed
	beqz $s3, roundnotpassed
	li $t0, 1
	beq $t0, $a1, startleveltwo
	li $t0, 2
	beq $t0, $a1, startlevelthree
	b wingamehandler 
	
roundnotpassed:

	#draw the hearts that represent each life:
	jal draw_hearts
	
	beqz $s1, zeroHealthHandler
	
	j loop
	
onclick:
	lw $t2, 4($t9) # t2 stores the value that was pressed
	beq $t2, 0x74, terminate # if T is pressed, terminate program
	beq $t2, 0x64, move_right # on d click
	beq $t2, 0x61, move_left # on a click
	beq $t2, 0x70, reset
	bne $t2, 0x77, notjump
	bne $s2, 1, notjump  # no jumping if no jump reset
	li $s2, 0
	beqz $s3, jumpnocheese
	li $s5, 10
	j notjump
jumpnocheese:
	li $s5, 12 # jump height with no cheese
	
notjump:
	j loop
	


	
########################### MISC FUNCTIONS ###########################

terminate:	# terminates process
	li $v0, 10
	syscall
reset:
	
	j main
	
clear_board:
	li $t0, 0 # iterate through t0
	li $t1, BLACK
clear_pixel:
	add $t2, $t0, $gp # pixel to clear in t2
	sw $t1, 0($t2)
	addi $t0, $t0, 4
	li $t3, 16384 # t3 stores final pixel to clear
	bne $t0, $t3 clear_pixel
	
	# finished clearing board
	jr $ra

deathhandler:
	addi $s1, $s1, -1
	li $t0, 1
	beq $a1, $t0, startlevelone
	li $t0, 2
	beq $a1, $t0, startleveltwo
	b startlevelthree
	
	

########################### MOUSE DRAWING ###########################
draw_mouse:
	li $t1, 2
	beq $t1, $s4, draw_mouse2

draw_mouse1: #(colour $t1, address $t0)
	lw $t0, 0($sp)
	addi $t0, $t0, -520
	lw $t1, 4($sp)
	addi $sp, $sp, 8
	li $t2, 0
	la $t4, mouse1_pixels #load location of pixels of mouse1 into t4
	li $s4, 2
	j drawmousepixels
draw_mouse2:
	lw $t0, 0($sp)
	addi $t0, $t0, -520
	lw $t1, 4($sp)
	addi $sp, $sp, 8
	li $t2, 0
	la $t4, mouse2_pixels #load location of pixels of mouse2 into t4
	li $s4, 1
drawmousepixels:
	sll $t6, $t2, 2
	add $t5, $t6, $t4 # add offset and starting location to get current position in array in memory
	lw $t5, 0($t5) # load position in pixels
	add $t5, $t5, $t0 # add position in pixel to starting position
	sw $t1, 0($t5)
	addi $t2, $t2, 1
	bne $t2, mousepx_length, drawmousepixels # index not yet at length of array, thus must return to loop

	beqz $s3, endmousedrawing # branch to end no cheese, do not draw
	
	li $t1, YELLOW
	sw $t1, 1028($t0)
	sw $t1, 1036($t0)

endmousedrawing:
	jr $ra # exit loop and function

deletemousedrawing:
	lw $t0, 0($sp)
	addi $t0, $t0, -520 # set location of mouse to delete
	li $t1, BLACK
	addi $sp, $sp, 4
	li $t2, 0 # t2 stores the iterable
	la $t4, del_pixels #load location of pixels to delete into t4
delmousepixels:
	sll $t6, $t2, 2
	add $t5, $t6, $t4
	lw $t5, 0($t5) # load position in pixels
	add $t5, $t5, $t0 # add position in pixel to starting position
	sw $t1, 0($t5)
	addi $t2, $t2, 1
	bne $t2, 24, delmousepixels # index not yet at length of array, thus must return to loop
	
	jr $ra # mouse successfully deleted


	

################### DRAWING OTHER OBJECTS ####################

draw_door: #(Address of top left)
	lw $t0, 0($sp) #load address of top left
	addi $sp, $sp, 4
	addi $t0, $t0, -1032
	li $t1, RED
	li $t2, LIGHT_RED
	li $t3, YELLOW
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 256($t0)
	sw $t2, 260($t0)
	sw $t1, 264($t0)
	sw $t2, 268($t0)
	sw $t1, 272($t0)
	sw $t1, 512($t0)
	sw $t2, 516($t0)
	sw $t1, 520($t0)
	sw $t2, 524($t0)
	sw $t1, 528($t0)
	sw $t1, 768($t0)
	sw $t2, 772($t0)
	sw $t1, 776($t0)
	sw $t2, 780($t0)
	sw $t1, 784($t0)
	sw $t1, 1024($t0)
	sw $t1, 1028($t0)
	sw $t1, 1032($t0)
	sw $t1, 1036($t0)
	sw $t3, 1040($t0)
	sw $t1, 1280($t0)
	sw $t2, 1284($t0)
	sw $t1, 1288($t0)
	sw $t2, 1292($t0)
	sw $t1, 1296($t0)
	sw $t1, 1536($t0)
	sw $t2, 1540($t0)
	sw $t1, 1544($t0)
	sw $t2, 1548($t0)
	sw $t1, 1552($t0)
	sw $t1, 1792($t0)
	sw $t1, 1796($t0)
	sw $t1, 1800($t0)
	sw $t1, 1804($t0)
	sw $t1, 1808($t0)
	jr $ra


draw_cheese: # (address of top left)
	lw $t0, 0($sp) #load address of middle
	addi $t0, $t0, 248
	addi $sp, $sp, 4
	beqz $s3, drawyellowcheese
	li $t1, BLACK
	li $t2, BLACK
	j drawcheesepixels
drawyellowcheese:
	li $t1, YELLOW
	li $t2, DARK_YELLOW
drawcheesepixels:
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	sw $t2, 268($t0)
	sw $t1, 272($t0)
	sw $t2, 276($t0)
	sw $t2, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 524($t0)
	sw $t1, 528($t0)
	sw $t1, 532($t0)
	jr $ra

draw_heart:
	li $t1, RED
	lw $t0, 0($sp) # Store address of center
	addi $sp, $sp, 4
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, -4($t0)
	sw $t1, -8($t0)
	sw $t1, -264($t0)
	sw $t1, -260($t0)
	sw $t1, -256($t0)
	sw $t1, -252($t0)
	sw $t1, -248($t0)
	sw $t1, -508($t0)
	sw $t1, -516($t0)
	sw $t1, 256($t0)
	sw $t1, 252($t0)
	sw $t1, 260($t0)
	sw $t1, 512($t0)
	jr $ra
	
draw_hearts:
	#store $ra in sp
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $t2, $gp #store address of first heart
	addi $t2, $t2, 1040
	li $t3, 0
draw_hearts_loop:
	beq $t3, $s1, end_draw_hearts
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal draw_heart
	addi $t2, $t2, 32
	addi $t3, $t3, 1
	j draw_hearts_loop
end_draw_hearts:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

draw_health_pack:
	li $t1, LIGHT_RED
	lw $t0, 0($sp) # Store address of center
	addi $sp, $sp, 4
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, -4($t0)
	sw $t1, -8($t0)
	sw $t1, -264($t0)
	sw $t1, -260($t0)
	sw $t1, -256($t0)
	sw $t1, -252($t0)
	sw $t1, -248($t0)
	sw $t1, -508($t0)
	sw $t1, -516($t0)
	sw $t1, 256($t0)
	sw $t1, 252($t0)
	sw $t1, 260($t0)
	sw $t1, 512($t0)
	jr $ra
	
	
	
	

######################## PLATFORM GENERATION ####################################

horizontal_platform: # draw horizontal platform starting from (platform length ,address of leftmost pixel)
	lw $t0, 0($sp) # t0 contains address of leftmost pixel
	lw $t4, 4($sp) # t4 contains length of platform
	addi $sp, $sp, 8
	sll $t4, $t4, 2
	li $t1, WHITE
	li $t2, 0 # t2 contains current iteration of loop
	
hplatform_loop:
	add $t3, $t0, $t2 # t3 contains address of pixel to be drawn
	sw $t1, 0($t3)
	addi $t2, $t2, 4
	bne $t2, $t4, hplatform_loop
	jr $ra

vertical_platform: # draw vertical platform starting from (platform length, address of topmost pixel)
	lw $t0, 0($sp) # t0 caontains address of topmost pixel
	lw $t1, 4($sp) # t1 contains height of platform
	addi $sp, $sp, 8
	sll $t1, $t1, 8
	li $t2, WHITE # t2 contains color of platform
	li $t3, 0 # t3 contains interation of loop
vplatform_loop:
	add $t4, $t0, $t3 # t3 contains address of pixel to be drawn
	sw $t2, 0($t4)
	addi $t3, $t3, 256
	bne $t3, $t1, vplatform_loop
	jr $ra
	
	
####################### MAP GENERATION #########################################
level_one:
	addi $sp, $sp, -4 #store $ra into stack
	sw $ra, 0($sp)
	
	# draw door
	addi $t0, $gp, 4876 # address of door being drawn
	move $s6, $t0
	addi $sp, $sp, -4
	sw $t0, 0($sp) # store door address in stack, call function
	jal draw_door
	
	#initialize health pack
	addi $t0, $gp, 5248
	move $a2, $t0
	li $a3, 1
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_health_pack

	
	# draw floor
	addi $t0, $zero, 12
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 5888
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal horizontal_platform
	addi $t0, $zero, 12
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 6096
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal horizontal_platform
	addi $t0, $zero, 41
	sw $t0, -4($sp)
	addi $t0, $gp, 6016
	sw $t0, -8($sp)
	addi $sp, $sp, -8
	jal vertical_platform
	addi $t0, $zero, 41
	sw $t0, -4($sp)
	addi $t0, $gp, 5936
	sw $t0, -8($sp)
	addi $sp, $sp, -8
	jal vertical_platform
	addi $t0, $zero, 41
	sw $t0, -4($sp)
	addi $t0, $gp, 6096
	sw $t0, -8($sp)
	addi $sp, $sp, -8
	jal vertical_platform

	# draw mouse and initialize state structure
	
	addi $sp, $sp, -4
	li $t0, 4900
	sw $t0, 0($sp)
	jal initialize_mouse
	
		
	# draw cheese
	addi $t0, $gp, 5100
	move $s7, $t0
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_cheese
	
	
	# end of drawing level 1, pull $ra from stack and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
level_two:
	addi $sp, $sp, -4 #store $ra into stack
	sw $ra, 0($sp)
	
	# draw door
	addi $t0, $gp, 13068 # address of door being drawn
	move $s6, $t0
	addi $sp, $sp, -4
	sw $t0, 0($sp) # store door address in stack, call function
	jal draw_door

	# draw mouse and initialize state structure
	
	addi $sp, $sp, -4
	li $t0, 13092
	sw $t0, 0($sp)
	jal initialize_mouse
	# draw cheese
	addi $t0, $gp, 3052
	move $s7, $t0
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_cheese
	
	li $a3, 0
	
	# drawing platform
	
	addi $t0, $zero, 32
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 14080
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal horizontal_platform
	addi $t0, $zero, 32
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 3968
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal horizontal_platform
	addi $t0, $zero, 41
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 3968
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal vertical_platform
	
	# end of drawing level 1, pull $ra from stack and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
level_three:
	addi $sp, $sp, -4 #store $ra into stack
	sw $ra, 0($sp)
	
	# draw door
	addi $t0, $gp, 13068 # address of door being drawn
	move $s6, $t0
	addi $sp, $sp, -4
	sw $t0, 0($sp) # store door address in stack, call function
	jal draw_door
	
	li $a3, 0
	# draw mouse and initialize state structure
	
	addi $sp, $sp, -4
	li $t0, 13092
	sw $t0, 0($sp)
	jal initialize_mouse
	# draw cheese
	addi $t0, $gp, 2824
	move $s7, $t0
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_cheese
	
	
	# drawing platform
	
	addi $t0, $zero, 12
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 14080
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal horizontal_platform
	addi $t0, $zero, 12
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 14156
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal horizontal_platform
	addi $t0, $zero, 12
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 14228
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal horizontal_platform
	
	addi $t0, $zero, 14
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 4008
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal horizontal_platform
	addi $t0, $zero, 12
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 3920
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal horizontal_platform
	addi $t0, $zero, 12
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 3840
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal horizontal_platform
	
	addi $t0, $zero, 30
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 4016
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal vertical_platform
	
	addi $t0, $zero, 30
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $t0, $gp, 4092
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal vertical_platform
	
	# end of drawing level 1, pull $ra from stack and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
########################### MOUSE CONTROL ################################

initialize_mouse: # initialize mouse at (x $t0)
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	add $t0, $t0, $gp
	move $s0, $t0
	li $s2, 0
	li $s3, 0
	li $s4, 1
	li $s5, 0
	addi $sp, $sp, -4
	sw $ra, 0($sp) #store ra onto stack
	
	li $t0, BROWN
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	
	addi $sp, $sp, -4
	sw $s0, 0($sp) #store mouse coord onto stack
	jal draw_mouse
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4 #retrieve ra from stack
	
	jr $ra

move_left:
	#check if there is boundary/object in left
	
	addi $t0, $s0, -8
	li $t1, 256
	div $t0, $t1
	mfhi $t0
	beqz $t0, endmoveleft
	
	li, $t1, WHITE
	addi $t0, $s0, 756
	lw $t2, 0($t0)
	beq $t2, $t1, endmoveleft
	lw $t2, -256($t0)
	beq $t2, $t1, endmoveleft
	lw $t2, -512($t0)
	beq $t2, $t1, endmoveleft
	lw $t2, -768($t0)
	beq $t2, $t1, endmoveleft
	lw $t2, -1024($t0)
	beq $t2, $t1, endmoveleft
	lw $t2, -1280($t0)
	beq $t2, $t1, endmoveleft
	
	# erase old mouse drawing
	
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	jal deletemousedrawing
	
	# redraw cheese, hole, healthpack (if applicable)
	addi $sp, $sp, -4
	sw $s6, 0($sp)
	jal draw_door
	
	addi $sp, $sp, -4
	sw $s7 0($sp)
	jal draw_cheese
	
	beqz $a3, moveleftnohp
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	jal draw_health_pack
	
	
	# update mouse position
moveleftnohp:
	addi $s0, $s0, -4
	
	# draw new mouse
	addi $sp, $sp, -4
	li $t0, BROWN
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	
	jal draw_mouse
	
	li, $t1, WHITE
	addi $t0, $s0, 756
	lw $t2, 0($t0)
	beq $t2, $t1, resetjump
	lw $t2, -256($t0)
	beq $t2, $t1, resetjump
	lw $t2, -512($t0)
	beq $t2, $t1, resetjump
	lw $t2, -768($t0)
	beq $t2, $t1, resetjump
	lw $t2, -1024($t0)
	beq $t2, $t1, resetjump
	lw $t2, -1280($t0)
	beq $t2, $t1, resetjump
endmoveleft:	
	j loop


move_right:

	#check if there is boundary/object in left
	
	addi $t0, $s0, 12
	li $t1, 256
	div $t0, $t1
	mfhi $t0
	beqz $t0, endmoveright
	
	addi $t0, $s0, 780
	li, $t1, WHITE
	lw $t2, 0($t0)
	beq $t2, $t1, endmoveright
	lw $t2, -256($t0)
	beq $t2, $t1, endmoveright
	lw $t2, -512($t0)
	beq $t2, $t1, endmoveright
	lw $t2, -768($t0)
	beq $t2, $t1, endmoveright
	lw $t2, -1024($t0)
	beq $t2, $t1, endmoveright
	lw $t2, -1280($t0)
	beq $t2, $t1, endmoveright
	
	# erase old mouse drawing
	
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	jal deletemousedrawing
	
	# redraw cheese, hole
	addi $sp, $sp, -4
	sw $s6, 0($sp)
	jal draw_door
	
	addi $sp, $sp, -4
	sw $s7 0($sp)
	jal draw_cheese
	
	beqz $a3, moverightnohp
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	jal draw_health_pack
	# update mouse position
moverightnohp:	
	addi $s0, $s0, 4
	
	# draw new mouse
	addi $sp, $sp, -4
	li $t0, BROWN
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	
	jal draw_mouse
	
	addi $t0, $s0, 780
	li, $t1, WHITE
	lw $t2, 0($t0)
	beq $t2, $t1, resetjump
	lw $t2, -256($t0)
	beq $t2, $t1, resetjump
	lw $t2, -512($t0)
	beq $t2, $t1, resetjump
	lw $t2, -768($t0)
	beq $t2, $t1, resetjump
	lw $t2, -1024($t0)
	beq $t2, $t1, resetjump
	lw $t2, -1280($t0)
	beq $t2, $t1, resetjump
endmoveright:
	j loop
resetjump:
	li $s2, 1
	j loop

checktouchgroundstate:
	# check for touching ground state
	addi $t0, $s0, 1024
	lw $t1, -4($t0)
	li $t2, WHITE
	beq $t1, $t2, groundstatetrue
	lw $t1, 0($t0)
	beq $t1, $t2, groundstatetrue
	lw $t1, 4($t0)
	beq $t1, $t2, groundstatetrue
	lw $t1, -8($t0)
	beq $t1, $t2, groundstatetrue
	lw $t1, 8($t0)
	beq $t1, $t2, groundstatetrue
	
	bgtz $s5, endgroundstateif
	# not grounded not jumping
	li $s5, -1
	
	# not grounded jumping
	j endgroundstateif
groundstatetrue:
	bgtz $s5, endgroundstateif
	li $s5, 0 # grounded and falling, set to 0
	li $s2, 1
endgroundstateif:
	jr $ra


gravityfalls:
	# push $ra into stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# erase old mouse drawing
	
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	jal deletemousedrawing
	# redraw cheese, hole
	addi $sp, $sp, -4
	sw $s6, 0($sp)
	jal draw_door
	
	addi $sp, $sp, -4
	sw $s7 0($sp)
	jal draw_cheese
	beqz $a3, movedownnohp
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	jal draw_health_pack
	# update mouse position
movedownnohp:
	addi $s0, $s0, 256
	
	# draw new mouse
	addi $sp, $sp, -4
	li $t0, BROWN
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	
	jal draw_mouse
	
	# retrieve ra of caller and return to program counter
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
jump:
	#check if there is platform on top of mouse
	
	addi $t0, $s0, -768
	li, $t1, WHITE
	lw $t2, 0($t0)
	beq $t2, $t1, objectoverhead
	lw $t2, -4($t0)
	beq $t2, $t1, objectoverhead
	lw $t2, -8($t0)
	beq $t2, $t1, objectoverhead
	lw $t2, 4($t0)
	beq $t2, $t1, objectoverhead
	lw $t2, 8($t0)
	beq $t2, $t1, objectoverhead
	bgt $t2, $gp, objectoverhead
	
	addi $s5, $s5, -1
	# push $ra into stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# erase old mouse drawing
	
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	jal deletemousedrawing
	# redraw cheese, hole
	addi $sp, $sp, -4
	sw $s6, 0($sp)
	jal draw_door
	
	addi $sp, $sp, -4
	sw $s7 0($sp)
	jal draw_cheese
	beqz $a3, moveupnohp
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	jal draw_health_pack
	
	# update mouse position
moveupnohp:	
	addi $s0, $s0, -256
	
	# draw new mouse
	addi $sp, $sp, -4
	li $t0, BROWN
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	
	jal draw_mouse
	
	# retrieve ra of caller and return to program counter
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
objectoverhead:
	li $s5, 0
	jr $ra
	
zeroHealthHandler:
	jal clear_board
	addi $t0, $gp, 1040 # load start of YOU LOSE message
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_y
	addi $t0, $gp, 1060
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_o
	addi $t0, $gp, 1080
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_u
	addi $t0, $gp, 3088
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_l
	addi $t0, $gp, 3108
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_o
	addi $t0, $gp, 3128
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_s
	addi $t0, $gp, 3148
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_e
	j endgameloop
wingamehandler:
	jal clear_board
	addi $t0, $gp, 1040 # load start of YOU LOSE message
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_y
	addi $t0, $gp, 1060
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_o
	addi $t0, $gp, 1080
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_u
	addi $t0, $gp, 3088
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_w
	addi $t0, $gp, 3112
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_i
	addi $t0, $gp, 3120
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_n
	
endgameloop:
	li $t9, KEYSTROKE_EVENT # t9 stores address of keystroke event
	lw $t8, 0($t9)
	beq $t8, 1, endgameonclick
	# Refresh syscall
	li $v0, 32
	li $a0, WAIT
	syscall
	j endgameloop
endgameonclick:
	lw $t2, 4($t9) # t2 stores the value that was pressed
	beq $t2, 0x70, reset
	j endgameloop



################### DRAW LETTERS ###################

draw_y:
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	li $t1, WHITE # load colour white for message
	sw $t1, 0($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 768($t0)
	sw $t1, 772($t0)
	sw $t1, 776($t0)
	sw $t1, 12($t0)
	sw $t1, 268($t0)
	sw $t1, 524($t0)
	sw $t1, 780($t0)
	sw $t1, 1036($t0)
	sw $t1, 1292($t0)
	sw $t1, 1548($t0)
	sw $t1, 1544($t0)
	sw $t1, 1540($t0)
	sw $t1, 1536($t0)
	jr $ra
draw_o:
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	li $t1, WHITE # load colour white for message
	sw $t1, 0($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 768($t0)
	sw $t1, 1024($t0)
	sw $t1, 1280($t0)
	sw $t1, 1536($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 268($t0)
	sw $t1, 524($t0)
	sw $t1, 780($t0)
	sw $t1, 1036($t0)
	sw $t1, 1292($t0)
	sw $t1, 1548($t0)
	sw $t1, 1544($t0)
	sw $t1, 1540($t0)
	jr $ra
	
draw_u:
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	li $t1, WHITE # load colour white for message
	sw $t1, 0($t0)
	sw $t1, 12($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 768($t0)
	sw $t1, 1024($t0)
	sw $t1, 1280($t0)
	sw $t1, 1536($t0)
	sw $t1, 268($t0)
	sw $t1, 524($t0)
	sw $t1, 780($t0)
	sw $t1, 1036($t0)
	sw $t1, 1292($t0)
	sw $t1, 1548($t0)
	sw $t1, 1544($t0)
	sw $t1, 1540($t0)
	jr $ra

draw_l:
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	li $t1, WHITE # load colour white for message
	sw $t1, 0($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 768($t0)
	sw $t1, 1024($t0)
	sw $t1, 1280($t0)
	sw $t1, 1536($t0)
	sw $t1, 1548($t0)
	sw $t1, 1544($t0)
	sw $t1, 1540($t0)
	jr $ra

draw_s:
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	li $t1, WHITE # load colour white for message
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 768($t0)
	sw $t1, 772($t0)
	sw $t1, 776($t0)
	sw $t1, 780($t0)
	sw $t1, 1036($t0)
	sw $t1, 1292($t0)
	sw $t1, 1548($t0)
	sw $t1, 1536($t0)
	sw $t1, 1548($t0)
	sw $t1, 1544($t0)
	sw $t1, 1540($t0)
	jr $ra

draw_e:
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	li $t1, WHITE # load colour white for message
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 768($t0)
	sw $t1, 1024($t0)
	sw $t1, 1280($t0)
	sw $t1, 1536($t0)
	sw $t1, 1548($t0)
	sw $t1, 1544($t0)
	sw $t1, 1540($t0)
	sw $t1, 772($t0)
	sw $t1, 776($t0)
	jr $ra

draw_w:
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	li $t1, WHITE # load colour white for message
	sw $t1, 0($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 768($t0)
	sw $t1, 1024($t0)
	sw $t1, 1280($t0)
	sw $t1, 1540($t0)
	sw $t1, 1548($t0)
	sw $t1, 1288($t0)
	sw $t1, 1032($t0)
	sw $t1, 776($t0)
	sw $t1, 16($t0)
	sw $t1, 272($t0)
	sw $t1, 528($t0)
	sw $t1, 784($t0)
	sw $t1, 1040($t0)
	sw $t1, 1296($t0)
	jr $ra

draw_i:
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	li $t1, WHITE # load colour white for message
	sw $t1, 0($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 768($t0)
	sw $t1, 1024($t0)
	sw $t1, 1280($t0)
	sw $t1, 1536($t0)
	jr $ra

draw_n:
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	li $t1, WHITE # load colour white for message
	sw $t1, 0($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 768($t0)
	sw $t1, 1024($t0)
	sw $t1, 1280($t0)
	sw $t1, 1536($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 268($t0)
	sw $t1, 524($t0)
	sw $t1, 780($t0)
	sw $t1, 1036($t0)
	sw $t1, 1292($t0)
	sw $t1, 1548($t0)
	jr $ra
