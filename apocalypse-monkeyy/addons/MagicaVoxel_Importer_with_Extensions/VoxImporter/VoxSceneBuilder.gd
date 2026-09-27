@tool
extends RefCounted

const VoxData = preload("../VoxFormat/VoxData.gd")
const VoxNode = preload("../VoxFormat/VoxNode.gd")
const GreedyMeshGenerator = preload("../MeshGenerators/GreedyMeshGenerator.gd")
const CulledMeshGenerator = preload("../MeshGenerators/CulledMeshGenerator.gd")

const VOX_TO_GODOT = Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)

var _vox: VoxData
var _scale := 0.1
var _use_greedy_mesh := true
var _origins_to_geometry := false
var _keyframe_id := 0
var _scene_root: Node3D
var _generated_mesh_count := 0
var _generated_animation_track_count := 0
var _build_error := OK
var _model_mesh_cache := {}
var _geometry_origin_mesh_cache := {}
var _geometry_origin_offsets_by_vox_node_id := {}
var _generated_nodes_by_vox_node_id := {}

func build_packed_scene(
	vox: VoxData,
	keyframe_ids: Array,
	source_path: String,
	scale: float,
	use_greedy_mesh: bool,
	snap_to_ground: bool,
	origins_to_geometry: bool,
	import_animation: bool,
	animation_fps: float,
	animation_loop: bool,
	animation_autoplay: bool
) -> Dictionary:
	_vox = vox
	_scale = scale
	_use_greedy_mesh = use_greedy_mesh
	_origins_to_geometry = origins_to_geometry
	_generated_mesh_count = 0
	_generated_animation_track_count = 0
	_build_error = OK
	_model_mesh_cache.clear()
	_geometry_origin_mesh_cache.clear()
	_geometry_origin_offsets_by_vox_node_id.clear()
	_generated_nodes_by_vox_node_id.clear()
	_keyframe_id = _find_first_keyframe_id(keyframe_ids)

	_scene_root = Node3D.new()
	_scene_root.name = _sanitize_node_name(source_path.get_file().get_basename(), "MagicaVoxelScene")

	if _vox.nodes.has(0):
		_append_vox_node(_scene_root, 0, -1, {})
	else:
		_append_models_without_scene_graph()

	if _build_error != OK:
		_scene_root.free()
		return { "error": _build_error }
	if _generated_mesh_count == 0:
		_scene_root.free()
		push_error("No models were found to generate from the VOX scene: %s" % source_path)
		return { "error": ERR_PARSE_ERROR }

	if snap_to_ground:
		_move_scene_content_to_ground()

	if import_animation:
		_append_animation_player(
			keyframe_ids,
			animation_fps,
			animation_loop,
			animation_autoplay
		)
		if _build_error != OK:
			_scene_root.free()
			return { "error": _build_error }

	var packed_scene = PackedScene.new()
	var pack_error = packed_scene.pack(_scene_root)
	if pack_error != OK:
		_scene_root.free()
		return { "error": pack_error }
	return {
		"error": OK,
		"scene": packed_scene,
		"source_root": _scene_root,
		"mesh_count": _generated_mesh_count,
		"animation_track_count": _generated_animation_track_count,
		"keyframe_id": _keyframe_id,
	}

