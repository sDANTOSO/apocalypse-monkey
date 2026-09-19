extends Node2D

@onready var character_Test = %Character
@onready var dialog_ui = %"Dialoge UI"
var dialog_index : int = 0

const dialog_lines : Array[String] = [
	"Sato: It's been 6 months since the start",
	"Sato: My garden. It hasn't even grown",
	"Sato: There has been no fruit. No vegetables. No Income",
	"Sato: No Harvest.",
	"Sato: My tribe has started to starve",
	"Sato: I must do something!",
	"Minato: Yo"
]

# Called when the node enters the scene tree for the first time.
func _ready():
	dialog_index = 0
	process_current_line()

func _input(event):
	if event.is_action_pressed("next_line"):
		if dialog_index < len(dialog_lines) - 1:
			dialog_index += 1
			process_current_line()

func parse_line(line: String) -> Dictionary:
	var line_info = line.split(":")
	assert(len(line_info) >= 2)
	return {
		"speaker_name": line_info[0],
		"dialog_line": line_info[1]
	}

func process_current_line():
	var line_info = parse_line(dialog_lines[dialog_index])
	dialog_ui.speaker_name.text = line_info["speaker_name"]
	dialog_ui.dialog_line.text = line_info["dialog_line"]
	character_Test.change_character(line_info["speaker_name"])
