class_name WorldView
extends Node3D
## What the player sees of a zone: the zone is played in 2D (physics, exits, encounters,
## saves stay 2D) and shown here in 2.5D. The ground is a 3D relief (HeightMap), the plain
## scenery stands as camera-facing pictures (MultiMesh, swaying), the tall grass parts
## around Chloé, and everything that moves or changes in 2D (Chloé, dinos, people,
## obstacles, pickups, their particles and glows) is mirrored every frame.
## Sun, moon and sky follow the game clock; rain and mist dim them, close the horizon, and
## rain falls around Chloé. Quality: shadows, render scale, glow, far blur, rain density.

const PX := HeightMap.PX
const STRETCH := 1.15                       # same as the billboard shader
const PROP_SCRIPT := preload("res://world/prop.gd")
const BILLBOARD := preload("res://world/view3d/billboard.gdshader")
const GROUND := preload("res://world/view3d/ground.gdshader")
const WATER := preload("res://world/view3d/water.gdshader")
const CONTACT := preload("res://world/view3d/contact_shadow.gdshader")
## How rounded each kind of scenery looks (volume lighting); flat things stay flat.
const ROUNDNESS := {
	"arbre_rond": 0.85, "araucaria": 0.6, "fougere_arbre": 0.6, "buisson": 0.8, "rocher": 0.75,
	"cailloux": 0.6, "tronc": 0.5, "ronces": 0.5, "hautes_herbes": 0.2, "fougeres": 0.35,
	"fleurs_roses": 0.3, "fleurs_violettes": 0.3, "panneau": 0.1, "cloture": 0.1, "ambre": 0.3, "souche": 0.5,
}
const TUFT := preload("res://assets/art/props/hautes_herbes.png")
const OUTER_TREES := ["arbre_rond", "araucaria", "fougere_arbre", "arbre_rond"]
## On the near side (towards the camera) only low plants: trees there would hide the zone.
const OUTER_LOW := ["buisson", "fougeres", "buisson", "hautes_herbes"]
const TUFTS_PER_CELL := 3
## The ground and the scenery are cut into square chunks (m): only those near the camera
## are drawn (VIEW_RANGE), and the far ones fade out in the mist.
const CHUNK := 16
const VIEW_RANGE := 72.0
const GRASS_RANGE := 46.0
## A campfire's flame (tools/draw-placeholders.mjs, as the web version drew it), metres wide.
const FLAME := preload("res://assets/art/props/flamme.png")
const FLAME_WIDTH := 0.7
## The colour of a little sign over a dino (emote): a heart is red, the rest dark brown.
const EMOTE_COLOURS := {"♥": Color(0.86, 0.22, 0.35), "♪": Color(0.3, 0.2, 0.55)}
## How far a neighbouring zone is shown beyond an exit (tiles).
const PREVIEW_DEPTH := 26.0
## Trees filling the "forest" tiles (weights by repetition).
const FOREST_TREES := ["arbre_rond", "araucaria", "arbre_rond", "fougere_arbre", "araucaria", "arbre_rond"]
const CAVE := preload("res://world/view3d/cave_mouth.gdshader")
const OCCLUDER_HEIGHT := 2.2               # metres: taller scenery may hide Chloé
const POLLEN_MOTES := 60
const RAIN_DROPS := 320
## A storm: this much more rain, flashes of lightning every so often (s), thunder after them.
const STORM_RAIN := 1.8
const LIGHTNING_EVERY := Vector2(6.0, 16.0)
const THUNDER: Array[AudioStream] = [preload("res://assets/audio/ambience/tonnerre-1.mp3"), preload("res://assets/audio/ambience/tonnerre-2.mp3")]
const WEATHER_BLEND := 0.6                  # how fast rain and mist come and go
## A 2D move longer than this in one physics step is a teleport, not blended (px).
const TELEPORT := 96.0
## Light over the day: [hour, sun elevation°, sun azimuth°, colour, energy, ambient, ambient energy, sky].
const DAYLIGHT := [
	[0.0, 48.0, 30.0, Color(0.55, 0.65, 1.0), 0.35, Color(0.24, 0.28, 0.44), 0.6, Color(0.08, 0.1, 0.2)],
	[5.0, 48.0, 30.0, Color(0.55, 0.65, 1.0), 0.35, Color(0.24, 0.28, 0.44), 0.6, Color(0.08, 0.1, 0.2)],
	[6.5, 12.0, -60.0, Color(1.0, 0.76, 0.62), 0.8, Color(0.62, 0.56, 0.62), 0.7, Color(0.9, 0.72, 0.66)],
	[8.0, 42.0, -25.0, Color(1.0, 0.95, 0.85), 1.2, Color(0.72, 0.78, 0.86), 0.75, Color(0.66, 0.8, 0.9)],
	[13.0, 60.0, 15.0, Color(1.0, 0.96, 0.88), 1.25, Color(0.72, 0.78, 0.86), 0.75, Color(0.64, 0.8, 0.92)],
	[17.0, 38.0, 55.0, Color(1.0, 0.92, 0.8), 1.15, Color(0.74, 0.76, 0.8), 0.75, Color(0.7, 0.8, 0.88)],
	[19.0, 12.0, 75.0, Color(1.0, 0.66, 0.42), 0.95, Color(0.7, 0.55, 0.55), 0.75, Color(0.95, 0.66, 0.5)],
	[20.5, 48.0, 30.0, Color(0.55, 0.65, 1.0), 0.35, Color(0.24, 0.28, 0.44), 0.6, Color(0.08, 0.1, 0.2)],
	[24.0, 48.0, 30.0, Color(0.55, 0.65, 1.0), 0.35, Color(0.24, 0.28, 0.44), 0.6, Color(0.08, 0.1, 0.2)],
]

var heights: HeightMap
var camera: CameraRig
var player: Node2D

var _region: Region
var _zone: Node3D                            # everything built for the current zone
var _proxies: Array[Dictionary] = []         # {src, sprite, vis, light, glow, prev, cur}
## Chloé's last two physics positions (the 2D world moves at the physics rate; the view
## blends between them, so it stays smooth on 90–120 Hz screens).
var _player_prev := Vector2.ZERO
var _player_cur := Vector2.ZERO
var _sun: DirectionalLight3D
var _env: Environment
var _pollen: CPUParticles3D
var _wildlife: Wildlife
var _magic: NightMagic
## Scenery props drawn in a MultiMesh -> [MultiMesh, index] (to shake or lift one of them).
var _instances := {}
## The "!" over Chloé's dino when it senses something hidden nearby.
var _hint: Label3D
var _contact_mesh: PlaneMesh
## Where neighbour zones are shown beyond the edges (world tiles).
var _bands: Array[Rect2] = []
var _zones := {}
var _rain: CPUParticles3D
var _ground_mat: ShaderMaterial
var _rain_amount := 0.0                     # 0..1, blended towards the weather
var _storm_amount := 0.0
var _flash := 0.0                           # lightning: 1 at the flash, fading
var _next_lightning := 8.0
var _mist_amount := 0.0


