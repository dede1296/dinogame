class_name WorldView
extends Node3D
## What the player sees of a zone: the zone is played in 2D (physics, exits, encounters,
## saves stay 2D) and shown here in 2.5D. The ground is a 3D relief (HeightMap), the plain
## scenery stands as camera-facing pictures (MultiMesh, swaying), the tall grass parts
## around Chloé, and everything that moves or changes in 2D (Chloé, dinos, people,
## obstacles, pickups, their particles and glows) is mirrored every frame.
## Sun, moon and sky follow the game clock; rain and mist dim them, close the horizon, and
## rain falls around Chloé; a sandstorm veils everything in ochre, sand streaking past; snow
## drifts down, and a blizzard veils everything in white, flakes driven past (Snowfall).
## Quality: shadows, render scale, glow, far blur, rain density.
## Swimming (Swim), Chloé's dino and Chloé on its back sit half under the water sheet, bobbing,
## a wake behind them. Flood water (Flood) stands as a block of water that drains away.
## The houses one goes into (the shops, the Cabinet) stand with their door apart, which opens
## and closes for the scenes (Doors, and « doors » below; Doorway walks people through it).

const PX := HeightMap.PX
const STRETCH := 1.15                       # same as the billboard shader
const PROP_SCRIPT := preload("res://world/prop.gd")
const BILLBOARD := preload("res://world/view3d/billboard.gdshader")
const GROUND := preload("res://world/view3d/ground.gdshader")
const WATER := preload("res://world/view3d/water.gdshader")
const CONTACT := preload("res://world/view3d/contact_shadow.gdshader")
const RELIEF := preload("res://world/view3d/relief.gdshader")
## How strongly the real 3D models' details (normal map) catch the sun (relief.gdshader "detail").
const MODEL_DETAIL := 3.0
## How rounded each kind of scenery looks (volume lighting); flat things stay flat.
const ROUNDNESS := {
	"arbre_rond": 0.85, "araucaria": 0.6, "fougere_arbre": 0.6, "buisson": 0.8, "rocher": 0.75,
	"cailloux": 0.6, "tronc": 0.5, "ronces": 0.5, "hautes_herbes": 0.2, "fougeres": 0.35,
	"fleurs_roses": 0.3, "fleurs_violettes": 0.3, "panneau": 0.1, "cloture": 0.1, "ambre": 0.3, "souche": 0.5,
}
const TUFT := preload("res://assets/art/props/hautes_herbes.png")
## Zones whose tall grass is a picture of its own (the Monts: tundra tufts, brown-green and
## frosted). One not made yet: TUFT.
const ZONE_TUFT := {&"monts": "res://assets/art/props/herbes_toundra.png"}
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
const FLAME_WIDTH := 0.5
## The painted campfire (29/09): its dancing flame, FLAME_FRAMES cells in a row, and its smoke.
const FLAME_ANIM := "res://assets/art/props/flamme_anim.png"
const FLAME_FRAMES := 6
const SMOKE := "res://assets/art/props/fumee.png"
## The colour of a little sign over a dino (emote): a heart is red, the rest dark brown.
const EMOTE_COLOURS := {"♥": Color(0.86, 0.22, 0.35), "♪": Color(0.3, 0.2, 0.55)}
## The signs over heads (emote, show_hint): this far above the top of the picture (m).
const EMOTE_ABOVE := 0.3
const HINT_ABOVE := 0.45
## How far a neighbouring zone is shown beyond an exit (tiles).
const PREVIEW_DEPTH := 26.0
## Trees filling the "forest" tiles (weights by repetition).
const FOREST_TREES := ["arbre_rond", "araucaria", "arbre_rond", "fougere_arbre", "araucaria", "arbre_rond"]
## Zones whose woods are not the Forêt's (weights by repetition): what fills their "forest"
## tiles, what stands beyond their edges, and the low plants by the paths and on the near side
## (towards the camera: tall ones there would hide the zone).
const ZONE_TREES := {
	&"marais": {
		"forest": ["arbre_noye", "roseaux", "arbre_noye", "fougere_arbre", "roseaux", "arbre_noye"],
		"outer": ["arbre_noye", "arbre_noye", "fougere_arbre", "roseaux"],
		"low": ["hautes_herbes", "fougeres", "hautes_herbes", "fougeres"],
	},
	# The Désert: palms by the water, rocks and dry scrub beyond its edges.
	&"desert": {
		"forest": ["palmier_oasis", "buisson_sec", "palmier_oasis", "fougere_arbre"],
		"outer": ["rocher_canyon", "buisson_sec", "rocher_canyon", "cailloux"],
		"low": ["buisson_sec", "cailloux", "buisson_sec", "cailloux"],
	},
	&"sanctuaire_vents": {
		"forest": ["rocher_canyon", "buisson_sec"],
		"outer": ["rocher_canyon", "buisson_sec"],
		"low": ["cailloux", "buisson_sec"],
	},
	# The Côte: palms and cycads in its grove, araucarias towards the Monts.
	&"cote": {
		"forest": ["palmier_oasis", "fougere_arbre", "palmier_oasis", "araucaria", "fougere_arbre"],
		"outer": ["palmier_oasis", "araucaria", "fougere_arbre", "buisson"],
		"low": ["fougeres", "buisson", "fougeres", "hautes_herbes"],
	},
	# The Monts Gelés: snowy firs and wind-twisted pines, frosted bushes and snowy rocks low down;
	# where their snow thins out (Region.cover_at < 0.5, towards the Côte): the Côte's woods ("thin").
	&"monts": {
		"thin": &"cote",
		"forest": ["sapin_neige", "sapin_neige", "pin_tordu", "sapin_neige", "pin_tordu"],
		"outer": ["sapin_neige", "pin_tordu", "sapin_neige", "rocher_neige"],
		"low": ["buisson_givre", "rocher_neige", "buisson_givre", "buisson_givre"],
	},
}
## A zone's woods where its cover layer lies thin (ZONE_TREES "thin": another zone's woods), at a
## point (tiles): those without snow under a dose of THIN_COVER.
const THIN_COVER := 0.5


static func _woods_at(r: Region, t: Vector2) -> Dictionary:
	var own: Dictionary = ZONE_TREES.get(r.region_id, {})
	if own.has("thin") and r.cover_data and r.cover_at(t * PX) < THIN_COVER:
		return ZONE_TREES.get(own["thin"], {})
	return own


## How far from a zone's south edge (tiles) its woods stay low (ZONE_TREES "low").
const LOW_SOUTH := 7
## A zone's cliffs and walls in another picture than the earth wall (the temple's masonry; the
## Monts' snowy rock, the ice caves' walls of ice). One not made yet: the earth wall.
const CLIFF_TEX := {
	&"temple_englouti": "res://assets/art/ground/dalles_temple.png",
	&"monts": "res://assets/art/ground/falaise_neige.png", &"grottes_glace": "res://assets/art/ground/glace.png",
	&"sanctuaire_givre": "res://assets/art/ground/falaise_neige.png",
}
## Zones whose walls are paved like their floor (the temple; the ice caves, their floor ice as
## well): the tops of the walls darker, so the rooms and passages read at a glance (0: as lit as
## the floor).
const WALL_SHADE := {&"temple_englouti": 0.8, &"grottes_glace": 0.35}
## Zones whose raised ground is all walls (the ice caves): their tops in the walls' own picture
## (CLIFF_TEX, CLIFF_TINT), masses of dark ice apart from the floor.
const WALL_TOPS := [&"grottes_glace"]
## Flood water of a zone in its own shades: [shallow, deep] (the temple: murky, greenish).
const FLOOD_TINT := {&"temple_englouti": [Color(0.3, 0.52, 0.48), Color(0.05, 0.17, 0.2)]}
## The Marais' ground ("mud" tiles).
const MUD_TEX := "res://assets/art/ground/vase.png"
## The Désert's canyon rock ("rock" tiles).
const ROCK_TEX := "res://assets/art/ground/roche_canyon.png"
## Zones whose sand ("sand" tiles) is a picture of its own (the dunes; in the Monts, the ice of
## the frozen lake and the glacier); elsewhere the beaches are the path's dirt, lightened.
const SAND_TEX := {
	&"desert": "res://assets/art/ground/sable.png", &"sanctuaire_vents": "res://assets/art/ground/sable.png",
	&"cote": "res://assets/art/ground/sable.png", &"recif_sanctuaire": "res://assets/art/ground/sable.png",
	&"monts": "res://assets/art/ground/glace.png", &"grottes_glace": "res://assets/art/ground/glace.png",
	&"sanctuaire_givre": "res://assets/art/ground/glace.png",
}
## Zones whose "sand" is ice: their trails are not on it (they keep Region.path_tex: packed snow).
const ICE := [&"monts", &"grottes_glace", &"sanctuaire_givre"]
## Zones whose grass is tinted (the Marais: olive, less bright next to its mud).
const GRASS_TINT := {&"marais": Color(0.86, 0.92, 0.74)}
## Zones whose cliffs are tinted (the Désert: warm canyon rock; 1 = the grey-brown rock).
## (The ice caves: their walls of ice a deep, darker blue, apart from the pale floor.)
const CLIFF_TINT := {&"desert": Color(1.22, 0.98, 0.8), &"sanctuaire_vents": Color(1.22, 0.98, 0.8),
	&"grottes_glace": Color(0.5, 0.66, 0.95)}
