extends Control

const ChoiceButtonScene = preload("res://Scenes/player_choice.tscn")
signal choice_selected(anchor: String)

@onready var speaker_name: Label = %SpeakerName
@onready var dialog_line: RichTextLabel = %Dialog_Line
@onready var choice_list = %ChoiceList
@onready var blip_player: AudioStreamPlayer = %TextBlipSound

signal finished_typing

var chars_per_second : float = 40.0  
var char_timer : float = 0.0
var is_typing : bool = false
var last_char_shown : int = 0

var skip_blip_chars := [" ", ".", ",", "!", "?", "\n"]

func _ready() -> void:
	choice_list.hide()
	dialog_line.visible_characters = 0

func _process(delta: float) -> void:
	if not is_typing:
		return
	char_timer += delta
	var chars_to_show = int(char_timer * chars_per_second)
	dialog_line.visible_characters = chars_to_show

	while last_char_shown < chars_to_show:
		last_char_shown += 1
		play_blip(last_char_shown)

	if dialog_line.visible_characters >= dialog_line.get_total_character_count():
		is_typing = false
		finished_typing.emit()

func play_blip(char_index: int) -> void:
	var text = dialog_line.get_parsed_text()
	if char_index - 1 >= text.length():
		return
	var current_char = text[char_index - 1]
	if current_char in skip_blip_chars:
		return
	blip_player.pitch_scale = randf_range(1.1, 1.3) 
	blip_player.play()

func set_line(speaker: String, text: String) -> void:
	speaker_name.text = speaker
	dialog_line.text = text
	dialog_line.visible_characters = 0
	char_timer = 0.0
	last_char_shown = 0
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
