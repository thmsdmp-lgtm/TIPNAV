# script for handling info page opening and functionalities
extends Panel

# back button
var back_button:Button

# setup events
func _ready() -> void:
	back_button = get_node("back")
	back_button.pressed.connect(Callable(self,"toggle_info_vis").bind(false))
	get_tree().node_added.connect(_on_added)

# fillout info page
func fill_info(card_name: String) -> void:
	print("Opening info for: ", card_name)

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
			fill_info(node.name)
			toggle_info_vis(true))