func _append_vox_node(
	parent: Node3D,
	node_id: int,
	inherited_layer_id: int,
	ancestor_node_ids: Dictionary
) -> void:
	if _build_error != OK:
		return
	if ancestor_node_ids.has(node_id):
		_set_build_error(
			ERR_PARSE_ERROR,
			"The VOX scene hierarchy contains a circular reference. Node ID: %d" % node_id
		)
		return
	if not _vox.nodes.has(node_id):
		_set_build_error(
			ERR_PARSE_ERROR,
			"The VOX scene references a node that does not exist. Node ID: %d" % node_id
		)
		return

	var node = _vox.nodes[node_id] as VoxNode
	var active_layer_id = inherited_layer_id
	if _vox.layers.has(node.layerId):
		if not _vox.layers[node.layerId].isVisible:
			return
		active_layer_id = node.layerId

	var child_ancestor_ids = ancestor_node_ids.duplicate()
	child_ancestor_ids[node_id] = true
	match node.node_type:
		VoxNode.NodeType.TRANSFORM:
			_append_transform_node(parent, node, active_layer_id, child_ancestor_ids)
		VoxNode.NodeType.GROUP:
			_append_group_node(parent, node, active_layer_id, child_ancestor_ids)
		VoxNode.NodeType.SHAPE:
			_append_shape_node(parent, node)
		_:
			_append_unknown_node(parent, node, active_layer_id, child_ancestor_ids)

func _append_transform_node(
	parent: Node3D,
	node: VoxNode,
	active_layer_id: int,
	ancestor_node_ids: Dictionary
) -> void:
	var local_transform = _create_godot_transform(node.transforms)
	var imported_name = _get_imported_node_name(node)
	if _try_append_single_shape_as_mesh_instance(parent, node, imported_name, local_transform):
		return

	var child_parent = parent
	if (
		not imported_name.is_empty()
		or local_transform != Transform3D.IDENTITY
		or node.transforms.size() > 1
	):
		var transform_node = Node3D.new()
		transform_node.name = _sanitize_node_name(imported_name, "VoxTransform_%d" % node.id)
		transform_node.transform = local_transform
		transform_node.set_meta("magica_voxel_node_id", node.id)
		_add_owned_child(parent, transform_node)
		_generated_nodes_by_vox_node_id[node.id] = transform_node
		child_parent = transform_node

	for child_id in node.child_nodes:
		_append_vox_node(child_parent, int(child_id), active_layer_id, ancestor_node_ids)

func _try_append_single_shape_as_mesh_instance(
	parent: Node3D,
	transform_node: VoxNode,
	imported_name: String,
	local_transform: Transform3D
) -> bool:
	if transform_node.child_nodes.size() != 1:
		return false
	var shape_node_id = int(transform_node.child_nodes[0])
	if not _vox.nodes.has(shape_node_id):
		return false
	var shape_node = _vox.nodes[shape_node_id] as VoxNode
	if shape_node.node_type != VoxNode.NodeType.SHAPE:
		return false
	if _vox.layers.has(shape_node.layerId) and not _vox.layers[shape_node.layerId].isVisible:
		return true
	if imported_name.is_empty():
		imported_name = _get_imported_node_name(shape_node)
	_append_shape_node(
		parent,
		shape_node,
		imported_name,
		local_transform,
		transform_node.id
	)
	return true

func _append_group_node(
	parent: Node3D,
	node: VoxNode,
	active_layer_id: int,
	ancestor_node_ids: Dictionary
) -> void:
	var imported_name = _get_imported_node_name(node)
	var child_parent = parent
	if not imported_name.is_empty():
		var group_node = Node3D.new()
		group_node.name = _sanitize_node_name(imported_name, "VoxGroup_%d" % node.id)
		group_node.set_meta("magica_voxel_node_id", node.id)
		_add_owned_child(parent, group_node)
		child_parent = group_node

	for child_id in node.child_nodes:
		_append_vox_node(child_parent, int(child_id), active_layer_id, ancestor_node_ids)

