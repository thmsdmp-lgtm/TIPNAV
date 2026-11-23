extends Node

# grab all the screen panels and buttons from the scene tree
@onready var ui_container: Control = $Ui if has_node("Ui") else self
@onready var screen_home: Panel = ui_container.get_node("home")
@onready var screen_search: Panel = ui_container.get_node("search")
@onready var screen_place_info: Panel = ui_container.get_node("place_info")
@onready var screen_categories: Panel = ui_container.get_node("categories")
@onready var screen_map: Panel = ui_container.get_node("map")
@onready var tabs_bar: Panel = ui_container.get_node("tabs")

# bottom footer tab buttons
@onready var btn_tab_home: Button = tabs_bar.get_node("home")
@onready var btn_tab_map: Button = tabs_bar.get_node("map")
@onready var btn_tab_categories: Button = tabs_bar.get_node("categories")

# back button on the place info screen
@onready var info_back_panel: Panel = screen_place_info.get_node("back")

# labels and containers we generate in code
var info_title_lbl: Label
var info_subtitle_lbl: Label
var info_meta_lbl: Label
var info_hours_lbl: Label
var info_desc_lbl: Label
var info_services_lbl: Label
var info_scroll: ScrollContainer

var search_line_edit: LineEdit
var search_scroll: ScrollContainer
var search_results_vbox: VBoxContainer
var categories_scroll: ScrollContainer
var categories_vbox: VBoxContainer

var previous_screen: String = "home"
var search_previous_screen: String = "home"
var current_place: Dictionary = {}

# used to tell if the user is dragging to scroll vs just tapping
var _drag_start_y: float = 0.0
var _is_dragging: bool = false

# custom icon list
class CategoryGlyph extends Control:
	var glyph_type: String = "lab"
	var stroke_color: Color = Color(0.24, 0.42, 0.64)
	
	func _draw() -> void:
		var c := size * 0.5
		var w := 2.6
		match glyph_type:
			"lab":
				# flask icon
				draw_line(c + Vector2(-6, -15), c + Vector2(6, -15), stroke_color, w)
				draw_line(c + Vector2(-4, -15), c + Vector2(-4, -5), stroke_color, w)
				draw_line(c + Vector2(4, -15), c + Vector2(4, -5), stroke_color, w)
				draw_line(c + Vector2(-4, -5), c + Vector2(-15, 14), stroke_color, w)
				draw_line(c + Vector2(4, -5), c + Vector2(15, 14), stroke_color, w)
				draw_line(c + Vector2(-15, 14), c + Vector2(15, 14), stroke_color, w)
				draw_line(c + Vector2(-9, 5), c + Vector2(9, 5), stroke_color, 2.0)
			"classroom":
				# book / board icon
				draw_rect(Rect2(c + Vector2(-15, -12), Vector2(30, 22)), stroke_color, false, w)
				draw_line(c + Vector2(0, -12), c + Vector2(0, 10), stroke_color, 2.0)
				draw_line(c + Vector2(-8, 15), c + Vector2(8, 15), stroke_color, w)
			"office":
				# building icon
				draw_rect(Rect2(c + Vector2(-13, -15), Vector2(26, 30)), stroke_color, false, w)
				draw_rect(Rect2(c + Vector2(-5, 5), Vector2(10, 10)), stroke_color, false, 2.0)
				draw_line(c + Vector2(-7, -7), c + Vector2(-3, -7), stroke_color, w)
				draw_line(c + Vector2(3, -7), c + Vector2(7, -7), stroke_color, w)
				draw_line(c + Vector2(-7, -1), c + Vector2(-3, -1), stroke_color, w)
				draw_line(c + Vector2(3, -1), c + Vector2(7, -1), stroke_color, w)
			"finance":
				# card icon
				draw_rect(Rect2(c + Vector2(-16, -11), Vector2(32, 22)), stroke_color, false, w)
				draw_line(c + Vector2(-16, -4), c + Vector2(16, -4), stroke_color, w)
				draw_line(c + Vector2(-10, 4), c + Vector2(-2, 4), stroke_color, w)
			"search":
				# magnifying glass icon
				draw_arc(c + Vector2(-3, -3), 10.0, 0.0, TAU, 24, stroke_color, w)
				draw_line(c + Vector2(4, 4), c + Vector2(13, 13), stroke_color, w)
			"pin":
				# location pin icon
				draw_arc(c + Vector2(0, -4), 9.0, 0.0, TAU, 24, stroke_color, w)
				draw_circle(c + Vector2(0, -4), 3.0, stroke_color)
				draw_line(c + Vector2(-7, 2), c + Vector2(0, 14), stroke_color, w)
				draw_line(c + Vector2(7, 2), c + Vector2(0, 14), stroke_color, w)

