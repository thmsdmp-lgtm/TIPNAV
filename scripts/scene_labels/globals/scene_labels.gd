extends Control

var labels: Array[Dictionary] = []
var label_scene: PackedScene = preload("res://scenes/scene_label.tscn")

@export_group("Label Visibility")
@export var max_label_distance: float = 100

var camera: Camera3D
var label_container: Control

func _ready() -> void:
	await get_tree().process_frame
	var current_scene = get_tree().current_scene
	var tab_bar
	
	if current_scene:
		camera = current_scene.get_node_or_null("World/camera/Camera3D")
		label_container = current_scene.get_node_or_null("Interface/scene_labels")
		label_container.get_parent().move_child(label_container, 0)
		tab_bar = current_scene.get_node_or_null("%tab_bar")
		
		if not is_instance_valid(camera) or not is_instance_valid(label_container):
			return
	
	initialize()
	
	# get current tab
	if tab_bar.get_active_tab().name == "home":
		label_container.hide()

func initialize() -> void:
	
	var meshes = {}
	var g = get_tree().get_nodes_in_group("Mesh")
	for mesh in g:
		meshes.set(mesh.name,mesh)
	
	# initialize
	for data in PlaceManager.data:
		if meshes.has(data.name):
			var mesh = meshes[data.name]
			var label = label_scene.instantiate()
			label.name = data.name
			label_container.add_child(label)
			
			var button = label.get_node("info")
			# set button text
			button.text = data.name
			
			# no need to connect button event since info page script
			# already sets up control nodes in group Place Cards
			
			labels.append({
				"name":data.name,
				"label": label,
				"mesh": mesh
			})

func _process(_delta: float) -> void:
	if not is_instance_valid(camera):
		var current_scene = get_tree().current_scene
		
		if current_scene:
			camera = current_scene.get_node_or_null("World/camera/Camera3D")
			label_container = current_scene.get_node_or_null("Interface/scene_labels")
		
		if not is_instance_valid(camera) or not is_instance_valid(label_container):
			return
		
	for item in labels:
		var mesh: Node3D = item["mesh"]
		var label: Control = item["label"]

		if not is_instance_valid(mesh):
			label.hide()
			continue

		var world_position := mesh.global_position
		var distance := camera.global_position.distance_to(world_position)

		if camera.is_position_behind(world_position) or distance > max_label_distance:
			label.hide()
			continue

		label.show()
		label.position = camera.unproject_position(world_position) - label.size / 2
