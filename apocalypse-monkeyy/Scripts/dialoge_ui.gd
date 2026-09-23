extends Control

@onready var speaker_name: Label = %SpeakerName
@onready var dialog_line: RichTextLabel = %Dialog_Line
@onready var choice_list

signal finished_typing

var chars_per_second : float = 30.0
var char_timer : float = 0.0
var is_typing : bool = false

func _ready() -> void:
	dialog_line.visible_ratio = 1.0

func _process(delta: float) -> void:
	if not is_typing:
		return
	char_timer += delta
	var chars_to_show = int(char_timer * chars_per_second)
	dialog_line.visible_characters = chars_to_show
	if dialog_line.visible_characters >= dialog_line.get_total_character_count():
		is_typing = false
		finished_typing.emit()

func set_line(speaker: String, text: String) -> void:
	speaker_name.text = speaker
	dialog_line.text = text
	dialog_line.visible_characters = 0
	char_timer = 0.0
	is_typing = true