func _ready() -> void:
	add_to_group(&"world_view")
	_sun = DirectionalLight3D.new()
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_sun.directional_shadow_max_distance = 45.0
	_sun.shadow_blur = 1.5
	add_child(_sun)
	var world := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.fog_mode = Environment.FOG_MODE_DEPTH
	_env.fog_depth_begin = 22.0
	_env.fog_depth_end = 60.0
	_env.glow_intensity = 0.35
	_env.glow_bloom = 0.05
	world.environment = _env
	add_child(world)
	camera = CameraRig.new()
	camera.attributes = CameraAttributesPractical.new()
	add_child(camera)
	camera.current = true
	_pollen = _make_pollen()
	add_child(_pollen)
	_wildlife = Wildlife.new()
	add_child(_wildlife)
	_magic = NightMagic.new()
	add_child(_magic)
	_rain = _make_rain()
	add_child(_rain)
	_rain_amount = 1.0 if Game.is_raining() else 0.0
	_storm_amount = 1.0 if Game.weather == &"storm" else 0.0
	_mist_amount = 1.0 if Game.weather == &"mist" else 0.0
	Quality.changed.connect(_apply_quality)
	_apply_quality()
	get_tree().node_added.connect(_on_node_added)


func _apply_quality() -> void:
	var shadows: int = Quality.setting(&"shadows")
	_sun.shadow_enabled = shadows > 0
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if shadows > 1 else DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.directional_shadow_max_distance = 45.0 if shadows > 1 else 28.0
	_env.glow_enabled = Quality.setting(&"glow")
	var attributes := camera.attributes as CameraAttributesPractical
	attributes.dof_blur_far_enabled = Quality.setting(&"dof")
	attributes.dof_blur_far_transition = 14.0
	attributes.dof_blur_amount = 0.04
	get_viewport().scaling_3d_scale = Quality.setting(&"render_scale")
	_pollen.amount = Quality.scaled(POLLEN_MOTES)
	_rain.amount = Quality.scaled(RAIN_DROPS)
	# Relief detail, grass density, swaying: rebuilt with the zone.
	if _region and is_instance_valid(_region) and player:
		show_zone(_region, player)


# ------------------------------------------------------------------ zone

## Builds the 3D view of `region` (replacing the previous zone's), following `chloe`.
## `zones`: every zone id -> scene path, to show the neighbours beyond the exits.
func show_zone(region: Region, chloe: Node2D, zones := {}) -> void:
	for p in _proxies:
		_free_proxy(p)
	_proxies.clear()
	_instances.clear()
	if _zone:
		_zone.queue_free()
	if _region and _region.entities.child_entered_tree.is_connected(_on_entity_added):
		_region.entities.child_entered_tree.disconnect(_on_entity_added)
	_region = region
	player = chloe
	_zone = Node3D.new()
	_zone.name = "Zone"
	add_child(_zone)
	heights = HeightMap.new(region, Quality.setting(&"ground_step"))
	_bands.clear()
	if not zones.is_empty():
		_zones = zones
	var neighbours := [] if region.indoor else _neighbours(_zones)
	_ground_mat = _build_ground(region, heights)
	_set_holes(_ground_mat)
	if heights.has_water:
		_set_holes(_build_water(heights))
	for n: Dictionary in neighbours:
		_build_neighbour(n)
	_build_scenery()
	_build_forest(region, heights)
	_build_tall_grass()
	for dock in region.docks():
		if not dock is MoonFord:   # (its stones: NightMagic)
			_build_dock(dock)
	for mouth in region.find_children("*", "CaveMouth", true, false):
		_build_cave_mouth(mouth)
	if not region.indoor:
		_build_outer_forest()
	_magic.build(self, region, _zone)
	(camera.attributes as CameraAttributesPractical).dof_blur_far_enabled = Quality.setting(&"dof") and not region.indoor
	for n in region.entities.get_children():
		_track(n)
	region.entities.child_entered_tree.connect(_on_entity_added)
	camera.zone_size = Vector2(heights.size)
	camera.shake_source = chloe.get_node_or_null("Camera") as Camera2D
	_player_prev = chloe.global_position
	_player_cur = chloe.global_position
	camera.target = heights.to_3d(chloe.global_position)
	camera.snap()


## The ground of zone `r` (its relief `hm`), moved by `shift` tiles, drawn only inside
## `keep` (world tiles; empty = all): the current zone, or a neighbour beyond an edge.
## Flat grid chunks raised by the height texture in the shader; each chunk is culled alone.
func _build_ground(r: Region, hm: HeightMap, shift := Vector2.ZERO, keep := Rect2()) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GROUND
	mat.set_shader_parameter("grass_tex", r.ground_tex if r.ground_tex else load("res://assets/art/ground/herbe.png"))
	var dirt: Texture2D = load("res://assets/art/ground/terre.png")
	if r.path_tex and r.paved_rect.has_area():
		mat.set_shader_parameter("dirt_tex", dirt)
		mat.set_shader_parameter("paved_tex", r.path_tex)
		var pr := r.paved_rect
		mat.set_shader_parameter("paved_rect", Vector4(pr.position.x, pr.position.y, pr.size.x, pr.size.y))
	else:
		mat.set_shader_parameter("dirt_tex", r.path_tex if r.path_tex else dirt)
	mat.set_shader_parameter("plain", r.indoor)
	mat.set_shader_parameter("cliff_tex", load("res://assets/art/ground/falaise.png"))
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	mat.set_shader_parameter("water_level", HeightMap.WATER_LEVEL if hm.has_water else -100.0)
	var masks := _terrain_masks(r, hm)
	mat.set_shader_parameter("terrain_mask", masks[0])
	mat.set_shader_parameter("terrain_mask2", masks[1])
	mat.set_shader_parameter("map_tiles", Vector2(hm.size))
	mat.set_shader_parameter("clouds", Quality.setting(&"clouds"))
	mat.set_shader_parameter("zone_offset", shift)
	var tex := hm.height_texture()
	mat.set_shader_parameter("height_tex", tex["texture"])
	mat.set_shader_parameter("height_origin", tex["origin"])
	mat.set_shader_parameter("height_res", tex["res"])
	mat.set_shader_parameter("height_texels", tex["texels"])
	if keep.has_area():
		mat.set_shader_parameter("keep_rect", Vector4(keep.position.x, keep.position.y, keep.size.x, keep.size.y))
	var grid := _chunk_mesh(hm.step)
	var area := hm.extent()
	var cy := area.position.y
	while cy < area.end.y - 0.01:
		var cx := area.position.x
		while cx < area.end.x - 0.01:
			var cell := Rect2(cx, cy, CHUNK, CHUNK).intersection(area)
			if not keep.has_area() or keep.intersects(Rect2(cell.position + shift, cell.size)):
				var chunk := MeshInstance3D.new()
				chunk.mesh = grid
				chunk.material_override = mat
				chunk.position = Vector3(cx + CHUNK / 2.0 + shift.x, 0.0, cy + CHUNK / 2.0 + shift.y)
				var hr := hm.range_in(cell)
				chunk.custom_aabb = AABB(Vector3(-CHUNK / 2.0, hr.x - 0.5, -CHUNK / 2.0), Vector3(CHUNK, hr.y - hr.x + 1.0, CHUNK))
				if not r.indoor:
					chunk.visibility_range_end = VIEW_RANGE
					chunk.visibility_range_end_margin = 8.0
					chunk.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				_zone.add_child(chunk)
			cx += CHUNK
		cy += CHUNK
	return mat


