class_name PuddleRipple
extends MeshInstance3D
## The ripples of a puddle (puddle_ripple.gdshader), laid flat over its picture in the 3D view:
## impact() sends a train of round waves out from its middle (a heavy step far off). Calm, it
## shows nothing (the picture is the water). Stage.puddle makes one; it frees itself `linger`
## seconds after its last impact.

const SHADER := preload("res://world/view3d/puddle_ripple.gdshader")
const MAX_IMPACTS := 6

var time := 0.0
var linger := 4.0
var _impacts: Array[float] = []
var _last := -INF
var _mat: ShaderMaterial


## `radius_m`: half its width; `squash`: its depth over its width (an ellipse on the ground).
func setup(radius_m: float, squash := 1.0) -> void:
	var quad := PlaneMesh.new()   # (flat on the ground, facing up)
	quad.size = Vector2(radius_m * 2.0, radius_m * 2.0 * squash)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.render_priority = 2   # (over the puddle's standing picture)
	_mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	quad.material = _mat
	mesh = quad
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in MAX_IMPACTS:
		_impacts.append(-1.0)
	_push()


## A heavy step far off: a new train of waves (`strength` 1: a big one).
func impact(strength := 1.0) -> void:
	_impacts.pop_front()
	_impacts.append(time)
	_last = time
	_mat.set_shader_parameter("strength", strength)
	_push()


func _process(delta: float) -> void:
	time += delta
	_mat.set_shader_parameter("now", time)
	if time - _last > linger and _last > -INF:
		var t := create_tween()
		t.tween_property(self, "transparency", 1.0, 0.6)
		t.tween_callback(queue_free)
		set_process(false)


func _push() -> void:
	_mat.set_shader_parameter("impacts", PackedFloat32Array(_impacts))
