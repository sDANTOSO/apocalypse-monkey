extends Node2D

@onready var character_Test = %Character
@onready var dialog_ui = %"Dialoge UI"
var dialog_index : int = 0
var current_speaker : String = ""


var  dialog_lines : Array = []

func _ready():
	dialog_lines = load_dialog("res://Recourses/story/story.json")
	dialog_ui.finished_typing.connect(_on_finished_typing)
	dialog_index = 0
	process_current_line()

func _input(event):
	if event.is_action_pressed("next_line"):
		if dialog_index < len(dialog_lines) - 1:
			dialog_index += 1
			process_current_line()
		if dialog_index == 10:
			get_tree().change_scene_to_file("res://Scenes/forest.tscn")

func process_current_line():
	var line = dialog_lines[dialog_index]
	current_speaker = line["speaker_name"]
	dialog_ui.set_line(line["speaker_name"], line["dialog_line"])
	character_Test.change_character(current_speaker, true)

func _on_finished_typing():
	character_Test.change_character(current_speaker, false)

func load_dialog(file_path):
	# check if file exists
	if not FileAccess.file_exists(file_path):
		printerr("ERROR: File does not exist: ", file_path)
		return null

	# open the file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("ERROR: Failed to open file: ", file_path)
		return null

	# read the content of the file
	var content = file.get_as_text()

	# parse the JSON
	var json_content = JSON.parse_string(content)

	# check if parsing was successful
	if json_content == null:
		printerr("ERROR: Failed to parse JSON: ", file_path)
		return null

	# return the dialog
	return json_content
	
