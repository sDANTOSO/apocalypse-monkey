extends PanelContainer
class_name dialog_choice

signal selected(index);

@onready var choice_list: VBoxContainer = $margins/choices_container;
@onready var choice_prefab: Button = $margins/choices_container/choice_button;

var choices:Array[String]:
	set(value):
		choices = value;
		init_buttons();

func _ready() -> void:
	choice_list.get_child(0).pressed.connect(on_choice.bind(0));

func init_buttons():
	var button;
	
	# remove all but one button
	while choice_list.get_child_count()>1:
		button = choice_list.get_child(choice_list.get_child_count() - 1);
		choice_list.remove_child(button);
		button.queue_free();
	
	# create new buttons for each choice
	for choice_index in range(choices.size()):
		if choice_index == 0:
			choice_list.get_child(0).text = choices[choice_index];
		else:
			choice_list.add_child(choice_prefab.duplicate());
			choice_list.get_child(choice_index).text = choices[choice_index];
			choice_list.get_child(choice_index).pressed.connect(on_choice.bind(choice_index));

func on_choice(choice_index):
	visible = false;
	selected.emit(choice_index);
