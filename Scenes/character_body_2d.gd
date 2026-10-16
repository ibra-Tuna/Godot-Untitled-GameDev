extends CharacterBody2D

# --- Tweakable Movement Variables ---
@export_group("Movement Speeds")
@export var walk_speed: float = 150.0
@export var run_speed: float = 250.0
@export var sneak_speed: float = 75.0

@export_group("Acceleration & Friction (The 'Leg Push' Feel)")
@export var ground_acceleration: float = 1200.0  
@export var ground_friction: float = 1400.0      
@export var air_acceleration: float = 700.0      
@export var air_friction: float = 300.0          # MIDDLE GROUND: Balanced momentum
@export var turn_multiplier: float = 2.5         

@export_group("Jump & Gravity Settings")
@export var jump_velocity: float = -550.0        
@export var gravity: float = 1400.0              
@export var max_fall_speed: float = 900.0        
@export var run_jump_boost: float = 100.0                 # MIDDLE GROUND: Nice burst, not a cannon
@export var run_jump_air_control_multiplier: float = 2.0  # MIDDLE GROUND: Good steering
@export var run_jump_gravity_multiplier: float = 0.90     # MIDDLE GROUND: Slight hang, but grounded

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- State Machine ---
enum State { NORMAL, RUN_TURN, SNEAK_START, SNEAK_ACTIVE, SNEAK_TURN, SNEAK_STOP }
var current_state: State = State.NORMAL

# Tracks which way the character is currently facing (1 = Right, -1 = Left)
var facing_direction: int = 1 
var jumped_from_run: bool = false

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity (with run-jump modifier)
	if not is_on_floor():
		var current_gravity: float = gravity
		if jumped_from_run:
			current_gravity *= run_jump_gravity_multiplier
		
		velocity.y = min(velocity.y + current_gravity * delta, max_fall_speed)
	else:
		if velocity.y >= 0:
			jumped_from_run = false

	# 2. Handle Inputs
	var direction: float = Input.get_axis("Left", "Right")
	var is_running: bool = Input.is_action_pressed("Run") and is_on_floor() and current_state == State.NORMAL
	var is_sneaking: bool = current_state in [State.SNEAK_START, State.SNEAK_ACTIVE, State.SNEAK_TURN, State.SNEAK_STOP]

	# Jump Input
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not is_sneaking:
		velocity.y = jump_velocity
		
		if is_running and direction != 0:
			velocity.x += direction * run_jump_boost 
			jumped_from_run = true
		else:
			jumped_from_run = false

	# Sneak Inputs
	if Input.is_action_just_pressed("Sneak") and is_on_floor() and current_state == State.NORMAL:
		current_state = State.SNEAK_START
		animated_sprite.play("Start_Sneaking")
	
	elif Input.is_action_just_released("Sneak") and current_state in [State.SNEAK_ACTIVE, State.SNEAK_START, State.SNEAK_TURN]:
		current_state = State.SNEAK_STOP
		animated_sprite.play("Stop_Sneaking")

	# 3. Manage State Transitions
	if not animated_sprite.is_playing():
		match current_state:
			State.SNEAK_START, State.SNEAK_TURN:
				current_state = State.SNEAK_ACTIVE
				if direction != 0:
					facing_direction = sign(direction)
				animated_sprite.flip_h = facing_direction < 0
			State.SNEAK_STOP:
				current_state = State.NORMAL
			State.RUN_TURN:
				current_state = State.NORMAL
				if direction != 0:
					facing_direction = sign(direction)
				animated_sprite.flip_h = facing_direction < 0

	# 4. Detect Direction Change
	if direction != 0 and sign(direction) != facing_direction:
		if current_state == State.SNEAK_ACTIVE:
			current_state = State.SNEAK_TURN
			animated_sprite.play("Sneak_Turn")
		elif current_state == State.NORMAL and is_running:
			current_state = State.RUN_TURN
			animated_sprite.play("Run_Turn")

	# 5. Apply Horizontal Movement
	var current_max_speed: float = 0.0
	if current_state == State.SNEAK_ACTIVE:
		current_max_speed = sneak_speed
	elif current_state == State.NORMAL:
		if is_on_floor():
			current_max_speed = run_speed if is_running else walk_speed
		else:
			if jumped_from_run:
				# MIDDLE GROUND CAP: Allows the initial burst, but naturally decays to a comfortable 300
				current_max_speed = run_speed + (run_jump_boost * 0.5)
			else:
				current_max_speed = walk_speed

	# Calculate Air Control
	var actual_air_accel: float = air_acceleration
	if jumped_from_run:
		actual_air_accel *= run_jump_air_control_multiplier

	var accel_rate: float = ground_acceleration if is_on_floor() else actual_air_accel
	var fric_rate: float = ground_friction if is_on_floor() else air_friction
	
	# Turning friction on ground
	if is_on_floor() and direction != 0 and sign(direction) != sign(velocity.x) and velocity.x != 0:
		accel_rate *= turn_multiplier

	# Lock horizontal movement during transitions and turning
	if current_state in [State.SNEAK_START, State.SNEAK_STOP, State.SNEAK_TURN, State.RUN_TURN]:
		velocity.x = move_toward(velocity.x, 0, ground_friction * 2.0 * delta)
	else:
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * current_max_speed, accel_rate * delta)
			if current_state == State.NORMAL or current_state == State.SNEAK_ACTIVE:
				if not (current_state == State.NORMAL and is_running and sign(direction) != facing_direction):
					facing_direction = sign(direction)
					animated_sprite.flip_h = facing_direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, fric_rate * delta)

	# 6. Move the Character
	move_and_slide()

	# 7. Update Animations
	update_animations(direction, is_running)


func update_animations(direction: float, is_running: bool) -> void:
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("Jumping")
		else:
			animated_sprite.play("Falling")
		return

	match current_state:
		State.SNEAK_START, State.SNEAK_TURN, State.SNEAK_STOP, State.RUN_TURN:
			pass
		State.SNEAK_ACTIVE:
			if direction != 0:
				animated_sprite.play("Sneak_Walking")
			else:
				animated_sprite.play("Idle_Sneak")
		State.NORMAL:
			if direction != 0:
				if is_running:
					animated_sprite.play("Running")
				else:
					animated_sprite.play("Walking")
			else:
				animated_sprite.play("Idle")
