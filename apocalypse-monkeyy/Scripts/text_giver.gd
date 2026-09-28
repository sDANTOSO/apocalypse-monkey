extends Control
class_name text_giver

var target_text: String = "";
@onready var label: RichTextLabel = $Label;

var timeBetweenChars: float = 0.02;
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
		add_char();
		
		if target_text.length()==0:
			complete = true;

func add_char():
	# requires function do handle wether it encounters a '[' character for a text effect
	var new_char: String = target_text[0];
	var is_an_effect: bool = false;
	
	if new_char == "[":
		var text_copy: String = target_text;
		var full_effect: String = new_char;
		while !full_effect.ends_with("]") && text_copy.length()>0:
			full_effect += text_copy[0];
			text_copy = text_copy.substr(1);
		
		if text_copy.length()>0:
			is_an_effect = true;
			new_char = full_effect;
			print(new_char);
	
	label.text+=new_char;
	target_text = target_text.substr(new_char.length());

func new_text(new_text: String) -> void:
	complete = false;
	target_text = new_text;
	label.text = "";
