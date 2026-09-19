extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

const CHARACTER_FRAMES = {
	"Sato": preload("res://Sprite Frames/apocolypseMonkeyFrames.tres"),
	"Minato": preload("res://Sprite Frames/cowboy_moneky_frames.tres")
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func change_character(character_name: String, is_talking: bool = true):
	animated_sprite.sprite_frames = CHARACTER_FRAMES[character_name]
	if is_talking:
		# change to talking when we get animated sprites (:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("idle")

 
