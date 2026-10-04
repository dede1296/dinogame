class_name Zone3D
extends Node3D
## A zone of the 3D version (docs/migration-3d.md, phase 4), built when it starts from the 2.5D
## zone `zone_id` (ZoneSource): its relief, ground and water (Terrain3D), what stops Chloé
## (Blockers3D: the 2.5D's rules), its scenery and woods (Scatter3D), a navigation mesh for the
## dinos, Chloé at her arrival point, and the wild dinos of its habitats that have a 3D sheet.
## Its map is `zone_scale` times wider than the 2.5D's. Not saved yet (phase 5).

const PLAYER := preload("res://world3d/player/player_3d.tscn")
const WALKABLE: Array[StringName] = [&"grass", &"path", &"tall_grass", &"sand"]

@export var zone_id: StringName = &"plaines"
## Where Chloé comes in (a Spawns marker of the 2.5D zone).
@export var arrival: StringName = &"DepuisPort"
@export var zone_scale := ZoneSource.DEFAULT_SCALE

var source: ZoneSource
var terrain: Terrain3D
var blockers: Blockers3D
var scatter: Scatter3D
var navigation: NavigationRegion3D
var player: Player3D
var dinos: Array[Dinosaur3D] = []
## How long the zone took to build (ms), for the tests.
var build_ms := 0


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	var steps := {}
	source = ZoneSource.open(zone_id, zone_scale)
	if source == null:
		return
	steps["lecture"] = Time.get_ticks_msec() - t0
	_add_environment()
	terrain = Terrain3D.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.build(source)
	steps["terrain"] = Time.get_ticks_msec() - t0
	blockers = Blockers3D.new()
	blockers.name = "Blockers"
	add_child(blockers)
	blockers.build(source)
	steps["obstacles"] = Time.get_ticks_msec() - t0
	scatter = Scatter3D.new()
	scatter.name = "Scatter"
	add_child(scatter)
	scatter.build(source, terrain)
	steps["décors"] = Time.get_ticks_msec() - t0
	_add_navigation()
	_add_player()
	_add_dinos()
	build_ms = Time.get_ticks_msec() - t0
	print("Zone3D %s : %d × %d m, construite en %d ms (cumul %s), %d dinos, décors %s" % [zone_id, source.size_m().x, source.size_m().y,
		build_ms, steps, dinos.size(), scatter.counts()])


func _exit_tree() -> void:
	if source:
		source.close()


## Puts Chloé at a 2.5D arrival point (a Spawns marker), the camera behind her.
func place(spawn_name: StringName, yaw_deg := 180.0) -> void:
	var at := source.spawn(spawn_name)
	at.y = terrain.height_at(at.x, at.z) + 0.3
	player.place_at(at, deg_to_rad(yaw_deg))
	player.pivot.set_view(yaw_deg + 180.0, CameraPivot.PITCH_DEFAULT)
	player.pivot.snap()


func _add_player() -> void:
	player = PLAYER.instantiate()
	add_child(player)
	place(arrival)


## The navigation mesh, from the ground and the blockers (their group nav_source), baked on a thread:
## the dinos stand still the few seconds it takes.
func _add_navigation() -> void:
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = Layers3D.WORLD | Layers3D.WATER
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh.geometry_source_group_name = &"nav_source"
	mesh.cell_size = 0.5
	mesh.cell_height = 0.25
	mesh.agent_radius = 0.5
	mesh.agent_height = 1.0
	mesh.agent_max_climb = 0.25
	mesh.agent_max_slope = 40.0
	navigation = NavigationRegion3D.new()
	navigation.name = "Navigation"
	navigation.navigation_mesh = mesh
	add_child(navigation)
	navigation.bake_navigation_mesh(true)


## The wild dinos of the zone's habitats (those seen out in the open; the time of day: phase 5) whose
## species has a 3D sheet: so many per habitat (Habitat.roamers), on open ground inside it.
func _add_dinos() -> void:
	for habitat in source.habitats():
		var area: Rect2 = habitat["area"]
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(area.position)
		for enc: Encounter in habitat["encounters"]:
			if enc.hidden:   # (the time of day comes with phase 5: every dino seen in the open is out)
				continue
			var species := Species3D.of(enc.species)
			if species == null:
				continue
			for i in int(habitat["roamers"]):
				var spot := _open_spot(area, rng)
				if spot == Vector3.INF:
					continue
				var dino := Dinosaur3D.create(species, enc.roll_level())
				dino.position = spot + Vector3(0, 0.3, 0)
				dino.home = spot
				add_child(dino)
				dinos.append(dino)


func _open_spot(area: Rect2, rng: RandomNumberGenerator) -> Vector3:
	for attempt in 20:
		var x := rng.randf_range(area.position.x, area.end.x)
		var z := rng.randf_range(area.position.y, area.end.y)
		if source.surface(source.tile_at(x, z)) in WALKABLE:
			return Vector3(x, terrain.height_at(x, z), z)
	return Vector3.INF


## A warm afternoon (the 2.5D's golden light, from the upper left): sky, sun with shadows, haze far
## off. (The time of day and the weather of the 2.5D come with phase 5.)
func _add_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.34, 0.54, 0.82)
	sky_mat.sky_horizon_color = Color(0.86, 0.82, 0.70)
	sky_mat.ground_horizon_color = Color(0.72, 0.68, 0.56)
	sky_mat.ground_bottom_color = Color(0.32, 0.30, 0.25)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.84, 0.82, 0.74)
	env.fog_depth_begin = 70.0
	env.fog_depth_end = 260.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-42.0, -40.0, 0.0)
	sun.light_color = Color(1.0, 0.92, 0.78)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)
