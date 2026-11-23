extends Node

# holds all the rooms and offices loaded from places.json
var places: Array = []

# reference to the main UI controller (UI_main.gd)
var main_ui: Node = null

func _ready() -> void:
	_load_places_json()

# called by UI_main.gd on startup so this singleton knows where to send place data
func register_ui(ui_node: Node) -> void:
	main_ui = ui_node

# reads res://data/places.json to turn into places array
func _load_places_json() -> void:
	var path := "res://data/places.json"
	if not FileAccess.file_exists(path):
		push_warning("places.json not found at: " + path)
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		places = parsed
	elif parsed is Dictionary and parsed.has("places") and parsed["places"] is Array:
		places = parsed["places"]

# opens the place info screen for a selected room
func create_info(place_data: Dictionary) -> void:
	if main_ui and main_ui.has_method("display_place_info"):
		main_ui.display_place_info(place_data)