func _ready() -> void:
	# register this UI with the global singleton
	ui_singleton.register_ui(self)
	
	# reset home screen scroll position and keep footer tabs on top
	screen_home.offset_top = 0.0
	screen_home.offset_bottom = 0.0
	ui_container.move_child(tabs_bar, -1)
	
	# build all the UI pages and connect card taps
	_setup_place_info_template()
	_setup_search_screen()
	_setup_categories_screen()
	_setup_home_interactions()
	_setup_map_cards()
	
	# hook up footer tab buttons
	btn_tab_home.pressed.connect(func(): switch_screen("home"))
	btn_tab_map.pressed.connect(func(): switch_screen("map"))
	btn_tab_categories.pressed.connect(func(): switch_screen("categories"))
	
	# back button on the info page
	_make_panel_clickable(info_back_panel, func(): switch_screen(previous_screen))
	
	# start on home
	switch_screen("home")

# mouse things
func _input(event: InputEvent) -> void:
	# pc mouse wheel
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_active_screen(55.0)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_active_screen(-55.0)
			return
	
	# track when finger/mouse presses down or lifts up
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start_y = event.position.y
			_is_dragging = false
		else:
			_is_dragging = false
	
	# only start scrolling if dragged more than 8px so taps still work
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		if absf(event.position.y - _drag_start_y) > 8.0:
			_is_dragging = true
		if _is_dragging:
			_scroll_active_screen(event.relative.y)

# scrolls whichever page is currently open
func _scroll_active_screen(delta_y: float) -> void:
	if screen_home.visible:
		# check where the lowest card ends so we don't scroll past it into empty space
		var lowest_y: float = 0.0
		for child in screen_home.get_children():
			if child is Control and child.visible:
				lowest_y = maxf(lowest_y, child.position.y + child.size.y)
		
		var visible_height: float = screen_home.size.y - tabs_bar.size.y - 40.0
		var max_scroll: float = minf(0.0, -(lowest_y - visible_height))
		screen_home.offset_top = clampf(screen_home.offset_top + delta_y, max_scroll, 0.0)
		screen_home.offset_bottom = screen_home.offset_top
	elif screen_search.visible and search_scroll:
		search_scroll.scroll_vertical = maxi(0, search_scroll.scroll_vertical - int(delta_y))
	elif screen_categories.visible and categories_scroll:
		categories_scroll.scroll_vertical = maxi(0, categories_scroll.scroll_vertical - int(delta_y))
	elif screen_place_info.visible and info_scroll:
		info_scroll.scroll_vertical = maxi(0, info_scroll.scroll_vertical - int(delta_y))

# --- PLACE INFO PAGE ---

# fills the info page with data from places.json (called by ui_singleton.create_info)
func display_place_info(data: Dictionary) -> void:
	current_place = data
	
	info_title_lbl.text = str(data.get("name", "Campus Location"))
	info_subtitle_lbl.text = str(data.get("subtitle", ""))
	info_meta_lbl.text = "%s  •  %s  •  %s" % [
		str(data.get("category", "")),
		str(data.get("location", "")),
		str(data.get("room", ""))
	]
	info_hours_lbl.text = "Hours: " + str(data.get("hours", "N/A"))
	info_desc_lbl.text = str(data.get("description", "No description available."))
	
	var services: Array = data.get("services", [])
	info_services_lbl.text = "Services: " + (", ".join(PackedStringArray(services)) if services.size() > 0 else "General Access")
	
	# scroll back to top whenever a new place opens
	if info_scroll:
		info_scroll.scroll_vertical = 0
	
	if not screen_place_info.visible:
		previous_screen = _get_active_screen_name()
	switch_screen("place_info")