func _append_shape_node(
	parent: Node3D,
	node: VoxNode,
	imported_name_override: String = "",
	local_transform: Transform3D = Transform3D.IDENTITY,
	transform_node_id: int = -1
) -> void:
	var model_id_value = _find_keyframed_value(node.models)
	if model_id_value == null:
		_set_build_error(
			ERR_PARSE_ERROR,
			"The VOX shape node has no model reference. Node ID: %d" % node.id
		)
		return

	var model_id = int(model_id_value)
	if not _vox.models.has(model_id):
		_set_build_error(
			ERR_PARSE_ERROR,
			"The VOX shape node references a model that does not exist. Model ID: %d" % model_id
		)
		return

	var source_mesh = _get_or_create_model_mesh(model_id)
	if source_mesh == null:
		_set_build_error(
			ERR_CANT_CREATE,
			"Could not generate the VOX model mesh. Model ID: %d" % model_id
		)
		return
	var geometry_origin = Vector3.ZERO
	var mesh = source_mesh
	if _origins_to_geometry:
		geometry_origin = source_mesh.get_aabb().get_center()
		mesh = _get_or_create_mesh_shifted_to_geometry_origin(model_id, geometry_origin)
		if mesh == null:
			_set_build_error(
				ERR_CANT_CREATE,
				"Could not move the VOX mesh origin to its geometry. Model ID: %d" % model_id
			)
			return

	var mesh_instance = MeshInstance3D.new()
	var imported_name = imported_name_override
	if imported_name.is_empty():
		imported_name = _get_imported_node_name(node)
	mesh_instance.name = _sanitize_node_name(
		imported_name,
		"Mesh_%d" % model_id
	)
	mesh_instance.transform = local_transform * Transform3D(Basis.IDENTITY, geometry_origin)
	mesh_instance.mesh = mesh
	if transform_node_id >= 0:
		mesh_instance.set_meta("magica_voxel_node_id", transform_node_id)
		mesh_instance.set_meta("magica_voxel_transform_node_id", transform_node_id)
	else:
		mesh_instance.set_meta("magica_voxel_node_id", node.id)
	mesh_instance.set_meta("magica_voxel_shape_node_id", node.id)
	mesh_instance.set_meta("magica_voxel_model_id", model_id)
	_add_owned_child(parent, mesh_instance)
	_generated_nodes_by_vox_node_id[node.id] = mesh_instance
	_geometry_origin_offsets_by_vox_node_id[node.id] = geometry_origin
	if transform_node_id >= 0:
		_generated_nodes_by_vox_node_id[transform_node_id] = mesh_instance
		_geometry_origin_offsets_by_vox_node_id[transform_node_id] = geometry_origin
	_generated_mesh_count += 1

func _append_unknown_node(
	parent: Node3D,
	node: VoxNode,
	active_layer_id: int,
	ancestor_node_ids: Dictionary
) -> void:
	if not node.models.is_empty():
		_append_shape_node(parent, node)
		return
	for child_id in node.child_nodes:
		_append_vox_node(parent, int(child_id), active_layer_id, ancestor_node_ids)

func _append_models_without_scene_graph() -> void:
	var model_ids = _vox.models.keys()
	model_ids.sort()
	for model_id_value in model_ids:
		var model_id = int(model_id_value)
		var source_mesh = _get_or_create_model_mesh(model_id)
		if source_mesh == null:
			continue
		var geometry_origin = Vector3.ZERO
		var mesh = source_mesh
		if _origins_to_geometry:
			geometry_origin = source_mesh.get_aabb().get_center()
			mesh = _get_or_create_mesh_shifted_to_geometry_origin(model_id, geometry_origin)
			if mesh == null:
				continue
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Model_%d" % model_id
		mesh_instance.position = geometry_origin
		mesh_instance.mesh = mesh
		mesh_instance.set_meta("magica_voxel_model_id", model_id)
		_add_owned_child(_scene_root, mesh_instance)
		_generated_mesh_count += 1

func _generate_model_mesh(model) -> Mesh:
	var voxel_data = {}
	var center_offset = (model.size / 2.0).floor()
	for voxel in model.voxels:
		voxel_data[voxel - center_offset] = model.voxels[voxel]
	if _use_greedy_mesh:
		return GreedyMeshGenerator.new().generate(_vox, voxel_data, _scale, false)
	return CulledMeshGenerator.new().generate(_vox, voxel_data, _scale, false)

