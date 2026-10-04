class_name Zone3D
extends Node3D
## A zone of the 3D version (docs/migration-3d.md, phases 4 and 5), built when it starts from the
## 2.5D zone `zone_id` (ZoneSource): its relief, ground and water (Terrain3D), what stops Chloé
## (Blockers3D: the 2.5D's rules), its scenery and woods (Scatter3D), its sky over the day (Sky3D),
## a navigation mesh for the dinos, Chloé (where the save left her, else at her arrival point), and
## the wild dinos of its habitats that have a 3D sheet, those of the time of day.
## The game around it (save, HUD, companion, battles): Session3D. Its map is `zone_scale` times wider
## than the 2.5D's.

const PLAYER := preload("res://world3d/player/player_3d.tscn")
const WALKABLE: Array[StringName] = [&"grass", &"path", &"tall_grass", &"sand"]

@export var zone_id: StringName = &"plaines"
## Where Chloé comes in (a Spawns marker of the 2.5D zone).
@export var arrival: StringName = &"DepuisPort"
@export var zone_scale := ZoneSource.DEFAULT_SCALE

var source: ZoneSource
var session: Session3D
var sky: Sky3D
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
	session = Session3D.new()
	session.name = "Session"
	session.zone = self
	add_child(session)
	session.begin()
	source = ZoneSource.open(zone_id, zone_scale)
	if source == null:
		return
	steps["lecture"] = Time.get_ticks_msec() - t0
	sky = Sky3D.new()
	sky.name = "Sky"
	add_child(sky)
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
	session.after_build()
	build_ms = Time.get_ticks_msec() - t0
	print("Zone3D %s : %d × %d m, construite en %d ms (cumul %s), %d dinos, décors %s" % [zone_id, source.size_m().x, source.size_m().y,
		build_ms, steps, dinos.size(), scatter.counts()])


func _exit_tree() -> void:
	if source:
		source.close()


## Puts Chloé at a 2.5D arrival point (a Spawns marker), the camera behind her.
func place(spawn_name: StringName, yaw_deg := 180.0) -> void:
	place_at(source.spawn(spawn_name), yaw_deg)


## Puts Chloé at a point of the zone (on the ground there), the camera behind her.
func place_at(at: Vector3, yaw_deg := 180.0) -> void:
	at.y = terrain.height_at(at.x, at.z) + 0.3
	player.place_at(at, deg_to_rad(yaw_deg))
	player.pivot.set_view(yaw_deg + 180.0, CameraPivot.PITCH_DEFAULT)
	player.pivot.snap()


func _add_player() -> void:
	player = PLAYER.instantiate()
	add_child(player)
	var saved := session.saved_spot()
	if saved != Vector3.INF:
		place_at(saved)
	else:
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


## The wild dinos out now: for each habitat, its dinos seen in the open at this time of day
## (Encounter.active, the weather too) whose species has a 3D sheet, so many per habitat
## (Habitat.roamers), on open ground inside it.
func _add_dinos() -> void:
	var phase := Game.phase()
	for habitat in source.habitats():
		var area: Rect2 = habitat["area"]
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(area.position) + hash(phase)
		for enc: Encounter in habitat["encounters"]:
			if enc.hidden or not enc.active(phase):
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


## The wild dinos of another time of day: those out now go, the ones of this time come.
func respawn_dinos() -> void:
	for d in dinos:
		if is_instance_valid(d):
			d.queue_free()
	dinos.clear()
	_add_dinos()


func _open_spot(area: Rect2, rng: RandomNumberGenerator) -> Vector3:
	for attempt in 20:
		var x := rng.randf_range(area.position.x, area.end.x)
		var z := rng.randf_range(area.position.y, area.end.y)
		if source.surface(source.tile_at(x, z)) in WALKABLE:
			return Vector3(x, terrain.height_at(x, z), z)
	return Vector3.INF