static var _grids: Dictionary = {}


## What a map of zone `r` is drawn from, when it is not the one shown (MapScreen).
static func map_layers_for(r: Region) -> Dictionary:
	var hm := HeightMap.new(r, 2)
	var masks := _terrain_masks(r, hm)
	var tex := hm.height_texture()
	return {"terrain_mask": masks[0], "terrain_mask2": masks[1], "map_tiles": Vector2(hm.size),
		"height_tex": tex["texture"], "height_origin": tex["origin"], "height_res": tex["res"], "height_texels": tex["texels"]}


## What the map screen draws the current zone from: its ground masks and its relief.
func map_layers() -> Dictionary:
	var layers := {}
	for key in ["terrain_mask", "terrain_mask2", "map_tiles", "height_tex", "height_origin", "height_res", "height_texels"]:
		layers[key] = _ground_mat.get_shader_parameter(key)
	return layers


## A flat square grid of CHUNK metres, `step` vertices per metre (shared by all chunks).
static func _chunk_mesh(step: int) -> PlaneMesh:
	if not _grids.has(step):
		var m := PlaneMesh.new()
		m.size = Vector2(CHUNK, CHUNK)
		m.subdivide_width = CHUNK * step - 1
		m.subdivide_depth = CHUNK * step - 1
		_grids[step] = m
	return _grids[step]


## Two textures, one pixel per tile: [R path, G tall grass, B water] and [R sand, G forest].
static func _terrain_masks(r: Region, hm: HeightMap) -> Array[ImageTexture]:
	var a := Image.create(hm.size.x, hm.size.y, false, Image.FORMAT_RGB8)
	var b := Image.create(hm.size.x, hm.size.y, false, Image.FORMAT_RGB8)
	for y in hm.size.y:
		for x in hm.size.x:
			var s := r.surface_at(Vector2((x + 0.5) * PX, (y + 0.5) * PX))
			a.set_pixel(x, y, Color(1, 0, 0) if s == &"path" else Color(0, 1, 0) if s == &"tall_grass" else Color(0, 0, 1) if s == &"water" else Color.BLACK)
			b.set_pixel(x, y, Color(1, 0, 0) if s == &"sand" else Color(0, 1, 0) if s == &"forest" else Color.BLACK)
	return [ImageTexture.create_from_image(a), ImageTexture.create_from_image(b)]


func _build_water(hm: HeightMap, shift := Vector2.ZERO, keep := Rect2()) -> ShaderMaterial:
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(hm.size) + Vector2.ONE * hm.margin * 2.0
	plane.mesh = mesh
	plane.position = Vector3(hm.size.x / 2.0 + shift.x, HeightMap.WATER_LEVEL, hm.size.y / 2.0 + shift.y)
	var mat := ShaderMaterial.new()
	mat.shader = WATER
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	mat.set_shader_parameter("water_level", HeightMap.WATER_LEVEL)
	var ground := hm.height_texture()
	mat.set_shader_parameter("ground_height", ground["texture"])
	mat.set_shader_parameter("height_origin", ground["origin"])
	mat.set_shader_parameter("height_res", ground["res"])
	mat.set_shader_parameter("height_texels", ground["texels"])
	mat.set_shader_parameter("zone_offset", shift)
	if keep.has_area():
		mat.set_shader_parameter("keep_rect", Vector4(keep.position.x, keep.position.y, keep.size.x, keep.size.y))
	plane.material_override = mat
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_zone.add_child(plane)
	return mat


# ------------------------------------------------------------------ neighbours beyond the edges

## The zones next to this one, as seen from it: for each exit leading outdoors,
## {region, heights, shift (tiles), band (world tiles: the part of it shown beyond the edge)}.
func _neighbours(zones: Dictionary) -> Array:
	var out := []
	var here := _region.bounds()
	for exit in _region.exits():
		if not zones.has(exit.target_zone) or exit.target_zone == _region.region_id:
			continue
		var other := Region.open_for_preview(zones[exit.target_zone])
		var back: ZoneExit = null
		for e in other.exits():
			if e.target_zone == _region.region_id:
				back = e
		if other.indoor or back == null:
			other.free()
			continue
		var edge := _region.exit_edge(exit)
		var mine := _region.exit_rect(exit)
		var theirs := other.exit_rect(back)
		var there := other.bounds()
		# Their entrance joins our exit: centres aligned along the edge, edges touching.
		var shift := mine.get_center() - theirs.get_center()
		if edge.x > 0.0:
			shift.x = here.end.x - there.position.x
		elif edge.x < 0.0:
			shift.x = here.position.x - there.end.x
		elif edge.y > 0.0:
			shift.y = here.end.y - there.position.y
		else:
			shift.y = here.position.y - there.end.y
		shift /= PX
		# Along the edge, as wide as this zone's margins; beyond it, as far as the camera sees.
		var zone := Rect2(Vector2(here.position) / PX, Vector2(here.size) / PX)
		var beyond := zone.grow(float(heights.margin))
		var side := Rect2()
		if edge.x > 0.0:
			side = Rect2(zone.end.x, beyond.position.y, PREVIEW_DEPTH, beyond.size.y)
		elif edge.x < 0.0:
			side = Rect2(zone.position.x - PREVIEW_DEPTH, beyond.position.y, PREVIEW_DEPTH, beyond.size.y)
		elif edge.y > 0.0:
			side = Rect2(beyond.position.x, zone.end.y, beyond.size.x, PREVIEW_DEPTH)
		else:
			side = Rect2(beyond.position.x, zone.position.y - PREVIEW_DEPTH, beyond.size.x, PREVIEW_DEPTH)
		var band := side.intersection(Rect2(Vector2(there.position) / PX + shift, Vector2(there.size) / PX))
		if not band.has_area():
			other.free()
			continue
		_bands.append(band)
		out.append({"region": other, "heights": HeightMap.new(other, 2), "shift": shift, "band": band})
	return out


## This zone's ground and water are cut where a neighbour is shown.
func _set_holes(mat: ShaderMaterial) -> void:
	var holes: Array[Vector4] = []
	for b in _bands.slice(0, 4):
		holes.append(Vector4(b.position.x, b.position.y, b.size.x, b.size.y))
	while holes.size() < 4:
		holes.append(Vector4.ZERO)
	mat.set_shader_parameter("holes", holes)
	mat.set_shader_parameter("hole_count", mini(_bands.size(), 4))


