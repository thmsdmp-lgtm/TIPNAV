# script for handling search related ui
extends Panel

# initialize
func _ready() -> void:
	# bind back button
	if has_node("back") and get_node("back") is Button:
		get_node("back").pressed.connect(Callable(self, "toggle").bind(false))
	
	# get all search box and setup events
	for search in get_tree().get_nodes_in_group("Search Bar"):
		if search is Control and search.has_node("Button"):
			search.get_node("Button").pressed.connect(Callable(self, "toggle").bind(true))

# toogle the search page
func toggle(mode:bool):
	if mode != null:
		visible = mode
	else:
		visible = not visible
