class_name CameraPivot
extends Node3D
## Third-person camera: Player3D ─ CameraPivot ─ SpringArm3D ─ Camera3D.
## The pivot is top-level: it follows its target smoothly (the interpolated transform, so no
## jitter with physics interpolation) without turning with it. It turns around the target: the mouse
## dragged with its right button (or the left one on the right half of the screen, which Godot turns
## into a finger), the right stick, a finger on a touch screen. It zooms: mouse wheel, pinch
## (remembered, like CameraRig's).
## The spring arm pulls the camera in when a wall or a cliff comes between the target and it.
## Other uses (a dino watched, a battle, a cut-scene) only swap `target` and call set_view.

const LOOK_HEIGHT := 1.2        # metres above the target's feet it looks at (Chloé's shoulders)
const FOLLOW := 10.0            # smoothing of the follow (higher = tighter)
const DISTANCE_MIN := 2.5
const DISTANCE_MAX := 14.0
const DISTANCE_DEFAULT := 4.5      # Chloé (1.50 m) about a third of the screen high
const ZOOM_STEP := 0.8          # metres per notch of the wheel
const ZOOM_FOLLOW := 8.0        # how fast the arm reaches the distance asked for
const PITCH_MIN := -70.0        # degrees: looking down steeply…
const PITCH_MAX := 8.0          # …to slightly from below
const PITCH_DEFAULT := -22.0
const DRAG_DEG_PER_PX := 0.25
const STICK_DEG_PER_S := 140.0
const STICK_DEAD_ZONE := 0.2
const ARM_RADIUS := 0.25        # the camera keeps this far from walls
const PREFS := "camera3d"

## Whom it follows (the parent by default).
var target: Node3D
## The on-screen controls (ui/touch_controls.gd): touches on their buttons are not the camera's.
var touch_controls: Node
var yaw := 0.0      # radians, around the vertical: 0 = the camera south of the target (+Z)
var pitch := deg_to_rad(PITCH_DEFAULT)

var _distance := DISTANCE_DEFAULT
var _touches := {}            # index → position, for the fingers that are not on a control
var _orbit_index := -1        # the finger turning the camera
var _pinch_start := 0.0
var _pinch_distance := 0.0

@onready var arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # moved in _process
	if target == null:
		target = get_parent() as Node3D
	var shape := SphereShape3D.new()
	shape.radius = ARM_RADIUS
	arm.shape = shape
	arm.collision_mask = Layers3D.WORLD
	arm.margin = 0.05
	camera.fov = 55.0
	camera.near = 0.1
	camera.far = 400.0
	_distance = clampf(float(Quality.pref(PREFS, "distance", DISTANCE_DEFAULT)), DISTANCE_MIN, DISTANCE_MAX)
	arm.spring_length = _distance
	snap()


## Jumps onto the target (arrival in a zone, a teleport), no smoothing.
func snap() -> void:
	if target:
		global_position = _focus()
	_apply_rotation()


## Looks from this angle and distance (degrees, metres; the distance is not remembered).
func set_view(yaw_deg: float, pitch_deg: float, metres := -1.0) -> void:
	yaw = deg_to_rad(yaw_deg)
	pitch = deg_to_rad(clampf(pitch_deg, PITCH_MIN, PITCH_MAX))
	if metres > 0.0:
		_distance = clampf(metres, DISTANCE_MIN, DISTANCE_MAX)
	_apply_rotation()


func distance() -> float:
	return _distance


func set_distance(d: float, remember := true) -> void:
	_distance = clampf(d, DISTANCE_MIN, DISTANCE_MAX)
	if remember:
		Quality.set_pref(PREFS, "distance", _distance)


## The direction on the ground for a move input (x right, y down as Input.get_vector gives it):
## up goes away from the camera. Keeps the analog length (0–1).
func flat_direction(input: Vector2) -> Vector3:
	var turn := Basis(Vector3.UP, yaw)
	return turn.x * input.x + turn.z * input.y


func _process(delta: float) -> void:
	_stick(delta)
	if target:
		global_position = global_position.lerp(_focus(), 1.0 - exp(-FOLLOW * delta))
	arm.spring_length = lerpf(arm.spring_length, _distance, 1.0 - exp(-ZOOM_FOLLOW * delta))
	_apply_rotation()


func _focus() -> Vector3:
	var t := target.get_global_transform_interpolated() if target.is_inside_tree() else target.transform
	return t.origin + Vector3(0.0, LOOK_HEIGHT, 0.0)


func _apply_rotation() -> void:
	rotation = Vector3(pitch, yaw, 0.0)


func _turn(dx_deg: float, dy_deg: float) -> void:
	yaw = wrapf(yaw - deg_to_rad(dx_deg), -PI, PI)
	pitch = clampf(pitch - deg_to_rad(dy_deg), deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))


func _stick(delta: float) -> void:
	if Input.get_connected_joypads().is_empty():
		return
	var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if v.length() < STICK_DEAD_ZONE:
		return
	_turn(v.x * STICK_DEG_PER_S * delta, v.y * STICK_DEG_PER_S * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_distance(_distance - ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_distance(_distance + ZOOM_STEP)
	elif event is InputEventMagnifyGesture:
		set_distance(_distance / event.factor)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		_turn(event.relative.x * DRAG_DEG_PER_PX, event.relative.y * DRAG_DEG_PER_PX)


## Fingers (and the mouse's left button, emulated as a finger): one on the right half turns the
## camera; two anywhere pinch to zoom (and take the joystick's finger back). A finger on an on-screen
## control (A, B, a HUD button) is that control's.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_controls and touch_controls.has_method(&"owns_touch") and touch_controls.owns_touch(event.position):
				return
			_touches[event.index] = event.position
			if _touches.size() == 1 and event.position.x >= get_viewport().get_visible_rect().size.x * 0.5:
				_orbit_index = event.index
		else:
			_touches.erase(event.index)
			if event.index == _orbit_index:
				_orbit_index = -1
			if _touches.size() < 2 and _pinch_start > 0.0:
				_pinch_start = 0.0
				set_distance(_distance)
		if _touches.size() == 2:
			_orbit_index = -1
			var p: Array = _touches.values()
			_pinch_start = (p[0] as Vector2).distance_to(p[1])
			_pinch_distance = _distance
			if touch_controls and touch_controls.has_method(&"release_stick"):
				touch_controls.release_stick()
	elif event is InputEventScreenDrag and _touches.has(event.index):
		_touches[event.index] = event.position
		if _touches.size() == 2 and _pinch_start > 0.0:
			var p: Array = _touches.values()
			var now := (p[0] as Vector2).distance_to(p[1])
			if now > 1.0:
				set_distance(_pinch_distance * _pinch_start / now, false)
		elif event.index == _orbit_index:
			_turn(event.relative.x * DRAG_DEG_PER_PX, event.relative.y * DRAG_DEG_PER_PX)
