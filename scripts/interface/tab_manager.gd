# script for handling tabs
extends Panel

@export var button_padding: float = 12 ## side padding inside the active button
var _active_width: float = 0.0

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
@export var icon_label_gap: float = 8 ## space between icon and text when active

# variables
var _bar: Control
var _tween: Tween
var _buttons: Dictionary = {}
var _reveal: Dictionary = {}   # button -> 0.0 (icon only) .. 1.0 (icon + text)
var _icons: Dictionary = {}    # button -> TextureRect
var _labels: Dictionary = {}   # button -> Label
var _icon_sizes: Dictionary = {}   # button -> Vector2 (inspector size, read once)
var _label_sizes: Dictionary = {}  # button -> Vector2 (inspector size, read once)

func _ready():
	
	for tab_button in get_tree().get_nodes_in_group("Tab Buttons"):
		if tab_button is Button and get_tab(tab_button.name):
			_bar = tab_button.get_parent()
			_buttons.set(tab_button.name,tab_button)
			tab_button.self_modulate.a = 0
			tab_button.pressed.connect(Callable(self, "switch_tab").bind(tab_button.name))
			_setup_button_content(tab_button)
	
	update_buttons(false)

# finds the icon/label children and keeps them from eating clicks
func _setup_button_content(button: Button) -> void:
	for child in button.get_children():
		if child is TextureRect and not _icons.has(button):
			_icons[button] = child
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_icon_sizes[button] = child.size
			child.set_anchors_preset(Control.PRESET_TOP_LEFT)
			child.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			child.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_icon_sizes[button] = child.custom_minimum_size if child.custom_minimum_size != Vector2.ZERO else child.size
		elif child is AutoSizeLabel and not _labels.has(button):
			_labels[button] = child
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_label_sizes[button] = child.size
	
	_reveal[button] = 0.0
	button.resized.connect(_layout_button.bind(button))
	

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
	
	# update labels
	if target_tab.name == "home":
		SceneLabels.label_container.visible = false
	else:
		SceneLabels.label_container.visible = true
	
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
	_active_width = active_width
	
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
	
	for button_name in _buttons:
		var button = _buttons[button_name]
		var is_active: bool = button.name == active_tab.name
		var target_width = active_width if is_active else inactive_width
		var target_position = Vector2(current_x, button.position.y)
		var target_reveal := 1.0 if is_active else 0.0
		var target_alpha := 1.0 if is_active else 0.0
		
		if animate:
			_tween.tween_property(button, "size:x", target_width, animation_duration)
			_tween.tween_property(button, "position", target_position, animation_duration)
			_tween.tween_property(button, "self_modulate:a", target_alpha, animation_duration*3)
			_tween.tween_method(_set_reveal.bind(button), _reveal[button], target_reveal, animation_duration)
		else:
			button.size.x = target_width
			button.position = target_position
			button.self_modulate.a = target_alpha
			_set_reveal(target_reveal, button)
		
		current_x += target_width + button_spacing

# called by the tween (and directly when not animating)
func _set_reveal(value: float, button: Button) -> void:
	_reveal[button] = value
	_layout_button(button)

# positions the icon + label inside a button based on its current width and reveal value
func _layout_button(button: Button) -> void:
	var icon: TextureRect = _icons.get(button)
	var label: Label = _labels.get(button)
	if icon == null:
		return
	
	var p: float = _reveal.get(button, 0.0)
	var icon_size: Vector2 = _icon_sizes[button]
	
	# Icon alone, centered
	var rest_x := (button.size.x - icon_size.x) * 0.5
	var icon_x := rest_x
	
	if label:
		var label_size: Vector2 = _label_sizes[button]
		
		# Icon + text, centered as a group
		var group_w := icon_size.x + icon_label_gap + label_size.x
		var active_x := maxf((button.size.x - group_w) * 0.5, 0.0)
		icon_x = lerpf(rest_x, active_x, p)
		
		label.visible_ratio = p
		label.position.x = icon_x + icon_size.x + icon_label_gap
		label.position.y = (button.size.y - label_size.y) * 0.5
	
	icon.position.x = icon_x
	icon.position.y = (button.size.y - icon_size.y) * 0.5

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
