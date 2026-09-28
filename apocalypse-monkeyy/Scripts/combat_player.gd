extends CharacterBody2D

@export var speed: float = 100;
@export var smoothing: float = 8;

@export var max_health = 3;
var health = 3;

func _ready() -> void:
	health = max_health;

func _process(delta: float) -> void:
	# get input for x and y, move in that direction smoothly
	var inputX = Input.get_axis("left", "right");
	var inputY = Input.get_axis("up", "down");
	var newVel = Vector2(inputX, inputY).normalized() * speed;
	velocity = lerp(velocity, newVel, smoothing * delta);
	move_and_slide()
	
func _damage():
	health-=1;
	if health <= 0:
		print("dead");
		queue_free();
