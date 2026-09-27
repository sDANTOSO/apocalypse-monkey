@tool
extends EditorInspectorPlugin

const VoxImportInfoPanel = preload("./vox_import_info_panel.gd")

var _editor_interface: EditorInterface

func _init(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface

func _can_handle(object: Object) -> bool:
	if object == null or object.get_class() != "ImportDockParameters":
		return false
	var selected_paths = _editor_interface.get_selected_paths()
	if selected_paths.size() != 1:
		return false
	return String(selected_paths[0]).get_extension().to_lower() == "vox"

func _parse_end(object: Object) -> void:
	var selected_paths = _editor_interface.get_selected_paths()
	if selected_paths.size() != 1:
		return
	var source_path = String(selected_paths[0])
	if source_path.get_extension().to_lower() != "vox":
		return

	var info_panel = VoxImportInfoPanel.new()
	info_panel.initialize(source_path, object)
	add_custom_control(info_panel)
