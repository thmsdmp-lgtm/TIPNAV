extends Node3D

@export var camera3d: Camera3D
@export var input_area: Control ## Camera only reacts to input that lands on this control
@export var smoothing: float = 20.0
@export var sensitivity: float = 0.05
@export var mode: bool = false ## false = pan, true = rotate
@export var focus: bool = false ## false = freecam, true = focus on user

@export_group("Zoom")
@export var min_distance: float = 3.0
@export var max_distance: float = 100
@export var zoom_smoothing: float = 12.0
@export var wheel_zoom_step: float = 1.1 ## desktop testing

var _drag_delta: Vector2 = Vector2.ZERO
var _smoothed_delta: Vector2 = Vector2.ZERO

var _touches: Dictionary = {}          # finger index -> position
var _last_pinch_distance: float = 0.0
var _pinch_locked: bool = false        # true from pinch start until ALL fingers are lifted

var _camera_dir: Vector3 = Vector3.BACK
var _distance: float = 10.0
var _target_distance: float = 10.0


func _ready() -> void:
	if camera3d == null:
		push_error("camera3d is not assigned.")
		set_process(false)
		return
	if input_area == null:
		push_error("input_area is not assigned.")
		set_process(false)
		return

	# The control must not ignore the mouse/touch, otherwise it never gets gui_input.
	if input_area.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		input_area.mouse_filter = Control.MOUSE_FILTER_STOP
	input_area.gui_input.connect(_on_input_area_gui_input)
	# If the area gets hidden (e.g. tab switch) mid-touch, drop stale fingers.
	input_area.visibility_changed.connect(_reset_touch_state)

	# Assumes the camera is a child of this node, positioned away from the pivot.
	var offset := camera3d.position
	if offset.length() < 0.001:
		offset = Vector3(0, 0, 10)
	_camera_dir = offset.normalized()
	_distance = clampf(offset.length(), min_distance, max_distance)
	_target_distance = _distance


func _reset_touch_state() -> void:
	_touches.clear()
	_pinch_locked = false
	_last_pinch_distance = 0.0
	_drag_delta = Vector2.ZERO
	_smoothed_delta = Vector2.ZERO


func _on_input_area_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var was_pinching := _touches.size() >= 2
		
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		
		if _touches.size() >= 2:
			_pinch_locked = true
		elif _touches.is_empty():
			_pinch_locked = false
		
		# Only kill momentum when entering or leaving a pinch.
		# A plain one-finger release keeps gliding via the smoothing.
		if was_pinching or _touches.size() >= 2:
			_drag_delta = Vector2.ZERO
			_smoothed_delta = Vector2.ZERO
		
		_last_pinch_distance = _get_pinch_distance() if _touches.size() == 2 else 0.0
	
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		
		if _touches.size() == 2:
			_handle_pinch()
		elif _touches.size() == 1 and not _pinch_locked:
			_drag_delta += event.relative

	elif event is InputEventMagnifyGesture:
		_zoom_by_factor(event.factor)
	
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by_factor(wheel_zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by_factor(1.0 / wheel_zoom_step)


func _process(delta: float) -> void:
	# Frame-rate independent smoothing
	var t := 1.0 - exp(-smoothing * delta)
	
	_smoothed_delta = _smoothed_delta.lerp(_drag_delta * sensitivity, t)
	_drag_delta = _drag_delta.lerp(Vector2.ZERO, t)
	
	if focus and is_instance_valid(%capsule):
		position = %capsule.position
	
	if not mode:
		# Camera-relative horizontal movement
		var right := camera3d.global_basis.x
		var forward := -camera3d.global_basis.z
		right.y = 0.0
		forward.y = 0.0
		right = right.normalized()
		forward = forward.normalized()
		
		var movement := right * -_smoothed_delta.x + forward * _smoothed_delta.y
		position += movement * t
	else:
		rotation_degrees.y -= _smoothed_delta.x * 2.0 * t
		rotation_degrees.x -= _smoothed_delta.y * 2.0 * t
	
	# Always clamp, regardless of mode
	rotation_degrees.x = clampf(rotation_degrees.x, 10.0, 85.0)
	
	_update_zoom(delta)


# --- Zoom -------------------------------------------------------------------

func _handle_pinch() -> void:
	var dist := _get_pinch_distance()
	if _last_pinch_distance > 0.0 and dist > 0.0:
		# Fingers spreading -> factor > 1 -> zoom in
		_zoom_by_factor(dist / _last_pinch_distance)
	_last_pinch_distance = dist


func _get_pinch_distance() -> float:
	if _touches.size() < 2:
		return 0.0
	# Sorted keys so the same two fingers are always compared in the same order
	var keys := _touches.keys()
	keys.sort()
	return (_touches[keys[0]] as Vector2).distance_to(_touches[keys[1]] as Vector2)


func _zoom_by_factor(factor: float) -> void:
	if factor <= 0.0:
		return
	_target_distance = clampf(_target_distance / factor, min_distance, max_distance)


func _update_zoom(delta: float) -> void:
	_distance = lerpf(_distance, _target_distance, 1.0 - exp(-zoom_smoothing * delta))
	camera3d.position = _camera_dir * _distance
