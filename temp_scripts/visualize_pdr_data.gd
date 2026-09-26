extends Node

# settings
var max_y:float = 100

# instances
var line:Line2D

# initialize
func _ready() -> void:
	
	# create line
	line = Line2D.new()
	line.width = 5
	line.joint_mode = Line2D.LINE_JOINT_BEVEL
	add_child(line)
	
	# init line points
	init_line_points()
	
	# init connections
	get_viewport().size_changed.connect(init_line_points)
	

# init or reset line positions
func init_line_points():
	if not line: return
	
	# check for existing points
	if line.get_point_count() > 0:
		line.clear_points()
	
	# get viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# add first point
	line.add_point(Vector2(0 , viewport_size.y / 2))
	
	# get section length
	var section_length = viewport_size.x / PedestrianDeadReckoning.data_size_limit
	
	# x
	var x:float = section_length
	
	# create points
	for i in PedestrianDeadReckoning.data_size_limit:
		line.add_point(Vector2(x , viewport_size.y / 2))
		x += section_length

# update points
func _process(delta: float) -> void:
	
	# get viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# loop for every data
	for i in PedestrianDeadReckoning.data_set.size():
		
		# get variables
		var data = PedestrianDeadReckoning.data_set[i]
		var point_pos = line.get_point_position(i)
		
		# check for variables
		if not data or not point_pos: return
		
		# set point pos
		line.set_point_position(i,Vector2(point_pos.x, (viewport_size.y / 2) - (max_y * data.accelerometer_data.length())))