func _get_or_create_model_mesh(model_id: int) -> Mesh:
	if _model_mesh_cache.has(model_id):
		return _model_mesh_cache[model_id] as Mesh
	var mesh = _generate_model_mesh(_vox.models[model_id])
	if mesh != null:
		mesh.resource_name = "VoxModel_%d" % model_id
		for surface_index in range(mesh.get_surface_count()):
			var material = mesh.surface_get_material(surface_index)
			if material != null and material.resource_name.is_empty():
				material.resource_name = "VoxModel_%d_Material_%d" % [model_id, surface_index]
		_model_mesh_cache[model_id] = mesh
	return mesh

func _get_or_create_mesh_shifted_to_geometry_origin(
	model_id: int,
	geometry_origin: Vector3
) -> Mesh:
	if not _geometry_origin_mesh_cache.has(model_id):
		_geometry_origin_mesh_cache[model_id] = {}
	var model_origin_meshes = _geometry_origin_mesh_cache[model_id] as Dictionary
	if model_origin_meshes.has(geometry_origin):
		return model_origin_meshes[geometry_origin] as Mesh

	var source_mesh = _get_or_create_model_mesh(model_id)
	if source_mesh == null:
		return null
	var shifted_mesh = _create_mesh_shifted_by_local_offset(source_mesh, -geometry_origin)
	if shifted_mesh != null:
		shifted_mesh.resource_name = "VoxModel_%d_GeometryOrigin" % model_id
		model_origin_meshes[geometry_origin] = shifted_mesh
	return shifted_mesh

func _create_mesh_shifted_by_local_offset(source_mesh: Mesh, offset: Vector3) -> ArrayMesh:
	var shifted_mesh = ArrayMesh.new()
	for surface_index in range(source_mesh.get_surface_count()):
		var surface_arrays = source_mesh.surface_get_arrays(surface_index)
		var vertices = surface_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		for vertex_index in range(vertices.size()):
			vertices[vertex_index] += offset
		surface_arrays[Mesh.ARRAY_VERTEX] = vertices
		shifted_mesh.add_surface_from_arrays(
			source_mesh.surface_get_primitive_type(surface_index),
			surface_arrays
		)
		shifted_mesh.surface_set_name(
			surface_index,
			source_mesh.surface_get_name(surface_index)
		)
		shifted_mesh.surface_set_material(
			surface_index,
			source_mesh.surface_get_material(surface_index)
		)
	return shifted_mesh

func _create_godot_transform(keyframed_transforms: Dictionary) -> Transform3D:
	return _create_godot_transform_for_frame(keyframed_transforms, _keyframe_id)

func _create_godot_transform_for_frame(
	keyframed_transforms: Dictionary,
	frame_id: int
) -> Transform3D:
	var transform_value = _find_keyframed_value_for_frame(keyframed_transforms, frame_id)
	if transform_value == null:
		return Transform3D.IDENTITY
	var vox_position: Vector3 = transform_value.get("position", Vector3.ZERO)
	var vox_rotation: Basis = transform_value.get("rotation", Basis.IDENTITY)
	var godot_rotation = VOX_TO_GODOT * vox_rotation * VOX_TO_GODOT.inverse()
	var godot_position = VOX_TO_GODOT * vox_position * _scale
	return Transform3D(godot_rotation, godot_position)

func _find_first_keyframe_id(keyframe_ids: Array) -> int:
	if keyframe_ids.is_empty():
		return 0
	var sorted_ids = keyframe_ids.duplicate()
	sorted_ids.sort()
	return int(sorted_ids[0])

func _find_keyframed_value(values: Dictionary):
	return _find_keyframed_value_for_frame(values, _keyframe_id)

func _find_keyframed_value_for_frame(values: Dictionary, frame_id: int):
	if values.is_empty():
		return null
	var sorted_ids = values.keys()
	sorted_ids.sort()
	var selected_id = sorted_ids[0]
	for candidate_id in sorted_ids:
		if int(candidate_id) > frame_id:
			break
		selected_id = candidate_id
	return values[selected_id]

