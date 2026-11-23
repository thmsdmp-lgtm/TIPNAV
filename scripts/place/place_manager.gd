# singleton for managing places
extends Node

# json data
var json_path:String = "res://data/places.json"

# data
var data = null

# initialize
func _ready() -> void:
	
	# convert data
	data = json_to_array(json_path)

# get a random place
func get_random_place():
	return data[randi_range(0,data.size() - 1)]

# get place data from name
func get_data(name:String):
	if name == null: return
	
	for place in data:
		if place.name == name:
			return place

# returns every place whose name contains the query (case-insensitive)
func search(query: String) -> Array:
	var q := query.strip_edges().to_lower()
	if q.is_empty():
		return []
	
	var starts: Array = []
	var contains: Array = []
	
	for place in data:
		var n: String = str(place.get("name", "")).to_lower()
		if n.begins_with(q):
			starts.append(place)
		elif n.contains(q):
			contains.append(place)
	
	# names that start with the query come first
	return starts + contains

# convert json to dict
func json_to_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("File not found: " + path)
		return []
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open file: " + path)
		return []
	
	var text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_error("JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return []
	
	if typeof(json.data) != TYPE_ARRAY:
		push_error("JSON root is not an array")
		return []
	
	return json.data
