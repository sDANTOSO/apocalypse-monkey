@tool
extends FoldableContainer

const VoxImporterCommon = preload("../VoxImporter/vox-importer-common.gd")
const VoxSceneBuilder = preload("../VoxImporter/VoxSceneBuilder.gd")

static var _folded_states_by_source_path := {}

var _source_path := ""
var _import_options: Object
var _content: VBoxContainer
var _content_generation := 0

func initialize(source_path: String, import_options: Object) -> void:
	_source_path = source_path
	_import_options = import_options
	title = "VOX Info"
	folded = bool(_folded_states_by_source_path.get(_source_path, true))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_content)
	folding_changed.connect(_on_folding_changed)
	if not folded:
		call_deferred("_on_folding_changed", false)

func _exit_tree() -> void:
	_discard_generated_content()
	_import_options = null

func _on_folding_changed(is_folded: bool) -> void:
	_folded_states_by_source_path[_source_path] = is_folded
	_content_generation += 1
	_discard_generated_content()
	if is_folded:
		return

	var loading_label = Label.new()
	loading_label.text = "Calculating VOX statistics..."
	_content.add_child(loading_label)
	call_deferred("_generate_info_content", _content_generation)

func _generate_info_content(expected_generation: int) -> void:
	if folded or expected_generation != _content_generation:
		return
	_discard_generated_content()

	var info_result = _calculate_vox_info()
	if folded or expected_generation != _content_generation:
		return

	var info_text = RichTextLabel.new()
	info_text.bbcode_enabled = true
	info_text.fit_content = true
	info_text.scroll_active = false
	info_text.selection_enabled = true
	info_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if info_result["error"] == OK:
		info_text.text = info_result["text"]
	else:
		info_text.text = "[color=tomato]%s[/color]" % info_result["message"]
	_content.add_child(info_text)

func _calculate_vox_info() -> Dictionary:
	var common_importer = VoxImporterCommon.new()
	var read_result = common_importer.read_vox_data(_source_path)
	if read_result["error"] != OK:
		return {
			"error": read_result["error"],
			"message": "Could not read the VOX file.",
		}

	var scale = float(_get_import_option("Scale", 0.1))
	var use_greedy_mesh = bool(_get_import_option("GreedyMeshGenerator", true))
	var origins_to_geometry = bool(_get_import_option("OriginsToGeometry", false))
	var animation_fps = float(_get_import_option("AnimationFPS", 8.0))
	var scene_result = VoxSceneBuilder.new().build_packed_scene(
		read_result["vox"],
		read_result["keyframe_ids"],
		_source_path,
		scale,
		use_greedy_mesh,
		false,
		origins_to_geometry,
		true,
		animation_fps,
		true,
		false
	)
	if scene_result["error"] != OK:
		return {
			"error": scene_result["error"],
			"message": "Could not generate meshes for VOX statistics.",
		}

	var scene_root = scene_result["source_root"] as Node3D
	var info_text = _format_scene_info(
		scene_root,
		read_result["vox"],
		read_result["keyframe_ids"],
		scale,
		use_greedy_mesh
	)
	scene_root.free()
	return {
		"error": OK,
		"text": info_text,
	}

func _format_scene_info(
	scene_root: Node3D,
	vox,
	keyframe_ids: Array,
	scale: float,
	use_greedy_mesh: bool
) -> String:
	var mesh_instances: Array[MeshInstance3D] = []
	_append_mesh_instances(scene_root, mesh_instances)
	var loaded_meshes: Array[Mesh] = []
	var mesh_entry_count := 0
	var total_vertices := 0
	var total_triangles := 0
	var rows: Array[String] = []

	for mesh_instance in mesh_instances:
		var current_mesh_statistics = _calculate_mesh_statistics(mesh_instance.mesh)
		total_vertices += int(current_mesh_statistics["vertices"])
		total_triangles += int(current_mesh_statistics["triangles"])

		var frame_entries = _collect_mesh_frame_entries(scene_root, mesh_instance, vox)
		mesh_entry_count += frame_entries.size()
		for frame_entry in frame_entries:
			var frame_mesh = frame_entry["mesh"] as Mesh
			if frame_mesh != null and not loaded_meshes.has(frame_mesh):
				loaded_meshes.append(frame_mesh)
			var mesh_statistics = _calculate_mesh_statistics(frame_mesh)
			var source_statistics = _calculate_source_model_statistics(
				vox,
				int(frame_entry["model_id"])
			)
			var row_format = (
				"[cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]"
				+ "[cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]"
				+ "[cell]%s[/cell][cell]%s[/cell]"
			)
			rows.append(
				row_format % [
					_escape_bbcode(String(mesh_instance.name)),
					str(frame_entry["frame"]),
					str(frame_entry["model_id"]),
					source_statistics["size"],
					source_statistics["voxels"],
					str(mesh_statistics["vertices"]),
					str(mesh_statistics["triangles"]),
					str(mesh_statistics["surfaces"]),
				]
			)

	var frame_count = maxi(keyframe_ids.size(), 1)
	var generator_name = "Greedy" if use_greedy_mesh else "Culled"
	var result := "[b]%s[/b]\n" % _escape_bbcode(_source_path.get_file())
	result += "Mesh nodes: %d   Loaded meshes: %d   Frame entries: %d\n" % [
		mesh_instances.size(),
		loaded_meshes.size(),
		mesh_entry_count,
	]
	result += "Animation frames: %d   Scale: %s   Generator: %s\n" % [
		frame_count,
		_format_decimal(scale),
		generator_name,
	]
	result += "Current frame: %d vertices, %d triangles\n\n" % [
		total_vertices,
		total_triangles,
	]
	result += "[table=8]"
	result += "[cell][b]Node[/b][/cell][cell][b]Frame[/b][/cell]"
	result += "[cell][b]Model[/b][/cell][cell][b]VOX Size[/b][/cell]"
	result += "[cell][b]Voxels[/b][/cell][cell][b]Vertices[/b][/cell]"
	result += "[cell][b]Triangles[/b][/cell][cell][b]Surfaces[/b][/cell]"
	for row in rows:
		result += row
	result += "[/table]"
	return result

