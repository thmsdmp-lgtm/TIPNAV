# TIP nav uigodot branch
extends Control

@onready var view_container: ScrollContainer = find_child("ViewContainer", true, false)
@onready var home_content: Control = find_child("HomeContent", true, false)
@onready var category_content: Control = find_child("CategoryContent", true, false)
@onready var search_view: Control = find_child("SearchView", true, false)
@onready var detail_view: Control = find_child("DetailView", true, false)

@onready var btn_home: Button = find_child("BtnHome", true, false)
@onready var btn_category: Button = find_child("BtnCategory", true, false)
@onready var btn_search_back: Button = find_child("BtnSearchBack", true, false)
@onready var btn_detail_back: Button = find_child("BtnDetailBack", true, false)
@onready var btn_detail_search: Button = find_child("BtnDetailSearch", true, false)

@onready var search_places_input: LineEdit = find_child("SearchPlacesInput", true, false)
@onready var search_categories_input: LineEdit = find_child("SearchCategoriesInput", true, false)
@onready var category_header_label: Label = find_child("CategoryHeaderLabel", true, false)
@onready var results_list: VBoxContainer = find_child("ResultsList", true, false)

# DetailView automated target nodes
@onready var detail_title: Label = find_child("DetailTitle", true, false)
@onready var detail_subtitle: Label = find_child("DetailSubtitle", true, false)
@onready var badge_building: Label = find_child("BadgeBuilding", true, false)
@onready var badge_floor: Label = find_child("BadgeFloor", true, false)
@onready var detail_description: Label = find_child("DetailDescription", true, false)
@onready var val_hours: Label = find_child("ValHours", true, false)
@onready var val_room: Label = find_child("ValRoom", true, false)
@onready var val_in_charge: Label = find_child("ValInCharge", true, false)
@onready var services_container: Container = find_child("ServicesContainer", true, false)

var previous_tab: String = "home"
var tab_before_detail: String = "search"
var current_category_filter: String = "All"

var places_data: Array[Dictionary] = [
	{
		"name": "Computer Lab 1",
		"category": "Laboratories",
		"subtitle": "Information Technology Department",
		"building": "Bldg 5",
		"floor": "3F",
		"location": "Building 5 • 3rd Floor",
		"room": "Room 5301",
		"hours": "7:30 AM - 8:30 PM",
		"in_charge": "ITSO / Lab Coordinator",
		"description": "Equipped with desktop workstations for programming, software development, and 3D modeling classes.",
		"services": ["PC Workstations", "LAN Internet", "Air Conditioned", "Projector"]
	},
	{
		"name": "Physics & Chemistry Lab",
		"category": "Laboratories",
		"subtitle": "Math & Science Department",
		"building": "Bldg 2",
		"floor": "2F",
		"location": "Building 2 • 2nd Floor",
		"room": "Room 2204",
		"hours": "8:00 AM - 5:00 PM",
		"in_charge": "Science Lab Custodian",
		"description": "Laboratory facility for physics experiments, chemical analysis, and STEM coursework.",
		"services": ["Lab Apparatus", "Safety Shower", "Reagent Storage", "Workbenches"]
	},
	{
		"name": "Lecture Room 301",
		"category": "Classrooms",
		"subtitle": "General Academic Classroom",
		"building": "Bldg 3",
		"floor": "3F",
		"location": "Building 3 • 3rd Floor",
		"room": "Room 3301",
		"hours": "7:00 AM - 9:00 PM",
		"in_charge": "Academic Services",
		"description": "Standard multimedia-ready lecture room for general education and engineering courses.",
		"services": ["Whiteboard", "Smart TV", "Air Conditioned", "45 Seats"]
	},
	{
		"name": "Registrar's Office",
		"category": "Administrative Offices",
		"subtitle": "Student Records & Enrollment",
		"building": "Main",
		"floor": "GF",
		"location": "Main Building • Ground Floor",
		"room": "Room 1101",
		"hours": "8:00 AM - 5:00 PM (Mon-Sat)",
		"in_charge": "Office of the Registrar",
		"description": "Handles official academic transcripts, enrollment verification, form 137 requests, and course credentials.",
		"services": ["TOR Request", "Enrollment", "Good Moral / Credentials", "Document Receiving"]
	},
	{
		"name": "Teller & Cashier",
		"category": "Finance & Cashier",
		"subtitle": "Tuition & Miscellaneous Payments",
		"building": "Main",
		"floor": "GF",
		"location": "Main Building • Ground Floor",
		"room": "Windows 1-5",
		"hours": "8:00 AM - 4:30 PM (Mon-Sat)",
		"in_charge": "Finance Department",
		"description": "Official payment windows for tuition fees, laboratory deposits, and document processing fees.",
		"services": ["Tuition Payment", "Balance Inquiry", "Official Receipts", "Promissory Notes"]
	}
]

