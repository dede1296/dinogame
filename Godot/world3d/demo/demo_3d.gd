extends Node3D
## The 3D test ground of phase 1 (docs/migration-3d.md): a meadow with what Chloé's body and the
## camera must handle — a gentle ramp up to a 1.2 m terrace (a relief level of the 2.5D zones), a
## slope too steep to climb, low steps, a long wall the camera must not go through, a few rocks;
## (phase 2) crates to jump on and a sign to read; (phase 3) two wild Velociraptors living to the
## south, on a navigation mesh baked from the ground and the blocks when the scene starts.
## Built in code so the test (tools/test_world3d.gd) and this scene share the same marks (Marks).
## Not saved: the game's save stays off here (Save.enabled is only set by the 2.5D world).
## The 3D version targets the PC: keyboard, mouse and gamepad; no on-screen controls.

const PLAYER := preload("res://world3d/player/player_3d.tscn")
const GRASS := preload("res://assets/art/ground/herbe.png")
const ROCK := preload("res://assets/art/ground/falaise.png")
const DIRT := preload("res://assets/art/ground/terre.png")

const GROUND_SIZE := 80.0
const TERRACE_HEIGHT := 1.2       # one relief level of the 2.5D zones (Region: 1.2 m)
const GENTLE_DEG := 18.0
const STEEP_DEG := 55.0
const STEP_HEIGHT := 0.15

## Where things are, for the test as much as for the scene: name → [position, yaw (degrees)].
const MARKS := {
	&"start": [Vector3(0, 0.6, 0), 180.0],
	&"before_steep": [Vector3(-12, 0, 2.5), 180.0],
	&"before_ramp": [Vector3(12, 0, 3.0), 180.0],
	&"by_wall": [Vector3(0, 0, -16.6), 0.0],
	&"before_steps": [Vector3(-4, 0, 9.0), 0.0],
	&"before_low_box": [Vector3(6, 0, 8.2), 180.0],
	&"before_high_box": [Vector3(10, 0, 8.2), 180.0],
	&"before_sign": [Vector3(-3, 0, 5.0), 180.0],
	&"near_raptors": [Vector3(9, 0, 13), 0.0],
	&"far_away": [Vector3(-30, 0, -30), 0.0],
}
## The raptors: home (they amble about it) and level — a grown one (DinoSize.GROWN_LEVEL 14) and a
## young one as met in the Plaines (levels 4–6, DexPlaces), half its size.
const RAPTOR_HOMES: Array[Vector3] = [Vector3(8, 0, 22), Vector3(11, 0, 24.5)]
const RAPTOR_LEVELS: Array[int] = [14, 5]
const NAV_GROUP := &"nav_source"
const LOW_BOX := 0.5          # jumped onto
const HIGH_BOX := 1.0         # too high to jump onto (Player3D.JUMP_HEIGHT 0.65)
const WOOD := preload("res://assets/art/ground/plancher.png")
const SIGN_LINES: Array[Dictionary] = [
	{"who": "", "text": "Terrain d'essai d'Ambrelune en 3D. Les vrais lieux de l'île viendront ici, un par un."},
	{"who": "Chloé", "text": "Une caisse basse, une caisse haute… Voyons voir jusqu'où je saute."},
]

var player: Player3D
var signpost: Interactable3D
var raptors: Array[Dinosaur3D] = []
var navigation: NavigationRegion3D


func _ready() -> void:
	_add_environment()
	_add_ground()
	_add_ramps()
	_add_wall_and_rocks()
	_add_steps()
	_add_jump_boxes()
	signpost = _add_sign(Vector3(-3, 0, 4))
	_add_navigation()
	_add_raptors()
	player = PLAYER.instantiate()
	add_child(player)
	place(&"start")
	_add_caption()


## The ground the dinos can walk, worked out from the solid blocks (their group NAV_GROUP).
func _add_navigation() -> void:
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = Layers3D.WORLD
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh.geometry_source_group_name = NAV_GROUP
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	mesh.agent_radius = 0.5   # a multiple of cell_size
	mesh.agent_height = 1.0
	mesh.agent_max_climb = 0.25
	mesh.agent_max_slope = 40.0
	navigation = NavigationRegion3D.new()
	navigation.name = "Navigation"
	navigation.navigation_mesh = mesh
	add_child(navigation)
	navigation.bake_navigation_mesh(false)


func _add_raptors() -> void:
	var species := Species3D.of(&"velociraptor")
	for i in RAPTOR_HOMES.size():
		var raptor := Dinosaur3D.create(species, RAPTOR_LEVELS[i])
		raptor.position = RAPTOR_HOMES[i] + Vector3(0, 0.3, 0)
		raptor.home = RAPTOR_HOMES[i]
		add_child(raptor)
		raptors.append(raptor)


## Puts Chloé on a mark (see MARKS) and the camera behind her.
func place(mark: StringName) -> void:
	var m: Array = MARKS[mark]
	player.place_at(m[0], deg_to_rad(m[1]))
	player.pivot.set_view(m[1] + 180.0, CameraPivot.PITCH_DEFAULT)
	player.pivot.snap()


func _add_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.36, 0.55, 0.82)
	sky_mat.sky_horizon_color = Color(0.86, 0.80, 0.68)
	sky_mat.ground_horizon_color = Color(0.70, 0.66, 0.56)
	sky_mat.ground_bottom_color = Color(0.30, 0.28, 0.24)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.82, 0.80, 0.74)
	env.fog_density = 0.004
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.93, 0.80)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)


