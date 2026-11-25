# script to handle suggested categories
extends HBoxContainer

# json file path
@export_file("*.json") var json_path: String

# card scene
@export var card: PackedScene

# parent for cards
@export var parent:Control

# data
var categories:Array = []

# initialize
func _ready() -> void:
	if (not json_path
	or not card
	or not parent): return
	
	# load categories json.
	var text := FileAccess.get_file_as_string(json_path)
	categories = JSON.parse_string(text)
	
	# fill parent
	fill()

# fill
func fill():
	for category in categories:
		var texture = load(str("res://assets/icons/",category,".svg"))
		if not texture: return
		
		var c = card.instantiate()
		if c.has_node("AspectRatioContainer/Panel/TextureRect"): c.get_node("AspectRatioContainer/Panel/TextureRect").texture = texture
		if c.has_node("AspectRatioContainer/Panel/label"): c.get_node("AspectRatioContainer/Panel/label").text = category
		parent.add_child(c)
