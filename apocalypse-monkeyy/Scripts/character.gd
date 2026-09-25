extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

const CHARACTER_FRAMES = {
	"Sato": preload("res://Sprite Frames/apocolypseMonkeyFrames.tres"),
	"Minato": preload("res://Sprite Frames/cowboy_moneky_frames.tres"),
	"Narrarator": preload("res://Sprite Frames/narrarator.tres")
}

var current_character_name: String = ""

func _ready() -> void:
	pass

func change_character(character_name: String, is_talking: bool, expression: String = ""):
	var sprite_frames = CHARACTER_FRAMES[character_name]
	var stance = "talking" if is_talking else "idle"
	var animation_name = expression + "-" + stance if expression else stance

	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)
		else:
			animated_sprite.play(stance)
	else:
		play_idle_animation()

func play_idle_animation():
	var last_animation = animated_sprite.animation
	if last_animation and not last_animation.ends_with("-idle"):
		var idle_expression = last_animation.replace("talking", "idle")
		if animated_sprite.sprite_frames.has_animation(idle_expression):
			animated_sprite.play(idle_expression)
		else:
			animated_sprite.play("idle")
	else:
		animated_sprite.play("idle")
