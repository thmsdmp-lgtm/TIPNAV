# script for handling image slides
# presented in info page
extends Panel

# place images folder
@export_dir() var images

# allowed image formats
@export var IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "svg"]

# custom min size for texture rect
@export var min_size:Vector2 = Vector2(100,200)

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
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rect.texture = image
