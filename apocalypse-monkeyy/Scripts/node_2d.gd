extends Node2D

@onready var character_Test = %Character
@onready var dialog_ui = %"Dialoge UI"
var dialog_index : int = 0
var current_speaker : String = ""

const dialog_lines : Array[String] = [
	"Sato: It's been 6 months since the start",
	"Sato: My garden. It hasn't even grown",
	"Sato: There has been no fruit. No vegetables. No Income",
	"Sato: No Harvest.",
	"Sato: My family has started to starve",
	"Sato: I must do something!",
	"Sato: But what.",
	"Sato: I know there is something not natural about this.",
	"Sato: Ever since the ice age started, all the cities got empty",
	"Sato: Everyone evacuated.",
	"Sato: Or died.",
	"Sato: In Japan the only people who roam the streets are criminals",
	"Sato: Japan has become a wasteland",
	"Sato: Its time for me to go.",
	"Sato: I must find other people who want change.",
	"Sato: Who want to stop the apocolypse.",
	"Sato: And take down whatever, and whoever is cauing it."

]

func _ready():
	dialog_ui.finished_typing.connect(_on_finished_typing)
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
	current_speaker = line_info["speaker_name"]
	dialog_ui.set_line(line_info["speaker_name"], line_info["dialog_line"])
	character_Test.change_character(current_speaker, true)

func _on_finished_typing():
	character_Test.change_character(current_speaker, false)
