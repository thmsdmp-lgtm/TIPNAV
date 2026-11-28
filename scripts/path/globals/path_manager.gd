# singleton for managing paths
extends Node

const CORNER_STEPS := 8

var batch_size: int = 500
var points: PackedVector3Array = []
var initialized: bool = false

# path settings (set current_node and path_material from your scene)
var current_node: Node3D
var path_material: Material
var width := 0.7
var height_offset := 0
var corner_radius := 0.8

var _path_mesh: MeshInstance3D
var _target := Vector3.ZERO
var _has_target := false
var _last_state := []

func _ready() -> void:
	_path_mesh = MeshInstance3D.new()
	_path_mesh.mesh = ImmediateMesh.new()
	add_child(_path_mesh)

func _process(_delta: float) -> void:
	if _has_target:
		_update_path()

# show a path from current_node to a global position
func set_path(target: Vector3) -> void:
	_target = target
	_has_target = true
	_last_state = []
	print("set_path: target=", target, " current_node=", current_node,
			" material=", path_material)

# hide the path
func remove_path() -> void:
	_has_target = false
	_last_state = []
	(_path_mesh.mesh as ImmediateMesh).clear_surfaces()

# get closest
func get_closest_point(pos: Vector3, search_radius: float = 5.0) -> Vector3:
	var closest_point := Vector3.ZERO
	var closest_distance := search_radius * search_radius
	
	for point in points:
		var distance := pos.distance_squared_to(point)
		
		if distance < closest_distance:
			closest_distance = distance
			closest_point = point
	
	return closest_point

# initialize path
func initialize(user_node:Node3D,path_mesh: MeshInstance3D,material:ShaderMaterial):
	initialized = false
	
	path_material = material
	current_node = user_node
	
	if points.size() > 0:
		points.clear()
	
	if not is_instance_valid(path_mesh):
		return points
	
	var mesh := path_mesh.mesh
	
	if mesh == null:
		return points
	
	var processed_faces := 0
	
	for surface_idx in mesh.get_surface_count():
		var tool := MeshDataTool.new()
		var error := tool.create_from_surface(mesh, surface_idx)
		
		if error != OK:
			continue
		
		for face_idx in tool.get_face_count():
			var face_pos := Vector3.ZERO
			
			for vert_in_face in 3:
				var vert_idx := tool.get_face_vertex(face_idx, vert_in_face)
				face_pos += tool.get_vertex(vert_idx)
			
			# Convert face center to global coordinates.
			points.append(
				path_mesh.to_global(face_pos / 3.0)
			)
			
			processed_faces += 1
			
			if processed_faces % batch_size == 0:
				await get_tree().process_frame
		
		tool.clear()
	initialized = true

# rebuild the path only when something changes
func _update_path() -> void:
	var im := _path_mesh.mesh as ImmediateMesh
	
	if not is_instance_valid(current_node):
		im.clear_surfaces()
		_last_state = []
		return
	
	var map := _path_mesh.get_world_3d().navigation_map
	var map_version := NavigationServer3D.map_get_iteration_id(map)
	if map_version == 0:
		return
	
	var from := current_node.global_position
	var state := [from, _target, map_version, width, height_offset,
			corner_radius, path_material]
	if state == _last_state:
		return
	_last_state = state
	
	var route := NavigationServer3D.map_get_path(map, from, _target, true)
	print("route points: ", route.size(), " ", route)
	_draw_ribbon(im, _remove_duplicates(_round_corners(route)))

func _draw_ribbon(im: ImmediateMesh, route: PackedVector3Array) -> void:
	im.clear_surfaces()
	if route.size() < 2:
		return
	
	var last := route.size() - 1
	var distance := 0.0
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, path_material)
	
	for i in route.size():
		if i > 0:
			distance += route[i].distance_to(route[i - 1])
		
		var side_in := _side(route[maxi(i - 1, 0)], route[maxi(i, 1)])
		var side_out := _side(route[mini(i, last - 1)], route[mini(i + 1, last)])
		
		var miter := (side_in + side_out).normalized()
		if miter == Vector3.ZERO:
			miter = side_out
		var offset := miter * (width * 0.5 / maxf(miter.dot(side_out), 0.5))
		var lifted := route[i] + Vector3.UP * height_offset
		
		# the mesh sits at the origin, so global positions can be used directly
		_add_point(im, lifted - offset, Vector2(0, distance))
		_add_point(im, lifted + offset, Vector2(1, distance))
	
	im.surface_end()

func _add_point(im: ImmediateMesh, vertex: Vector3, uv: Vector2) -> void:
	im.surface_set_uv(uv)
	im.surface_add_vertex(vertex)

func _side(a: Vector3, b: Vector3) -> Vector3:
	var side := (b - a).cross(Vector3.UP)
	return side.normalized() if side.length() > 0.001 else Vector3.RIGHT

func _round_corners(route: PackedVector3Array) -> PackedVector3Array:
	if route.size() < 3 or corner_radius <= 0.0:
		return route
	
	var result := PackedVector3Array([route[0]])
	for i in range(1, route.size() - 1):
		var corner := route[i]
		var to_prev := route[i - 1] - corner
		var to_next := route[i + 1] - corner
		var a := corner + to_prev.limit_length(minf(corner_radius, to_prev.length() * 0.5))
		var b := corner + to_next.limit_length(minf(corner_radius, to_next.length() * 0.5))
		
		for s in CORNER_STEPS + 1:
			var t := float(s) / CORNER_STEPS
			result.append(a.lerp(corner, t).lerp(corner.lerp(b, t), t))
	
	result.append(route[route.size() - 1])
	return result

func _remove_duplicates(route: PackedVector3Array) -> PackedVector3Array:
	var result := PackedVector3Array()
	for p in route:
		if result.is_empty() or p.distance_to(result[result.size() - 1]) > 0.01:
			result.append(p)
	return result