# builds the text labels and navigate button inside place_info
func _setup_place_info_template() -> void:
	var back_lbl := Label.new()
	back_lbl.text = "←"
	back_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back_lbl.add_theme_font_size_override("font_size", 32)
	back_lbl.add_theme_color_override("font_color", Color(0.1, 0.12, 0.2))
	back_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_back_panel.add_child(back_lbl)
	
	info_scroll = ScrollContainer.new()
	info_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_scroll.offset_left = 48
	info_scroll.offset_right = -48
	info_scroll.offset_top = 420
	info_scroll.offset_bottom = -60
	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	info_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	screen_place_info.add_child(info_scroll)
	
	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 18)
	info_scroll.add_child(content_vbox)
	
	info_title_lbl = _make_label(38, Color(0.08, 0.1, 0.18), true)
	info_subtitle_lbl = _make_label(24, Color(0.3, 0.33, 0.42), true)
	info_meta_lbl = _make_label(22, Color(0.35, 0.4, 0.65), true)
	info_hours_lbl = _make_label(22, Color(0.2, 0.22, 0.28), false)
	info_desc_lbl = _make_label(22, Color(0.25, 0.27, 0.33), true)
	info_services_lbl = _make_label(21, Color(0.15, 0.35, 0.55), true)
	
	for lbl in [info_title_lbl, info_subtitle_lbl, info_meta_lbl, info_hours_lbl, info_desc_lbl, info_services_lbl]:
		content_vbox.add_child(lbl)
	
	# button that switches to the map view
	var nav_btn := Button.new()
	nav_btn.text = "Navigate to Place"
	nav_btn.custom_minimum_size = Vector2(0, 72)
	nav_btn.mouse_filter = Control.MOUSE_FILTER_PASS
	nav_btn.add_theme_font_size_override("font_size", 24)
	nav_btn.pressed.connect(_on_navigate_pressed)
	content_vbox.add_child(nav_btn)

func _on_navigate_pressed() -> void:
	if _is_dragging:
		return
	switch_screen("map")

# --- SEARCH PAGE ---

func _setup_search_screen() -> void:
	# back button returns to whichever screen opened search
	var search_back_panel: Panel = screen_search.get_node("search/search2")
	var back_lbl := Label.new()
	back_lbl.text = "←"
	back_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back_lbl.add_theme_font_size_override("font_size", 28)
	back_lbl.add_theme_color_override("font_color", Color(0.12, 0.14, 0.2))
	back_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	search_back_panel.add_child(back_lbl)
	_make_panel_clickable(search_back_panel, func(): switch_screen(search_previous_screen))
	
	# transparent text box inside the white search bar pill
	var search_bar_panel: Panel = screen_search.get_node("search")
	search_line_edit = LineEdit.new()
	search_line_edit.placeholder_text = "Search rooms, labs, offices..."
	search_line_edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	search_line_edit.offset_left = 28
	search_line_edit.offset_right = -24
	search_line_edit.add_theme_font_size_override("font_size", 23)
	search_line_edit.add_theme_color_override("font_color", Color(0.1, 0.12, 0.18))
	search_line_edit.add_theme_color_override("font_placeholder_color", Color(0.55, 0.58, 0.65))
	search_line_edit.add_theme_color_override("caret_color", Color(0.24, 0.42, 0.64))
	search_line_edit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	search_line_edit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	search_line_edit.text_changed.connect(_filter_search_results)
	search_bar_panel.add_child(search_line_edit)
	
	# scrollable list for search result cards
	search_scroll = ScrollContainer.new()
	search_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	search_scroll.offset_left = 44
	search_scroll.offset_right = -44
	search_scroll.offset_top = 185
	search_scroll.offset_bottom = -190
	search_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	search_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	screen_search.add_child(search_scroll)
	
	search_results_vbox = VBoxContainer.new()
	search_results_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_results_vbox.add_theme_constant_override("separation", 18)
	search_scroll.add_child(search_results_vbox)

# --- CATEGORIES PAGE ---