## Zones whose water is not the clear blue of the coast: [shallow, deep] (a marsh: greener, murkier).
const WATER_TINT := {&"marais": [Color(0.4, 0.56, 0.42), Color(0.1, 0.2, 0.17)]}
## The clear blue of the coast (water.gdshader's shallow and deep).
const WATER_DEFAULT := [Color(0.36, 0.64, 0.62), Color(0.07, 0.22, 0.32)]
## Near an edge that leads to a zone whose water, grass or cliffs are of another colour
## (WATER_TINT, GRASS_TINT, CLIFF_TINT), the colours blend towards the neighbour's over this many
## tiles, half and half at the edge; the neighbour, shown beyond it, does the same towards this
## one, so the two meet without a seam (ground.gdshader, water.gdshader: tint_edges).
const TINT_BLEND := 12.0


## The edges of zone `r` towards neighbours of other colours (its exits on the map's edge; one per
## side): [Vector4(axis 0 x / 1 y, the edge's line in tiles, 1 or -1 towards the inside, 0),
## the neighbour's id].
static func _tint_edges(r: Region) -> Array:
	var out := []
	var size := Vector2(r.map_size())
	var sides := {}
	for exit in r.exits():
		var other: StringName = exit.target_zone
		if other == r.region_id or not r.exit_on_edge(exit) or not _tints_differ(r.region_id, other):
			continue
		var edge := r.exit_edge(exit)
		if sides.has(edge):
			continue
		sides[edge] = true
		var line := Vector4(0.0, 0.0, 1.0, 0.0)
		if edge.x > 0.0:
			line = Vector4(0.0, size.x, -1.0, 0.0)
		elif edge.y < 0.0:
			line = Vector4(1.0, 0.0, 1.0, 0.0)
		elif edge.y > 0.0:
			line = Vector4(1.0, size.y, -1.0, 0.0)
		out.append([line, other])
	return out.slice(0, 4)


static func _tints_differ(a: StringName, b: StringName) -> bool:
	return WATER_TINT.get(a, WATER_DEFAULT) != WATER_TINT.get(b, WATER_DEFAULT) 		or GRASS_TINT.get(a, Color.WHITE) != GRASS_TINT.get(b, Color.WHITE) 		or CLIFF_TINT.get(a, Color.WHITE) != CLIFF_TINT.get(b, Color.WHITE)


## Gives a ground or water material of zone `r` its edges towards neighbours of other colours,
## and their colours (see TINT_BLEND).
static func _set_edge_tints(mat: ShaderMaterial, r: Region) -> void:
	var edges := _tint_edges(r)
	var lines: Array[Vector4] = []
	var shallow: Array[Color] = []
	var deep: Array[Color] = []
	var grass: Array[Color] = []
	var cliff: Array[Vector3] = []
	for i in 4:
		var e: Array = edges[i] if i < edges.size() else [Vector4.ZERO, r.region_id]
		var water: Array = WATER_TINT.get(e[1], WATER_DEFAULT)
		var c: Color = CLIFF_TINT.get(e[1], Color.WHITE)
		lines.append(e[0])
		shallow.append(water[0])
		deep.append(water[1])
		grass.append(GRASS_TINT.get(e[1], Color.WHITE))
		cliff.append(Vector3(c.r, c.g, c.b))
	mat.set_shader_parameter("tint_edge_count", edges.size())
	mat.set_shader_parameter("tint_blend", TINT_BLEND)
	mat.set_shader_parameter("tint_edges", lines)
	mat.set_shader_parameter("edge_shallow", shallow)
	mat.set_shader_parameter("edge_deep", deep)
	mat.set_shader_parameter("edge_grass", grass)
	mat.set_shader_parameter("edge_cliff", cliff)
const CAVE := preload("res://world/view3d/cave_mouth.gdshader")
const OCCLUDER_HEIGHT := 1.6               # metres: taller scenery may hide Chloé (1.50 m)
const POLLEN_MOTES := 60
const RAIN_DROPS := 320
## A storm: this much more rain, flashes of lightning every so often (s), thunder after them.
const STORM_RAIN := 1.8
const LIGHTNING_EVERY := Vector2(6.0, 16.0)
const THUNDER: Array[AudioStream] = [preload("res://assets/audio/ambience/tonnerre-1.mp3"), preload("res://assets/audio/ambience/tonnerre-2.mp3")]
const WEATHER_BLEND := 0.6                  # how fast rain and mist come and go
## A sandstorm: grains streaking past on the wind, clouds of dust drifting, an ochre sky.
const SAND_GRAINS := 260
const DUST_CLOUDS := 36
const SAND_SKY := Color(0.86, 0.66, 0.42)
const SAND := Color(0.93, 0.76, 0.5)
## A 2D move longer than this in one physics step is a teleport, not blended (px).
const TELEPORT := 96.0
const SWIM := preload("res://world/swim.gd")
## Swimming: a slow bob (m, s); the wake behind the swimmer; droplets going in and out.
const SWIM_BOB := 0.04
const SWIM_BOB_S := 2.2
const WAKE_DOTS := 26
const SPLASH: Array[Color] = [Color(0.92, 0.97, 1.0), Color(0.72, 0.87, 0.95), Color(0.56, 0.78, 0.86)]
const FLOOD := preload("res://world/view3d/flood.gdshader")
const FLOOD_SHEET := 0.04   # metres: the flood water's sheet, just above the floor
const UNDERWATER := preload("res://world/view3d/underwater.gd")
const SNOWFALL := preload("res://world/view3d/snowfall.gd")
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
var _mount_hop := 0.0   # the mount's hop this frame (m): Chloé in the saddle rises with it
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
## Real 3D models (Prop.KINDS "model"): path -> its mesh painted to be lit like the pictures.
var _models := {}
## The zone's houses one goes into, their doors apart and turning (see Doors, and « doors » below).
var doors := Doors.new()
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
var _sand_amount := 0.0
var _sand: CPUParticles3D
var _dust: CPUParticles3D
var _wake: CPUParticles3D
## Flood water of the zone: [Flood (2D), its block of water, floor height (m)].
var _floods: Array[Array] = []
## A scene shows something away from Chloé (Stage.look_at): the camera glides there (world
## pixels), then back to her when it is INF again.
var focus_px := Vector2.INF
## A scene's close-up on something small (Stage.close_up): the camera's distance (m) while it
## lasts; 0: the player's own.
var close_up := 0.0
## Someone walks through a door (Doorway): the scenery turns see-through as if Chloé stood here
## (world pixels: the front of the door), not deep in the doorway behind the facade.
var occlusion_px := Vector2.INF
## Big scenery as its real 3D model (with the quality's relief_props); off: pictures (to compare).
var reliefs := true
## Their details from normal maps (bricks, planks…); off: without them (to compare).
var details := true
## The dive (Dive): how far below its place the swimmer and Chloé are shown (m; < 0: above).
var dive_sink := 0.0
## Under the sea (Region.underwater): its light, its shafts and bubbles (null above the water).
var _underwater: UNDERWATER
## Snow and the blizzard (the Monts).
var _snow: SNOWFALL


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
	_sand = _make_sand()
	add_child(_sand)
	_dust = _make_dust()
	add_child(_dust)
	_snow = SNOWFALL.new()
	add_child(_snow)
	_wake = _make_wake()
	add_child(_wake)
	_rain_amount = 1.0 if Game.is_raining() else 0.0
	_storm_amount = 1.0 if Game.weather == &"storm" else 0.0
	_mist_amount = 1.0 if Game.weather == &"mist" else 0.0
	_sand_amount = 1.0 if Game.weather == &"sandstorm" else 0.0
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
	_sand.amount = Quality.scaled(SAND_GRAINS)
	_dust.amount = Quality.scaled(DUST_CLOUDS)
	_wake.amount = Quality.scaled(WAKE_DOTS)
	# Relief detail, grass density, swaying: rebuilt with the zone.
	if _region and is_instance_valid(_region) and player:
		show_zone(_region, player)


