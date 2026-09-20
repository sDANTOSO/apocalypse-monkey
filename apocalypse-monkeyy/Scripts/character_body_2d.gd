extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const jump_powe = JUMP_VELOCITY
const acc = 50
const friction = 70
const gravity = 120
const wall_jump_pushback = 100



func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		if is_on_wall_only and Input.is_action_just_pressed("right"):
			velocity.y = JUMP_VELOCITY
			velocity.x = -wall_jump_pushback
		if is_on_wall_only and Input.is_action_just_pressed("left"):
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_jump_pushback
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
