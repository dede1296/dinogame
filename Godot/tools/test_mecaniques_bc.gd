extends SceneTree
## Headless checks of the Marais and Désert mechanics: La Nage (Swim: its conditions, the
## water's own physics layer, Chloé walking into the water and out of it on her swimmer's
## back, carried in the view), flood water (Flood: blocks, drains on its flag, rises again
## but never over Chloé), the sandstorm (only where a zone allows it, or set by a scene; the
## view, the battle, the clock), items dug up with Flair (DigSpot.item_id) and the new items.
## Prints each check, quits with 1 on a failure:
##   godot --headless --path Godot --script res://tools/test_mecaniques_bc.gd
## The game's scripts are loaded at run time (they need the autoloads, which a --script main
## loop only gets after it is compiled), so everything here is untyped. Nothing is saved.

const TILE := 48.0
## Scripts touched by these mechanics: each must compile.
const SCRIPTS := [
	"res://world/swim.gd", "res://world/flood.gd", "res://actors/player.gd", "res://actors/companion.gd",
	"res://actors/saddle.gd", "res://world/dig_spot.gd", "res://tools/zone_builder.gd", "res://data/abilities.gd",
	"res://data/items_db.gd", "res://core/game_state.gd", "res://world/view3d/world_view.gd",
	"res://battle/battle_weather.gd", "res://ui/clock_badge.gd", "res://world/region.gd",
]
## A small zone: a pond (tiles 6–9 across, 2–5 down) between two meadows.
const PLAN := [
	"....................",
	"....................",
	"......~~~~..........",
	"......~~~~..........",
	"......~~~~..........",
	"......~~~~..........",
	"....................",
	"....................",
]
const ROW := 3.5   # the row Chloé walks along (tiles)

var _checks := 0
var _failures := 0
var game: Node
var SwimS: GDScript
var DinoS: GDScript
var Builder: GDScript
var region: Node2D
var player: CharacterBody2D
var companion: Node2D
var view: Node3D
var flood: Node2D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("— Mécaniques (Marais, Désert) : tests headless —")
	for path: String in SCRIPTS:
		var s: GDScript = load(path)
		_check(s != null and s.can_instantiate(), "compile %s" % path)
	_check(load("res://world/view3d/flood.gdshader") is Shader, "shader de l'eau de crue")
	game = root.get_node_or_null("Game")
	_check(game != null, "autoload Game présent")
	if game == null or _failures > 0:
		_finish()
		return
	SwimS = load("res://world/swim.gd")
	DinoS = load("res://game/dino.gd")
	Builder = load("res://tools/zone_builder.gd")
	_test_tileset()
	_test_swim_rules()
	_test_items()
	_test_dig_item()
	_test_weather_rules()
	await _test_weather_views()
	await _test_zone()
	_finish()


