extends Control
class_name text_giver

var target_text: String = "";
@onready var label: RichTextLabel = $Label;

var timeBetweenChars: float = 0.2;
var currentDelay: float = 0;

var complete: bool = true;

#func _ready() -> void:
	#complete = true;
	#new_text("wow the apoclypse is here oh no but oh yes it is the monkey hitman lets go chat he is here to unapoclypse this crazy apoclypse lets go")

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

func new_text(new_text: String) -> void:
	complete = false;
	target_text = new_text;
	label.text = "";
