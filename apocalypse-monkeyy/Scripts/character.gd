extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

const CHARACTER_FRAMES = {
	"Sato": preload("res://Sprite Frames/apocolypseMonkeyFrames.tres"),
	"Minato": preload("res://Sprite Frames/cowboy_moneky_frames.tres")
}

var current_character_name: String = ""

func _ready() -> void:
	pass

func change_character(character_name: String, is_talking: bool = true):
	if character_name != current_character_name:
		if not CHARACTER_FRAMES.has(character_name):
			printerr("ERROR: No sprite frames for character: ", character_name)
			return
		animated_sprite.sprite_frames = CHARACTER_FRAMES[character_name]
		current_character_name = character_name

	if is_talking:
		animated_sprite.play("talking")
	else:
		animated_sprite.play("idle")

 
