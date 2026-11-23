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
	
	# initialize buildings
	for node in get_tree().get_nodes_in_group("Buildings"):
		if node is Node3D:
			var label = label_scene.instantiate()
			label_container.add_child(label)
			
			var button = label.get_node("button")
			button.text = node.name
			button.pressed.connect(Callable(self, "_on_label_pressed").bind(node))
			
			labels.append({
				"label": label,
				"building": node
			})
	
	# initialize places
	for node in get_tree().get_nodes_in_group("Places"):
		if node is Node3D:
			var label = label_scene.instantiate()
			label_container.add_child(label)
			
			var button = label.get_node("button")
			button.text = node.name
			button.pressed.connect(_on_label_pressed(node))
			
			labels.append({
				"label": label,
				"place": node
			})

# function called when a label button is pressed
func _on_label_pressed(place:Node3D):
	
	# get place data
	var data = PlaceManager.get_data(place.name)
	print(data)
	
	if data == null: return

func _process(_delta: float) -> void:
	if not is_instance_valid(camera):
		var current_scene = get_tree().current_scene
		
		if current_scene:
			camera = current_scene.get_node_or_null("World/camera/Camera3D")
			label_container = current_scene.get_node_or_null("Interface/scene_labels")
		
		if not is_instance_valid(camera) or not is_instance_valid(label_container):
			return
		
	for item in labels:
		var building: Node3D = item.get("building", item.get("place"))
		var label: Control = item["label"]
		
		if not is_instance_valid(building):
			label.hide()
			continue
		
		var world_position = building.global_position
		
		# Check distance from camera
		var distance = camera.global_position.distance_to(world_position)
		
		if item.has("place"):
			if camera.is_position_behind(world_position) or distance > max_label_distance / 2:
				label.hide()
				continue
		else:
			if camera.is_position_behind(world_position) or distance > max_label_distance:
				label.hide()
				continue
			
		label.show()
		label.position = camera.unproject_position(world_position) - label.size / 2
