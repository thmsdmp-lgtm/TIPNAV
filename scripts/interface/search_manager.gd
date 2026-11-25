# script for handling search related ui
extends Panel

@export var card:PackedScene
@export var card_container:Control
@export var back:Button
@export var open_position:int

var line

# initialize
func _ready() -> void:
	# bind back button
	if back: back.pressed.connect(Callable(self, "toggle").bind(false))
	
	# bind line edit
	if has_node("bar") and get_node("bar").has_node("line"):
		line = get_node("bar").get_node("line")
		line.text_changed.connect(Callable(self,"update_search").bind())
	
	# get all search box and setup events
	for search in get_tree().get_nodes_in_group("Search Bar"):
		if search is Control and search.has_node("Button"):
			search.get_node("Button").pressed.connect(Callable(self, "toggle").bind(true))

# called when the line edit is updated
# update search parameters
func update_search(text: String) -> void:
	if not card or not card_container: return
	
	# clear old results
	for child in card_container.get_children():
		child.queue_free()
	
	var results := PlaceManager.search(text)
	for place in results:
		var c = card.instantiate()
		c.name = place.get("name","")
		c.name = place.get("name","")
		if c.has_node("card"): c.get_node("card").name = place.get("name","")
		card_container.add_child(c)
		
		var title = c.get_node_or_null("title")
		if title: title.text = place.get("name", "")
		
		var subtitle = c.get_node_or_null("subtitle")
		if subtitle: subtitle.text = place.get("subtitle", "")

# toogle the search page
var tween
func toggle(mode:bool):
	if tween:
			tween.kill()
	
	if mode != null:
		if mode == true:
			tween = create_tween()
			tween.tween_property(self, "position", Vector2(0,open_position), 0.2).set_trans(Tween.TRANS_EXPO)
		else:
			tween = create_tween()
			tween.tween_property(self, "position", Vector2(0,get_viewport().get_visible_rect().size.y), 0.2).set_trans(Tween.TRANS_EXPO)
		tween.play()
	else:
		if position.y == 0:
			tween = create_tween()
			tween.tween_property(self, "position", Vector2(0,get_viewport().get_visible_rect().size.y), 0.2).set_trans(Tween.TRANS_EXPO)
		else:
			tween = create_tween()
			tween.tween_property(self, "position", Vector2(0,open_position), 0.2).set_trans(Tween.TRANS_EXPO)
		tween.play()