func _get_imported_node_name(node: VoxNode) -> String:
	return String(node.attributes.get("_name", "")).strip_edges()

func _sanitize_node_name(imported_name: String, fallback_name: String) -> String:
	var sanitized_name = imported_name.strip_edges()
	if sanitized_name.is_empty():
		sanitized_name = fallback_name
	for invalid_character in [".", ":", "@", "/", "\"", "%"]:
		sanitized_name = sanitized_name.replace(invalid_character, "_")
	return sanitized_name

func _add_owned_child(parent: Node, child: Node) -> void:
	parent.add_child(child, true)
	child.owner = _scene_root

func _append_animation_player(
	keyframe_ids: Array,
	animation_fps: float,
	animation_loop: bool,
	animation_autoplay: bool
) -> void:
	if keyframe_ids.size() < 2:
		return
	if animation_fps <= 0.0:
		_set_build_error(ERR_INVALID_PARAMETER, "VOX animation FPS must be greater than zero.")
		return

	var sorted_frame_ids = keyframe_ids.duplicate()
	sorted_frame_ids.sort()
	var first_frame_id = int(sorted_frame_ids[0])
	var last_frame_id = int(sorted_frame_ids[sorted_frame_ids.size() - 1])
	var animation = Animation.new()
	animation.resource_name = "default"
	animation.length = float(last_frame_id - first_frame_id + 1) / animation_fps
	animation.loop_mode = Animation.LOOP_LINEAR if animation_loop else Animation.LOOP_NONE

	_append_transform_animation_tracks(animation, first_frame_id, animation_fps)
	_append_shape_animation_tracks(animation, first_frame_id, animation_fps)
	if _generated_animation_track_count == 0:
		return

	var animation_library = AnimationLibrary.new()
	animation_library.resource_name = "MagicaVoxelAnimations"
	var add_animation_error = animation_library.add_animation("default", animation)
	if add_animation_error != OK:
		_set_build_error(add_animation_error, "Could not add the VOX animation to the animation library.")
		return

	var animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	var add_library_error = animation_player.add_animation_library("", animation_library)
	if add_library_error != OK:
		animation_player.free()
		_set_build_error(add_library_error, "Could not create the VOX animation library.")
		return
	if animation_autoplay:
		animation_player.set_autoplay("default")
	_add_owned_child(_scene_root, animation_player)
	_scene_root.move_child(animation_player, 0)

func _append_transform_animation_tracks(
	animation: Animation,
	first_frame_id: int,
	animation_fps: float
) -> void:
	var node_ids = _vox.nodes.keys()
	node_ids.sort()
	for node_id_value in node_ids:
		var node_id = int(node_id_value)
		var vox_node = _vox.nodes[node_id] as VoxNode
		if vox_node.node_type != VoxNode.NodeType.TRANSFORM:
			continue
		if vox_node.transforms.size() < 2 or not _generated_nodes_by_vox_node_id.has(node_id):
			continue

		var target = _generated_nodes_by_vox_node_id[node_id] as Node3D
		if not is_instance_valid(target):
			continue
		var imported_first_transform = _create_godot_transform_for_frame(
			vox_node.transforms,
			first_frame_id
		)
		var geometry_origin = Vector3(
			_geometry_origin_offsets_by_vox_node_id.get(node_id, Vector3.ZERO)
		)
		var geometry_origin_transform = Transform3D(Basis.IDENTITY, geometry_origin)
		var local_adjustment = (
			target.transform
			* geometry_origin_transform.affine_inverse()
			* imported_first_transform.affine_inverse()
		)
		var track_index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(
			track_index,
			NodePath("%s:transform" % _scene_root.get_path_to(target))
		)
		animation.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)

		var transform_frame_ids = vox_node.transforms.keys()
		transform_frame_ids.sort()
		for frame_id_value in transform_frame_ids:
			var frame_id = int(frame_id_value)
			if frame_id < first_frame_id:
				continue
			var frame_transform = _create_godot_transform_for_frame(
				vox_node.transforms,
				frame_id
			)
			animation.track_insert_key(
				track_index,
				float(frame_id - first_frame_id) / animation_fps,
				local_adjustment * frame_transform * geometry_origin_transform
			)
		_generated_animation_track_count += 1

