extends SceneTree
## Headless checks of the Monts' weather (chapter 6): snow and the blizzard only where a zone
## allows them (Region.snow_chance, blizzard_chance) or set by a scene, a blizzard dying down
## into snow, saved; the habitats' weather option (Encounter.weathers, ZoneBuilder.habitat);
## the 3D view (soft flakes, driven flakes and a white veil, the little life sheltering from the
## blizzard but not from the snow, the few flakes of the snowy places giving way), the battle,
## the clock, the debug panel, the sounds (the Monts' ambiences, the blizzard's howl); the Monts'
## species (their sheets, families, abilities, sizes); Chloé's steps in the snow and on the ice, her
## down coat in a cold region; sliding on slippery ice.
## Prints each check, quits with 1 on a failure:
##   godot --headless --path Godot --script res://tools/test_meteo_neige.gd
## The game's scripts are loaded at run time (they need the autoloads), so everything here is
## untyped. Nothing is saved.

const SCRIPTS := [
	"res://core/game_state.gd", "res://world/region.gd", "res://data/encounter.gd", "res://world/habitat.gd",
	"res://tools/zone_builder.gd", "res://world/view3d/snowfall.gd", "res://world/view3d/world_view.gd",
	"res://world/view3d/wildlife.gd", "res://data/wildlife_db.gd", "res://battle/battle_weather.gd",
	"res://ui/clock_badge.gd", "res://ui/debug_menu.gd", "res://data/ambience_db.gd", "res://core/ambience_player.gd",
	"res://world/world.gd", "res://actors/player.gd", "res://actors/outfits.gd", "res://actors/saddle.gd",
]
const MONTS := {"rain": 0.0, "mist": 0.05, "storm": 0.0, "sandstorm": 0.0, "snow": 0.12, "blizzard": 0.03}
const PLAINS := {"rain": 0.08, "mist": 0.1, "storm": 0.03}
## The Monts' species: [family, ability it must have or &"", seen height range (m) of an adult].
const SPECIES := {
	&"pachyrhinosaurus": [&"ceratopsian", &"charge", Vector2(2.0, 2.8)],
	&"edmontosaurus": [&"hadrosaur", &"monture", Vector2(2.6, 3.4)],
	&"leaellynasaura": [&"hadrosaur", &"flair", Vector2(0.7, 1.3)],
	&"minmi": [&"armored", &"charge", Vector2(1.0, 1.8)],
	&"nanuqsaurus": [&"tyrant", &"", Vector2(2.2, 2.8)],
	&"cryolophosaure_titan": [&"tyrant", &"", Vector2(2.6, 3.3)],
}

var _checks := 0
var _failures := 0
var game: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("— Météo des Monts (neige, blizzard) : tests headless —")
	for path: String in SCRIPTS:
		var s: GDScript = load(path)
		_check(s != null and s.can_instantiate(), "compile %s" % path)
	game = root.get_node_or_null("Game")
	_check(game != null, "autoload Game présent")
	if game == null or _failures > 0:
		_finish()
		return
	_test_rules()
	_test_habitats()
	await _test_view()
	await _test_battle_and_clock()
	_test_sounds()
	_test_species()
	_test_steps()
	_test_coat()
	await _test_ice()
	_test_cover()
	game.set_weather(&"clear")
	_finish()