## A neighbour's ground, water and scenery in its band beyond the edge.
func _build_neighbour(n: Dictionary) -> void:
	var r: Region = n["region"]
	var hm: HeightMap = n["heights"]
	var shift: Vector2 = n["shift"]
	var band: Rect2 = n["band"]
	# Heights meet exactly at the edge (no rolling near edges): the two grounds just touch.
	_build_ground(r, hm, shift, band)
	if hm.has_water:
		_build_water(hm, shift, band)
	var corridors := r.exits().map(func(e: ZoneExit) -> Rect2: return r.exit_corridor(e, Region.CORRIDOR_DEPTH))
	var groups := {}
	for p in r.entities.get_children():
		if not (p is Prop and p.get_script() == PROP_SCRIPT):
			continue
		var t: Vector2 = p.position / PX
		if not band.has_point(t + shift) or corridors.any(func(c: Rect2) -> bool: return c.has_point(p.position)):
			continue
		var at := Vector3(t.x + shift.x, hm.height(t), t.y + shift.y)
		if Prop.KINDS.get(p.kind, {}).get("float", false):
			at.y = maxf(at.y, HeightMap.WATER_LEVEL + 0.06)
		if not groups.has(p.kind):
			groups[p.kind] = []
		groups[p.kind].append([at, p.flip, 1.0])
	for kind: String in groups:
		_add_billboards(kind, groups[kind])
	_build_forest(r, hm, shift, band)
	r.free()


## Plain props (not obstacles, pickups, signs…) never change: one MultiMesh per kind.
func _build_scenery() -> void:
	var groups := {}   # kind -> Array of [position (m), flipped]
	for n in _region.entities.get_children():
		if n is Prop and n.get_script() == PROP_SCRIPT:
			if not groups.has(n.kind):
				groups[n.kind] = []
			var at := heights.to_3d(n.position)
			var def: Dictionary = Prop.KINDS.get(n.kind, {})
			if def.get("float", false):
				at.y = maxf(at.y, HeightMap.WATER_LEVEL + 0.06)
			groups[n.kind].append([at, n.flip, 1.0, n])
			if def.get("light", false) and Quality.setting(&"lights"):
				_add_lamp(at)
			if n.kind == "feu_camp":
				_add_fire(at)
	for kind: String in groups:
		_add_billboards(kind, groups[kind])


## Shakes (a tree searched) or lifts (a stone turned over) one scenery prop, for `time` s.
func nudge(prop: Node2D, shake: float, lift: float, time := 0.8) -> void:
	var ref: Array = _instances.get(prop, [])
	if ref.is_empty():
		return
	var mm: MultiMesh = ref[0]
	var i: int = ref[1]
	var base := mm.get_instance_custom_data(i)
	create_tween().tween_method(func(t: float) -> void:
		mm.set_instance_custom_data(i, Color(base.r, base.g, shake * (1.0 - t), lift * sin(PI * t))), 0.0, 1.0, time)


## A burst of little bits at `p` (2D world position): leaves from a tree, earth dug up,
## sparkles of amber. `colours`: picked at random per bit.
func burst(p: Vector2, colours: Array[Color], amount := 18, height := 1.0, spread := 0.8) -> void:
	var bits := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.16, 0.16)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	bits.mesh = quad
	bits.amount = Quality.scaled(amount)
	bits.one_shot = true
	bits.explosiveness = 0.9
	bits.lifetime = 1.3
	bits.direction = Vector3.UP
	bits.spread = 70.0
	bits.initial_velocity_min = 1.0
	bits.initial_velocity_max = 2.4
	bits.gravity = Vector3(0, -3.2, 0)
	bits.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	bits.emission_sphere_radius = spread
	# Each bit takes one of the colours (spread evenly along the initial-colour ramp).
	var ramp := Gradient.new()
	var offsets := PackedFloat32Array()
	for i in colours.size():
		offsets.append(i / maxf(colours.size() - 1.0, 1.0))
	ramp.offsets = offsets
	ramp.colors = PackedColorArray(colours)
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	bits.color_initial_ramp = ramp
	bits.scale_amount_min = 0.6
	bits.scale_amount_max = 1.3
	bits.position = heights.to_3d(p) + Vector3(0, height, 0)
	_zone.add_child(bits)
	bits.emitting = true
	bits.finished.connect(bits.queue_free)


## Something found pops up from `p` (2D world position), `height` m up, and fades away.
func pop_up(p: Vector2, picture: Texture2D, height := 0.3) -> void:
	var item := Sprite3D.new()
	item.texture = picture
	item.pixel_size = 0.4 / maxf(picture.get_width(), 1.0)
	item.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	item.no_depth_test = true
	item.render_priority = 9
	var from := heights.to_3d(p) + Vector3(0, height, 0)
	item.position = from
	_zone.add_child(item)
	var t := item.create_tween().set_parallel(true)
	t.tween_property(item, "position", from + Vector3(0, 1.1, 0), 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(item, "modulate:a", 0.0, 0.4).set_delay(1.0)
	t.chain().tween_callback(item.queue_free)


## A little sign over `who` (what the dino thinks: "~" the water, "♥" a fire…), rising
## and fading away.
func emote(who: Node2D, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 84
	label.outline_size = 26
	label.modulate = EMOTE_COLOURS.get(text, Color(0.26, 0.14, 0.05))
	label.outline_modulate = Color(1.0, 0.95, 0.85)
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 10
	var from := heights.to_3d(who.global_position) + Vector3(0.25, 1.9, 0)
	label.position = from
	_zone.add_child(label)
	var t := label.create_tween().set_parallel(true)
	t.tween_property(label, "position", from + Vector3(0, 0.5, 0), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(1.3)
	t.tween_property(label, "outline_modulate:a", 0.0, 0.5).set_delay(1.3)
	t.chain().tween_callback(label.queue_free)


## Shows (or hides) the "!" over Chloé's dino, which senses something hidden nearby.
func show_hint(dino: Node2D, on: bool) -> void:
	if _hint == null or not is_instance_valid(_hint):
		_hint = Label3D.new()
		_hint.text = "!"
		_hint.font_size = 110
		_hint.outline_size = 34
		_hint.modulate = Color(0.26, 0.14, 0.05)
		_hint.outline_modulate = Color(1.0, 0.84, 0.36)
		_hint.pixel_size = 0.014
		_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_hint.no_depth_test = true
		_hint.render_priority = 10
		_zone.add_child(_hint)
	_hint.visible = on
	if on:
		_hint.position = heights.to_3d(dino.global_position) + Vector3(0.25, 2.1 + 0.1 * sin(Time.get_ticks_msec() / 150.0), 0)


## A campfire's flame (the web version's picture, flickering), a few embers rising, and its
## wavering light.
func _add_fire(at: Vector3) -> void:
	var flame := Sprite3D.new()
	flame.texture = FLAME
	flame.pixel_size = FLAME_WIDTH / FLAME.get_width()
	flame.centered = false
	flame.offset = Vector2(-FLAME.get_width() / 2.0, 0.0)
	flame.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	flame.shaded = false
	flame.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame.position = at + Vector3(0, 0.08, 0.02)
	_zone.add_child(flame)
	# The web version's flicker: taller and narrower, back again, 170 ms each way.
	var t := flame.create_tween().set_loops()
	t.tween_property(flame, "scale", Vector3(0.9, 1.18, 1.0), 0.17).set_trans(Tween.TRANS_SINE)
	t.tween_property(flame, "scale", Vector3.ONE, 0.17).set_trans(Tween.TRANS_SINE)
	var embers := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = mat
	embers.mesh = quad
	embers.amount = Quality.scaled(8)
	embers.lifetime = 1.6
	embers.direction = Vector3.UP
	embers.spread = 20.0
	embers.initial_velocity_min = 0.4
	embers.initial_velocity_max = 0.8
	embers.gravity = Vector3(0.1, 0.2, 0)
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 0.15
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1.0, 0.8, 0.35, 1.0), Color(1.0, 0.35, 0.05, 0.0)])
	embers.color_ramp = fade
	embers.position = at + Vector3(0, 0.5, 0.05)
	_zone.add_child(embers)
	if Quality.setting(&"lights"):
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.62, 0.28)
		light.light_energy = 1.6
		light.omni_range = 5.0
		light.shadow_enabled = false
		light.position = at + Vector3(0, 0.8, 0.2)
		_zone.add_child(light)
		var w := light.create_tween().set_loops()
		w.tween_property(light, "light_energy", 1.2, 0.13).set_trans(Tween.TRANS_SINE)
		w.tween_property(light, "light_energy", 1.8, 0.17).set_trans(Tween.TRANS_SINE)
		w.tween_property(light, "light_energy", 1.4, 0.11).set_trans(Tween.TRANS_SINE)


