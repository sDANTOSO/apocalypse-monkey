extends Area2D

@export var speed: float = 50;

func _ready() -> void:
	body_entered.connect(collision);

func _process(delta: float) -> void:
	position += transform.x*speed*delta;

func collision(body: Node2D):
	if "_damage" in body:
		print("hit");
		body._damage();