func _finish() -> void:
	print("— %d vérifications, %d échec(s) —" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


## Sets the clock without the hour turning the weather (Game rolls it when the hour changes).
func _set_hour(hour: int) -> void:
	game.clock = hour * 60.0
	game._hour = hour


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print(("  ok    " if ok else "  ÉCHEC ") + what)


# ------------------------------------------------------------------ rules

func _test_rules() -> void:
	game.new_game()
	_check(&"snow" in game.WEATHERS and &"blizzard" in game.WEATHERS, "Game.WEATHERS : neige et blizzard")
	var r = load("res://world/region.gd").new()
	_check(is_zero_approx(r.snow_chance) and is_zero_approx(r.blizzard_chance), "Region.snow_chance, blizzard_chance : 0 par défaut")
	r.free()
	var counts := {&"snow": 0, &"blizzard": 0}
	var elsewhere := 0
	for hour in 24:
		for i in 1000:
			var w: StringName = game.weather_for(i / 1000.0, hour, MONTS)
			if counts.has(w):
				counts[w] += 1
			if game.weather_for(i / 1000.0, hour, PLAINS) in [&"snow", &"blizzard"]:
				elsewhere += 1
	_check(elsewhere == 0, "sans snow_chance : jamais de neige ni de blizzard")
	_check(absi(counts[&"snow"] - 24 * 120) <= 12 and absi(counts[&"blizzard"] - 24 * 30) <= 12,
		"Monts (0,12 / 0,03) : %d neiges, %d blizzards sur 24 000 tirages" % [counts[&"snow"], counts[&"blizzard"]])
	_check(game.weather_for(0.05, 12, PLAINS) == &"mist" and game.weather_for(0.15, 12, PLAINS) == &"rain"
		and game.weather_for(0.2, 12, PLAINS) == &"storm" and game.weather_for(0.5, 12, PLAINS) == &"clear",
		"les autres météos tirées comme avant")
	game.set_climate(MONTS)
	game.set_weather(&"blizzard")
	_check(game.weather == &"blizzard" and game.is_snowing() and not game.is_raining(), "une scène pose le blizzard ; il neige, il ne pleut pas")
	game.set_climate(MONTS)
	_check(game.weather == &"blizzard", "aux Monts, il continue")
	var calmed := false
	for i in 60:
		game._roll_weather(12)
		if game.weather != &"blizzard":
			calmed = true
			break
	_check(calmed and game.weather == &"snow", "le blizzard retombe en neige (%s)" % game.weather)
	var saved = JSON.parse_string(JSON.stringify(game.to_dict()))
	game.from_dict(saved)
	_check(game.weather == &"snow", "neige sauvegardée et relue")
	game.set_climate(PLAINS)
	_check(game.weather == &"clear", "hors des Monts : la neige s'arrête")
	game.set_weather(&"blizzard")
	game.climate = {"rain": 0.0, "snow": 0.0, "blizzard": 0.0}
	game._roll_weather(12)
	_check(game.weather == &"clear", "sans chance de neige, le blizzard s'arrête net (pas de neige)")
	game.set_weather(&"sandstorm")
	game.set_climate(PLAINS)
	_check(game.weather == &"clear", "la tempête de sable s'arrête toujours hors du Désert")


func _test_habitats() -> void:
	var builder: GDScript = load("res://tools/zone_builder.gd")
	var region = builder.region(&"test_neige", "Essai", "Col", Vector2i(33, 40), ["........", "........", "........"])
	var h = builder.habitat(region, "Le Col", Rect2(0, 0, 8, 3), [
		[&"minmi", 33, 35, 10, "toujours", true],
		[&"nanuqsaurus", 38, 40, 3, "toujours", false, {"weather": [&"snow", &"blizzard"]}],
		[&"nanuqsaurus", 38, 40, 3, "toujours", true, {"weather": [&"blizzard"]}],
	], 2)
	_check(h.encounters[0].weathers.is_empty() and h.encounters[1].weathers == [&"snow", &"blizzard"],
		"ZoneBuilder.habitat : option {\"weather\": [...]} → Encounter.weathers")
	_check(h.weather_bound(), "l'habitat dépend de la météo (ses rôdeurs repartent quand elle tourne)")
	game.set_weather(&"clear")
	_check(not h.encounters[1].active(&"day") and h.encounters[0].active(&"day"), "beau temps : pas de Nanuqsaurus")
	game.set_weather(&"snow")
	_check(h.encounters[1].active(&"night") and not h.encounters[2].active(&"night"), "neige : il rôde (pas encore caché dans l'herbe)")
	game.set_weather(&"blizzard")
	var hidden_nanuq := 0
	for i in 200:
		if h.pick_hidden(&"day").species == &"nanuqsaurus":
			hidden_nanuq += 1
	_check(hidden_nanuq > 0 and hidden_nanuq < 200, "blizzard : aussi dans les rencontres cachées (%d / 200)" % hidden_nanuq)
	var plain = builder.habitat(region, "La Vallée", Rect2(0, 0, 8, 3), [[&"minmi", 33, 35, 10, "jour", false]], 2)
	_check(not plain.weather_bound(), "un habitat sans option : indifférent à la météo")
	region.free()
	game.set_weather(&"clear")


# ------------------------------------------------------------------ views

func _test_view() -> void:
	game.set_climate(MONTS)   # (else the next hour would stop the snow)
	_set_hour(12)
	game.set_weather(&"snow")
	var v: Node3D = load("res://world/view3d/world_view.gd").new()
	root.add_child(v)
	for i in 3:
		await process_frame
	var snow = v._snow
	_check(snow.snow > 0.9 and snow._flakes.emitting and not snow._driven.emitting, "vue 3D, neige : flocons doux, pas de rafales")
	_check(snow._flakes.amount == root.get_node("Quality").scaled(snow.FLAKES), "nombre de flocons selon Quality (%d)" % snow._flakes.amount)
	var snow_end: float = v._env.fog_depth_end
	_check(snow_end < v.camera.distance() + 46.0 and snow_end > v.camera.distance() + 20.0, "neige : l'horizon se ferme un peu (%.1f m)" % snow_end)
	_check(not v._pollen.visible, "neige : pas de pollen")
	game.set_weather(&"blizzard")
	v._snow.blizzard = 1.0   # (as if blended in already)
	v._snow.snow = 0.0
	await process_frame
	_check(snow._driven.emitting and snow._puffs.emitting, "vue 3D, blizzard : flocons chassés et bouffées de neige")
	_check(snow._driven.amount <= v.SAND_GRAINS * root.get_node("Quality").setting(&"particles") + 1 and snow._puffs.amount <= v.DUST_CLOUDS,
		"blizzard : pas plus de particules que la tempête de sable (%d + %d)" % [snow._driven.amount, snow._puffs.amount])
	var fog: Color = v._env.fog_light_color
	_check(fog.b >= fog.r and fog.get_luminance() > 0.6, "blizzard : voile blanc (%s)" % fog)
	_check(v._env.fog_depth_end < v.camera.distance() + 15.0, "blizzard : on voit moins loin (%.1f m)" % v._env.fog_depth_end)
	var bright: float = snow._driven.color.get_luminance()
	_set_hour(23)
	await process_frame
	_check(snow._driven.color.get_luminance() < bright, "la nuit, les flocons sont moins vifs")
	_set_hour(12)
	_test_wildlife(v)
	v.free()


func _test_wildlife(v: Node3D) -> void:
	var db: GDScript = load("res://data/wildlife_db.gd")
	for place in [&"monts", &"grotte_glace", &"sanctuaire_givre"]:
		_check(db.PLACES.has(place), "WildlifeDB.PLACES : %s" % place)
	var flakes: Dictionary = db.effects_of(&"monts").filter(func(e: Dictionary) -> bool: return e["id"] == &"flocons")[0]
	_check(flakes.get("snowfall", true) == false, "Monts : leurs flocons s'effacent quand il neige (pas de doublon)")
	var beast: Dictionary = db.kinds_of(&"monts").filter(func(e: Dictionary) -> bool: return e["id"] == &"mammifere")[0]
	var day: int = db.DAY
	_check(db.is_out(beast, day, 0.0), "la faune « neige » sort sous la neige (la neige ne compte pas comme pluie)")
	_check(not db.is_out(beast, day, 1.0), "…et s'abrite du blizzard")
	var shelter: float = maxf(maxf(v._rain_amount, v._sand_amount), v._snow.blizzard)
	_check(shelter > 0.9, "la vue passe le blizzard à la faune comme la pluie (%.2f)" % shelter)


func _test_battle_and_clock() -> void:
	game.set_climate(MONTS)
	_set_hour(12)
	var bw: GDScript = load("res://battle/battle_weather.gd")
	var clear: Color = bw.tint(12.0, &"clear")
	_check(bw.tint(12.0, &"snow") != clear and bw.tint(12.0, &"blizzard") != clear, "combat : lumière froide sous la neige, le blizzard")
	for weather in [&"snow", &"blizzard"]:
		game.set_weather(weather)
		var parent := Control.new()
		var backdrop := Control.new()
		var fighters := Control.new()
		parent.add_child(backdrop)
		parent.add_child(fighters)
		root.add_child(parent)
		var layer: Control = bw.apply(parent, backdrop, fighters)
		await process_frame
		var veil := false
		var flakes := 0
		for c in layer.get_children():
			veil = veil or c is TextureRect
			if c is CPUParticles2D:
				flakes += 1
		if weather == &"snow":
			_check(flakes == 1 and not veil, "combat, neige : des flocons, pas de voile")
		else:
			_check(flakes == 1 and veil and layer._driven != null, "combat, blizzard : voile blanc et flocons chassés en rafales")
		parent.free()
		var badge: Control = load("res://ui/clock_badge.gd").new()
		root.add_child(badge)
		await process_frame
		var entry: Array = badge.LOCAL_ICONS[weather]
		var own: bool = ResourceLoader.exists(entry[0])
		_check(badge._icon.texture != null and badge._icon.modulate.is_equal_approx(Color.WHITE if own else entry[1]),
			"horloge : icône %s (%s, %s)" % [weather, "la sienne" if own else "repli : brume teintée", badge._icon.modulate])
		badge.free()
	var menu: GDScript = load("res://ui/debug_menu.gd")
	_check(game.WEATHERS.all(func(w: StringName) -> bool: return menu.WEATHER_NAMES.has(w)), "débogage : un bouton par météo (Neige, Blizzard)")
	game.set_weather(&"clear")


func _test_sounds() -> void:
	var amb: GDScript = load("res://data/ambience_db.gd")
	for place in [&"monts", &"grotte_glace", &"sanctuaire_givre"]:
		var def: Dictionary = amb.get_ambience(place)
		var ok: bool = amb.has(place)
		for bed: Array in def["beds"]:
			ok = ok and ResourceLoader.exists(amb.PATH % bed[0])
		for call: Dictionary in def["calls"]:
			for id: String in call["ids"]:
				ok = ok and ResourceLoader.exists(amb.PATH % id)
		_check(ok, "ambiance %s : ses sons existent" % place)
	var world: GDScript = load("res://world/world.gd")
	_check(world.BLIZZARD_SOUND != null, "le blizzard a son hurlement (blizzard.ogg)")


func _test_species() -> void:
	var db: GDScript = load("res://data/species_db.gd")
	var size: GDScript = load("res://actors/dino_size.gd")
	var abilities: GDScript = load("res://data/abilities.gd")
	var dino_s: GDScript = load("res://game/dino.gd")
	for id: StringName in SPECIES:
		if not db.PATHS.has(id):
			print("  …     %s : en attente de sa planche" % id)
			continue
		var want: Array = SPECIES[id]
		var sp = db.get_species(id)
		_check(sp != null and sp.sheet != null and sp.face_back_sheet != null and sp.family == want[0],
			"%s : fiche, planches, famille %s" % [id, want[0]])
		var h: float = size.height_m(sp, sp.world_scale)
		var range_m: Vector2 = want[2]
		_check(h >= range_m.x and h <= range_m.y, "%s : %.2f m de haut adulte (attendu %.1f-%.1f)" % [id, h, range_m.x, range_m.y])
		var d = dino_s.create(id, 36)
		_check(d.moves.size() > 0, "%s : des attaques (%s)" % [id, ", ".join(d.moves)])
		if want[1] != &"":
			_check(abilities.has(d, want[1]), "%s : capacité %s" % [id, want[1]])
	_check(ResourceLoader.exists("res://assets/art/dinos/nanuqsaurus_corrompu.png"), "Aconit : planche du Nanuqsaurus corrompu")


func _test_steps() -> void:
	var player_s: GDScript = load("res://actors/player.gd")
	var r = load("res://world/region.gd").new()
	_check(r.cold == false, "Region.cold : faux par défaut")
	r.free()
	var kinds := {}
	for surface in [&"grass", &"tall_grass", &"path", &"forest", &"sand", &"rock", &"mud"]:
		kinds[surface] = [player_s.step_kind(surface, false), player_s.step_kind(surface, true, true), player_s.step_kind(surface, false, true)]
	_check(kinds[&"grass"] == [&"grass", &"snow", &"grass"] and kinds[&"path"] == [&"path", &"snow", &"path"]
		and kinds[&"tall_grass"][1] == &"snow" and kinds[&"rock"][1] == &"snow",
		"sous la neige : herbe, chemin, herbes hautes, roche = pas dans la neige ; sans neige, comme avant")
	_check(kinds[&"sand"] == [&"grass", &"ice", &"ice"], "région froide : « sable » = glace, neige ou pas ; ailleurs le sable reste doux")
	var ok: bool = player_s.SNOW_STEPS.size() == 6 and player_s.ICE_CRACKS.size() == 3
	for s in player_s.SNOW_STEPS + player_s.ICE_CRACKS:
		ok = ok and s != null and s.get_length() > 0.2 and s.get_length() < 0.7
	_check(ok, "6 pas dans la neige, 3 craquements de glace (0,4-0,5 s chacun)")
	_check(player_s.STEP_DB[&"snow"] < player_s.STEP_DB[&"grass"] and player_s.STEP_DB[&"crack"] < player_s.STEP_DB[&"ice"],
		"niveaux : neige %d dB, glace %d dB, craquement %d dB (herbe %d, chemin %d)" % [player_s.STEP_DB[&"snow"],
		player_s.STEP_DB[&"ice"], player_s.STEP_DB[&"crack"], player_s.STEP_DB[&"grass"], player_s.STEP_DB[&"path"]])


func _test_coat() -> void:
	var outfits: GDScript = load("res://actors/outfits.gd")
	var player = load("res://actors/player.tscn").instantiate()
	game.new_game()
	var coat: bool = outfits.drawn(outfits.COAT_SHEET)
	var coat_saddle: bool = outfits.drawn(outfits.SADDLE_SHEETS[outfits.COAT])
	player.cold = true
	_check(not outfits.wears_coat(player) and outfits.walk_look(player) == "", "région froide sans manteau : comme d'habitude")
	game.give_item(outfits.COAT_ITEM)
	_check(outfits.wears_coat(player), "région froide + manteau_duvet : elle le porte")
	_check(outfits.walk_look(player) == (outfits.COAT if coat else ""),
		"à pied : %s" % ("manteau:" if coat else "repli (chloe_manteau.png pas encore là)"))
	game.give_item(outfits.BOOTS_ITEM)
	_check(outfits.walk_look(player) == (outfits.COAT if coat else outfits.BOOTS), "le manteau passe avant les bottes (repli : les bottes)")
	_check(outfits.saddle_look(player) == (outfits.COAT if coat_saddle else ""),
		"en selle : %s" % ("manteau:" if coat_saddle else "repli (chloe_selle_manteau.png pas encore là)"))
	player.diving = true
	_check(outfits.saddle_look(player) == outfits.MASK, "sous l'eau : le masque reste prioritaire")
	player.diving = false
	player.cold = false
	_check(outfits.walk_look(player) == outfits.BOOTS and outfits.saddle_look(player) == "", "hors région froide : les bottes, pas de manteau")
	player.free()


## Walks Chloé right on a strip of snow or of ice, lets go, and measures how far she goes on (m).
func _slide(slippery: bool, ground: String) -> float:
	var builder: GDScript = load("res://tools/zone_builder.gd")
	var row := ground.repeat(30)
	var region = builder.region(&"test_glace", "Essai", "Lac", Vector2i(33, 35), [row, row, row, row, row])
	region.slippery = slippery
	region.cold = true
	root.add_child(region)
	var player = load("res://actors/player.tscn").instantiate()
	region.entities.add_child(player)
	player.surface_at = region.surface_at
	player.slippery = slippery
	player.cold = true
	player.teleport(Vector2(3.5, 2.5) * 48.0)
	Input.action_press(&"move_right")
	for i in int(1.2 * Engine.physics_ticks_per_second):
		await physics_frame
	Input.action_release(&"move_right")
	var from: float = player.global_position.x
	for i in int(1.0 * Engine.physics_ticks_per_second):
		await physics_frame
	var slid: float = (player.global_position.x - from) / 48.0
	region.queue_free()
	await process_frame
	return slid


func _test_ice() -> void:
	game.new_game()
	var r = load("res://world/region.gd").new()
	_check(r.slippery == false, "Region.slippery : faux par défaut")
	r.free()
	var on_ice: float = await _slide(true, "s")
	var on_snow: float = await _slide(true, ".")
	var plain_ice: float = await _slide(false, "s")
	_check(on_ice > 0.5 and on_ice < 1.4, "glace glissante : elle glisse encore %.2f m en lâchant" % on_ice)
	_check(on_snow < 0.3 and plain_ice < 0.3, "dans la neige, ou sur une glace non glissante : elle s'arrête (%.2f m, %.2f m)" % [on_snow, plain_ice])


## The cover layer (Region.cover_data): read between the tiles, the steps follow it.
func _test_cover() -> void:
	var builder: GDScript = load("res://tools/zone_builder.gd")
	var region = builder.region(&"test_couche", "Essai", "Jointure", Vector2i(33, 35), ["....", "....", "...."])
	var data := Image.create(4, 3, false, Image.FORMAT_L8)
	for y in 3:
		for x in 4:
			data.set_pixel(x, y, Color(x / 3.0, x / 3.0, x / 3.0))
	root.add_child(region)
	_check(is_equal_approx(region.cover_at(Vector2(100, 100)), -1.0), "sans couche : cover_at = -1")
	region.cover_data = data
	region.cover_tex = load("res://assets/art/ground/herbe.png")
	var a: float = region.cover_at(Vector2(0.5, 1.5) * 48.0)
	var b: float = region.cover_at(Vector2(2.0, 1.5) * 48.0)
	var c: float = region.cover_at(Vector2(3.5, 1.5) * 48.0)
	_check(a < 0.05 and absf(b - 0.5) < 0.05 and c > 0.95, "cover_at : 0 à l'ouest, 0,5 au milieu (entre deux cases), 1 à l'est (%.2f, %.2f, %.2f)" % [a, b, c])
	var player = load("res://actors/player.tscn").instantiate()
	region.entities.add_child(player)
	player.snow_at = region.snow_at
	player.cold = true
	player.global_position = Vector2(0.5, 1.5) * 48.0
	var west: bool = player._on_snow()
	player.global_position = Vector2(3.5, 1.5) * 48.0
	_check(not west and player._on_snow(), "les pas suivent la couche : pas de neige à l'ouest, neige à l'est")
	var v: Node3D = load("res://world/view3d/world_view.gd").new()
	root.add_child(v)
	region.cover_tex = load("res://assets/art/ground/neige.png") if ResourceLoader.exists("res://assets/art/ground/neige.png") else load("res://assets/art/ground/herbe.png")
	v.show_zone(region, player)
	_check(v._ground_mat.get_shader_parameter("cover_count") == 1 and v._ground_mat.get_shader_parameter("cover_mask") != null,
		"vue 3D : la couche est passée au sol")
	var layers: Dictionary = v.map_layers()
	_check(layers.get("cover_count") == 1 and layers.get("icy") == false, "carte : la neige de la couche")
	# A second layer (sand, not snow), rising the other way.
	var sand := Image.create(4, 3, false, Image.FORMAT_L8)
	for y in 3:
		for x in 4:
			sand.set_pixel(x, y, Color(1.0 - x / 3.0, 0, 0))
	region.cover_layers.assign([{"tex": load("res://assets/art/ground/sable.png"), "data": sand}])
	_check(region.covers().size() == 2 and region.covers()[0].get("snow") == true and not region.covers()[1].get("snow", false),
		"couches : la neige d'abord, puis le sable (Region.covers)")
	_check(region.snow_at(Vector2(0.5, 1.5) * 48.0) < 0.05, "les pas « neige » ne suivent que la couche de neige")
	v.show_zone(region, player)
	var mask: Texture2D = v._ground_mat.get_shader_parameter("cover_mask")
	var packed := mask.get_image()
	_check(v._ground_mat.get_shader_parameter("cover_count") == 2 and packed.get_pixel(0, 1).g > 0.95 and packed.get_pixel(3, 1).r > 0.95,
		"vue 3D : 2 couches, leurs doses rangées dans R et G d'une seule texture")
	_check((v.map_layers().get("cover_colours") as PackedVector3Array).size() == 3, "carte : une couleur par couche")
	region.cover_layers.clear()
	v.free()
	data.save_png("user://test_couche.png")
	builder.cover(region, "user://test_couche.png", "user://test_couche.res", region.cover_tex)
	_check(region.cover_data != null and region.cover_data.get_format() == Image.FORMAT_L8 and region.cover_data.get_width() == 4
		and absf(region.cover_at(Vector2(3.5, 1.5) * 48.0) - 1.0) < 0.02, "ZoneBuilder.cover : la couche lue d'une image grise, sauvée à part")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_couche.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_couche.res"))
	region.free()