## A warm glow around a lantern, a lamp, the incubator.
func _add_lamp(at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.72, 0.38)
	light.light_energy = 1.1
	light.omni_range = 4.0
	light.shadow_enabled = false
	light.position = at + Vector3(0, 1.6, 0.3)
	light.set_meta(&"lamp", true)
	_zone.add_child(light)


## A dark opening in a rock face (a cave entrance): a vertical arch, black inside, soft
## at its edges, standing on the ground in front of the face and facing the camera (south).
func _build_cave_mouth(mouth: Node2D) -> void:
	var t: Vector2 = mouth.position / PX
	var w: float = mouth.get("width")
	var h: float = mouth.get("height")
	# The floor in front of the face, then the face itself: where the ground comes down to it.
	var foot := heights.height(t + Vector2(0.0, 0.9))
	var z := t.y - 0.5
	while z < t.y + 0.9 and heights.height(Vector2(t.x, z)) > foot + 0.1:
		z += 0.05
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	quad.center_offset = Vector3(0.0, h / 2.0 - 0.1, 0.0)
	var mat := ShaderMaterial.new()
	mat.shader = CAVE
	quad.material = mat
	var inst := MeshInstance3D.new()
	inst.mesh = quad
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.position = Vector3(t.x, foot, z + 0.03)
	_zone.add_child(inst)
	_add_contact_shadows([[Vector3(t.x, foot, z + 0.35), w * 1.1]])


## Planks on posts over the water.
func _build_dock(dock: Dock) -> void:
	var area := dock.area()
	var top := HeightMap.DOCK_TOP
	var size := Vector3(area.size.x / PX, 0.22, area.size.y / PX)
	var deck := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = load("res://assets/art/ground/plancher.png")
	wood.uv1_triplanar = true
	wood.uv1_scale = Vector3.ONE / 2.5
	wood.roughness = 0.9
	box.material = wood
	deck.mesh = box
	var corner := Vector3(area.position.x / PX, 0.0, area.position.y / PX)
	deck.position = corner + Vector3(size.x / 2.0, top - size.y / 2.0, size.z / 2.0)
	_zone.add_child(deck)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.3, 0.2, 0.13)
	post_mat.roughness = 1.0
	var z := 0.0
	while z <= size.z + 0.01:
		for x: float in [0.08, size.x - 0.08]:
			var post := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.09
			cyl.bottom_radius = 0.09
			cyl.height = 1.6
			cyl.material = post_mat
			post.mesh = cyl
			post.position = corner + Vector3(x, top - 0.8 + 0.12, minf(z, size.z - 0.08))
			_zone.add_child(post)
		z += 2.0


## Pictures of one prop kind standing at `items` ([position, flipped, scale]).
func _add_billboards(kind: String, items: Array, shadows := true) -> void:
	var def: Dictionary = Prop.KINDS[kind]
	var tex: Texture2D = load(Prop.ART % kind)
	var metres := float(def["scale"]) / PX
	var quad := QuadMesh.new()
	quad.size = Vector2(tex.get_width(), tex.get_height()) * metres
	quad.center_offset = Vector3(0, (tex.get_height() / 2.0 - tex.get_height() * float(def["foot"])) * metres, 0)
	var mat := ShaderMaterial.new()
	mat.shader = BILLBOARD
	mat.set_shader_parameter("tex", tex)
	mat.set_shader_parameter("stretch", STRETCH)
	if Quality.setting(&"sway_props"):
		mat.set_shader_parameter("sway", float(def["sway"]) / PX)
		mat.set_shader_parameter("push", float(def["sway"]) * 3.0 / PX)
	mat.set_shader_parameter("occluder", quad.size.y * STRETCH > OCCLUDER_HEIGHT)
	mat.set_shader_parameter("half_width", quad.size.x * 0.5)
	mat.set_shader_parameter("roundness", ROUNDNESS.get(kind, 0.4))
	quad.material = mat
	_add_multimesh(quad, items, shadows)
	var foot := float(def["shadow"]) / PX
	if foot > 0.0:
		_add_contact_shadows(items.map(func(it: Array) -> Array: return [it[0], foot * float(it[2])]))