# ------------------------------------------------------------------ zone

## Builds the 3D view of `region` (replacing the previous zone's), following `chloe`.
## `zones`: every zone id -> scene path, to show the neighbours beyond the exits.
func show_zone(region: Region, chloe: Node2D, zones := {}) -> void:
	focus_px = Vector2.INF
	close_up = 0.0
	occlusion_px = Vector2.INF
	for p in _proxies:
		_free_proxy(p)
	_proxies.clear()
	_instances.clear()
	doors = Doors.new()
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
	_find_doors(region)
	_ground_mat = _build_ground(region, heights)
	_set_holes(_ground_mat)
	if heights.has_water:
		_set_holes(_build_water(region, heights))
	for n: Dictionary in neighbours:
		_build_neighbour(n)
	_build_scenery()
	_build_forest(region, heights)
	_build_tall_grass()
	for dock in region.docks():
		if not dock is MoonFord:   # (its stones: NightMagic)
			_build_dock(dock)
	_build_floods()
	_underwater = UNDERWATER.build(self, region, _zone)   # its dive spots; under the water, the water
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
	var cliff: String = CLIFF_TEX.get(r.region_id, "")
	var own_cliff := ResourceLoader.exists(cliff)
	# Under cover layers (Region.covers()): the zone's own cliffs where the first one lies, the
	# earth wall elsewhere (the snowy rock of the Monts fades out towards the Côte, like the snow).
	var covers := r.covers()
	mat.set_shader_parameter("cover_count", covers.size())
	if not covers.is_empty():
		mat.set_shader_parameter("cover_mask", _cover_mask(covers))
		mat.set_shader_parameter("cover_tex", covers[0]["tex"])
		mat.set_shader_parameter("cover_path_tex", covers[0].get("path_tex", covers[0]["tex"]))
		for i in range(1, covers.size()):
			mat.set_shader_parameter("cover_tex%d" % i, covers[i]["tex"])
		mat.set_shader_parameter("cover_spares_sand", r.cold)
		mat.set_shader_parameter("cover_cliff", own_cliff)
		if own_cliff:
			mat.set_shader_parameter("cover_cliff_tex", load(cliff))
			own_cliff = false
	mat.set_shader_parameter("cliff_tex", load(cliff if own_cliff else "res://assets/art/ground/falaise.png"))
	mat.set_shader_parameter("mud_tex", load(MUD_TEX))
	mat.set_shader_parameter("rock_tex", load(ROCK_TEX))
	if SAND_TEX.has(r.region_id) and ResourceLoader.exists(SAND_TEX[r.region_id]):
		mat.set_shader_parameter("sand_tex", load(SAND_TEX[r.region_id]))
		mat.set_shader_parameter("sand_picture", true)
		mat.set_shader_parameter("sand_is_ice", r.region_id in ICE)
	mat.set_shader_parameter("wall_tops", r.region_id in WALL_TOPS)
	mat.set_shader_parameter("grass_tint", GRASS_TINT.get(r.region_id, Color.WHITE))
	mat.set_shader_parameter("cliff_tint", CLIFF_TINT.get(r.region_id, Color.WHITE))
	_set_edge_tints(mat, r)
	mat.set_shader_parameter("top_shade", WALL_SHADE.get(r.region_id, 0.0))
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


## The doses of a zone's cover layers (Region.covers()) packed in one texture: R, G, B = the
## first, second, third layer (one pixel per tile).
static func _cover_mask(covers: Array[Dictionary]) -> ImageTexture:
	var first: Image = covers[0]["data"]
	if covers.size() == 1:
		return ImageTexture.create_from_image(first)
	var packed := Image.create(first.get_width(), first.get_height(), false, Image.FORMAT_RGB8)
	for y in packed.get_height():
		for x in packed.get_width():
			var c := Color(0, 0, 0)
			for i in covers.size():
				var data: Image = covers[i]["data"]
				c[i] = data.get_pixel(mini(x, data.get_width() - 1), mini(y, data.get_height() - 1)).r
			packed.set_pixel(x, y, c)
	return ImageTexture.create_from_image(packed)


## What a map of zone `r` is drawn from, when it is not the one shown (MapScreen).
static func map_layers_for(r: Region) -> Dictionary:
	var hm := HeightMap.new(r, 2)
	var masks := _terrain_masks(r, hm)
	var tex := hm.height_texture()
	var layers := {"terrain_mask": masks[0], "terrain_mask2": masks[1], "map_tiles": Vector2(hm.size),
		"height_tex": tex["texture"], "height_origin": tex["origin"], "height_res": tex["res"], "height_texels": tex["texels"],
		"icy": r.cold}
	return layers.merged(_cover_map_layers(r))


## What the map screen draws the current zone from: its ground masks and its relief.
func map_layers() -> Dictionary:
	var layers := {}
	for key in ["terrain_mask", "terrain_mask2", "map_tiles", "height_tex", "height_origin", "height_res", "height_texels"]:
		layers[key] = _ground_mat.get_shader_parameter(key)
	layers["icy"] = _region.cold if _region else false
	return layers.merged(_cover_map_layers(_region)) if _region else layers


## The map's cover layers: their doses (cover_mask), how many, and the colour of each (the
## average of its picture).
static func _cover_map_layers(r: Region) -> Dictionary:
	var covers := r.covers()
	if covers.is_empty():
		return {"cover_count": 0}
	var colours := PackedVector3Array()
	for layer in covers:
		var img := (layer["tex"] as Texture2D).get_image()
		if img.is_compressed():
			img.decompress()
		img.resize(1, 1, Image.INTERPOLATE_BILINEAR)
		var c := img.get_pixel(0, 0)
		colours.append(Vector3(c.r, c.g, c.b))
	while colours.size() < Region.COVER_MAX:
		colours.append(Vector3.ONE)
	return {"cover_count": covers.size(), "cover_mask": _cover_mask(covers), "cover_colours": colours}


## A flat square grid of CHUNK metres, `step` vertices per metre (shared by all chunks).
static func _chunk_mesh(step: int) -> PlaneMesh:
	if not _grids.has(step):
		var m := PlaneMesh.new()
		m.size = Vector2(CHUNK, CHUNK)
		m.subdivide_width = CHUNK * step - 1
		m.subdivide_depth = CHUNK * step - 1
		_grids[step] = m
	return _grids[step]