func _ready() -> void:
	# 1. Footer & Back Buttons
	if btn_home:
		btn_home.pressed.connect(func(): switch_tab("home"))
	if btn_category:
		btn_category.pressed.connect(func(): switch_tab("category"))
	if btn_search_back:
		btn_search_back.pressed.connect(func(): switch_tab(previous_tab))
	if btn_detail_back:
		btn_detail_back.pressed.connect(func(): switch_tab(tab_before_detail))
	if btn_detail_search:
		btn_detail_search.pressed.connect(func():
			open_category_list("All")
			if search_places_input:
				search_places_input.grab_focus()
		)

	# 2. Universal Home Search Trigger (works for Button, LineEdit, or PanelContainer)
	var search_trigger: Control = find_child("BtnSearchTrigger", true, false) as Control
	if search_trigger:
		if search_trigger is BaseButton:
			search_trigger.pressed.connect(func():
				open_category_list("All")
				if search_places_input:
					search_places_input.grab_focus()
			)
		elif search_trigger is LineEdit:
			search_trigger.focus_entered.connect(func():
				open_category_list("All")
				if search_places_input:
					search_places_input.grab_focus()
			)
		else:
			search_trigger.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					open_category_list("All")
					if search_places_input:
						search_places_input.grab_focus()
			)

	# 3. Other Home Triggers ("Search Now", "See all" buttons)
	for btn_name: String in ["BtnSearchNow", "BtnSeeAllSuggested"]:
		var b: BaseButton = find_child(btn_name, true, false) as BaseButton
		if b:
			b.pressed.connect(func():
				open_category_list("All")
				if search_places_input:
					search_places_input.grab_focus()
			)

	var see_all_cat: BaseButton = find_child("BtnSeeAllCategories", true, false) as BaseButton
	if see_all_cat:
		see_all_cat.pressed.connect(func(): switch_tab("category"))

	# 4. Bind Category Cards (Categories Page + Home 2x2 Grid)
	_bind_card("CardLaboratories", "Laboratories")
	_bind_card("CardClassrooms", "Classrooms")
	_bind_card("CardOffices", "Administrative Offices")
	_bind_card("CardFinance", "Finance & Cashier")
	_bind_card("CardCatLabs", "Laboratories")
	_bind_card("CardCatRooms", "Classrooms")
	_bind_card("CardCatOffices", "Administrative Offices")
	_bind_card("CardCatFinance", "Finance & Cashier")

	# 5. Bind Suggested Places cards on Home screen
	_bind_suggested_card("CardPH1", 0)
	_bind_suggested_card("CardPH2", 3)
	_bind_suggested_card("CardPH3", 4)

	# 6. Live Search Input inside SearchView
	if search_places_input:
		search_places_input.text_changed.connect(func(new_text: String):
			populate_results(current_category_filter, new_text)
		)

	# 7. Filter the 4 Category Cards in place on the Categories Page
	if search_categories_input:
		search_categories_input.text_changed.connect(_filter_category_cards)

	switch_tab("home")


func switch_tab(tab: String) -> void:
	if tab in ["home", "category"]:
		previous_tab = tab
	if home_content:
		home_content.visible = (tab == "home")
	if category_content:
		category_content.visible = (tab == "category")
	if search_view:
		search_view.visible = (tab == "search")
	if detail_view:
		detail_view.visible = (tab == "detail")
	if tab == "category" and search_categories_input:
		search_categories_input.text = ""
		_filter_category_cards("")
	if view_container:
		view_container.scroll_vertical = 0


func _bind_card(node_name: String, category_name: String) -> void:
	var card: Control = find_child(node_name, true, false) as Control
	if not card:
		return
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			open_category_list(category_name)
	)


