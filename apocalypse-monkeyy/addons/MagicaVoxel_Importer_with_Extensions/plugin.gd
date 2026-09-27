@tool
extends EditorPlugin

var pluginToMesh
var pluginToMeshLibrary
var pluginToScene
var voxImportInfoInspectorPlugin
var editorFileSystem: EditorFileSystem
var pendingVoxImportDockRefreshPath := ""

func _enter_tree():
	pluginToMesh = preload('VoxImporter/vox-importer-mesh.gd').new()
	pluginToMeshLibrary = preload('VoxImporter/vox-importer-meshLibrary.gd').new()
	pluginToScene = preload('VoxImporter/vox-importer-scene.gd').new()
	add_import_plugin(pluginToScene, true)
	add_import_plugin(pluginToMesh)
	add_import_plugin(pluginToMeshLibrary)
	voxImportInfoInspectorPlugin = preload('Editor/vox_import_info_inspector_plugin.gd').new(
		get_editor_interface()
	)
	add_inspector_plugin(voxImportInfoInspectorPlugin)
	editorFileSystem = get_editor_interface().get_resource_filesystem()
	var reimport_callback = Callable(self, "_close_open_vox_scene_tabs_before_reimport")
	if not editorFileSystem.resources_reimporting.is_connected(reimport_callback):
		editorFileSystem.resources_reimporting.connect(reimport_callback)
	var reimported_callback = Callable(self, "_refresh_selected_vox_import_options_after_reimport")
	if not editorFileSystem.resources_reimported.is_connected(reimported_callback):
		editorFileSystem.resources_reimported.connect(reimported_callback)
	add_custom_type("FramedMeshInstance", "MeshInstance3D",
			preload("Runtime/framed_mesh_instance.gd"), preload("framed_mesh_instance.png"))

func _exit_tree():
	var reimport_callback = Callable(self, "_close_open_vox_scene_tabs_before_reimport")
	var reimported_callback = Callable(self, "_refresh_selected_vox_import_options_after_reimport")
	if (
		is_instance_valid(editorFileSystem)
		and editorFileSystem.resources_reimporting.is_connected(reimport_callback)
	):
		editorFileSystem.resources_reimporting.disconnect(reimport_callback)
	if (
		is_instance_valid(editorFileSystem)
		and editorFileSystem.resources_reimported.is_connected(reimported_callback)
	):
		editorFileSystem.resources_reimported.disconnect(reimported_callback)
	pendingVoxImportDockRefreshPath = ""
	editorFileSystem = null
	remove_inspector_plugin(voxImportInfoInspectorPlugin)
	voxImportInfoInspectorPlugin = null
	remove_import_plugin(pluginToMesh)
	remove_import_plugin(pluginToMeshLibrary)
	remove_import_plugin(pluginToScene)
	pluginToMesh = null
	pluginToMeshLibrary = null
	pluginToScene = null
	remove_custom_type("FramedMeshInstance")

func _get_priority() -> float:
	return 1.0

func _close_open_vox_scene_tabs_before_reimport(resource_paths: PackedStringArray) -> void:
	# Godot 4.7은 열린 임포트 씬을 재임포트할 때 씬 탭 인덱스가 무효화되어 종료될 수 있습니다.
	var editor_interface = get_editor_interface()
	var open_scene_paths = editor_interface.get_open_scenes()
	var vox_scene_paths_to_close: Array[String] = []
	for resource_path_value in resource_paths:
		var resource_path = String(resource_path_value)
		if resource_path.get_extension().to_lower() != "vox":
			continue
		if open_scene_paths.has(resource_path):
			vox_scene_paths_to_close.append(resource_path)

	for vox_scene_path in vox_scene_paths_to_close:
		editor_interface.open_scene_from_path(vox_scene_path)
		var close_error = editor_interface.close_scene()
		if close_error == OK:
			print("VOX reimport safeguard: closed the open source scene tab: ", vox_scene_path)
		else:
			push_error(
				"Could not close the open source scene tab before VOX reimport: %s (error: %d)"
				% [vox_scene_path, close_error]
			)

func _refresh_selected_vox_import_options_after_reimport(
	resource_paths: PackedStringArray
) -> void:
	var editor_interface = get_editor_interface()
	var selected_paths = editor_interface.get_selected_paths()
	if selected_paths.size() != 1:
		return

	var selected_path = String(selected_paths[0])
	if selected_path.get_extension().to_lower() != "vox":
		return
	if not resource_paths.has(selected_path):
		return

	pendingVoxImportDockRefreshPath = selected_path
	call_deferred("_clear_vox_selection_before_import_options_refresh", selected_path)

func _clear_vox_selection_before_import_options_refresh(resource_path: String) -> void:
	if pendingVoxImportDockRefreshPath != resource_path:
		return

	var editor_interface = get_editor_interface()
	var file_system_dock = editor_interface.get_file_system_dock()
	# 폴더를 먼저 표시하면 Import Dock이 현재 파일의 캐시된 옵션을 비웁니다.
	file_system_dock.navigate_to_path(resource_path.get_base_dir())
	_clear_file_system_dock_selection(file_system_dock)
	file_system_dock.emit_signal("selection_changed")

	if pendingVoxImportDockRefreshPath != resource_path:
		return
	if not FileAccess.file_exists(resource_path):
		pendingVoxImportDockRefreshPath = ""
		return

	pendingVoxImportDockRefreshPath = ""
	editor_interface.select_file(resource_path)

func _clear_file_system_dock_selection(file_system_dock: FileSystemDock) -> void:
	for tree_control in file_system_dock.find_children("*", "Tree", true, false):
		(tree_control as Tree).deselect_all()
	for item_list_control in file_system_dock.find_children("*", "ItemList", true, false):
		(item_list_control as ItemList).deselect_all()
