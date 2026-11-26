extends Control

const OCCLUDER_LAYER := 1 << 19 # physics layer 20, unlikely to clash with your own

var labels: Array[Dictionary] = []
var label_scene: PackedScene = preload("res://scenes/scene_label.tscn")

@export_group("Label Visibility")
@export var max_label_distance: float = 100
@export var hide_when_occluded: bool = true
@export_flags_3d_physics var occlusion_mask: int = OCCLUDER_LAYER ## physics layers that can block labels
@export var occlusion_check_interval: float = 0.1 ## seconds between raycast passes
@export var occlusion_target_offset: Vector3 = Vector3.ZERO ## raise the ray target if the mesh origin sits on the ground

@export_group("Label Position")
@export var label_height_padding: float = 1.0 ## extra world units above the top of the mesh

var camera: Camera3D
var prev_cam_pos: Vector3 = Vector3.ZERO
var label_container: Control
var tab_bar
var _occlusion_timer: float = 0.0


func _ready() -> void:
	await get_tree().process_frame
	var current_scene = get_tree().current_scene

	if current_scene:
		camera = current_scene.get_node_or_null("World/camera/Camera3D")
		label_container = current_scene.get_node_or_null("Interface/scene_labels")
		tab_bar = current_scene.get_node_or_null("%tab_bar")

		if not is_instance_valid(camera) or not is_instance_valid(label_container):
			return

		label_container.get_parent().move_child(label_container, 0)

	initialize()

	# get current tab
	if tab_bar and tab_bar.get_active_tab().name == "home":
		label_container.hide()


func initialize() -> void:
	var meshes = {}
	var g = get_tree().get_nodes_in_group("Mesh")
	for mesh in g:
		meshes.set(str(mesh.name).to_lower(), mesh)

	# initialize
	for data in PlaceManager.data:
		var key := str(data.name).to_lower()
		if meshes.has(key):
			var mesh = meshes[key]
			_add_occluders(mesh)
			
			var label = label_scene.instantiate()
			label.name = data.name
			label_container.add_child(label)
			
			var button = label.get_node("info")
			# set button text
			button.text = data.name
			
			# no need to connect button event since info page script
			# already sets up control nodes in group Place Cards
			
			labels.append({
				"name": data.name,
				"label": label,
				"mesh": mesh,
				"occluded": false,
				"anchor_offset": _compute_anchor_offset(mesh)
			})


# Offset from the mesh origin to the point just above the top of the mesh.
# Measured once, so it costs nothing per frame.
func _compute_anchor_offset(root: Node3D) -> Vector3:
	var meshes: Array[Node] = []
	if root is MeshInstance3D:
		meshes.append(root)
	meshes.append_array(root.find_children("*", "MeshInstance3D", true, false))

	var combined := AABB()
	var found := false
	for node in meshes:
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		# Bounding box in world space (handles rotation and scale)
		var world_aabb: AABB = mi.global_transform * mi.get_aabb()
		if found:
			combined = combined.merge(world_aabb)
		else:
			combined = world_aabb
			found = true

	if not found:
		return Vector3(0, label_height_padding, 0)

	var top := Vector3(
		combined.position.x + combined.size.x * 0.5,
		combined.position.y + combined.size.y,
		combined.position.z + combined.size.z * 0.5
	)
	return (top - root.global_position) + Vector3(0, label_height_padding, 0)


func _add_occluders(root: Node) -> void:
	var targets: Array[Node] = []
	if root is MeshInstance3D:
		targets.append(root)
	targets.append_array(root.find_children("*", "MeshInstance3D", true, false))

	for node in targets:
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue

		# Skip if it already has a collision body (yours or from an earlier call)
		var has_body := false
		for child in mi.get_children():
			if child is StaticBody3D:
				has_body = true
				# Make sure existing bodies are on the occluder layer too
				child.collision_layer |= OCCLUDER_LAYER
				break
		if has_body:
			continue

		mi.create_trimesh_collision()
		var body := mi.get_child(mi.get_child_count() - 1) as StaticBody3D
		if body:
			body.collision_layer = OCCLUDER_LAYER
			body.collision_mask = 0


func _process(delta: float) -> void:
	if tab_bar == null or tab_bar.get_active_tab().name != "map":
		return

	if not is_instance_valid(camera) or not is_instance_valid(label_container):
		var current_scene = get_tree().current_scene

		if current_scene:
			camera = current_scene.get_node_or_null("World/camera/Camera3D")
			label_container = current_scene.get_node_or_null("Interface/scene_labels")

		if not is_instance_valid(camera) or not is_instance_valid(label_container):
			return

	# Raycasts are the expensive part, so only refresh occlusion a few times per second.
	var refresh_occlusion := false
	if hide_when_occluded:
		_occlusion_timer -= delta
		if _occlusion_timer <= 0.0:
			_occlusion_timer = occlusion_check_interval
			refresh_occlusion = true

	var space_state: PhysicsDirectSpaceState3D = null
	if refresh_occlusion:
		space_state = camera.get_world_3d().direct_space_state

	for item in labels:
		var mesh: Node3D = item["mesh"]
		var label: Control = item["label"]

		if not is_instance_valid(mesh):
			label.hide()
			continue

		var world_position := mesh.global_position
		var label_world_position: Vector3 = world_position + item["anchor_offset"]
		var distance := camera.global_position.distance_to(world_position)

		if camera.is_position_behind(label_world_position) or distance > max_label_distance:
			label.hide()
			continue

		# Occlusion still tests against the mesh itself, so a label is hidden
		# when the building is hidden, not when its floating label point is.
		if hide_when_occluded:
			if refresh_occlusion:
				item["occluded"] = _is_occluded(space_state, mesh, world_position)
			if item["occluded"]:
				label.hide()
				continue

		label.show()
		label.position = camera.unproject_position(label_world_position) - label.size / 2


func _is_occluded(space_state: PhysicsDirectSpaceState3D, mesh: Node3D, world_position: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		camera.global_position,
		world_position + occlusion_target_offset,
		occlusion_mask
	)
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return false # nothing in the way

	var collider := hit["collider"] as Node
	if collider == null:
		return false

	# Hitting the target's own collider means it's visible.
	if collider == mesh or mesh.is_ancestor_of(collider) or collider.is_ancestor_of(mesh):
		return false

	return true # something else is in front
