extends Node2D

@onready var Character_Test = %Character_Test
@onready var Dialouge_UI = %Dialouge_UI

const dialog_lines : Array[String] = [
	"Assassin Monkey: I am an assasin, not a entertainer",
	"Cowboy Monkey: That's not what I asked"
]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
