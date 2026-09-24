extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

const CHARACTER_FRAMES = {
	"Sato": preload("res://Sprite Frames/apocolypseMonkeyFrames.tres"),
	"Minato": preload("res://Sprite Frames/cowboy_moneky_frames.tres")
}

var current_character_name: String = ""

func _ready() -> void:
	pass

func change_character(character_name: String, is_talking: bool, expression: String = ""):
	if not CHARACTER_FRAMES.has(character_name):
		printerr("ERROR: No sprite frames for character: ", character_name)
		return

	var sprite_frames = CHARACTER_FRAMES[character_name]
	var stance = "talking" if is_talking else "idle"
	var animation_name = expression + "-" + stance if expression else stance

	if character_name != current_character_name:
		animated_sprite.sprite_frames = sprite_frames
		current_character_name = character_name

	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		animated_sprite.play(stance)