## Instances of one picture, split into chunks (each culled and faded alone).
func _add_multimesh(quad: QuadMesh, items: Array, shadows: bool, range_end := VIEW_RANGE) -> void:
	var chunks := {}
	for it: Array in items:
		var at: Vector3 = it[0]
		var key := Vector2i(floori(at.x / CHUNK), floori(at.z / CHUNK))
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(it)
	var reach := maxf(quad.size.x, quad.size.y) * STRETCH
	for key: Vector2i in chunks:
		var list: Array = chunks[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = quad
		mm.instance_count = list.size()
		var lo := Vector3(INF, INF, INF)
		var hi := -lo
		for i in list.size():
			var it: Array = list[i]
			var at: Vector3 = it[0]
			mm.set_instance_transform(i, Transform3D(Basis(), at))
			mm.set_instance_custom_data(i, Color(1.0 if it[1] else 0.0, it[2], 0.0, 0.0))
			if it.size() > 3:
				_instances[it[3]] = [mm, i]
			lo = lo.min(at)
			hi = hi.max(at)
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Pictures stand up and sway in the shader: a box around them all, a bit larger.
		inst.custom_aabb = AABB(lo - Vector3(reach, 1.0, reach), hi - lo + Vector3(reach * 2.0, reach * 1.6 + 1.0, reach * 2.0))
		if not _region.indoor:
			inst.visibility_range_end = range_end
			inst.visibility_range_end_margin = 6.0
			inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		_zone.add_child(inst)


## Trees filling the "forest" tiles of zone `r` (inside `keep`, world tiles, when given).
func _build_forest(r: Region, hm: HeightMap, shift := Vector2.ZERO, keep := Rect2()) -> void:
	var density: float = Quality.setting(&"forest_density")
	var groups := {}
	for y in hm.size.y:
		for x in hm.size.x:
			if r.surface_at(Vector2((x + 0.5) * PX, (y + 0.5) * PX)) != &"forest":
				continue
			if keep.has_area() and not keep.has_point(Vector2(x + 0.5, y + 0.5) + shift):
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(Vector2i(x, y) * 7 + Vector2i(3, 11))
			var count := int(density) + (1 if rng.randf() < fmod(density, 1.0) else 0)
			for i in count:
				var t := Vector2(x + rng.randf_range(0.1, 0.9), y + rng.randf_range(0.2, 0.95))
				var kind: String = FOREST_TREES[rng.randi() % FOREST_TREES.size()]
				# Bushes mostly, along a path: the trees would hide it (and what lies on it).
				if rng.randf() < (0.7 if _by_path(r, x, y) else 0.18):
					kind = "buisson"
				if not groups.has(kind):
					groups[kind] = []
				groups[kind].append([Vector3(t.x + shift.x, hm.height(t), t.y + shift.y), rng.randf() < 0.5, rng.randf_range(0.9, 1.3)])
	for kind: String in groups:
		_add_billboards(kind, groups[kind])


static func _by_path(r: Region, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if r.surface_at(Vector2((x + dx + 0.5) * PX, (y + dy + 0.5) * PX)) == &"path":
				return true
	return false


func _build_tall_grass() -> void:
	var items := []
	var tufts: int = Quality.setting(&"grass_tufts") + 1
	for y in heights.size.y:
		for x in heights.size.x:
			if _region.surface_at(Vector2((x + 0.5) * PX, (y + 0.5) * PX)) != &"tall_grass":
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(Vector2i(x, y))
			for i in tufts:
				var p := Vector2(x + rng.randf_range(0.1, 0.9), y + (i + 0.5 + rng.randf_range(-0.2, 0.2)) / tufts)
				items.append([Vector3(p.x, heights.height(p), p.y), rng.randf() < 0.5, rng.randf_range(0.85, 1.12)])
	if items.is_empty():
		return
	var metres := 0.23 / PX
	var quad := QuadMesh.new()
	quad.size = Vector2(TUFT.get_width(), TUFT.get_height()) * metres
	quad.center_offset = Vector3(0, (TUFT.get_height() / 2.0 - TUFT.get_height() * 0.06) * metres, 0)
	var mat := ShaderMaterial.new()
	mat.shader = BILLBOARD
	mat.set_shader_parameter("tex", TUFT)
	mat.set_shader_parameter("stretch", STRETCH)
	mat.set_shader_parameter("sway", 3.0 / PX)
	mat.set_shader_parameter("push", 16.0 / PX)
	mat.set_shader_parameter("stiffness", 1.4)
	mat.set_shader_parameter("roundness", 0.2)
	mat.set_shader_parameter("base_shade", 0.35)
	quad.material = mat
	_add_multimesh(quad, items, false, GRASS_RANGE)


## Soft dark patches on the ground under standing things: [position, width (m)].
func _add_contact_shadows(items: Array) -> void:
	var chunks := {}
	for it: Array in items:
		var at: Vector3 = it[0]
		var key := Vector2i(floori(at.x / CHUNK), floori(at.z / CHUNK))
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(it)
	for key: Vector2i in chunks:
		var list: Array = chunks[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _contact()
		mm.instance_count = list.size()
		for i in list.size():
			var w: float = list[i][1] * 1.15
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(w, 1.0, w * 0.62)), list[i][0] + Vector3(0, 0.03, 0)))
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if not _region.indoor:
			inst.visibility_range_end = VIEW_RANGE
		_zone.add_child(inst)


func _contact() -> PlaneMesh:
	if _contact_mesh == null:
		_contact_mesh = PlaneMesh.new()
		_contact_mesh.size = Vector2.ONE
		var mat := ShaderMaterial.new()
		mat.shader = CONTACT
		_contact_mesh.material = mat
	return _contact_mesh


## Woods all around, beyond the zone's edges, so the view never ends on bare ground.
func _build_outer_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_region.region_id)
	var groups := {}
	var w := heights.size.x
	var h := heights.size.y
	var ways_out := _region.exits().map(func(e: ZoneExit) -> Rect2: return _region.exit_corridor(e, -heights.margin))
	for b in _bands:
		ways_out.append(Rect2(b.position * PX, b.size * PX))
	for i in 220:
		var p := Vector2(rng.randf_range(-heights.margin + 1, w + heights.margin - 1), rng.randf_range(-heights.margin + 1, h + heights.margin - 1))
		if p.x > -0.5 and p.x < w + 0.5 and p.y > -0.5 and p.y < h + 0.5:
			continue
		if heights.height(p) < HeightMap.WATER_LEVEL + 0.1:   # the sea goes on out there
			continue
		if heights.height(p) > 2.5:   # mountains out there: bare rock and grass
			continue
		if ways_out.any(func(c: Rect2) -> bool: return c.has_point(p * PX)):   # the path goes on
			continue
		var near_side := p.y > h - 0.5
		var kinds: Array = OUTER_LOW if near_side else OUTER_TREES
		var kind: String = kinds[rng.randi() % kinds.size()]
		if not groups.has(kind):
			groups[kind] = []
		groups[kind].append([Vector3(p.x, heights.height(p), p.y), rng.randf() < 0.5, rng.randf_range(0.9, 1.25)])
	for kind: String in groups:
		_add_billboards(kind, groups[kind])


# ------------------------------------------------------------------ mirrored 2D nodes

func _on_entity_added(node: Node) -> void:
	_track.call_deferred(node)   # its sprite is set up in its _ready


## Mirrors a 2D node that moves or changes (not plain scenery, built once in MultiMeshes).
func _track(node: Node) -> void:
	if not is_instance_valid(node) or not node is Node2D or node is TallGrass:
		return
	if node is Prop and node.get_script() == PROP_SCRIPT:
		return
	for p in _proxies:
		if p["src"] == node:
			return
	var sprite: Node2D = node.get("sprite") if "sprite" in node else node.get_node_or_null("Sprite")
	if sprite == null:
		return
	var vis: SpriteBase3D = AnimatedSprite3D.new() if sprite is AnimatedSprite2D else Sprite3D.new()
	vis.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	vis.shaded = true
	# Props stand still: cut out like the scenery (see _sync), so they write depth and a
	# character in front of a big facade is never drawn behind it (the rest is only sorted).
	vis.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	vis.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	vis.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_zone.add_child(vis)
	var proxy := {"src": node, "sprite": sprite, "vis": vis, "light": null, "glow": null,
		"prev": node.global_position, "cur": node.global_position, "foot": null, "foot_2d": null}
	var shadow_2d := node.get_node_or_null("Shadow") as Sprite2D
	if shadow_2d:
		var foot := MeshInstance3D.new()
		foot.mesh = _contact()
		foot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_zone.add_child(foot)
		proxy["foot"] = foot
		proxy["foot_2d"] = shadow_2d
	for child in node.get_children():
		if child is PointLight2D:
			var light := OmniLight3D.new()
			light.light_color = child.color
			light.omni_range = 3.0
			_zone.add_child(light)
			proxy["light"] = light
			proxy["glow"] = child
	_proxies.append(proxy)
	_sync(proxy)