func _bind_suggested_card(node_name: String, data_index: int) -> void:
	var card: Control = find_child(node_name, true, false) as Control
	if not card or data_index >= places_data.size():
		return
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			tab_before_detail = "home"
			open_place_details(places_data[data_index])
	)


func open_category_list(category_name: String) -> void:
	current_category_filter = category_name
	if category_header_label:
		category_header_label.text = "All Places" if category_name == "All" else category_name
	if search_places_input:
		search_places_input.text = ""
	populate_results(category_name, "")
	switch_tab("search")


func populate_results(category_name: String, query: String) -> void:
	if not results_list:
		return
	for child in results_list.get_children():
		child.queue_free()

	var q: String = query.strip_edges().to_lower()
	var match_count: int = 0

	for place: Dictionary in places_data:
		var p_cat: String = str(place.get("category", "")).to_lower()
		var p_name: String = str(place.get("name", "")).to_lower()
		var p_loc: String = str(place.get("location", "")).to_lower()
		var p_room: String = str(place.get("room", "")).to_lower()
		var p_services: String = " ".join(place.get("services", [])).to_lower()

		var matches_cat: bool = (category_name == "All" or str(place.get("category", "")) == category_name)
		var matches_query: bool = (
			q == ""
			or q in p_name
			or q in p_cat
			or q in p_loc
			or q in p_room
			or q in p_services
		)
		if matches_cat and matches_query:
			results_list.add_child(_create_place_card(place))
			match_count += 1

	if match_count == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "No rooms or offices found."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", Color("#64748b"))
		results_list.add_child(empty_lbl)


func _create_place_card(place: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 84)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ffffff")
	style.set_corner_radius_all(16)
	style.set_border_width_all(1)
	style.border_color = Color("#e2e8f0")
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var title := Label.new()
	title.text = str(place.get("name", ""))
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("#0f172a"))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = str(place.get("location", "")) + "  |  " + str(place.get("room", ""))
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color("#64748b"))
	vbox.add_child(sub)

	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			tab_before_detail = "search"
			open_place_details(place)
	)
	return card


func open_place_details(place: Dictionary) -> void:
	if detail_title:
		detail_title.text = str(place.get("name", "..."))
	if detail_subtitle:
		detail_subtitle.text = str(place.get("subtitle", "..."))
	if badge_building:
		badge_building.text = str(place.get("building", "--"))
	if badge_floor:
		badge_floor.text = str(place.get("floor", "--"))
	if detail_description:
		detail_description.text = str(place.get("description", "..."))
	if val_hours:
		val_hours.text = str(place.get("hours", "--"))
	if val_room:
		val_room.text = str(place.get("room", "--"))
	if val_in_charge:
		val_in_charge.text = str(place.get("in_charge", "--"))

	if services_container:
		for child in services_container.get_children():
			child.queue_free()
		var services: Array = place.get("services", [])
		for service_name in services:
			var pill := PanelContainer.new()
			var pill_style := StyleBoxFlat.new()
			pill_style.bg_color = Color("#e0e7ff")
			pill_style.set_corner_radius_all(12)
			pill_style.content_margin_left = 10
			pill_style.content_margin_right = 10
			pill_style.content_margin_top = 4
			pill_style.content_margin_bottom = 4
			pill.add_theme_stylebox_override("panel", pill_style)

			var lbl := Label.new()
			lbl.text = str(service_name)
			lbl.add_theme_font_size_override("font_size", 11)
			lbl.add_theme_color_override("font_color", Color("#1e40af"))
			pill.add_child(lbl)
			services_container.add_child(pill)

	switch_tab("detail")


func _filter_category_cards(query: String) -> void:
	var q: String = query.strip_edges().to_lower()
	var map: Dictionary = {
		"CardLaboratories": "laboratories computer labs physics chemistry workshop",
		"CardClassrooms": "classrooms lecture rooms halls",
		"CardOffices": "administrative offices registrar osa itso guidance clinic",
		"CardFinance": "finance cashier teller student accounting assessment"
	}
	for card_name: String in map.keys():
		var card: Control = find_child(card_name, true, false) as Control
		if card:
			card.visible = (q == "" or q in map[card_name])
