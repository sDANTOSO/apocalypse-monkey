extends Control

@export var story_flow: PackedScene;

@onready var text: text_giver = $TextGiver;
@onready var choices_dialog: dialog_choice = $dialog_choice;
@export var bg: AnimatedSprite2D;

var start_beat: story_node;
var current_beat: story_node;

func _ready() -> void:
	start_story();
	choices_dialog.selected.connect(next_node);

func start_story():
	start_beat = story_flow.instantiate();
	current_beat = start_beat;
	narrate(current_beat);

func narrate(beat: story_node):
	choices_dialog.choices = current_beat.choices;
	text.new_text(beat.text);
	
	bg.sprite_frames = beat.animation;
	bg.play("default");

func next_node(index: int):
	var next: story_node = current_beat.get_child(index);
	narrate(next)
	current_beat = next;
