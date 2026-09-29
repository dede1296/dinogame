class_name NightMagic
extends Node3D
## What the amber does at night (drawn over the zone by the WorldView):
##   the full moon: a brighter, silvery night; every amber pebble still hidden glints from
##   afar; the amber stones of a MoonFord light up across the water;
##   the amber lantern (story flag "lanterne"): a warm light around Chloé at night and in
##   caves, and the hidden pebbles near her glint.

const GLINT_SIZE := 0.34            # metres
const GLINT_HEIGHT := {"arbre_rond": 1.6, "fougere_arbre": 1.4, "araucaria": 1.8}
const LANTERN_REACH := 6.0          # tiles: hidden pebbles glint this close to the lantern
const STONE_EVERY := 0.75           # metres between the ford's stones
const AMBER := Color(1.0, 0.72, 0.28)

var _view: WorldView
var _glints: Array[Array] = []      # [node (2D), Sprite3D]
var _stones: Array[Array] = []      # [MoonFord, Node3D holding its stones]
var _lantern: OmniLight3D
var _time := 0.0


## Called by the view after it has built zone `region` (the glints and stones are rebuilt).
func build(view: WorldView, region: Region, zone: Node3D) -> void:
	_view = view
	_glints.clear()
	_stones.clear()
	for n in region.entities.get_children():
		if _hides_pebble(n):
			_glints.append([n, _make_glint(zone)])
	for dock in region.docks():
		if dock is MoonFord:
			_stones.append([dock, _make_stones(dock, zone)])
	if _lantern == null:
		_lantern = OmniLight3D.new()
		_lantern.light_color = Color(1.0, 0.7, 0.36)
		_lantern.light_energy = 1.3
		_lantern.omni_range = 6.0
		_lantern.shadow_enabled = false
		add_child(_lantern)


static func _hides_pebble(n: Node) -> bool:
	if n.has_method(&"is_hiding"):
		return true
	return n is Pickup and String((n as Pickup).taken_flag).begins_with("galet_")


## After the sky of the frame is set: the moon's light, the glints, the lantern, the ford.
func update(delta: float, region: Region, chloe: Node2D, sun: DirectionalLight3D, env: Environment) -> void:
	_time += delta
	if region == null or chloe == null:
		return
	var night := Game.phase() == &"night"
	var moon := Game.is_full_moon() and not region.indoor
	if moon:
		sun.light_color = sun.light_color.lerp(Color(0.8, 0.86, 1.0), 0.6)
		sun.light_energy += 0.3
		env.ambient_light_energy += 0.2
	var lantern: bool = Game.flag(&"lanterne") and (night or region.cave)
	_lantern.visible = lantern and Quality.setting(&"lights")
	var feet := _view.heights.to_3d(chloe.global_position)
	if lantern:
		_lantern.position = feet + Vector3(0.3, 1.0, 0.3)   # in her hand (she is 1.50 m)
	var pulse := 0.75 + 0.25 * sin(_time * 3.0)
	for g in _glints:
		var glint: Sprite3D = g[1]
		if not is_instance_valid(g[0]):   # picked up
			glint.visible = false
			continue
		var node: Node2D = g[0]
		var hiding := _still_hiding(node)
		var near: bool = lantern and chloe.global_position.distance_to(node.global_position) < LANTERN_REACH * 48.0
		glint.visible = hiding and ((moon and night) or near)
		if glint.visible:
			var kind: String = node.get("kind") if "kind" in node else ""
			glint.position = _view.heights.to_3d(node.global_position) + Vector3(0, GLINT_HEIGHT.get(kind, 0.35), 0.15)
			glint.modulate = Color(AMBER, pulse)
	for s in _stones:
		var ford: MoonFord = s[0]
		(s[1] as Node3D).visible = is_instance_valid(ford) and ford.open


static func _still_hiding(n: Node) -> bool:
	if n.has_method(&"is_hiding"):
		return n.call(&"is_hiding")
	return not Game.flag((n as Pickup).taken_flag)


func _make_glint(zone: Node3D) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = WorldView._soft_dot()
	s.pixel_size = GLINT_SIZE / s.texture.get_width()
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.no_depth_test = true
	s.render_priority = 5
	s.visible = false
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	zone.add_child(s)
	return s


## Flat amber stones across the ford, glowing a little, top at the height Chloé stands on.
func _make_stones(ford: MoonFord, zone: Node3D) -> Node3D:
	var holder := Node3D.new()
	holder.visible = false
	zone.add_child(holder)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.24
	mesh.bottom_radius = 0.3
	mesh.height = 0.44
	mesh.radial_segments = 9   # a little faceted, like a rough stone
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.31, 0.27)
	mat.emission_enabled = true
	mat.emission = AMBER
	mat.emission_energy_multiplier = 0.22
	mat.roughness = 0.95
	mesh.material = mat
	# One staggered line of stones per column of the ford.
	var area := ford.area()
	var top := area.position / 48.0
	var length := area.size.y / 48.0 - 0.1
	var i := 0
	for column in int(area.size.x / 48.0):
		var d := 0.15 + (STONE_EVERY / 2.0 if column % 2 else 0.0)
		while d <= length:
			var stone := MeshInstance3D.new()
			stone.mesh = mesh
			var wobble := 0.14 * sin(i * 2.3)
			# Just breaking the surface: most of the stone stays under water.
			stone.position = Vector3(top.x + column + 0.5 + wobble, HeightMap.FORD_TOP - 0.22, top.y + d)
			stone.rotation.y = i * 1.1
			stone.scale = Vector3.ONE * (0.85 + 0.2 * absf(sin(i * 1.7)))
			holder.add_child(stone)
			d += STONE_EVERY
			i += 1
	return holder
