# script for handling info page opening and functionalities
extends Control

# service card
@export var service_card:PackedScene

# service card container
@export var service_container:Control

# buttons
@export var back_button:Button

# labels
@export var title: AutoSizeLabel
@export var subtitle: AutoSizeLabel
@export var category: AutoSizeLabel
@export var location: AutoSizeLabel
@export var hours: AutoSizeLabel
@export var about: AutoSizeLabel

# setup events
func _ready() -> void:
	if back_button: back_button.pressed.connect(Callable(self,"toggle_info_vis").bind(false))
	get_tree().node_added.connect(_on_added)

# fillout info page
func fill_info(card_name: String):
	
	# get data
	var data = PlaceManager.get_data(card_name)
	
	# check if data exists
	if data:
		# fill in info
		if title: title.text = data.name
		if subtitle: subtitle.text = data.subtitle
		if category: category.text = str("● ",data.category)
		if location: location.text = data.location
		if hours: hours.text = data.hours
		if about: about.text = data.description
		
		# create service cards
		if service_card:
			for service in data.services:
				var card = service_card.instantiate()
				if card.has_node("container/label"): card.get_node("container/label").text = service
				service_container.add_child(card)
				
				card.custom_minimum_size = Vector2(randf_range(1.5,3.0) * 150, 80)
		
		# fill services
		return true
	else: return false

# make info page visible or no
func toggle_info_vis(mode:bool):
	if mode != null:
		visible = mode
	else:
		visible = not visible

# when new card is added
func _on_added(node: Node) -> void:
	# Wait 1 frame so the node can finish setup/renaming
	await get_tree().process_frame
	
	if not is_instance_valid(node):
		return
	
	if node.is_in_group("Place Cards") and node.has_node("info"):
		var button: Button = node.get_node("info")
		
		button.pressed.connect(func():
			if fill_info(node.name):
				toggle_info_vis(true))