## Two textures, one pixel per tile: [R path, G tall grass, B water] and
## [R sand, G forest, B mud, A rock]. In a sandy zone (SAND_TEX) the trails lie on sand (not on
## the ice: ICE).
static func _terrain_masks(r: Region, hm: HeightMap) -> Array[ImageTexture]:
	var a := Image.create(hm.size.x, hm.size.y, false, Image.FORMAT_RGB8)
	var b := Image.create(hm.size.x, hm.size.y, false, Image.FORMAT_RGBA8)
	var sandy := SAND_TEX.has(r.region_id) and not r.region_id in ICE
	for y in hm.size.y:
		for x in hm.size.x:
			var s := r.surface_at(Vector2((x + 0.5) * PX, (y + 0.5) * PX))
			a.set_pixel(x, y, Color(1, 0, 0) if s == &"path" else Color(0, 1, 0) if s == &"tall_grass" else Color(0, 0, 1) if s == &"water" else Color.BLACK)
			b.set_pixel(x, y, Color(1, 0, 0, 0) if s == &"sand" or (sandy and s == &"path") else Color(0, 1, 0, 0) if s == &"forest" else Color(0, 0, 1, 0) if s == &"mud"
				else Color(0, 0, 0, 1) if s == &"rock" else Color(0, 0, 0, 0))
	return [ImageTexture.create_from_image(a), ImageTexture.create_from_image(b)]


## The water sheet of zone `r` (its relief `hm`), moved by `shift` tiles, drawn only inside `keep`
## (as _build_ground): its shades (WATER_TINT), blended towards the neighbours' near the edges.
func _build_water(r: Region, hm: HeightMap, shift := Vector2.ZERO, keep := Rect2()) -> ShaderMaterial:
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(hm.size) + Vector2.ONE * hm.margin * 2.0
	plane.mesh = mesh
	plane.position = Vector3(hm.size.x / 2.0 + shift.x, HeightMap.WATER_LEVEL, hm.size.y / 2.0 + shift.y)
	var mat := ShaderMaterial.new()
	mat.shader = WATER
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	var own: Array = WATER_TINT.get(r.region_id, WATER_DEFAULT)
	mat.set_shader_parameter("shallow", own[0])
	mat.set_shader_parameter("deep", own[1])
	_set_edge_tints(mat, r)
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
		if not ResourceLoader.exists(zones[exit.target_zone]):   # a zone still to be built
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
		_build_water(r, hm, shift, band)
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
		_add_props(kind, groups[kind])
	_build_forest(r, hm, shift, band)
	r.free()


## Plain props (not obstacles, pickups, signs…) never change: one MultiMesh per kind.
func _build_scenery() -> void:
	var groups := {}   # kind -> Array of [position (m), flipped]
	for n in _region.entities.get_children():
		if n is Prop and n.get_script() == PROP_SCRIPT:
			var at := heights.to_3d(n.position)
			if doors.houses.has(n) and _add_door_house(n, at):
				continue
			var def: Dictionary = Prop.KINDS.get(n.kind, {})
			if not groups.has(n.kind):
				groups[n.kind] = []
			if def.get("float", false):
				at.y = maxf(at.y, HeightMap.WATER_LEVEL + 0.06)
			groups[n.kind].append([at, n.flip, 1.0, n])
			if def.get("light", false) and Quality.setting(&"lights"):
				_add_lamp(at)
			if n.kind == "feu_camp":
				_add_fire(at)
	for kind: String in groups:
		_add_props(kind, groups[kind])


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
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = _soft_dot()   # round and soft, not little squares
	quad.material = mat
	bits.mesh = quad
	var fade := Gradient.new()   # they fade out at the end of their flight
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	bits.color_ramp = fade
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
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 10
	var from := heights.to_3d(who.global_position) + Vector3(0.25, head_height(who) + EMOTE_ABOVE, 0)
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
		_hint.pixel_size = 0.0105
		_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_hint.no_depth_test = true
		_hint.render_priority = 10
		_zone.add_child(_hint)
	_hint.visible = on
	if on:
		_hint.position = heights.to_3d(dino.global_position) + Vector3(0.25, head_height(dino) + HINT_ABOVE + 0.1 * sin(Time.get_ticks_msec() / 150.0), 0)


## Height (m) of the top of `who`'s picture as it is now, above its feet (what is drawn, not
## its frame; Chloé in the saddle: her head). 1.5 m for a node without a picture.
static func head_height(who: Node2D) -> float:
	var sprite: Node2D = who.get("sprite") if "sprite" in who else who.get_node_or_null("Sprite")
	var frame: Texture2D = null
	var offset := Vector2.ZERO
	if sprite == null:
		return 1.5
	if sprite is AnimatedSprite2D:
		var anim := sprite as AnimatedSprite2D
		offset = anim.offset
		if anim.sprite_frames and anim.sprite_frames.has_animation(anim.animation):
			frame = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	elif sprite is Sprite2D:
		frame = (sprite as Sprite2D).texture
		offset = (sprite as Sprite2D).offset
	if frame == null:
		return 1.5
	var top := offset.y - frame.get_height() / 2.0 + SheetFrames.drawn_in(frame).position.y   # px of the picture
	return -(top * absf(sprite.global_scale.y) + sprite.position.y) / PX * STRETCH


## A campfire's flame (the web version's picture, flickering), a few embers rising, and its
## wavering light.
func _add_fire(at: Vector3) -> void:
	var flame: SpriteBase3D = _fire_flame()
	flame.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	flame.shaded = false
	flame.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame.position = at + Vector3(0, 0.08, 0.02)
	_zone.add_child(flame)
	if flame is AnimatedSprite3D:
		(flame as AnimatedSprite3D).play(&"burn")
	else:   # the web version's flicker: taller and narrower, back again, 170 ms each way
		var t := flame.create_tween().set_loops()
		t.tween_property(flame, "scale", Vector3(0.9, 1.18, 1.0), 0.17).set_trans(Tween.TRANS_SINE)
		t.tween_property(flame, "scale", Vector3.ONE, 0.17).set_trans(Tween.TRANS_SINE)
	var smoke := _fire_smoke()
	if smoke:
		smoke.position = at + Vector3(0, 0.95, 0.05)
		_zone.add_child(smoke)
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


## The campfire's flame, FLAME_WIDTH wide, its base at its origin: the painted one dancing
## (props/flamme_anim.png, FLAME_FRAMES cells, « burn »), or the web version's picture.
func _fire_flame() -> SpriteBase3D:
	if not ResourceLoader.exists(FLAME_ANIM):
		var still := Sprite3D.new()
		still.texture = FLAME
		still.pixel_size = FLAME_WIDTH / FLAME.get_width()
		still.centered = false
		still.offset = Vector2(-FLAME.get_width() / 2.0, 0.0)
		return still
	var sheet: Texture2D = load(FLAME_ANIM)
	var cell := Vector2(sheet.get_width() / float(FLAME_FRAMES), sheet.get_height())
	var frames := SpriteFrames.new()
	frames.add_animation(&"burn")
	frames.set_animation_speed(&"burn", 10.0)
	for i in FLAME_FRAMES:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(Vector2(cell.x * i, 0.0), cell)
		frames.add_frame(&"burn", frame)
	var dancing := AnimatedSprite3D.new()
	dancing.sprite_frames = frames
	dancing.pixel_size = FLAME_WIDTH / cell.x
	dancing.centered = false
	dancing.offset = Vector2(-cell.x / 2.0, 0.0)
	dancing.frame = randi() % FLAME_FRAMES   # (two fires side by side do not dance in step)
	return dancing