func _append_shape_animation_tracks(
	animation: Animation,
	first_frame_id: int,
	animation_fps: float
) -> void:
	var node_ids = _vox.nodes.keys()
	node_ids.sort()
	for node_id_value in node_ids:
		var node_id = int(node_id_value)
		var vox_node = _vox.nodes[node_id] as VoxNode
		if vox_node.node_type != VoxNode.NodeType.SHAPE:
			continue
		if vox_node.models.size() < 2 or not _generated_nodes_by_vox_node_id.has(node_id):
			continue

		var target = _generated_nodes_by_vox_node_id[node_id] as MeshInstance3D
		if not is_instance_valid(target):
			continue
		var track_index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(
			track_index,
			NodePath("%s:mesh" % _scene_root.get_path_to(target))
		)
		animation.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)

		var model_frame_ids = vox_node.models.keys()
		model_frame_ids.sort()
		for frame_id_value in model_frame_ids:
			var frame_id = int(frame_id_value)
			if frame_id < first_frame_id:
				continue
			var model_id = int(vox_node.models[frame_id_value])
			if not _vox.models.has(model_id):
				_set_build_error(
					ERR_PARSE_ERROR,
					"The VOX animation references a model that does not exist. Model ID: %d" % model_id
				)
				return
			var mesh = _get_or_create_model_mesh(model_id)
			if _origins_to_geometry:
				var geometry_origin = Vector3(
					_geometry_origin_offsets_by_vox_node_id.get(node_id, Vector3.ZERO)
				)
				mesh = _get_or_create_mesh_shifted_to_geometry_origin(
					model_id,
					geometry_origin
				)
			if mesh == null:
				_set_build_error(
					ERR_CANT_CREATE,
					"Could not generate the VOX animation mesh. Model ID: %d" % model_id
				)
				return
			animation.track_insert_key(
				track_index,
				float(frame_id - first_frame_id) / animation_fps,
				mesh
			)
		_generated_animation_track_count += 1

func _move_scene_content_to_ground() -> void:
	var lowest_mesh_y = _find_lowest_mesh_y(_scene_root, Transform3D.IDENTITY)
	if lowest_mesh_y == INF:
		return
	var ground_offset = Vector3(0.0, -lowest_mesh_y, 0.0)
	for child in _scene_root.get_children():
		if child is Node3D:
			var child_3d = child as Node3D
			child_3d.position += ground_offset

func _find_lowest_mesh_y(node: Node, parent_transform: Transform3D) -> float:
	var node_transform = parent_transform
	if node is Node3D:
		node_transform = parent_transform * (node as Node3D).transform

	var lowest_y = INF
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh != null:
			lowest_y = _find_transformed_aabb_lowest_y(
				mesh_instance.mesh.get_aabb(),
				node_transform
			)

	for child in node.get_children():
		lowest_y = min(lowest_y, _find_lowest_mesh_y(child, node_transform))
	return lowest_y

func _find_transformed_aabb_lowest_y(bounds: AABB, transform_value: Transform3D) -> float:
	var lowest_y = INF
	for x_offset in [0.0, bounds.size.x]:
		for y_offset in [0.0, bounds.size.y]:
			for z_offset in [0.0, bounds.size.z]:
				var corner = bounds.position + Vector3(x_offset, y_offset, z_offset)
				lowest_y = min(lowest_y, (transform_value * corner).y)
	return lowest_y

func _set_build_error(error_code: int, message: String) -> void:
	if _build_error != OK:
		return
	_build_error = error_code
	push_error(message)
