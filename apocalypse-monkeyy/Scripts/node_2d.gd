extends Node2D

@onready var character_Test = %Character
@onready var dialog_ui = %"Dialoge UI"
var dialog_index : int = 0
var current_speaker : String = ""


var  dialog_lines : Array = []

func _ready():
	dialog_lines = load_dialog("res://Recourses/story/story.json")
	dialog_ui.finished_typing.connect(_on_finished_typing)
	dialog_ui.choice_selected.connect(_on_choice_selected)
	dialog_index = 0
	process_current_line()
	

func _input(event):
	var line = dialog_lines[dialog_index]
	var has_choices = line.has("choices")
	if event.is_action_pressed("next_line") and not has_choices:
		if dialog_index < len(dialog_lines) - 1:
			dialog_index += 1
			process_current_line()
		else:
			# reached the true end of the story
			get_tree().change_scene_to_file("res://Scenes/forest.tscn")

func process_current_line():
	var line = dialog_lines[dialog_index]
	#check if this is a goto command first
	if line.has("goto"):
		var target = get_anchor_position(line["goto"])
		if target != null:
			dialog_index = target
			process_current_line()
		return
	
	#check if this is just an anchor declaration
	if line.has("anchor"):
		dialog_index += 1
		process_current_line()
		return 
		
	if line.has("choices"):
		dialog_ui.display_choices(line["choices"])
	else: 
		#reading tha line of dialog
		current_speaker = line["speaker"]
		dialog_ui.set_line(line["speaker"], line["text"])
		character_Test.change_character(current_speaker, true)
	
	

func get_anchor_position(anchor:String):
	# find entry with matching name
	for i in range(dialog_lines.size()):
		if dialog_lines[i].has("anchor") and dialog_lines[i]["anchor"] == anchor:
			return i
			
	#if we get here the anchor wasnt found
	printerr("ERROR: I couldnt find it" + anchor + "")
	return null
	


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
	
func _on_choice_selected(anchor: String):
	var target = get_anchor_position(anchor)
	if target != null:
		dialog_index = target
		process_current_line()
