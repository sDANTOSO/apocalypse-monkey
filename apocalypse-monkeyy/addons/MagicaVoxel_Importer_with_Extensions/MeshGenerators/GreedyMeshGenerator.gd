const Faces = preload("./Faces.gd")
const VoxData = preload("../VoxFormat/VoxData.gd")
const vox_to_godot = Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)

# Names for the faces by orientation
enum FaceOrientation {
	Top = 0,
	Bottom = 1,
	Left = 2,
	Right = 3,
	Front = 4,
	Back = 5,
}

# An Array(FaceOrientation) of all possible face orientations
const face_orientations :Array = [
	FaceOrientation.Top,
	FaceOrientation.Bottom,
	FaceOrientation.Left,
	FaceOrientation.Right,
	FaceOrientation.Front,
	FaceOrientation.Back
]

# An Array(int) of the depth axis by orientation
const depth_axis :Array = [
	Vector3.AXIS_Z,
	Vector3.AXIS_Z,
	Vector3.AXIS_X,
	Vector3.AXIS_X,
	Vector3.AXIS_Y,
	Vector3.AXIS_Y,
]

# An Array(int) of the width axis by orientation
const width_axis :Array = [
	Vector3.AXIS_Y,
	Vector3.AXIS_Y,
	Vector3.AXIS_Z,
	Vector3.AXIS_Z,
	Vector3.AXIS_X,
	Vector3.AXIS_X,
]

# An Array(int) of height axis by orientation
const height_axis :Array = [
	Vector3.AXIS_X,
	Vector3.AXIS_X,
	Vector3.AXIS_Y,
	Vector3.AXIS_Y,
	Vector3.AXIS_Z,
	Vector3.AXIS_Z,
]

# An Array(Vector3) describing what vectors to use to check for face occlusion
# by orientation
const face_checks :Array = [
	Vector3(0, 0, 1),
	Vector3(0, 0, -1),
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, -1, 0),
	Vector3(0, 1, 0),
]

# An array of the face meshes by orientation
const face_meshes :Array = [
	Faces.Front,
	Faces.Back,
	Faces.Left,
	Faces.Right,
	Faces.Bottom,
	Faces.Top,
]

# An Array(Vector3) describing what normals to use by orientation
const normals :Array = [
	Vector3(0, 1, 0),
	Vector3(0, -1, 0),
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, 0, 1),
	Vector3(0, 0, -1),
]

# The SurfaceTool the object will use to generate the mesh
var st :SurfaceTool = SurfaceTool.new()

# A Dictonary[Vector3]int of the voxel data for the visible faces of the
# current slice
var faces :Dictionary

# Minimum extends of the volume
var mins :Vector3 = Vector3(1000000, 1000000, 1000000)

# Generate a mesh for the given voxel_data with single-pass greedy face merging
# Primary RefCounted: https://0fps.net/2012/06/30/meshing-in-a-minecraft-game/
# Secondary RefCounted: https://www.gedge.ca/dev/2014/08/17/greedy-voxel-meshing
# voxel_data is a dict[Vector3]int
func generate(vox :VoxData, voxel_data :Dictionary, scale :float, snaptoground : bool):
	# Remeber, MagicaVoxel thinks Y is the depth axis. We convert to the correct
	# coordinate space when we generate the faces.
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Short-circut empty models
	if voxel_data.size() == 0:
		return st.commit()
	
	# Convert voxel data to raw color values
	for v in voxel_data:
		voxel_data[v] = vox.colors[voxel_data[v]]
	
	# 바닥 맞춤에 필요한 최소 좌표를 계산합니다.
	for v in voxel_data:
		mins.x = min(mins.x, v.x)
		mins.y = min(mins.y, v.y)
		mins.z = min(mins.z, v.z)
	
	# Itterate over all face orientations to reduce problem to 3 dimensions
	for o in face_orientations:
		generate_geometry_for_orientation(voxel_data, o, scale, snaptoground)

	# Finish the mesh and material and return
	var material = StandardMaterial3D.new()
	material.vertex_color_is_srgb = true
	material.vertex_color_use_as_albedo = true
	material.roughness = 1
	st.set_material(material)
	return st.commit()

# Generates all of the geometry for a given face orientation
func generate_geometry_for_orientation(voxel_data :Dictionary, o :int, scale :float, snaptoground :bool) -> void:
	var da :int = depth_axis[o]
	var faces_by_slice := {}
	# 방향마다 복셀을 한 번만 훑어 보이는 면을 깊이별로 분류합니다.
	for v in voxel_data:
		if voxel_data.has(v + face_checks[o]):
			continue
		var slice = int(v[da])
		if not faces_by_slice.has(slice):
			faces_by_slice[slice] = {}
		faces_by_slice[slice][v] = voxel_data[v]

	var slices = faces_by_slice.keys()
	slices.sort()
	for slice in slices:
		generate_geometry(faces_by_slice[slice], o, slice, scale, snaptoground)

# Generates geometry for the given orientation for the set of faces
func generate_geometry(faces :Dictionary, o :int, _slice :float, scale :float, snaptoground :bool) -> void:
	var wa :int = width_axis[o]
	var ha :int = height_axis[o]
	var face_positions = faces.keys()
	# 빈 공간 전체 대신 실제 면 좌표만 행 순서로 순회해 같은 Greedy 병합 결과를 만듭니다.
	face_positions.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		if a[ha] == b[ha]:
			return a[wa] < b[wa]
		return a[ha] < b[ha]
	)
	for face_position in face_positions:
		if faces.has(face_position):
			generate_geometry_for_face(faces, face_position, o, scale, snaptoground)

# Generates the geometry for the given face and orientation and scale and returns
# the set of remaining faces
func generate_geometry_for_face(faces :Dictionary, face :Vector3, o :int, scale :float, snaptoground :bool) -> Dictionary:
	var da :int = depth_axis[o]
	var wa :int = width_axis[o]
	var ha :int = height_axis[o]
	
	# Greedy face merging
	var width :int = width_query(faces, face, o)
	var height :int = height_query(faces, face, o, width)
	var grow :Vector3 = Vector3(1, 1, 1)
	grow[wa] *= width
	grow[ha] *= height
	
	# Generate geometry
	var yoffset = Vector3(0,0,0);
	if snaptoground : yoffset = Vector3(0, -mins.z * scale, 0);

	st.set_color(faces[face])
	st.set_normal(normals[o])
	for vert in face_meshes[o]:
		st.add_vertex(yoffset + vox_to_godot * ((vert * grow) + face) * scale)
	
	# Remove these faces from the pool
	var v :Vector3 = Vector3()
	v[da] = face[da]
	for iy in range(height):
		v[ha] = face[ha] + float(iy)
		for ix in range(width):
			v[wa] = face[wa] + float(ix)
			faces.erase(v)
	
	return faces

# Returns the number of voxels wide the run starting at face is with respect to
# the set of faces and orientation
func width_query(faces :Dictionary, face :Vector3, o :int) -> int:
	var wd :int = width_axis[o]
	var v :Vector3 = face
	while faces.has(v) and faces[v] == faces[face]:
		v[wd] += 1.0
	return int(v[wd] - face[wd])

# Returns the number of voxels high the run starting at face is with respect to
# the set of faces and orientation, with the given width
func height_query(faces :Dictionary, face :Vector3, o :int, width :int) -> int:
	var hd :int = height_axis[o]
	var c :Color = faces[face]
	var v :Vector3 = face
	v[hd] += 1.0
	while faces.has(v) and faces[v] == c and width_query(faces, v, o) >= width:
		v[hd] += 1.0
	return int(v[hd] - face[hd])
