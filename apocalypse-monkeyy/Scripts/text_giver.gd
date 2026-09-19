extends Control

var target_text: String = "";
@onready var label: RichTextLabel = $Label;

var timeBetweenChars: float = 0.2;
var currentDelay: float = 0;

var complete: bool = false;

func _ready() -> void:
	_new_text("wow the apoclypse is here oh no but oh yes it is the monkey hitman lets go chat he is here to unapoclypse this crazy apoclypse lets go")
	pass # Replace with function body.


func _process(delta: float) -> void:
	if complete:
		return;

	currentDelay -= delta;
	if currentDelay<=0:
		currentDelay = timeBetweenChars;
		
		label.text += target_text[0];
		target_text = target_text.substr(1);
		if target_text.length()==0:
			complete = true;

func _new_text(new_text: String):
	complete = false;
	target_text = new_text;
	label.text = "";
