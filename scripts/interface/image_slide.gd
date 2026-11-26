# script for handling image slides
# presented in info page
extends Panel

# place images folder
@export_dir() var images

# add image once created
@export var Initialize:bool

# allowed image formats
@export var IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "svg"]

# anchor the texture rect to fill the whole panel
@export var full_rect:bool = true

# set the rect's min size to the container's size so the image fits it
@export var fit_to_container:bool = false

# custom min size for texture rect
@export var min_size:Vector2 = Vector2(100,200)

func _ready() -> void:
	if not Initialize: return
	
	# wait a few frames so the parent/scene tree is fully set up
	for i in 3:
		await get_tree().process_frame
	
	var parent_node = get_parent()
	if parent_node == null: return
	var place_name:String = parent_node.name
	
	# folder named after the place
	var path = str(images, "/", place_name)
	if not DirAccess.dir_exists_absolute(path): return
	
	# collect valid images (exported builds list "name.png.import" / "name.png.remap")
	var valid:Array[String] = []
	var seen := {}
	for file_name in DirAccess.get_files_at(path):
		var clean = file_name.trim_suffix(".import").trim_suffix(".remap")
		if seen.has(clean): continue
		if clean.get_extension().to_lower() not in IMAGE_EXTENSIONS: continue
		seen[clean] = true
		valid.append(path.path_join(clean))
	if valid.is_empty(): return
	
	var image = load(valid.pick_random())
	if image == null: return
	
	var rect = TextureRect.new()
	add_child(rect)
	if full_rect:
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.custom_minimum_size = size if fit_to_container else min_size
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.texture = image

# creates and parents textureRects to specified parent
func create_images(place_name:String, parent:Control):
	# clear previous contents
	for stuff in parent.get_children():
		stuff.queue_free()
	
	# folder named after the place
	var path = str(images, "/", place_name)
	if not DirAccess.dir_exists_absolute(path): return
	
	var seen := {}
	for file_name in DirAccess.get_files_at(path):
		await get_tree().create_timer(0.2).timeout
		
		# exported builds list "name.png.import" / "name.png.remap"
		var clean = file_name.trim_suffix(".import").trim_suffix(".remap")
		if seen.has(clean): continue
		if clean.get_extension().to_lower() not in IMAGE_EXTENSIONS: continue
		seen[clean] = true
		
		var image = load(path.path_join(clean))
		if image == null: continue
		
		var rect = TextureRect.new()
		parent.add_child(rect)
		rect.custom_minimum_size = min_size
		rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rect.texture = image
