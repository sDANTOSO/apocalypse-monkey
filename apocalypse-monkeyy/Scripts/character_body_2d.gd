extends CharacterBody2D

@onready var main_character: CharacterBody2D = $"."

const SPEED = 300.0
const JUMP_VELOCITY = -600.0
const jump_powe = JUMP_VELOCITY
const acc = 50
const friction = 70
const wall_slide_gravity = 120
const wall_jump_pushback = 800
var wall_sliding = false


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	
		

	# Handle jump.
	if Input.is_action_just_pressed("jump"): 
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			
		if is_on_wall and Input.is_action_pressed("right"):
			velocity.y = JUMP_VELOCITY
			velocity.x = -wall_jump_pushback
			print("wall")
		if is_on_wall and Input.is_action_pressed("left"):
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_jump_pushback
			print("walls")
	
	wall_slide(delta)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	stealthcheck()
	move_and_slide()
	
	
func wall_slide(delta):
	if is_on_wall() and !is_on_floor():
		if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
			wall_sliding = true
			## create dropping tree animation
			## or maybe just monke sliding down tree animation
	else:
		wall_sliding = false
		## create monke jump maybe
		## monke idle
	if wall_sliding:
		velocity.y += (wall_slide_gravity * delta)
		velocity.y = min(velocity.y, wall_slide_gravity)
	
func stealthcheck():
	if (main_character.position.y >=-35):
		await get_tree().create_timer(0.2).timeout
		if (main_character.position.y >=-35):
			main_character.position.x = -363
			main_character.position.y = -41
		pass
	## add wall climbing animation and wall jumping animation and flip h
	