func _collect_mesh_frame_entries(
	scene_root: Node3D,
	mesh_instance: MeshInstance3D,
	vox
) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var model_ids_by_frame := {}
	var shape_node_id = int(mesh_instance.get_meta("magica_voxel_shape_node_id", -1))
	if vox.nodes.has(shape_node_id):
		var shape_node = vox.nodes[shape_node_id]
		for frame_id_value in shape_node.models:
			model_ids_by_frame[int(frame_id_value)] = int(shape_node.models[frame_id_value])

	if model_ids_by_frame.is_empty():
		entries.append({
			"frame": "-",
			"model_id": int(mesh_instance.get_meta("magica_voxel_model_id", -1)),
			"mesh": mesh_instance.mesh,
		})
		return entries

	var animation_meshes: Array[Mesh] = []
	var animation_player = scene_root.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player != null and animation_player.has_animation("default"):
		var animation = animation_player.get_animation("default")
		var expected_track_path = NodePath(
			"%s:mesh" % scene_root.get_path_to(mesh_instance)
		)
		for track_index in range(animation.get_track_count()):
			if animation.track_get_path(track_index) != expected_track_path:
				continue
			for key_index in range(animation.track_get_key_count(track_index)):
				animation_meshes.append(
					animation.track_get_key_value(track_index, key_index) as Mesh
				)
			break

	var frame_ids = model_ids_by_frame.keys()
	frame_ids.sort()
	for frame_index in range(frame_ids.size()):
		var frame_id = int(frame_ids[frame_index])
		var frame_mesh = mesh_instance.mesh
		if frame_index < animation_meshes.size() and animation_meshes[frame_index] != null:
			frame_mesh = animation_meshes[frame_index]
		entries.append({
			"frame": frame_id,
			"model_id": int(model_ids_by_frame[frame_id]),
			"mesh": frame_mesh,
		})
	return entries

func _calculate_mesh_statistics(mesh: Mesh) -> Dictionary:
	if mesh == null:
		return {
			"vertices": 0,
			"triangles": 0,
			"surfaces": 0,
		}
	var vertex_count := 0
	var triangle_count := 0
	for surface_index in range(mesh.get_surface_count()):
		var surface_arrays = mesh.surface_get_arrays(surface_index)
		var vertices = surface_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var indices = surface_arrays[Mesh.ARRAY_INDEX]
		vertex_count += vertices.size()
		if indices == null or indices.size() == 0:
			triangle_count += vertices.size() / 3
		else:
			triangle_count += indices.size() / 3

	return {
		"vertices": vertex_count,
		"triangles": triangle_count,
		"surfaces": mesh.get_surface_count(),
	}

func _calculate_source_model_statistics(vox, model_id: int) -> Dictionary:
	if not vox.models.has(model_id):
		return {
			"size": "-",
			"voxels": "-",
		}
	var model = vox.models[model_id]

	return {
		"size": "%d x %d x %d" % [model.size.x, model.size.y, model.size.z],
		"voxels": str(model.voxels.size()),
	}

func _append_mesh_instances(node: Node, mesh_instances: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		mesh_instances.append(node as MeshInstance3D)
	for child in node.get_children():
		_append_mesh_instances(child, mesh_instances)

func _get_import_option(option_name: String, fallback):
	if _import_options == null:
		return fallback
	for property_info in _import_options.get_property_list():
		if String(property_info["name"]) == option_name:
			return _import_options.get(option_name)
	return fallback

func _format_decimal(value: float) -> String:
	return String.num(value, 4).trim_suffix("0").trim_suffix(".")

func _escape_bbcode(value: String) -> String:
	return value.replace("[", "[​")

func _discard_generated_content() -> void:
	if not is_instance_valid(_content):
		return
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
