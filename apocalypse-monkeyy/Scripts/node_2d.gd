extends Node2D


@onready var background = %Background
@onready var character_Test = %Character
@onready var dialog_ui = %"Dialoge UI"
var dialog_index : int = 0
var current_speaker : String = ""

var dialog_lines : Array = []

func _ready():
	dialog_lines = load_dialog("res://Recourses/story/first_scene.json")
	if dialog_lines.is_empty():
		printerr("ERROR: dialog_lines is empty, aborting _ready()")
		return
	dialog_ui.finished_typing.connect(_on_finished_typing)
	dialog_ui.choice_selected.connect(_on_choice_selected)
	dialog_index = 0
	process_current_line()


func _input(event):
	if dialog_lines.is_empty():
		return
	var line = dialog_lines[dialog_index]
	var has_choices = line.has("choices")
	if event.is_action_pressed("next_line") and not has_choices:
		if dialog_index < len(dialog_lines) - 1:
			dialog_index += 1
			process_current_line()
		else:
			get_tree().change_scene_to_file("res://Scenes/forest.tscn")


func process_current_line():
	var line = dialog_lines[dialog_index]

	if line.has("location"):
		var background_file = "res://Assets-misc/" + line["location"] + ".png"
		background.texture = load(background_file)
		dialog_index += 1
		process_current_line()
		return

	if line.has("goto"):
		var target = get_anchor_position(line["goto"])
		if target != null:
			dialog_index = target
			process_current_line()
		return

	if line.has("anchor"):
		dialog_index += 1
		process_current_line()
		return

	if line.has("next_scene"):
		var next_scene_path = "res://Recourses/story/" + line["next_scene"] + ".json"
		dialog_lines = load_dialog(next_scene_path)
		if dialog_lines.is_empty():
			printerr("ERROR: failed to load next scene: ", next_scene_path)
			return
		dialog_index = 0
		process_current_line()
		return

	if line.has("show_character"):
		character_Test.change_character(line["show_character"], false, line.get("expression", ""))
	elif line.has("speaker"):
		character_Test.change_character(line["speaker"], true, line.get("expression", ""))

	if line.has("choices"):
		dialog_ui.display_choices(line["choices"])
	elif line.has("speaker"):
		current_speaker = line["speaker"]
		dialog_ui.set_line(line["speaker"], line["text"])
	else:
		dialog_index += 1
		process_current_line()
		return


func get_anchor_position(anchor:String):
	for i in range(dialog_lines.size()):
		if dialog_lines[i].has("anchor") and dialog_lines[i]["anchor"] == anchor:
			return i
	printerr("ERROR: I couldnt find it" + anchor + "")
	return null


func _on_finished_typing():
	character_Test.change_character(current_speaker, false)


func load_dialog(file_path) -> Array:
	if not FileAccess.file_exists(file_path):
		printerr("ERROR: File does not exist: ", file_path)
		return []

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("ERROR: Failed to open file: ", file_path)
		return []

	var content = file.get_as_text()
	var json_content = JSON.parse_string(content)

	if json_content == null:
		printerr("ERROR: Failed to parse JSON: ", file_path)
		return []

	return json_content


func _on_choice_selected(anchor: String):
	var target = get_anchor_position(anchor)
	if target != null:
		dialog_index = target
		process_current_line()
