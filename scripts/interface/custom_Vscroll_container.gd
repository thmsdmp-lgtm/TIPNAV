extends Control
class_name CustomVScrollContainer

# external variables
@export var TouchSource:Control # the Control that receives the touch/drag input
@export var Sensitivity:float = 4

# internal variables
var holding:bool = false
var deltaY:float

func _ready() -> void:
	if TouchSource:
		TouchSource.clip_contents = true
		TouchSource.gui_input.connect(_on_touch_source_input)

func _on_touch_source_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				deltaY = 0
				holding = true
			else:
				holding = false

	if event is InputEventMouseMotion and holding:
		var finalSen = clamp(5-Sensitivity,.1,10)
		var dt = get_process_delta_time()
		if dt > 0.0:
			# convert this event's pixel movement into a velocity (px/sec)
			deltaY = (event.relative.y/finalSen) / dt
	elif event is InputEventScreenDrag:
		var finalSen = clamp(5-Sensitivity,.1,10)
		var dt = get_process_delta_time()
		if dt > 0.0:
			deltaY = (event.relative.y/finalSen) / dt

func _process(delta: float) -> void:
	if not TouchSource: return

	# frame-rate independent exponential decay
	deltaY = lerp(deltaY, 0.0, 1.0 - exp(-10.0*delta))

	# this node moves itself, bounded by the touch source's rect
	var new_y := global_position.y + deltaY*delta
	var max_y := TouchSource.global_position.y
	var min_y := (TouchSource.global_position.y + TouchSource.size.y) - size.y

	# if this node is shorter than the touch area, keep it pinned to the top
	min_y = min(min_y, max_y)

	global_position.y = clamp(new_y, min_y, max_y)
