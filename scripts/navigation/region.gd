extends NavigationRegion3D
## Draws the path network as flat planes and bakes the navigation mesh from it.

@export var max_distance := 1.2     # link points closer than this

@export_group("Visual")
@export var path_width := 0.7
@export var outline_width := 0.08   # 0 = no outline
@export var height_offset := 0.05   # lift above the floor
@export var path_color := Color("4f6bed")
@export var outline_color := Color.WHITE

@export_group("Navigation")
@export var walk_width := 1.5       # keep well above 2 x agent_radius
@export var agent_radius := 0.25    # use multiples of 0.25 (the cell size)

const CIRCLE_STEPS := 16

var _visual: MeshInstance3D


func _ready() -> void:
	# The points are in global space, so this node must not be offset
	top_level = true
	global_transform = Transform3D.IDENTITY

	_visual = MeshInstance3D.new()
	add_child(_visual)
	
	# wait till pathmanager is initialized
	while not PathManager.initialized:
		await get_tree().process_frame
	
	# build navigation region
	build(PathManager.points)


func build(points: PackedVector3Array) -> void:
	var fill := PackedVector3Array()
	var outline := PackedVector3Array()
	var walk := PackedVector3Array()
	var joints := {}                 # indices of points that have a link
	var limit := max_distance * max_distance
	var half := path_width * 0.5

	# The outline is a wider copy placed just underneath the path
	var fill_lift := Vector3.UP * height_offset
	var outline_lift := Vector3.UP * (height_offset - 0.02)

	# 1. A flat strip for every pair of nearby points
	for i in points.size():
		for j in range(i + 1, points.size()):
			var a := points[i]
			var b := points[j]
			if a.distance_squared_to(b) > limit or a.distance_to(b) < 0.001:
				continue
			var direction := (b - a).normalized()
			if direction.cross(Vector3.UP).length() < 0.001:
				continue             # skip vertical links

			joints[i] = true
			joints[j] = true
			_add_strip(fill, a + fill_lift, b + fill_lift, half)
			if outline_width > 0.0:
				_add_strip(outline, a + outline_lift, b + outline_lift, half + outline_width)

			# Walkway ends are extended so corners have no gaps
			var extend := direction * walk_width * 0.5
			_add_strip(walk, a - extend, b + extend, walk_width * 0.5)

	if walk.is_empty():
		push_warning("No walkable links. Check the points or raise max_distance.")
		_visual.mesh = null
		navigation_mesh = null
		return

	# 2. A circle on every joint, for rounded corners and ends
	for i in joints:
		_add_circle(fill, points[i] + fill_lift, half)
		if outline_width > 0.0:
			_add_circle(outline, points[i] + outline_lift, half + outline_width)

	# 3. Combine into one visible mesh with two colors
	var mesh := ArrayMesh.new()
	_add_surface(mesh, fill, path_color)
	if not outline.is_empty():
		_add_surface(mesh, outline, outline_color)
	_visual.mesh = mesh

	# 4. Navigation
	_bake(walk)


## A rectangle from a to b, made of two triangles (clockwise seen from above).
func _add_strip(faces: PackedVector3Array, a: Vector3, b: Vector3, half: float) -> void:
	var side := (b - a).cross(Vector3.UP).normalized() * half
	faces.append_array(PackedVector3Array([
		a - side, b - side, b + side,
		a - side, b + side, a + side,
	]))


## A flat circle made of triangles around the center.
func _add_circle(faces: PackedVector3Array, center: Vector3, circle_radius: float) -> void:
	for step in CIRCLE_STEPS:
		var from := TAU * step / CIRCLE_STEPS
		var to := TAU * (step + 1) / CIRCLE_STEPS
		faces.append(center)
		faces.append(center + Vector3(cos(from), 0, sin(from)) * circle_radius)
		faces.append(center + Vector3(cos(to), 0, sin(to)) * circle_radius)


func _add_surface(mesh: ArrayMesh, faces: PackedVector3Array, color: Color) -> void:
	var data := []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = faces
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	mesh.surface_set_material(mesh.get_surface_count() - 1, material)


func _bake(faces: PackedVector3Array) -> void:
	var source := NavigationMeshSourceGeometryData3D.new()
	source.add_faces(faces, Transform3D.IDENTITY)

	var nav := NavigationMesh.new()
	nav.cell_size = 0.25                # must match the navigation map
	nav.cell_height = 0.05
	NavigationServer3D.map_set_cell_height(get_navigation_map(), 0.05)
	nav.agent_radius = agent_radius

	NavigationServer3D.bake_from_source_geometry_data(nav, source)
	navigation_mesh = nav               # hand the result to this region
