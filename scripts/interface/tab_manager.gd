# script for handling tabs
extends Panel

# animation settings
@export_group("Tab Animation")
@export var active_ratio: float = 0.5
@export var animation_duration: float = 0.3
@export var animation_transition: Tween.TransitionType = Tween.TRANS_EXPO
@export var animation_ease: Tween.EaseType = Tween.EASE_OUT

# tab settings
@export_group("Tab Layout")
@export var bar_padding: float = 40
@export var button_spacing: float = 10

# variables
var _bar: Control
var _tween: Tween
var _buttons: Array[Button] = []

func _ready():
	
	for tab_button in get_tree().get_nodes_in_group("Tab Buttons"):
		if tab_button is Button and get_tab(tab_button.name):
			_bar = tab_button.get_parent()
			_buttons.append(tab_button)
			tab_button.pressed.connect(Callable(self, "switch_tab").bind(tab_button.name))
	
	update_buttons(false)

# switch tab
func switch_tab(tab_name: String):
	if not tab_name:
		return
	
	var target_tab = get_tab(tab_name)
	if target_tab == null:
		return
	
	var current_tab = get_active_tab()
	if current_tab == null:
		return
	
	if current_tab == target_tab:
		return
	
	current_tab.hide()
	target_tab.show()
	
	update_buttons()

# update/animates button sizes and position
func update_buttons(animate: bool = true):
	if _buttons.is_empty() or _bar == null:
		return
	
	var active_tab = get_active_tab()
	if active_tab == null:
		return
	
	var button_count = _buttons.size()
	
	# Calculate available space
	var available_width = _bar.size.x - (bar_padding * 2)
	available_width -= button_spacing * (button_count - 1)
	
	# Calculate button widths
	var active_width = available_width * active_ratio
	var inactive_width = (available_width - active_width) / (button_count - 1) if button_count > 1 else available_width
	
	# Stop previous animation
	if _tween and _tween.is_running():
		_tween.kill()
		
	if animate:
		_tween = create_tween()
		_tween.set_parallel(true)
		_tween.set_trans(animation_transition)
		_tween.set_ease(animation_ease)
	
	# Calculate positions and widths
	var current_x = bar_padding
	
	for button in _buttons:
		var target_width = active_width if button.name == active_tab.name else inactive_width
		var target_position = Vector2(current_x, button.position.y)
		
		if animate:
			_tween.tween_property(button, "size:x", target_width, animation_duration)
			_tween.tween_property(button, "position", target_position, animation_duration)
		else:
			button.size.x = target_width
			button.position = target_position
		
		current_x += target_width + button_spacing

# get tab from name
func get_tab(tab_name: String) -> Control:
	
	for tab in get_tree().get_nodes_in_group("Tabs"):
		if tab is Control and tab.name == tab_name:
			return tab
	
	return null


# get active tab
func get_active_tab() -> Control:
	
	for tab in get_tree().get_nodes_in_group("Tabs"):
		if tab is Control and tab.visible:
			return tab
	
	return null