func _free_proxy(p: Dictionary) -> void:
	for key in ["vis", "light", "foot"]:
		if p[key] and is_instance_valid(p[key]):
			p[key].queue_free()


func _process(delta: float) -> void:
	for i in range(_proxies.size() - 1, -1, -1):
		var p := _proxies[i]
		if not is_instance_valid(p["src"]) or not (p["src"] as Node).is_inside_tree() or not is_instance_valid(p["sprite"]):
			_free_proxy(p)
			_proxies.remove_at(i)
			continue
		_sync(p)
	if player and heights:
		var feet := heights.to_3d(_player_prev.lerp(_player_cur, Engine.get_physics_interpolation_fraction()))
		camera.target = feet
		RenderingServer.global_shader_parameter_set(&"player_world", feet)
		_pollen.position = camera.target + Vector3(0, 1.5, 0)
		_wildlife.heights = heights
		_wildlife.update(delta, camera.target, Game.clock / 60.0, _rain_amount, not _region.indoor)
		_rain.position = camera.target + Vector3(0, 9.0, 2.0)
	var blend := 1.0 - exp(-WEATHER_BLEND * delta)
	_rain_amount = lerpf(_rain_amount, 1.0 if Game.is_raining() else 0.0, blend)
	_storm_amount = lerpf(_storm_amount, 1.0 if Game.weather == &"storm" else 0.0, blend)
	_lightning(delta)
	_mist_amount = lerpf(_mist_amount, 1.0 if Game.weather == &"mist" else 0.0, blend)
	_update_sky(Game.clock / 60.0)
	_magic.update(delta, _region, player, _sun, _env)
	(camera.attributes as CameraAttributesPractical).dof_blur_far_distance = camera.distance() + 13.0


func _sync(p: Dictionary) -> void:
	var src: Node2D = p["src"]
	var sprite: Node2D = p["sprite"]
	var vis: SpriteBase3D = p["vis"]
	vis.visible = _shown(sprite)
	var local := sprite.position
	var at: Vector2 = (p["prev"] as Vector2).lerp(p["cur"], Engine.get_physics_interpolation_fraction())
	vis.position = heights.to_3d(at) + Vector3(local.x / PX, -local.y / PX * STRETCH, 0)
	var gs := sprite.global_scale
	if absf(gs.x) > 0.0001:
		vis.pixel_size = absf(gs.x) / PX
		vis.scale = Vector3(1.0, STRETCH * absf(gs.y / gs.x), 1.0)
	vis.offset = Vector2(sprite.offset.x, -sprite.offset.y)
	vis.flip_h = sprite.flip_h
	# Cut out (writes depth, like the scenery): props, and a mount, whose body hides Chloé's legs.
	var cut := SpriteBase3D.ALPHA_CUT_DISCARD if src is Prop or src.get_meta(&"cut_out", false) else SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	if vis.alpha_cut != cut:
		vis.alpha_cut = cut
	vis.modulate = src.modulate * sprite.modulate * sprite.self_modulate
	if sprite is AnimatedSprite2D:
		var anim := vis as AnimatedSprite3D
		if anim.sprite_frames != sprite.sprite_frames:
			anim.sprite_frames = sprite.sprite_frames
		if anim.animation != sprite.animation:
			anim.animation = sprite.animation
		anim.frame = sprite.frame
	else:
		(vis as Sprite3D).texture = (sprite as Sprite2D).texture
	if p["foot"]:
		var foot: MeshInstance3D = p["foot"]
		var shadow_2d: Sprite2D = p["foot_2d"]
		foot.visible = vis.visible and is_instance_valid(shadow_2d) and shadow_2d.visible
		if foot.visible:
			var w := absf(shadow_2d.global_scale.x) * Shadow.BASE_PX / PX * 1.2
			foot.transform = Transform3D(Basis.from_scale(Vector3(w, 1.0, w * 0.62)), heights.to_3d(at) + Vector3(0, 0.03, 0))
			foot.transparency = 1.0 - (src.modulate.a * sprite.modulate.a)
	if p["light"]:
		var glow = p["glow"]   # untyped: the light may have been freed (a corrupted dino calmed)
		var light: OmniLight3D = p["light"]
		light.visible = is_instance_valid(glow) and _shown(glow)
		if light.visible:
			light.light_energy = (glow as PointLight2D).energy * 1.4
			light.position = vis.position + Vector3(0, 0.5, 0.2)


func _physics_process(_delta: float) -> void:
	for p in _proxies:
		if is_instance_valid(p["src"]):
			_step(p, (p["src"] as Node2D).global_position)
	if player:
		var now := player.global_position
		_player_prev = now if now.distance_to(_player_cur) > TELEPORT else _player_cur
		_player_cur = now


## New physics position of a mirrored node; a jump (teleport, spawn) is not blended.
func _step(p: Dictionary, now: Vector2) -> void:
	p["prev"] = now if now.distance_to(p["cur"]) > TELEPORT else p["cur"]
	p["cur"] = now


## Visible in the zone (the 2D world itself is hidden, so is_visible_in_tree() is always false).
func _shown(item: CanvasItem) -> bool:
	var n: Node = item
	while n and n != _region:
		if n is CanvasItem and not (n as CanvasItem).visible:
			return false
		n = n.get_parent()
	return true


# ------------------------------------------------------------------ effects

## 2D particles appearing in the zone (debris of a boulder…) get a 3D twin.
func _on_node_added(node: Node) -> void:
	if node is CPUParticles2D and _region and _region.is_ancestor_of(node):
		_mirror_particles.call_deferred(node)


func _mirror_particles(p2: CPUParticles2D) -> void:
	if not is_instance_valid(p2) or not p2.is_inside_tree():
		return
	var p := CPUParticles3D.new()
	p.amount = p2.amount
	p.lifetime = p2.lifetime
	p.one_shot = p2.one_shot
	p.explosiveness = p2.explosiveness
	p.direction = Vector3(p2.direction.x, -p2.direction.y, 0.0)
	p.spread = p2.spread
	p.gravity = Vector3(p2.gravity.x, -p2.gravity.y, 0.0) / PX
	p.initial_velocity_min = p2.initial_velocity_min / PX
	p.initial_velocity_max = p2.initial_velocity_max / PX
	p.scale_amount_min = p2.scale_amount_min
	p.scale_amount_max = p2.scale_amount_max
	p.color = p2.color
	p.color_ramp = p2.color_ramp
	p.mesh = _speck(0.045)
	var parent := p2.get_parent() as Node2D
	p.position = heights.to_3d(parent.global_position if parent else p2.global_position) + Vector3(p2.position.x / PX, -p2.position.y / PX, 0)
	_zone.add_child(p)
	p.emitting = true
	get_tree().create_timer(p.lifetime + 1.0).timeout.connect(p.queue_free)


## A small camera-facing square taking the particle colour.
static func _speck(size: float) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _soft_dot()
	q.material = m
	return q


static var _dot: GradientTexture2D