func _setup_categories_screen() -> void:
	# hide the raw placeholder bar on categories
	if screen_categories.has_node("search"):
		screen_categories.get_node("search").visible = false
	
	var back_btn := Button.new()
	back_btn.text = "←"
	back_btn.flat = true
	back_btn.position = Vector2(36, 36)
	back_btn.size = Vector2(64, 64)
	back_btn.add_theme_font_size_override("font_size", 32)
	back_btn.add_theme_color_override("font_color", Color(0.12, 0.14, 0.2))
	back_btn.pressed.connect(func(): switch_screen("home"))
	screen_categories.add_child(back_btn)
	
	var title_lbl := Label.new()
	title_lbl.text = "All Categories"
	title_lbl.position = Vector2(48, 120)
	title_lbl.add_theme_font_size_override("font_size", 36)
	title_lbl.add_theme_color_override("font_color", Color(0.1, 0.12, 0.18))
	screen_categories.add_child(title_lbl)
	
	# top-right search icon shortcut
	var search_icon_btn := Control.new()
	search_icon_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	search_icon_btn.offset_left = -104
	search_icon_btn.offset_right = -44
	search_icon_btn.offset_top = 116
	search_icon_btn.offset_bottom = 176
	screen_categories.add_child(search_icon_btn)
	
	var search_glyph := CategoryGlyph.new()
	search_glyph.glyph_type = "search"
	search_glyph.stroke_color = Color(0.15, 0.18, 0.24)
	search_glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	search_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	search_icon_btn.add_child(search_glyph)
	_make_panel_clickable(search_icon_btn, _on_home_search_tapped)
	
	categories_scroll = ScrollContainer.new()
	categories_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	categories_scroll.offset_left = 44
	categories_scroll.offset_right = -44
	categories_scroll.offset_top = 205
	categories_scroll.offset_bottom = -190
	categories_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	categories_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	screen_categories.add_child(categories_scroll)
	
	categories_vbox = VBoxContainer.new()
	categories_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories_vbox.add_theme_constant_override("separation", 20)
	categories_scroll.add_child(categories_vbox)
	
	# the 4 main categories
	var categories_data := [
		{"title": "Laboratories", "query": "Laborator", "glyph": "lab"},
		{"title": "Classrooms", "query": "Classroom", "glyph": "classroom"},
		{"title": "Administrative Offices", "query": "Office", "glyph": "office"},
		{"title": "Finance & Cashier", "query": "Cashier", "glyph": "finance"}
	]
	
	for cat in categories_data:
		categories_vbox.add_child(_create_category_row_card(cat))

# builds one white category card with pastel sky-blue badge and place count
func _create_category_row_card(cat: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 128)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 1, 1, 1)
	card_style.set_corner_radius_all(26)
	card_style.border_color = Color(0.91, 0.92, 0.95)
	card_style.set_border_width_all(2)
	card_style.shadow_color = Color(0, 0, 0, 0.05)
	card_style.shadow_size = 10
	card_style.shadow_offset = Vector2(0, 4)
	card_style.content_margin_left = 22
	card_style.content_margin_right = 26
	card_style.content_margin_top = 18
	card_style.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", card_style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 22)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hbox)
	
	# pastel sky-blue icon box
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(88, 88)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.86, 0.93, 0.99)
	badge_style.set_corner_radius_all(22)
	badge.add_theme_stylebox_override("panel", badge_style)
	hbox.add_child(badge)
	
	var glyph := CategoryGlyph.new()
	glyph.glyph_type = cat["glyph"]
	glyph.stroke_color = Color(0.24, 0.42, 0.64)
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(glyph)
	
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_vbox.add_theme_constant_override("separation", 4)
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_vbox)
	
	var name_lbl := Label.new()
	name_lbl.text = cat["title"]
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", Color(0.12, 0.14, 0.2))
	text_vbox.add_child(name_lbl)
	
	var count := _count_places_for_query(cat["query"])
	var count_lbl := Label.new()
	count_lbl.text = "%d Places" % count
	count_lbl.add_theme_font_size_override("font_size", 20)
	count_lbl.add_theme_color_override("font_color", Color(0.52, 0.55, 0.62))
	text_vbox.add_child(count_lbl)
	
	var arrow_lbl := Label.new()
	arrow_lbl.text = "›"
	arrow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_lbl.add_theme_font_size_override("font_size", 36)
	arrow_lbl.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55))
	hbox.add_child(arrow_lbl)
	
	_make_panel_clickable(card, _on_category_selected.bind(cat["query"], cat["title"]))
	return card