func _add_ground() -> void:
	_block(Vector3(GROUND_SIZE, 1.0, GROUND_SIZE), Vector3(0, -0.5, 0), Vector3.ZERO, GRASS, 0.5)
	# a dirt path from the start to the wall, to see the ground move under her feet
	_block(Vector3(2.5, 0.02, 18.0), Vector3(0, 0.01, -7.0), Vector3.ZERO, DIRT, 0.5, false)


## The terrace (one relief level, 1.2 m) east, reached by a gentle ramp; west, a slope too steep.
func _add_ramps() -> void:
	_block(Vector3(8.0, TERRACE_HEIGHT, 8.0), Vector3(12, TERRACE_HEIGHT * 0.5, -6.0), Vector3.ZERO, ROCK, 0.5)
	var run := TERRACE_HEIGHT / tan(deg_to_rad(GENTLE_DEG))
	var length := TERRACE_HEIGHT / sin(deg_to_rad(GENTLE_DEG))
	_block(Vector3(3.0, 0.2, length), Vector3(12, TERRACE_HEIGHT * 0.5 - 0.1 * cos(deg_to_rad(GENTLE_DEG)), -2.0 + run * 0.5),
		Vector3(GENTLE_DEG, 0, 0), DIRT, 0.5)
	_block(Vector3(8.0, 4.0, 8.0), Vector3(-12, 2.0, -6.0), Vector3.ZERO, ROCK, 0.5)
	var steep_len := 4.0 / sin(deg_to_rad(STEEP_DEG))
	var steep_run := 4.0 / tan(deg_to_rad(STEEP_DEG))
	_block(Vector3(3.0, 0.2, steep_len), Vector3(-12, 2.0 - 0.1 * cos(deg_to_rad(STEEP_DEG)), -2.0 + steep_run * 0.5),
		Vector3(STEEP_DEG, 0, 0), ROCK, 0.5)


## A long wall north (the camera must stay on Chloé's side of it) and a few rocks.
func _add_wall_and_rocks() -> void:
	_block(Vector3(20.0, 3.0, 1.0), Vector3(0, 1.5, -18.0), Vector3.ZERO, ROCK, 0.5)
	var rocks := [[Vector3(5, 0.5, 5), 1.2], [Vector3(-6, 0.7, -10), 1.6], [Vector3(7, 0.4, 12), 0.9], [Vector3(-8, 0.9, 14), 2.0]]
	for r: Array in rocks:
		var size: float = r[1]
		_block(Vector3(size, size * 0.8, size * 1.1), r[0], Vector3(0, 25.0 * size, 6.0), ROCK, 0.6)


## Low steps south-west: four of 15 cm, the height of a kerb.
func _add_steps() -> void:
	for i in 4:
		var h := STEP_HEIGHT * (i + 1)
		_block(Vector3(3.0, h, 1.0), Vector3(-4, h * 0.5, 11.0 + i), Vector3.ZERO, DIRT, 0.5)


## Two crates south-east: one she jumps onto, one too high.
func _add_jump_boxes() -> void:
	_block(Vector3(1.5, LOW_BOX, 1.5), Vector3(6, LOW_BOX * 0.5, 7.0), Vector3.ZERO, WOOD, 1.0)
	_block(Vector3(1.5, HIGH_BOX, 1.5), Vector3(10, HIGH_BOX * 0.5, 7.0), Vector3.ZERO, WOOD, 1.0)


## A wooden sign that reads out SIGN_LINES in the game's dialogue box.
func _add_sign(at: Vector3) -> Interactable3D:
	_block(Vector3(0.12, 1.2, 0.12), at + Vector3(0, 0.6, 0), Vector3.ZERO, WOOD, 1.0)
	_block(Vector3(0.9, 0.5, 0.06), at + Vector3(0, 1.1, 0.07), Vector3.ZERO, WOOD, 1.0)
	var it := Interactable3D.new()
	it.verb = "lire"
	it.lines = SIGN_LINES
	it.position = at
	add_child(it)
	return it


## A box, solid (on the world layer) unless `solid` is false, painted with `texture` in world
## space (triplanar, repeated `per_metre` times per metre) so any size keeps the same grain.
func _block(size: Vector3, pos: Vector3, rot_deg: Vector3, texture: Texture2D, per_metre: float, solid := true) -> Node3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * per_metre
	mat.roughness = 0.95
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var view := MeshInstance3D.new()
	view.mesh = mesh
	var node: Node3D = view
	if solid:
		var body := StaticBody3D.new()
		body.add_to_group(NAV_GROUP)
		body.collision_layer = Layers3D.WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		body.add_child(view)
		node = body
	node.position = pos
	node.rotation_degrees = rot_deg
	add_child(node)
	return node


func _add_caption() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	var label := Label.new()
	label.text = "Ambrelune 3D — démo · ZQSD / stick gauche : marcher · Maj / B / appui du stick gauche : courir · Espace / A : sauter · E / X : examiner · souris (clic droit) / stick droit : caméra · molette : zoom"
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override(&"font_size", 15)
	label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override(&"outline_size", 4)
	layer.add_child(label)
	add_child(layer)