## The campfire's smoke (props/fumee.png): soft grey puffs rising slowly, drifting with the
## wind, swelling and fading; null while the picture is not there.
func _fire_smoke() -> CPUParticles3D:
	if not ResourceLoader.exists(SMOKE):
		return null
	var puffs := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = load(SMOKE)
	quad.material = mat
	puffs.mesh = quad
	puffs.amount = maxi(3, Quality.scaled(9))
	puffs.lifetime = 4.5
	puffs.preprocess = 4.5
	puffs.direction = Vector3.UP
	puffs.spread = 12.0
	puffs.initial_velocity_min = 0.35
	puffs.initial_velocity_max = 0.55
	puffs.gravity = Vector3(0.12, 0.05, -0.04)   # (a light breeze)
	puffs.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	puffs.emission_sphere_radius = 0.1
	puffs.angle_min = -180.0
	puffs.angle_max = 180.0
	puffs.angular_velocity_min = -12.0
	puffs.angular_velocity_max = 12.0
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.35))
	grow.add_point(Vector2(1.0, 1.6))
	puffs.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	fade.colors = PackedColorArray([Color(0.8, 0.78, 0.75, 0.0), Color(0.75, 0.73, 0.7, 0.42), Color(0.7, 0.7, 0.7, 0.0)])
	puffs.color_ramp = fade
	return puffs


## A warm glow around a lantern, a lamp, the incubator.
func _add_lamp(at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.72, 0.38)
	light.light_energy = 1.1
	light.omni_range = 4.0
	light.shadow_enabled = false
	light.position = at + Vector3(0, 1.2, 0.3)   # (lanterns, lamps: people's size)
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


## Flood water (world/flood.gd) of the zone: a block of water on the floor of its area,
## `depth` metres high when full; it lowers as it drains (see _update_floods).
func _build_floods() -> void:
	_floods.clear()
	for f in get_tree().get_nodes_in_group(&"flood"):
		var flood := f as Node2D
		if flood == null or not _region.is_ancestor_of(flood):
			continue
		var area: Rect2 = flood.call(&"area")
		var t := Rect2(area.position / PX, area.size / PX)
		var floor_h := heights.range_in(t).x - 0.05
		# The brim: a flooded basin's edge (Region.BASIN_DEPTH above its floor), or a stair's top.
		var rim := minf(heights.range_in(t.grow(-0.3)).y, floor_h + 0.05 + Region.BASIN_DEPTH)
		var box := BoxMesh.new()
		box.size = Vector3(t.size.x, 1.0, t.size.y)
		var mat := ShaderMaterial.new()
		mat.shader = FLOOD
		mat.set_shader_parameter("noise_tex", WorldNoise.texture())
		mat.set_shader_parameter("half_size", Vector2(t.size.x, t.size.y) / 2.0)
		if FLOOD_TINT.has(_region.region_id):
			mat.set_shader_parameter("shallow", FLOOD_TINT[_region.region_id][0])
			mat.set_shader_parameter("deep", FLOOD_TINT[_region.region_id][1])
		box.material = mat
		var water := MeshInstance3D.new()
		water.mesh = box
		water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		water.position = Vector3(t.get_center().x, floor_h, t.get_center().y)
		_zone.add_child(water)
		_floods.append([flood, water, floor_h, rim])
		_update_flood(_floods[-1])


## Each flood's block of water at its level now (Flood.fill: 1 full, 0 drained).
func _update_floods() -> void:
	for f in _floods:
		_update_flood(f)


func _update_flood(f: Array) -> void:
	var water: MeshInstance3D = f[1]
	if not is_instance_valid(f[0]):
		water.visible = false
		return
	var depth: float = (f[0] as Node2D).get(&"depth")
	var fill := clampf(float((f[0] as Node2D).get(&"fill")), 0.0, 1.0)
	water.visible = fill > 0.005
	if not water.visible:
		return
	# A sheet of deep water up to the rim of the passage (a block standing on its floor looked
	# like glass): dark and opaque when full; as it drains it sinks down a flooded stair, step
	# by step, and clears up until the floor shows through.
	var h := maxf(depth * fill, 0.02)
	var bottom := float(f[2]) + 0.05
	var level := bottom + (maxf(float(f[3]), bottom) + 0.06 - bottom) * fill
	water.scale = Vector3(1.0, FLOOD_SHEET, 1.0)
	water.position.y = level - FLOOD_SHEET / 2.0
	var mat := (water.mesh as BoxMesh).material as ShaderMaterial
	mat.set_shader_parameter("height", h)


## One prop kind standing at `items` ([position, flipped, scale]): as its real 3D model when
## it has one ("model") and the quality allows it, else as pictures; with its soft shadow on
## the ground. (Scenery in bas-relief, tried the 27/09, looked warped: dropped.)
func _add_props(kind: String, items: Array) -> void:
	var model := _model_mesh(kind)
	if model:   # its surfaces carry their materials
		_add_multimesh(model, items, true)
	else:
		_add_billboards(kind, items)
	var foot := float(Prop.KINDS[kind]["shadow"]) / PX
	if foot > 0.0:
		_add_contact_shadows(items.map(func(it: Array) -> Array: return [it[0], foot * float(it[2])]))



## The real 3D model of a prop kind (Prop.KINDS "model": origin at its foot, front towards +z,
## in metres) when the quality shows the models, else null (its picture). Loaded once, shared
## by the scenery and the props mirrored as their model.
func _model_mesh(kind: String) -> Mesh:
	var path: String = Prop.KINDS.get(kind, {}).get("model", "")
	if path == "" or not reliefs or not Quality.setting(&"relief_props"):
		return null
	var key := path if details else path + "#plain"
	if not _models.has(key):
		_models[key] = _load_model(kind, path, details)
	return _models[key]


## A copy of the mesh of the model at `path` (a scene with one MeshInstance3D), each surface
## lit like the pictures (RELIEF) with its imported painting (and its details: normal map, if
## `with_details`); null (with a warning) if unusable.
static func _load_model(kind: String, path: String, with_details := true) -> Mesh:
	if not ResourceLoader.exists(path):
		push_warning("%s: model %s not found, shown as its picture" % [kind, path])
		return null
	var scene := (load(path) as PackedScene).instantiate()
	var found := scene.find_children("*", "MeshInstance3D", true, false)
	var source: Mesh = (found[0] as MeshInstance3D).mesh if not found.is_empty() else null
	scene.free()
	if source == null:
		push_warning("%s: no mesh in %s, shown as its picture" % [kind, path])
		return null
	var mesh := source.duplicate() as Mesh
	paint_model(mesh, kind, mesh.get_aabb(), with_details)
	return mesh


## Paints each surface of `mesh` (a model's) to be lit like the pictures (RELIEF), with its
## imported painting (and its details: normal map, if `with_details`), measured on `box`.
## `shared`: imported material -> its RELIEF one, for meshes painted from the same atlas (a
## house and its door's leaves, Doors).
static func paint_model(mesh: Mesh, kind: String, box: AABB, with_details := true, shared := {}) -> void:
	for s in mesh.get_surface_count():
		var painted := mesh.surface_get_material(s) as BaseMaterial3D
		if not shared.has(painted):
			var mat := _relief_material(kind, painted.albedo_texture if painted else null, box)
			if with_details and painted and painted.normal_enabled and painted.normal_texture:   # (v2)
				_set_details(mat, painted.normal_texture, 2, MODEL_DETAIL)
			shared[painted] = mat
		mesh.surface_set_material(s, shared[painted])


## A RELIEF material: painting `tex` on a mesh within `box`, as rounded as `kind`.
static func _relief_material(kind: String, tex: Texture2D, box: AABB) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = RELIEF
	mat.set_shader_parameter("tex", tex)
	mat.set_shader_parameter("occluder", box.size.y > OCCLUDER_HEIGHT)
	mat.set_shader_parameter("half_width", box.size.x * 0.5)
	mat.set_shader_parameter("roundness", ROUNDNESS.get(kind, 0.5))
	# Its foot darker like a picture's, measured on the mesh (its atlas UVs say nothing of height).
	mat.set_shader_parameter("foot_height", maxf(box.end.y, 0.01))
	return mat


