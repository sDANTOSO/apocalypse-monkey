extends Control

const ChoiceButtonScene = preload("res://Scenes/player_choice.tscn")
signal choice_selected(anchor: String)

@onready var speaker_name: Label = %SpeakerName
@onready var dialog_line: RichTextLabel = %Dialog_Line
@onready var choice_list = %ChoiceList

signal finished_typing

var chars_per_second : float = 30.0
var char_timer : float = 0.0
var is_typing : bool = false

func _ready() -> void:
	choice_list.hide()
	dialog_line.visible_characters = 0

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

func display_choices(choices: Array):
	choice_list.show()
	for child in choice_list.get_children():
		child.queue_free()
	for choice in choices:
		var choice_button = ChoiceButtonScene.instantiate()
		choice_button.text = choice["text"]
		choice_button.pressed.connect(_on_choice_button_pressed.bind(choice["goto"]))
		choice_list.add_child(choice_button)

func _on_choice_button_pressed(anchor: String):
	choice_list.hide()
	choice_selected.emit(anchor)