func _finish() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	print("— %d vérifications, %d échec(s) —" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print(("  ok    " if ok else "  ÉCHEC ") + what)


# ------------------------------------------------------------------ rules

func _test_tileset() -> void:
	var ts: TileSet = load("res://regions/terrain_tileset.tres")
	var src := ts.get_source(0) as TileSetAtlasSource
	var water := src.get_tile_data(Vector2i(3, 0), 0)
	var forest := src.get_tile_data(Vector2i(4, 0), 0)
	_check(ts.get_physics_layers_count() == 2 and ts.get_physics_layer_collision_layer(1) == SwimS.WATER_LAYER,
		"tileset : l'eau a sa couche physique (16)")
	_check(water.get_collision_polygons_count(1) == 1 and water.get_collision_polygons_count(0) == 0,
		"tileset : l'eau n'est plus sur la couche « monde »")
	_check(forest.get_collision_polygons_count(0) == 1 and ts.get_physics_layer_collision_layer(0) == 1,
		"tileset : la forêt bloque toujours (couche 1)")


func _test_swim_rules() -> void:
	game.new_game()
	game.give_starter(&"velociraptor")
	var abilities: GDScript = load("res://data/abilities.gd")
	_check(not abilities.DEFS[&"nage"].has("soon"), "Nage jouable (plus « bientôt »)")
	_check(not SwimS.can_swim() and SwimS.blocked_reason() == "Sans gilet de nage et sans dino nageur, impossible d'aller plus loin.",
		"ni gilet ni nageur : pas de nage, le message prévu")
	game.give_item("gilet_nage")
	_check(not SwimS.can_swim() and SwimS.blocked_reason().contains("dino nageur adulte"), "gilet seul : il manque un nageur")
	var young = DinoS.create(&"baryonyx", 8)
	game.add_caught(young)
	_check(not SwimS.can_swim() and SwimS.blocked_reason().contains("trop jeune"), "Baryonyx niv. 8 : trop jeune")
	young.level = 14
	_check(SwimS.can_swim() and SwimS.swimmer() == young, "Baryonyx niv. 14 + gilet : il porte Chloé")
	game.items.erase("gilet_nage")
	_check(not SwimS.can_swim() and SwimS.blocked_reason().contains("sans gilet"), "nageur sans gilet : il manque le gilet")
	game.set_flag(&"gilet_nage")
	_check(SwimS.can_swim(), "drapeau « gilet_nage » : vaut le gilet")
	var koola = DinoS.create(&"koolasuchus", 14)
	_check(abilities.usable(koola, &"nage"), "reptile marin adulte : nage aussi")
	_check(SwimS.sink(young) > 0.5 and SwimS.sink(young) < 1.5, "enfoncement du Baryonyx : %.2f m" % SwimS.sink(young))


func _test_items() -> void:
	var db: GDScript = load("res://data/items_db.gd")
	var ok := true
	for id: String in ["gilet_nage", "fossile", "coeur_1", "coeur_2", "sceau_marais", "sceau_desert", "sceau_foret"]:
		var item: Dictionary = db.ITEMS.get(id, {})
		if item.is_empty() or not FileAccess.file_exists("res://assets/art/ui/%s.png" % item["icon"]):
			ok = false
			print("    objet manquant ou sans icône : ", id)
	_check(ok, "objets : gilet, fossile, Cœurs, Sceaux (icônes présentes)")
	_check(db.ITEMS["coeur_1"]["kind"] == "cle" and db.ITEMS["sceau_desert"]["kind"] == "cle" and db.ITEMS["fossile"]["sell"] == 0,
		"Cœurs et Sceaux : objets clés ; fossile : jamais vendu")


func _test_dig_item() -> void:
	game.new_game()
	game.give_starter(&"velociraptor")
	var dig: GDScript = load("res://world/dig_spot.gd")
	var pebbles_before: int = game.pebbles_found()
	var first: String = dig.dig_up("fossile", &"fossile_test_01")
	var second: String = dig.dig_up("fossile", &"fossile_test_02")
	_check(game.item_count("fossile") == 2 and game.flag(&"fossile_test_01") and game.flag(&"fossile_test_02"),
		"fossiles déterrés : 2 dans le sac, drapeaux posés")
	_check(first == "Fossile !" and second == "Fossile ! Tu en as 2.", "messages : « %s », « %s »" % [first, second])
	_check(game.pebbles_found() == pebbles_before, "un fossile ne compte pas comme un galet")
	var spot: Node2D = dig.new()
	spot.pebble = &"fossile_test_03"
	spot.item_id = "fossile"
	root.add_child(spot)
	_check(not spot.visible, "sans Flair : l'endroit est invisible")
	game.add_caught(DinoS.create(&"compsognathus", 6))
	_check(spot.visible and spot.is_hiding() and spot.is_in_group(&"interactable"), "avec Flair : on le voit, le dino le sent")
	spot.free()
	var built: Node2D = Builder.buried_item(Node2D.new(), 3.0, 4.0, "fossile", &"fossile_test_04")
	_check(built.item_id == "fossile" and built.pebble == &"fossile_test_04" and built.position == Vector2(144, 192),
		"ZoneBuilder.buried_item")
	built.get_parent().free()


func _test_weather_rules() -> void:
	game.new_game()
	var plains := {"rain": 0.08, "mist": 0.1, "storm": 0.03}
	var desert := {"rain": 0.0, "mist": 0.0, "storm": 0.0, "sandstorm": 0.12}
	var sand_in_plains := 0
	var sand_in_desert := 0
	for hour in 24:
		for i in 1000:
			if game.weather_for(i / 1000.0, hour, plains) == &"sandstorm":
				sand_in_plains += 1
			if game.weather_for(i / 1000.0, hour, desert) == &"sandstorm":
				sand_in_desert += 1
	_check(sand_in_plains == 0, "sans sandstorm_chance : jamais de tempête de sable")
	_check(sand_in_desert == 24 * 120, "Désert (0,12) : 12 % des tirages")
	_check(game.weather_for(0.05, 12, plains) == &"mist" and game.weather_for(0.15, 12, plains) == &"rain"
		and game.weather_for(0.2, 12, plains) == &"storm" and game.weather_for(0.5, 12, plains) == &"clear",
		"les autres météos tirées comme avant")
	var region_s: GDScript = load("res://world/region.gd")
	var r = region_s.new()
	_check(is_zero_approx(r.sandstorm_chance), "Region.sandstorm_chance : 0 par défaut")
	r.free()
	game.set_climate(desert)
	game.set_weather(&"sandstorm")
	_check(game.weather == &"sandstorm", "Game.set_weather(&\"sandstorm\") : une scène la déclenche")
	game.set_climate(desert)
	_check(game.weather == &"sandstorm", "dans le Désert, elle continue")
	game.set_climate(plains)
	_check(game.weather == &"clear", "hors du Désert : elle s'arrête")
	game.set_weather(&"sandstorm")
	game.climate = plains   # (the world before its patch: no set_climate)
	for i in 5:
		game._roll_weather(12)
	_check(game.weather != &"sandstorm", "sans chance de tempête, l'heure suivante l'arrête")
	var saved = JSON.parse_string(JSON.stringify(game.to_dict()))
	game.set_weather(&"sandstorm")
	saved = JSON.parse_string(JSON.stringify(game.to_dict()))
	game.from_dict(saved)
	_check(game.weather == &"sandstorm", "sauvegardée et relue")
	game.set_weather(&"clear")


func _test_weather_views() -> void:
	game.set_weather(&"sandstorm")
	var bw: GDScript = load("res://battle/battle_weather.gd")
	var clear: Color = bw.tint(12.0, &"clear")
	var sand: Color = bw.tint(12.0, &"sandstorm")
	_check(sand != clear and sand.r > sand.b + 0.1, "combat : lumière ocre (%s)" % sand)
	var parent := Control.new()
	var backdrop := Control.new()
	var fighters := Control.new()
	parent.add_child(backdrop)
	parent.add_child(fighters)
	root.add_child(parent)
	var layer: Control = bw.apply(parent, backdrop, fighters)
	await process_frame
	var veil := false
	var grains := false
	for c in layer.get_children():
		veil = veil or c is TextureRect
		grains = grains or c is CPUParticles2D
	_check(veil and grains, "combat : voile ocre et sable qui vole")
	parent.free()
	var badge: Control = load("res://ui/clock_badge.gd").new()
	root.add_child(badge)
	await process_frame
	var own_icon: bool = ResourceLoader.exists(badge.LOCAL_ICONS[&"sandstorm"][0])   # meteo_sable.png, else the mist tinted ochre
	_check(badge._icon.texture != null and badge._icon.modulate.is_equal_approx(Color.WHITE if own_icon else badge.LOCAL_ICONS[&"sandstorm"][1]),
		"horloge : icône de tempête de sable")
	badge.free()
	var v: Node3D = load("res://world/view3d/world_view.gd").new()
	root.add_child(v)
	for i in 3:
		await process_frame
	_check(v._sand_amount > 0.9 and v._sand.emitting and v._dust.emitting, "vue 3D : sable et poussière qui volent")
	var fog: Color = v._env.fog_light_color
	_check(fog.r > fog.b + 0.1, "vue 3D : ciel et brume ocre (%s)" % fog)
	_check(v._env.fog_depth_end < v.camera.distance() + 20.0, "vue 3D : on voit moins loin")
	game.set_weather(&"clear")
	v.free()


# ------------------------------------------------------------------ in a zone

## A small zone with a pond (PLAN), flood water beyond it, Chloé and her dino, the 3D view.
func _make_zone() -> void:
	region = Builder.region(&"test_nage", "Essai", "Mare", Vector2i(2, 5), PLAN)
	flood = Builder.flood(region, Rect2(14, 1, 2, 5), &"test_crue_seche")
	root.add_child(region)
	player = load("res://actors/player.tscn").instantiate()
	companion = load("res://actors/companion.tscn").instantiate()
	companion.player = player
	region.entities.add_child(player)
	region.entities.add_child(companion)
	player.surface_at = region.surface_at
	player.teleport(Vector2(3.5, ROW) * TILE)
	companion.teleport(Vector2(2.8, ROW) * TILE)
	view = load("res://world/view3d/world_view.gd").new()
	root.add_child(view)
	view.show_zone(region, player)
	for i in 4:
		await physics_frame


## Holds a direction until `done` says so (or `seconds` pass). Returns true if it did.
func _walk(action: StringName, done: Callable, seconds := 3.0) -> bool:
	Input.action_press(action)
	var frames := int(seconds * Engine.physics_ticks_per_second)
	var ok := false
	for i in frames:
		await physics_frame
		if done.call():
			ok = true
			break
	Input.action_release(action)
	for i in 3:
		await physics_frame
	return ok


func _test_zone() -> void:
	game.new_game()
	game.give_starter(&"velociraptor")
	await _make_zone()
	var lead = game.lead_dino()
	var x := func() -> float: return player.global_position.x / TILE
	# No vest, no swimmer: the water is in the way; told why once.
	await _walk(&"move_right", func() -> bool: return false, 1.6)
	_check(x.call() < 6.0 and x.call() > 5.0, "sans gilet ni nageur : Chloé s'arrête au bord (x = %.2f)" % x.call())
	_check(player._water_told and root.get_node_or_null("Toast") != null, "…et on lui dit pourquoi")
	_check(player.collision_mask & SwimS.WATER_LAYER != 0 and player.swimmer == null, "…l'eau reste dans son masque")
	# With the vest and a grown Baryonyx: she goes in and swims on its back.
	game.give_item("gilet_nage")
	var bary = DinoS.create(&"baryonyx", 14)
	game.add_caught(bary)
	var swimming := await _walk(&"move_right", func() -> bool: return x.call() > 7.6, 2.5)
	_check(swimming and player.swimmer == bary, "gilet + Baryonyx adulte : elle entre dans l'eau et nage (x = %.2f)" % x.call())
	_check(companion.carrying() and companion.swimming() and companion.dino == bary, "son nageur la porte (le compagnon devient le Baryonyx)")
	_check(player.collision_mask & SwimS.WATER_LAYER == 0, "l'eau n'est plus dans son masque")
	_check(is_equal_approx(player.top_speed(), player.SPEED * SwimS.SPEED), "vitesse de nage ×1,3")
	_check(player.get_meta(&"cut_out", false) and companion.get_meta(&"cut_out", false), "vue : découpés (l'eau les coupe)")
	_check(String(player.sprite.animation).begins_with("ride_"), "Chloé assise sur son dos (%s)" % player.sprite.animation)
	var deep := Vector2(8.0, ROW) * TILE
	var drop: float = view._swim_drop(deep, bary)
	var floating: float = view.heights.to_3d(deep).y + drop
	_check(absf(floating - (-0.425 - SwimS.sink(bary))) < 0.06, "vue : à demi dans l'eau (%.2f m)" % floating)
	_check(is_zero_approx(view._swim_drop(Vector2(1.5, 0.5) * TILE, bary)), "vue : rien sur la terre")
	_check(view._swimmer_of(companion) == bary and view._swimmer_of(player) == bary, "vue : Chloé et son nageur repérés")
	# Out on the far shore: on her feet again.
	var out := await _walk(&"move_right", func() -> bool: return x.call() > 11.0, 3.0)
	_check(out and player.swimmer == null and not companion.carrying(), "sur l'autre rive : elle marche (x = %.2f)" % x.call())
	_check(companion.dino == lead and player.trail.size() < 16, "son dino de tête la suit de nouveau")
	# Flood water beyond: it blocks, then drains on its flag.
	_check(flood.wet and is_equal_approx(flood.fill, 1.0) and flood.is_in_group(&"flood"), "crue : pleine au départ")
	_check(view._floods.size() == 1 and view._floods[0][1].visible, "crue : dessinée dans la vue 3D")
	await _walk(&"move_right", func() -> bool: return false, 1.5)
	_check(x.call() < 14.0, "crue : le passage est bloqué (x = %.2f)" % x.call())
	_check(flood._bank.is_in_group(&"interactable") and flood._bank.global_position.distance_to(player.global_position) < 40.0,
		"crue : Chloé peut la regarder (A)")
	game.set_flag(&"test_crue_seche")
	_check(not flood.wet and not flood._bank.is_in_group(&"interactable"), "vanne ouverte : l'eau baisse")
	await create_timer(flood.DRAIN_S * 0.5).timeout
	_check(flood.fill > 0.05 and flood.fill < 0.95, "…peu à peu (%.2f)" % flood.fill)
	await create_timer(flood.DRAIN_S * 0.5 + 0.4).timeout
	await physics_frame
	_check(is_zero_approx(flood.fill) and flood._shape.disabled and not view._floods[0][1].visible, "…jusqu'au fond : le passage est libre")
	var passed := await _walk(&"move_right", func() -> bool: return x.call() > 16.5, 2.5)
	_check(passed, "Chloé passe (x = %.2f)" % x.call())
	# In the saddle, into the water: the swimmer takes her.
	var steed = DinoS.create(&"parasaurolophus", 14)
	game.add_caught(steed)
	player.teleport(Vector2(11.5, ROW) * TILE)
	player.mount = steed
	companion.refresh()
	var in_water := await _walk(&"move_left", func() -> bool: return player.swimmer != null, 2.0)
	_check(in_water and player.mount == null and companion.dino == bary, "en selle dans l'eau : le nageur la prend sur son dos")
	var ashore := await _walk(&"move_left", func() -> bool: return x.call() < 5.2, 3.0)
	_check(ashore and player.swimmer == null and player.mount == null, "de retour sur la rive : à pied")
	# In the water without what she needs (a save, a dino sent away): never stuck there.
	game.items.erase("gilet_nage")
	player.teleport(Vector2(8.0, ROW) * TILE)
	await physics_frame
	await physics_frame
	_check(player.swimmer == null and player.collision_mask & SwimS.WATER_LAYER == 0, "dans l'eau sans gilet : elle n'y reste pas coincée")
	var waded := await _walk(&"move_left", func() -> bool: return x.call() < 5.5, 3.0)
	_check(waded, "…elle en ressort (x = %.2f)" % x.call())
	# Water rising where Chloé stands: it waits for her to step out.
	var rising: Node2D = Builder.flood(region, Rect2(1, 6, 3, 2), &"", {"flooded_flag": &"test_crue_monte", "name": "Crue2"})
	await process_frame
	_check(not rising.wet and is_zero_approx(rising.fill) and rising._shape.disabled, "crue à drapeau : sèche tant qu'il n'est pas posé")
	player.teleport(Vector2(2.0, 7.0) * TILE)
	await physics_frame
	game.set_flag(&"test_crue_monte")
	await physics_frame
	await physics_frame
	_check(rising.wet and rising._block_when_clear and rising._shape.disabled, "l'eau monte sur Chloé : elle ne la bloque pas")
	player.teleport(Vector2(12.0, 0.5) * TILE)
	await physics_frame
	await process_frame
	await physics_frame
	_check(not rising._block_when_clear and not rising._shape.disabled, "une fois sortie : le passage se ferme")
	view.free()
	region.free()
