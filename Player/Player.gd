extends CharacterBody2D

const RUNSPEED = 650.0
const WALLPUSH = 550.0
const AIRFRICTION = 0.9
const DASHSPEED = 2000.0
const ACCELERATION = 50.0
const FRICTION = 70.0


@export var jump_height : float = 150
@export var jump_time_to_peak : float = 0.5
@export var jump_time_to_descent : float = 0.3


@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0
@onready var wall_slide_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent * 50)) * -1.0
# @onready var max_speed : float = 550.0
@onready var can_double_jump : bool = false
@onready var can_dash : bool = true
@onready var coyote_timer : float = 0.0
@onready var wall_coyote_timer = 0.0
@onready var jump_buffer_timer = 0.0
@onready var can_wall_jump : bool = false


func _physics_process(delta):

	if is_on_floor():
		can_double_jump = false
		can_wall_jump = false

		coyote_timer = 0.1
	else:
		can_wall_jump = false

		velocity.y += get_gravity() * delta # Adding gravity 

		jump_buffer_timer -= delta
		coyote_timer -= delta
		wall_coyote_timer -= delta

	if is_on_wall() and (Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right")):
		wall_coyote_timer = 0.2
		if velocity.y > 0:
			can_wall_jump = true

			velocity.y = wall_slide_gravity
	

	player_movement()

	jump()
	wall_jump()

	move_and_slide()

func get_gravity():
	return jump_gravity if velocity.y < 0.0 else fall_gravity


func player_movement():
	var direction = Input.get_axis("move_left", "move_right")
	
	if Input.is_action_just_pressed("dash_forward") and can_dash:
		can_dash = false
		velocity.x = direction * DASHSPEED
		$DashDelay.start()
	else:	
		if direction != 0:
			# Accelerate Player
			if is_on_floor():
				velocity.x = move_toward(velocity.x, direction * RUNSPEED, ACCELERATION)
			elif not is_on_floor():
				velocity.x = move_toward(velocity.x, direction * RUNSPEED * AIRFRICTION, ACCELERATION)
		else:
			# Adding Frection
			velocity.x = move_toward(velocity.x, 0, FRICTION)

func jump():
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.1
	
	if jump_buffer_timer > 0:
		if is_on_floor() or coyote_timer > 0: # Jump
			velocity.y = jump_velocity

			can_double_jump = true

			jump_buffer_timer = 0
			coyote_timer = 0

		elif can_double_jump and coyote_timer < 0: # Double Jump
			velocity.y = jump_velocity

			can_double_jump = false

			jump_buffer_timer = 0
			coyote_timer = 0

func wall_jump():
	if Input.is_action_just_pressed("jump"):
		if can_wall_jump or wall_coyote_timer > 0:
			velocity.y = jump_velocity

			if Input.is_action_pressed("move_left") and is_on_wall():
				velocity.x = WALLPUSH	
			elif Input.is_action_pressed("move_right") and is_on_wall():
				velocity.x = -WALLPUSH

			wall_coyote_timer = 0

func _on_dash_delay_timeout():
	can_dash = true