# connects rooms to each category
func _count_places_for_query(query: String) -> int:
	if query == "":
		return ui_singleton.places.size()
	var q := query.to_lower()
	var total := 0
	for place in ui_singleton.places:
		var blob := (
			str(place.get("name", "")) + " " +
			str(place.get("category", "")) + " " +
			str(place.get("subtitle", ""))
		).to_lower()
		if blob.contains(q):
			total += 1
	return total

func _on_category_selected(query: String, display_title: String) -> void:
	switch_screen("search")
	search_line_edit.text = display_title if query != "" else ""
	_filter_search_results(query)

# --- HOME & MAP INTERACTIONS ---

func _setup_home_interactions() -> void:
	_make_panel_clickable(screen_home.get_node("search"), _on_home_search_tapped)
	_make_panel_clickable(screen_home.get_node("map_card1"), func(): switch_screen("map"))
	if screen_home.has_node("map_card2"):
		_make_panel_clickable(screen_home.get_node("map_card2"), func(): switch_screen("map"))
	
	# hook up the 3 duplicated suggested place cards (place_card, place_card2, place_card3)
	var home_place_cards := ["place_card", "place_card2", "place_card3"]
	for i in range(home_place_cards.size()):
		if screen_home.has_node(home_place_cards[i]):
			var card: Control = screen_home.get_node(home_place_cards[i])
			_ignore_children_mouse(card)
			_make_panel_clickable(card, _on_home_place_tapped.bind(i))
	
	# hook up the 4 duplicated category bubbles on Home
	var fallback_cats := [
		{"query": "Laborator", "title": "Laboratories"},
		{"query": "Classroom", "title": "Classrooms"},
		{"query": "Office", "title": "Administrative Offices"},
		{"query": "Cashier", "title": "Finance & Cashier"}
	]
	var cat_names := ["category_card", "category_card2", "category_card3", "category_card4"]
	for i in range(cat_names.size()):
		if not screen_home.has_node(cat_names[i]):
			continue
		var cat_node: Control = screen_home.get_node(cat_names[i])
		_ignore_children_mouse(cat_node)
		
		# collect this node's name plus all nested child names to detect which category it is
		var label_hint := _collect_node_names(cat_node)
		if label_hint.contains("lab"):
			_make_panel_clickable(cat_node, _on_category_selected.bind("Laborator", "Laboratories"))
		elif label_hint.contains("class"):
			_make_panel_clickable(cat_node, _on_category_selected.bind("Classroom", "Classrooms"))
		elif label_hint.contains("admin") or label_hint.contains("office"):
			_make_panel_clickable(cat_node, _on_category_selected.bind("Office", "Administrative Offices"))
		elif label_hint.contains("finance") or label_hint.contains("cashier"):
			_make_panel_clickable(cat_node, _on_category_selected.bind("Cashier", "Finance & Cashier"))
		else:
			_make_panel_clickable(cat_node, _on_category_selected.bind(fallback_cats[i]["query"], fallback_cats[i]["title"]))

func _on_home_search_tapped() -> void:
	switch_screen("search")
	search_line_edit.grab_focus()
	_filter_search_results("")

func _on_home_place_tapped(idx: int) -> void:
	if idx < ui_singleton.places.size():
		ui_singleton.create_info(ui_singleton.places[idx])

func _setup_map_cards() -> void:
	if screen_map.has_node("search/search2"):
		var map_back: Panel = screen_map.get_node("search/search2")
		_make_panel_clickable(map_back, func(): switch_screen("home"))
	
	if screen_map.has_node("search"):
		var map_search: Panel = screen_map.get_node("search")
		_make_panel_clickable(map_search, _on_home_search_tapped)
	
	# hook up the 3 floating place cards at the bottom of the map
	var card_names := ["place_card", "place_card2", "place_card3"]
	for i in range(card_names.size()):
		if screen_map.has_node(card_names[i]):
			var card: Panel = screen_map.get_node(card_names[i])
			_ignore_children_mouse(card)
			_make_panel_clickable(card, _on_map_card_tapped.bind(i))

func _on_map_card_tapped(idx: int) -> void:
	if idx < ui_singleton.places.size():
		ui_singleton.create_info(ui_singleton.places[idx])

# --- LIVE SEARCH & SCREEN SWITCHING ---