## A round spot fading at its edge (particles are soft dots, not squares).
static func _soft_dot() -> GradientTexture2D:
	if _dot == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.55, Color(1, 1, 1, 0.85))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		_dot = GradientTexture2D.new()
		_dot.gradient = g
		_dot.fill = GradientTexture2D.FILL_RADIAL
		_dot.fill_from = Vector2(0.5, 0.5)
		_dot.fill_to = Vector2(1.0, 0.5)
		_dot.width = 32
		_dot.height = 32
	return _dot


## Motes of pollen floating in the light around Chloé.
func _make_pollen() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = POLLEN_MOTES
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(14, 2.5, 10)
	p.direction = Vector3(1, 0.3, 0)
	p.spread = 60.0
	p.gravity = Vector3(0.08, 0.05, 0)
	p.initial_velocity_min = 0.08
	p.initial_velocity_max = 0.3
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 0.95, 0.7, 0))
	fade.add_point(0.2, Color(1, 0.95, 0.7, 0.8))
	fade.add_point(0.8, Color(1, 0.95, 0.7, 0.8))
	fade.set_color(fade.get_point_count() - 1, Color(1, 0.95, 0.7, 0))
	p.color_ramp = fade
	p.mesh = _speck(0.06)
	return p


## Rain streaks falling around the camera's focus.
func _make_rain() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = RAIN_DROPS
	p.lifetime = 0.9
	p.local_coords = false
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(15, 0.5, 12)
	p.direction = Vector3(0.08, -1, 0)
	p.spread = 3.0
	p.initial_velocity_min = 11.0
	p.initial_velocity_max = 14.0
	p.gravity = Vector3(0, -9.0, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.008, 0.3)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	p.mesh = q
	return p


# ------------------------------------------------------------------ sky

## In a storm, a flash of lightning now and then, and its thunder a moment later (farther
## away: later and softer).
func _lightning(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 3.5)
	if _storm_amount < 0.5 or (_region and _region.indoor):
		return
	_next_lightning -= delta
	if _next_lightning > 0.0:
		return
	_next_lightning = randf_range(LIGHTNING_EVERY.x, LIGHTNING_EVERY.y)
	_flash = 1.0
	# A second, weaker flicker just after, like real lightning.
	get_tree().create_timer(0.12).timeout.connect(func() -> void: _flash = maxf(_flash, 0.6))
	var far := randf()
	get_tree().create_timer(lerpf(0.4, 2.8, far)).timeout.connect(func() -> void:
		Audio.play_sfx(THUNDER[0 if far > 0.5 else 1], lerpf(-3.0, -10.0, far), 0.08))


## Inside: a warm light from above, dimmer and bluer at night; no weather, black around.
func _indoor_light(hour: float) -> void:
	var night := hour >= 21.0 or hour < 6.0
	if _region.cave:
		night = true   # no daylight down there
	_sun.rotation_degrees = Vector3(-62.0, 20.0, 0.0)
	_sun.light_color = Color(1.0, 0.86, 0.68) if not night else Color(0.55, 0.62, 0.95)
	_sun.light_energy = 0.9 if not night else 0.25
	_env.ambient_light_color = Color(0.85, 0.72, 0.58) if not night else Color(0.22, 0.25, 0.4)
	_env.ambient_light_energy = 0.8 if not night else 0.5
	_env.background_color = Color(0.02, 0.02, 0.025)
	_env.fog_light_color = _env.background_color
	_env.fog_depth_begin = 200.0
	_env.fog_depth_end = 300.0
	_pollen.visible = false
	_rain.emitting = false
	if _ground_mat:
		_ground_mat.set_shader_parameter("wetness", 0.0)
	for n in _zone.get_children():
		if n.has_meta(&"lamp"):
			(n as OmniLight3D).light_energy = 1.1 if not night else 1.6
			if _region.cave:
				(n as OmniLight3D).omni_range = 6.0
	RenderingServer.global_shader_parameter_set(&"sun_dir", _sun.global_transform.basis.z.normalized())
	RenderingServer.global_shader_parameter_set(&"sun_light", clampf(_sun.light_energy / 1.25, 0.0, 1.0))


func _update_sky(hour: float) -> void:
	if _region and _region.indoor:
		_indoor_light(hour)
		return
	var a: Array = DAYLIGHT[0]
	var b: Array = DAYLIGHT[1]
	for i in DAYLIGHT.size() - 1:
		if hour <= DAYLIGHT[i + 1][0]:
			a = DAYLIGHT[i]
			b = DAYLIGHT[i + 1]
			break
	var t := smoothstep(a[0], b[0], hour) if b[0] > a[0] else 0.0
	var rain := _rain_amount
	var mist := _mist_amount
	_sun.rotation_degrees = Vector3(-lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), 0.0)
	_sun.light_color = (a[3] as Color).lerp(b[3], t)
	_sun.light_energy = lerpf(a[4], b[4], t) * (1.0 - 0.65 * rain) * (1.0 - 0.4 * mist)
	var sky := (a[7] as Color).lerp(b[7], t)
	var bright := clampf(sky.get_luminance() / 0.75, 0.15, 1.0)
	sky = sky.lerp(Color(0.55, 0.58, 0.62) * bright, rain * 0.8).lerp(Color(0.82, 0.84, 0.86) * bright, mist * 0.85)
	_env.ambient_light_color = (a[5] as Color).lerp(b[5], t).lerp(Color(0.62, 0.65, 0.7) * bright, rain * 0.5 + mist * 0.4)
	_env.ambient_light_energy = lerpf(a[6], b[6], t) * (1.0 + 0.2 * mist)
	_env.background_color = sky
	_env.fog_light_color = sky
	# Mist: clear around Chloé (the camera is ~distance away), thick a few metres beyond.
	var near := camera.distance()
	_env.fog_depth_begin = lerpf(lerpf(near + 8.0, near + 2.0, rain), near - 1.0, mist)
	_env.fog_depth_end = lerpf(lerpf(near + 46.0, near + 28.0, rain), near + 14.0, mist)
	_pollen.visible = hour > 6.0 and hour < 20.0 and rain < 0.3
	# Fine, faint streaks; a storm: more of them, a little more visible.
	_rain.emitting = rain > 0.05
	var drops := Quality.scaled(roundi(RAIN_DROPS * (STORM_RAIN if _storm_amount > 0.5 else 1.0)))
	if _rain.amount != drops:
		_rain.amount = drops
	_rain.color = Color(0.82, 0.87, 0.96, (0.16 + 0.08 * _storm_amount) * rain)
	# A storm: a darker sky, and the lightning's flash.
	var gloom := 1.0 - 0.5 * _storm_amount
	_sun.light_energy *= gloom
	_env.ambient_light_energy = _env.ambient_light_energy * gloom + _flash * 2.2
	_env.background_color = _env.background_color * gloom
	_env.fog_light_color = _env.background_color
	if _ground_mat:
		_ground_mat.set_shader_parameter("wetness", rain)
	RenderingServer.global_shader_parameter_set(&"sun_dir", _sun.global_transform.basis.z.normalized())
	RenderingServer.global_shader_parameter_set(&"sun_light", clampf(_sun.light_energy / 1.25, 0.0, 1.0))
