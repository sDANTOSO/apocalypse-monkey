@tool
extends EditorImportPlugin

const VoxImporterCommon = preload("./vox-importer-common.gd")
const VoxSceneBuilder = preload("./VoxSceneBuilder.gd")

func _init():
	print("MagicaVoxel Scene Importer: Ready")

func _get_importer_name():
	return "MagicaVoxel.With.Extensions.To.Scene"

func _get_visible_name():
	return "MagicaVoxel Scene"

func _get_recognized_extensions():
	return ["vox"]

func _get_resource_type():
	return "PackedScene"

func _get_save_extension():
	return "scn"

func _get_preset_count():
	return 0

func _get_preset_name(_preset):
	return "Default"

func _get_import_order():
	return 0

func _get_format_version() -> int:
	return 4

func _get_priority() -> float:
	return 2.0

func _get_import_options(_path, _preset):
	return [
		{
			"name": "Scale",
			"default_value": 0.1,
		},
		{
			"name": "GreedyMeshGenerator",
			"default_value": true,
		},
		{
			"name": "SnapToGround",
			"default_value": false,
		},
		{
			"name": "OriginsToGeometry",
			"default_value": false,
		},
		{
			"name": "ImportAnimation",
			"default_value": true,
		},
		{
			"name": "AnimationFPS",
			"default_value": 8.0,
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "1.0,60.0,1.0",
		},
		{
			"name": "AnimationLoop",
			"default_value": true,
		},
		{
			"name": "AnimationAutoplay",
			"default_value": false,
		},
	]

func _get_option_visibility(_path, option, options):
	if option in ["AnimationFPS", "AnimationLoop", "AnimationAutoplay"]:
		return bool(options.get("ImportAnimation", true))
	return true

func _import(source_path, destination_path, options, _platforms, _gen_files):
	var common_importer = VoxImporterCommon.new()
	var read_result = common_importer.read_vox_data(source_path)
	if read_result["error"] != OK:
		return read_result["error"]

	var scale = float(options.get("Scale", 0.1))
	var use_greedy_mesh = bool(options.get("GreedyMeshGenerator", true))
	var snap_to_ground = bool(options.get("SnapToGround", false))
	var origins_to_geometry = bool(options.get("OriginsToGeometry", false))
	var import_animation = bool(options.get("ImportAnimation", true))
	var animation_fps = float(options.get("AnimationFPS", 8.0))
	var animation_loop = bool(options.get("AnimationLoop", true))
	var animation_autoplay = bool(options.get("AnimationAutoplay", false))
	var scene_result = VoxSceneBuilder.new().build_packed_scene(
		read_result["vox"],
		read_result["keyframe_ids"],
		source_path,
		scale,
		use_greedy_mesh,
		snap_to_ground,
		origins_to_geometry,
		import_animation,
		animation_fps,
		animation_loop,
		animation_autoplay
	)
	if scene_result["error"] != OK:
		return scene_result["error"]

	print(
		"VOX scene import: ", source_path,
		" (scale: ", scale,
		", mesh nodes: ", scene_result["mesh_count"],
		", keyframe: ", scene_result["keyframe_id"],
		", animation tracks: ", scene_result["animation_track_count"],
		", snap to ground: ", snap_to_ground,
		", origins to geometry: ", origins_to_geometry, ")"
	)
	var full_path = "%s.%s" % [destination_path, _get_save_extension()]
	var save_error = ResourceSaver.save(scene_result["scene"], full_path)
	var source_root = scene_result.get("source_root") as Node3D
	if is_instance_valid(source_root):
		source_root.free()
	return save_error