# rebuilds the search results list whenever you type
func _filter_search_results(query: String) -> void:
	for child in search_results_vbox.get_children():
		child.queue_free()
	
	var q := query.strip_edges().to_lower()
	for place in ui_singleton.places:
		var blob := (
			str(place.get("name", "")) + " " +
			str(place.get("category", "")) + " " +
			str(place.get("subtitle", "")) + " " +
			str(place.get("location", "")) + " " +
			str(place.get("room", "")) + " " +
			" ".join(PackedStringArray(place.get("services", [])))
		).to_lower()
		
		if q == "" or blob.contains(q):
			search_results_vbox.add_child(_create_search_result_card(place))

# builds a white rounded card for each search result
func _create_search_result_card(place: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 114)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 1, 1, 1)
	card_style.set_corner_radius_all(24)
	card_style.border_color = Color(0.91, 0.92, 0.95)
	card_style.set_border_width_all(2)
	card_style.shadow_color = Color(0, 0, 0, 0.05)
	card_style.shadow_size = 8
	card_style.shadow_offset = Vector2(0, 3)
	card_style.content_margin_left = 20
	card_style.content_margin_right = 24
	card_style.content_margin_top = 16
	card_style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", card_style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hbox)
	
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(76, 76)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.86, 0.93, 0.99)
	badge_style.set_corner_radius_all(20)
	badge.add_theme_stylebox_override("panel", badge_style)
	hbox.add_child(badge)
	
	var glyph := CategoryGlyph.new()
	glyph.glyph_type = "pin"
	glyph.stroke_color = Color(0.24, 0.42, 0.64)
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(glyph)
	
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_vbox.add_theme_constant_override("separation", 4)
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_vbox)
	
	var name_lbl := Label.new()
	name_lbl.text = str(place.get("name", ""))
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(0.12, 0.14, 0.2))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_vbox.add_child(name_lbl)
	
	var sub_lbl := Label.new()
	sub_lbl.text = "%s • %s" % [str(place.get("location", "")), str(place.get("room", ""))]
	sub_lbl.add_theme_font_size_override("font_size", 19)
	sub_lbl.add_theme_color_override("font_color", Color(0.52, 0.55, 0.62))
	text_vbox.add_child(sub_lbl)
	
	var arrow_lbl := Label.new()
	arrow_lbl.text = "›"
	arrow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_lbl.add_theme_font_size_override("font_size", 34)
	arrow_lbl.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55))
	hbox.add_child(arrow_lbl)
	
	_make_panel_clickable(card, _on_search_result_pressed.bind(place))
	return card

func _on_search_result_pressed(place: Dictionary) -> void:
	if _is_dragging:
		return
	ui_singleton.create_info(place)

# switches between screens and hides/shows the footer tabs
func switch_screen(target: String) -> void:
	if target == "search" and not screen_search.visible:
		search_previous_screen = _get_active_screen_name()
	
	screen_home.visible = (target == "home")
	screen_search.visible = (target == "search")
	screen_place_info.visible = (target == "place_info")
	screen_categories.visible = (target == "categories")
	screen_map.visible = (target == "map")
	
	tabs_bar.visible = (target != "place_info")
	
	# make map panel transparent so the 3D viewport shows behind it
	if target == "map":
		screen_map.self_modulate = Color(1, 1, 1, 0)
	
	if target == "search" and search_results_vbox.get_child_count() == 0:
		_filter_search_results("")

func _get_active_screen_name() -> String:
	if screen_search.visible: return "search"
	if screen_categories.visible: return "categories"
	if screen_map.visible: return "map"
	return "home"

# --- HELPERS ---

# sets mouse_filter = IGNORE on all nested children so parent cards receive every tap
func _ignore_children_mouse(root: Node) -> void:
	for child in root.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_children_mouse(child)

# returns a lowercase string of all node names inside a card for matching
func _collect_node_names(root: Node) -> String:
	var result := root.name.to_lower() + " "
	for child in root.get_children():
		result += _collect_node_names(child)
	return result

# makes Control/Panel nodes clickable while ignoring taps after a scroll drag
func _make_panel_clickable(panel: Control, callback: Callable) -> void:
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_panel_gui_input.bind(callback))

func _on_panel_gui_input(event: InputEvent, callback: Callable) -> void:
	if _is_dragging:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		callback.call()

@warning_ignore("shadowed_global_identifier")
func _make_label(size: int, color: Color, wrap: bool) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	if wrap:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl
