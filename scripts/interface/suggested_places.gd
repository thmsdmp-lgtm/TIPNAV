# script for handling suggested places
extends Control

# settings
@export var parent: Control
@export var card: PackedScene
@export var amount: int = 5
## If true, ignores "amount" and adds as many cards as fit inside the parent
@export var fit_to_parent: bool = false
## Gap between cards, used only to calculate how many fit.
## Match this to the spacing your layout class uses.
@export var card_spacing: Vector2 = Vector2(10, 10)

func _ready() -> void:
	
	# wait until all script are done setting up
	await get_tree().create_timer(1).timeout
	
	if not parent or not card: return
	
	# wait for place manager to convert data
	while PlaceManager.data == null:
		await get_tree().process_frame
	
	# decide how many cards to add
	var target := amount
	if fit_to_parent:
		target = await _get_fit_amount() 
	
	# shuffle a copy so repeats are impossible
	var pool: Array = PlaceManager.data.duplicate()
	pool.shuffle()
	
	var added := 0
	for data in pool:
		if added >= target:
			break
	
		var c = card.instantiate()
		if c.has_node("card"): c.get_node("card").name = data.name
		parent.add_child(c)
		
		# fill in contents (skip any node the card doesn't have)
		var title = c.get_node_or_null("title")
		if title: title.text = data.get("name", "")
		
		var subtitle = c.get_node_or_null("subtitle")
		if subtitle: subtitle.text = data.get("subtitle", "")
		
		added += 1


# measures one card and calculates how many fit inside the parent
func _get_fit_amount() -> int:
	# add a temporary card so its size gets calculated
	var sample = card.instantiate()
	parent.add_child(sample)
	await get_tree().process_frame
	var card_size: Vector2 = sample.get_combined_minimum_size()
	if card_size.x <= 0 or card_size.y <= 0:
		card_size = sample.size
	parent.remove_child(sample)
	sample.queue_free()
	
	# can't measure, fall back to the fixed amount
	if card_size.x <= 0 or card_size.y <= 0:
		push_warning("Card has no size, using amount instead")
		return amount
	
	var space: Vector2 = parent.size
	
	# conservative: every card (including the last) counts its spacing
	var cols := maxi(floori(space.x / (card_size.x + card_spacing.x)), 1)
	var rows := maxi(floori(space.y / (card_size.y + card_spacing.y)), 1)
	var fit := cols * rows
	
	print("fit check -> space: ", space, " card: ", card_size, " cols: ", cols, " rows: ", rows, " fit: ", fit)
	return fit