## Details on a RELIEF material: `normals` in the picture's frame (`mode` 1) or the mesh's
## tangent frame (2), catching the sun this `strength`; the hollows darker (`ao`, optional).
static func _set_details(mat: ShaderMaterial, normals: Texture2D, mode: int, strength: float, ao: Texture2D = null) -> void:
	mat.set_shader_parameter("normal_mode", mode)
	mat.set_shader_parameter("normal_tex", normals)
	mat.set_shader_parameter("detail", strength)
	if ao:
		mat.set_shader_parameter("ao_tex", ao)
		mat.set_shader_parameter("has_ao", true)


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


## Instances of one picture (a QuadMesh with its material), relief (`material` given) or model
## (materials on its surfaces), split into chunks (each culled and faded alone).
func _add_multimesh(mesh: Mesh, items: Array, shadows: bool, range_end := VIEW_RANGE, material: Material = null) -> void:
	var chunks := {}
	for it: Array in items:
		var at: Vector3 = it[0]
		var key := Vector2i(floori(at.x / CHUNK), floori(at.z / CHUNK))
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(it)
	var box := mesh.get_aabb()
	var reach := maxf(box.size.x, box.size.y) * (STRETCH if mesh is QuadMesh else 1.0)
	reach = maxf(reach, box.size.z)
	for key: Vector2i in chunks:
		var list: Array = chunks[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = mesh
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
		inst.material_override = material
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
			var own := _woods_at(r, Vector2(x + 0.5, y + 0.5))
			var trees: Array = own.get("forest", FOREST_TREES)
			var low: Array = own.get("low", ["buisson"])
			for i in count:
				var t := Vector2(x + rng.randf_range(0.1, 0.9), y + rng.randf_range(0.2, 0.95))
				var kind: String = trees[rng.randi() % trees.size()]
				# Bushes mostly, along a path: the trees would hide it (and what lies on it).
				# (A zone with its own woods: low ones by its south edge too.)
				var near_side := not own.is_empty() and y >= hm.size.y - LOW_SOUTH
				if near_side or rng.randf() < (0.7 if _by_path(r, x, y) else 0.18):
					kind = low[rng.randi() % low.size()]
				if not groups.has(kind):
					groups[kind] = []
				groups[kind].append([Vector3(t.x + shift.x, hm.height(t), t.y + shift.y), rng.randf() < 0.5, rng.randf_range(0.9, 1.3)])
	for kind: String in groups:
		_add_props(kind, groups[kind])


static func _by_path(r: Region, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if r.surface_at(Vector2((x + dx + 0.5) * PX, (y + dy + 0.5) * PX)) == &"path":
				return true
	return false


func _build_tall_grass() -> void:
	var items := []
	var thin := []   # (where the cover layer lies thin: the usual tufts)
	var own: String = ZONE_TUFT.get(_region.region_id, "")
	var split := _region.cover_data != null and ResourceLoader.exists(own)
	var tufts: int = Quality.setting(&"grass_tufts") + 1
	for y in heights.size.y:
		for x in heights.size.x:
			if _region.surface_at(Vector2((x + 0.5) * PX, (y + 0.5) * PX)) != &"tall_grass":
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(Vector2i(x, y))
			for i in tufts:
				var p := Vector2(x + rng.randf_range(0.1, 0.9), y + (i + 0.5 + rng.randf_range(-0.2, 0.2)) / tufts)
				var item := [Vector3(p.x, heights.height(p), p.y), rng.randf() < 0.5, rng.randf_range(0.85, 1.12)]
				(thin if split and _region.cover_at(p * PX) < THIN_COVER else items).append(item)
	if not items.is_empty():
		_add_multimesh(_tuft_mesh(load(own) if ResourceLoader.exists(own) else TUFT), items, false, GRASS_RANGE)
	if not thin.is_empty():
		_add_multimesh(_tuft_mesh(TUFT), thin, false, GRASS_RANGE)


## The quad of a tuft of tall grass (its picture `tuft`), swaying and pushed aside by Chloé.
static func _tuft_mesh(tuft: Texture2D) -> QuadMesh:
	var metres := 0.23 / PX
	var quad := QuadMesh.new()
	quad.size = Vector2(tuft.get_width(), tuft.get_height()) * metres
	quad.center_offset = Vector3(0, (tuft.get_height() / 2.0 - tuft.get_height() * 0.06) * metres, 0)
	var mat := ShaderMaterial.new()
	mat.shader = BILLBOARD
	mat.set_shader_parameter("tex", tuft)
	mat.set_shader_parameter("stretch", STRETCH)
	mat.set_shader_parameter("sway", 3.0 / PX)
	mat.set_shader_parameter("push", 16.0 / PX)
	mat.set_shader_parameter("stiffness", 1.4)
	mat.set_shader_parameter("roundness", 0.2)
	mat.set_shader_parameter("base_shade", 0.35)
	quad.material = mat
	return quad


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
		var own := _woods_at(_region, p.clamp(Vector2.ZERO, Vector2(w - 1, h - 1)))
		var kinds: Array = own.get("low", OUTER_LOW) if near_side else own.get("outer", OUTER_TREES)
		var kind: String = kinds[rng.randi() % kinds.size()]
		if not groups.has(kind):
			groups[kind] = []
		groups[kind].append([Vector3(p.x, heights.height(p), p.y), rng.randf() < 0.5, rng.randf_range(0.9, 1.25)])
	for kind: String in groups:
		_add_props(kind, groups[kind])


# ------------------------------------------------------------------ doors

## The zone's houses one goes into, with their door apart (Doors): the shops (StoryProp) and
## the buildings a ZoneExit starts at (the Cabinet), when their kind has such a model.
func _find_doors(region: Region) -> void:
	var fronts := region.exits().map(func(e: ZoneExit) -> Rect2:
		return Rect2(e.global_position, e.size).grow(Doors.EXIT_REACH))
	for n in region.entities.get_children():
		if not n is Prop or n.is_queued_for_deletion() or not Doors.has_model(n.kind):
			continue
		var front: Vector2 = Doors.door_2d(n)["front"]
		if n is StoryProp or fronts.any(func(r: Rect2) -> bool: return r.has_point(front)):
			doors.register(n)


## A plain building with its door apart, standing alone (its body, its leaves): false when the
## quality shows pictures (it stays in its kind's batch).
func _add_door_house(house: Prop, at: Vector3) -> bool:
	var meshes := _door_meshes(house)
	if meshes.is_empty():
		return false
	var body := MeshInstance3D.new()
	body.mesh = meshes["body"]
	body.position = at
	body.scale = Vector3(-1.0 if house.flip else 1.0, 1.0, 1.0)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if not _region.indoor:
		body.visibility_range_end = VIEW_RANGE
		body.visibility_range_end_margin = 6.0
		body.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	_zone.add_child(body)
	doors.attach(house, body, meshes)
	return true


## The painted body and leaves of `house`, if it goes in and out through its door and the
## quality shows the real models ({}: its picture, or its kind's plain model).
func _door_meshes(house: Node) -> Dictionary:
	if not doors.houses.has(house) or not reliefs or not Quality.setting(&"relief_props"):
		return {}
	return Doors.painted(String(house.get("kind")), details)


## The door of `house` (a building one goes into) in the 2D world, Doors.door_2d: "threshold",
## "inside", "front" (px), "sill", "height", "width" (m)…; {} when it has none.
func door(house: Node) -> Dictionary:
	if house == null or not is_instance_valid(house) or not doors.houses.has(house):
		return {}
	return Doors.door_2d(house)


## Opens (or closes) the door of `house`, with its sound. Awaitable.
func open_door(house: Node, open := true, secs: float = Doors.OPEN_S) -> void:
	if is_instance_valid(house):
		await doors.open(house, open, secs)


## Shows the door of `house` open (or closed) at once, without a sound.
func set_door(house: Node, open: bool) -> void:
	if is_instance_valid(house):
		doors.set_open(house, open)



## The house whose door front is nearest `px` (2D), within `reach` px; null when none.
func door_near(px: Vector2, reach := 96.0) -> Node2D:
	var best: Node2D = null
	for house in doors.houses:   # (untyped: one may have been freed)
		if is_instance_valid(house):
			var dist := (Doors.door_2d(house)["front"] as Vector2).distance_to(px)
			if dist <= reach:
				reach = dist
				best = house
	return best


## The house `exit` starts at (going in through its door), or null (an exit in the open).
func door_of_exit(exit: ZoneExit) -> Node2D:
	if exit == null or not is_instance_valid(exit):
		return null
	var area := Rect2(exit.global_position, exit.size).grow(Doors.EXIT_REACH)
	for house in doors.houses:
		if is_instance_valid(house) and area.has_point(Doors.door_2d(house)["front"]):
			return house
	return null


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
	var model := _prop_model(node, sprite)
	# A house one goes into (a shop): its body with a real opening, its door apart (Doors).
	var with_door: Dictionary = _door_meshes(node) if model else {}
	if not with_door.is_empty():
		model = with_door["body"]
	var vis: GeometryInstance3D
	if model:   # a prop shown as its real 3D model (_sync_model)
		vis = MeshInstance3D.new()
		(vis as MeshInstance3D).mesh = model
	else:
		var pic: SpriteBase3D = AnimatedSprite3D.new() if sprite is AnimatedSprite2D else Sprite3D.new()
		pic.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		pic.shaded = true
		# Props stand still: cut out like the scenery (_sync_picture), so they write depth and a
		# character in front of a big facade is never drawn behind it (the rest is only sorted).
		pic.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
		pic.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		vis = pic
	vis.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_zone.add_child(vis)
	if not with_door.is_empty():
		doors.attach(node, vis, with_door)
	# "tex": the picture its model stands for (another one shown: back to a picture, _process).
	var proxy := {"src": node, "sprite": sprite, "vis": vis, "light": null, "glow": null,
		"prev": node.global_position, "cur": node.global_position, "foot": null, "foot_2d": null,
		"tex": (sprite as Sprite2D).texture if model else null}
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


## The real 3D model a mirrored prop is shown as, or null (its picture): its kind has one, the
## quality shows it (_model_mesh) and the prop shows its kind's own picture, not another one.
func _prop_model(node: Node, sprite: Node2D) -> Mesh:
	if not node is Prop or not sprite is Sprite2D:
		return null
	var tex := (sprite as Sprite2D).texture
	if tex == null or tex.resource_path != Prop.ART % (node as Prop).kind:
		return null
	return _model_mesh((node as Prop).kind)


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
		if p["tex"] and (p["sprite"] as Sprite2D).texture != p["tex"]:   # its model no longer fits
			_free_proxy(p)
			_proxies.remove_at(i)
			_track(p["src"])
			continue
		_sync(p)
	if player and heights:
		var at := _player_prev.lerp(_player_cur, Engine.get_physics_interpolation_fraction())
		var feet := heights.to_3d(at)
		if _underwater:   # under the sea: the height she swims at, over the rocks
			feet.y = _underwater.camera_height(feet.y)
		elif _swimmer_of(player):   # the camera follows her on the water, not the bottom
			feet.y = maxf(feet.y, HeightMap.WATER_LEVEL)
		camera.target = feet if focus_px == Vector2.INF else heights.to_3d(focus_px)
		camera.close_up = close_up
		RenderingServer.global_shader_parameter_set(&"player_world", feet if occlusion_px == Vector2.INF else heights.to_3d(occlusion_px))
		_pollen.position = camera.target + Vector3(0, 1.5, 0)
		_wildlife.heights = heights
		# The little life shelters from the rain, the sand, the blizzard (not from gentle snow).
		_wildlife.snowing = maxf(_snow.snow, _snow.blizzard)
		_wildlife.update(delta, camera.target, Game.clock / 60.0, maxf(maxf(_rain_amount, _sand_amount), _snow.blizzard),
			_region, feet)
		_rain.position = camera.target + Vector3(0, 9.0, 2.0)
		# The wind blows from the west: the grains start upwind and cross the view.
		_sand.position = camera.target + Vector3(-15.0, 1.2, 1.0)
		_dust.position = camera.target + Vector3(0.0, 1.4, 1.0)
		_snow.follow(camera.target)
		_update_wake(at)
	_update_floods()
	var blend := 1.0 - exp(-WEATHER_BLEND * delta)
	_rain_amount = lerpf(_rain_amount, 1.0 if Game.is_raining() else 0.0, blend)
	_storm_amount = lerpf(_storm_amount, 1.0 if Game.weather == &"storm" else 0.0, blend)
	_lightning(delta)
	_mist_amount = lerpf(_mist_amount, 1.0 if Game.weather == &"mist" else 0.0, blend)
	_sand_amount = lerpf(_sand_amount, 1.0 if Game.weather == &"sandstorm" else 0.0, blend)
	_snow.blend(delta, blend)
	_update_sky(Game.clock / 60.0)
	_magic.update(delta, _region, player, _sun, _env)
	(camera.attributes as CameraAttributesPractical).dof_blur_far_distance = camera.distance() + 13.0


func _sync(p: Dictionary) -> void:
	var src: Node2D = p["src"]
	var sprite: Node2D = p["sprite"]
	var at: Vector2 = (p["prev"] as Vector2).lerp(p["cur"], Engine.get_physics_interpolation_fraction())
	var swimmer := _swimmer_of(src)
	if p["vis"] is MeshInstance3D:
		_sync_model(p["vis"], src as Prop, sprite as Sprite2D, at)
	else:
		_sync_picture(p, at, swimmer)
	var vis: GeometryInstance3D = p["vis"]
	if p["foot"]:
		var foot: MeshInstance3D = p["foot"]
		var shadow_2d: Sprite2D = p["foot_2d"]
		# (No foot shadow in the water: it would show on the bottom, through the water sheet.)
		foot.visible = vis.visible and is_instance_valid(shadow_2d) and shadow_2d.visible and swimmer == null
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


## A prop mirrored as its real 3D model (see _track): standing on its foot (the model's origin,
## no picture offset), flipped by its node, fading with its sprite (the shader's opacity).
func _sync_model(model: MeshInstance3D, src: Prop, sprite: Sprite2D, at: Vector2) -> void:
	var alpha := src.modulate.a * sprite.modulate.a * sprite.self_modulate.a
	model.visible = _shown(sprite) and alpha > 0.01
	var local := sprite.position
	model.position = heights.to_3d(at) + Vector3(local.x / PX, -local.y / PX * STRETCH, 0)
	# In metres already: only a change of the prop's own scale (in a scene) applies.
	var size := absf(sprite.global_scale.x) / float(Prop.KINDS[src.kind]["scale"])
	model.scale = Vector3(-size if sprite.flip_h else size, size, size)
	model.set_instance_shader_parameter(&"opacity", alpha)
	if model.get_child_count() > 0:   # its door's leaves (Doors)
		doors.set_opacity(src, alpha)


## A mirrored node's picture (Sprite3D), as its 2D sprite is now (`at`: where it stands).
func _sync_picture(p: Dictionary, at: Vector2, swimmer: Dino) -> void:
	var src: Node2D = p["src"]
	var sprite: Node2D = p["sprite"]
	var vis: SpriteBase3D = p["vis"]
	vis.visible = _shown(sprite)
	var local := sprite.position
	var foot := heights.to_3d(at)
	if src is Prop and Prop.KINDS.get((src as Prop).kind, {}).get("float", false):
		foot.y = maxf(foot.y, HeightMap.WATER_LEVEL + 0.06)   # a boat of a scene rides the water, like the scenery's
	vis.position = foot + Vector3(local.x / PX, -local.y / PX * STRETCH, 0)
	if _underwater and not src is Prop:   # under the sea: they swim above the floor, over its rocks (Underwater.swim_lift)
		vis.position.y += _underwater.hover(src) + _underwater.swim_lift(p, src, at) - (dive_sink if swimmer else 0.0)
	elif swimmer:
		vis.position.y += _swim_drop(at, swimmer)
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
		if not src is Prop:   # characters and dinos: a hop at each step, breathing (swimming: the bob)
			var hop := 0.0 if swimmer or _underwater else SpriteMotion.apply(p, sprite, vis, get_process_delta_time())
			if src is Companion and (src as Companion).carrying():
				_mount_hop = hop
			elif src is Player and (src as Player).carried_by():
				vis.position.y += _mount_hop   # in the saddle: she follows her mount's steps
	else:
		(vis as Sprite3D).texture = (sprite as Sprite2D).texture
	if _underwater and not src is Prop:   # swimming, never walking: roll, pitch, soft turns
		_underwater.swim_pose(p, src, vis)


## The dino carrying Chloé in the water, when `node` is Chloé or that dino (else null).
func _swimmer_of(node: Node) -> Dino:
	var chloe := node as Player
	if chloe == null and node is Companion:
		chloe = (node as Companion).player
	if chloe == null or chloe.mount:
		return null
	return chloe.swimmer


## How far below its ground point the swimmer, and Chloé on its back, are shown (m): sunk to
## Swim.SINK of its height under the water sheet, bobbing gently; by the shore only as deep as
## the water is there, so they glide in and out of it.
func _swim_drop(at: Vector2, swimmer: Dino) -> float:
	var ground := heights.to_3d(at).y
	var wet := clampf((HeightMap.WATER_LEVEL - ground) / (HeightMap.WATER_DEPTH * 0.5), 0.0, 1.0)
	var bob := sin(Time.get_ticks_msec() / 1000.0 * TAU / SWIM_BOB_S) * SWIM_BOB
	var afloat := HeightMap.WATER_LEVEL - SWIM.sink(swimmer) + bob
	return (afloat - ground) * wet - dive_sink


## Ripples spreading behind the swimmer while it moves (Chloé at `at`, 2D).
func _update_wake(at: Vector2) -> void:
	var swimming := _swimmer_of(player) != null and not _region.indoor
	var speed := _player_cur.distance_to(_player_prev) * Engine.physics_ticks_per_second
	_wake.emitting = swimming and speed > 30.0
	if swimming:
		_wake.position = Vector3(at.x / PX, HeightMap.WATER_LEVEL + 0.03, at.y / PX)


## Droplets thrown up where Chloé goes into the water or comes out of it (`p`, 2D).
func splash(p: Vector2) -> void:
	if heights == null:
		return
	var ground := heights.to_3d(p).y
	burst(p, SPLASH, 16, maxf(0.0, HeightMap.WATER_LEVEL + 0.1 - ground), 0.45)


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


## A sandstorm's grains: thin ochre streaks flying past on the wind (west to east).
func _make_sand() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = SAND_GRAINS
	p.lifetime = 1.8
	p.local_coords = false
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(3.0, 2.2, 13.0)
	p.direction = Vector3(1.0, 0.05, 0.1)
	p.spread = 5.0
	p.initial_velocity_min = 13.0
	p.initial_velocity_max = 18.0
	p.gravity = Vector3(0, -0.5, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.28, 0.014)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	p.mesh = q
	return p


## …and clouds of dust drifting along with it, soft and pale.
func _make_dust() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = DUST_CLOUDS
	p.lifetime = 3.0
	p.preprocess = 3.0
	p.local_coords = false
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(15.0, 2.0, 12.0)
	p.direction = Vector3(1.0, 0.05, 0.0)
	p.spread = 10.0
	p.initial_velocity_min = 3.5
	p.initial_velocity_max = 6.0
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.2
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.3, Color(1, 1, 1, 0.16))
	fade.add_point(0.7, Color(1, 1, 1, 0.16))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	p.mesh = _speck(1.1)
	return p


## The wake of a swimmer: pale rings on the water, spreading out and fading.
func _make_wake() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = WAKE_DOTS
	p.lifetime = 1.4
	p.local_coords = false
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.35, 0.0, 0.25)
	p.direction = Vector3(1, 0, 0)
	p.spread = 180.0
	p.flatness = 1.0   # on the water only
	p.initial_velocity_min = 0.15
	p.initial_velocity_max = 0.45
	p.gravity = Vector3.ZERO
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 1.6))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(0.95, 0.98, 1.0, 0.55))
	fade.set_color(1, Color(0.95, 0.98, 1.0, 0.0))
	p.color_ramp = fade
	p.mesh = _speck(0.2)
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
	_sand.emitting = false
	_dust.emitting = false
	_snow.stop()
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
	var sand := _sand_amount
	var snow := _snow.snow
	var bliz := _snow.veil()   # (thicker in the gusts)
	_sun.rotation_degrees = Vector3(-lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), 0.0)
	_sun.light_color = (a[3] as Color).lerp(b[3], t).lerp(Color(1.0, 0.8, 0.55), sand * 0.5) \
		.lerp(Color(0.9, 0.94, 1.0), snow * 0.4 + bliz * 0.5)
	_sun.light_energy = lerpf(a[4], b[4], t) * (1.0 - 0.65 * rain) * (1.0 - 0.4 * mist) * (1.0 - 0.45 * sand) \
		* (1.0 - 0.45 * snow) * (1.0 - 0.55 * bliz)
	var sky := (a[7] as Color).lerp(b[7], t)
	var bright := clampf(sky.get_luminance() / 0.75, 0.15, 1.0)
	sky = sky.lerp(Color(0.55, 0.58, 0.62) * bright, rain * 0.8).lerp(Color(0.82, 0.84, 0.86) * bright, mist * 0.85)
	sky = sky.lerp(SAND_SKY * bright, sand * 0.85)
	# Snow: an overcast white-grey sky; the blizzard: all white.
	sky = sky.lerp(Color(0.76, 0.8, 0.86) * bright, snow * 0.7).lerp(SNOWFALL.SKY * bright, bliz * 0.9)
	_env.ambient_light_color = (a[5] as Color).lerp(b[5], t).lerp(Color(0.62, 0.65, 0.7) * bright, rain * 0.5 + mist * 0.4) \
		.lerp(Color(0.8, 0.64, 0.45) * bright, sand * 0.5).lerp(Color(0.76, 0.8, 0.88) * bright, snow * 0.35 + bliz * 0.5)
	# (Falling snow greys the day a little, so that the white flakes show against the snow.)
	_env.ambient_light_energy = lerpf(a[6], b[6], t) * (1.0 + 0.2 * mist + 0.15 * sand - 0.12 * snow + 0.2 * bliz)
	_env.background_color = sky
	_env.fog_light_color = sky
	# Mist (or blowing sand, or snow): clear around Chloé (the camera is ~distance away), thick a
	# few metres beyond; falling snow closes the horizon a little, like rain.
	var near := camera.distance()
	var veil := maxf(mist, sand)
	var closed := maxf(rain, snow * 0.6)
	var begin := lerpf(lerpf(near + 8.0, near + 2.0, closed), near - 1.0, veil)
	var end := lerpf(lerpf(near + 46.0, near + 28.0, closed), near + 14.0, veil)
	# The blizzard closes in more than the sand, even around Chloé, most in the gusts.
	_env.fog_depth_begin = lerpf(begin, near - 2.5, bliz)
	_env.fog_depth_end = lerpf(end, near + 9.0 - 3.0 * _snow.gust, bliz)
	_pollen.visible = hour > 6.0 and hour < 20.0 and rain < 0.3 and sand < 0.3 and snow < 0.3 and bliz < 0.3
	_snow.shade(bright)
	# Sand streaking past, dust drifting, as thick as the storm is.
	_sand.emitting = sand > 0.05
	_dust.emitting = sand > 0.05
	_sand.color = Color(SAND, 0.42 * sand)
	_dust.color = Color(SAND_SKY, sand)
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
