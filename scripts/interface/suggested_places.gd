# script for handling suggested places
extends Control

# settings
@export var parent: Control
@export var card: PackedScene
@export var amount: int = 5

func _ready() -> void:
	
	# wait until all script are done setting up
	await get_tree().create_timer(1).timeout
	
	if not parent or not card: return
	
	# wait for place manager to convert data
	while PlaceManager.data == null:
		await get_tree().process_frame
	
	# shuffle a copy so repeats are impossible
	var pool: Array = PlaceManager.data.duplicate()
	pool.shuffle()
	
	var added := 0
	for data in pool:
		if added >= amount:
			break
	
		var c = card.instantiate()
		c.name = data.name
		parent.add_child(c)
		
		# fill in contents (skip any node the card doesn't have)
		var title = c.get_node_or_null("title")
		if title: title.text = data.get("name", "")
		
		var subtitle = c.get_node_or_null("subtitle")
		if subtitle: subtitle.text = data.get("subtitle", "")
		
		added += 1
