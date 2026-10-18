extends SceneTree
## La lave du chapitre 8 (mécanique B, actors/lava.gd) dans une petite zone d'essai : une coulée en
## rectangles (méta « lave_cases »), une autre dessinée en image (méta « lave »), une coulée qui ne se
## retire qu'à son drapeau (« lave_retrait »). (a) les règles : le Cuir de feu (Pierre et Feu adultes, pas
## le Vent, pas un jeune), qui pourrait (« mets-le en tête », « trop jeune », personne) ; (b) à pied avec
## Vif : Chloé s'arrête au bord, `lave_bloquee` dit pourquoi, une fois ; (c) un Saichania en tête : elle
## monte sur son dos sur la coulée (son dino la porte), `lave_franchie` une fois (drapeau), elle redescend
## sur la roche ; la coulée dessinée en image se franchit aussi ; (d) la lave qui se retire : un mur pour
## tous jusqu'au drapeau, puis le passage ; (e) la chaleur légère : la jauge monte à pied près de la lave,
## pas sur le dos du Saichania ; pleine, « Trop chaud ! » et Chloé recule d'elle-même, sans PV perdus ;
## (f) les dinos sauvages heurtent la lave (masque).
##   godot --path Godot --script res://tools/test_lave_volcan.gd --resolution 1600x900 -- out=<dossier> [titre=…]
## (Script compilé avant les autoloads : tout est chargé par son chemin, sans type.)

const CAPTION := "Lave (ch. 8) : bloquée à pied, franchie sur le dos d'un dino de pierre/feu en tête, chaleur légère sans dégâts, coulée qui se retire"
const TILE := 48.0
## Une bande de roche ; la lave est posée par les métas (MÉCANIQUES ↔ CARTE : contrat_lave.md).
const PLAN := [
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
]
const FLOW_A := Rect2i(8, 0, 4, 8)     # « lave_cases »
const FLOW_B_X := Vector2i(15, 16)     # « lave » (image), colonnes
const RETREAT := Rect2i(20, 0, 2, 8)   # « lave_retrait »
const RETREAT_FLAG := &"test_lave_retiree"
const ROW := 3.5

var _out := "user://test_lave_volcan"
var _caption := CAPTION
var _failed := 0
var _checks := 0
var game: Node
var lava
var DinoS
var region: Node2D
var player: CharacterBody2D
var companion: Node2D
var view: Node3D


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("titre="):
			_caption = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	var banner := ShotCaption.show_on(self, _caption)
	root.get_node("Save").set("path", "user://test_lave_volcan_save.json")
	game = root.get_node("Game")
	lava = load("res://actors/lava.gd")
	DinoS = load("res://game/dino.gd")
	for path in ["res://actors/lava.gd", "res://actors/lava_field.gd", "res://actors/heat.gd", "res://actors/player.gd",
			"res://actors/companion.gd", "res://data/abilities.gd"]:
		var s: GDScript = load(path)
		_check("compile %s" % path, s != null and s.can_instantiate())
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	game.call("set_flag", &"prologue_done")
	game.call("set_flag", &"tuto_commandes")
	_rules()
	await _make_zone()
	await _blocked()
	await _crossing()
	await _retreat()
	await _heat()
	_wild_mask()
	_built_zones()
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	banner.queue_free()
	print("TEST lave du volcan : %s (%d vérifications, %d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _checks, _failed])
	quit(1 if _failed else 0)


# ------------------------------------------------------------------ (a) les règles

func _rules() -> void:
	print("— (a) le Cuir de feu, qui pourrait")
	var abilities = load("res://data/abilities.gd")
	var cases := [[&"saichania", 44, true], [&"ankylosaurus", 20, true], [&"stygimoloch", 30, true], [&"daspletosaurus", 46, true],
		[&"trex_magma", 48, true], [&"allosaurus", 20, true], [&"velociraptor", 40, false], [&"styracosaurus", 44, false],
		[&"plesiosaurus", 40, false], [&"pteranodon", 40, false]]
	for c: Array in cases:
		var d = DinoS.create(c[0], c[1])
		_check("%s niv. %d (%s) : Cuir de feu %s" % [c[0], c[1], d.type(), "oui" if c[2] else "non"], abilities.usable(d, &"cuir_de_feu") == c[2])
	var young = DinoS.create(&"saichania", 8)
	_check("un jeune Saichania (niv. 8) l'a, mais ne porte pas encore", abilities.has(young, &"cuir_de_feu") and not abilities.usable(young, &"cuir_de_feu"))
	_check("Vif en tête : personne ne passe (« Les Saichania des coulées refroidies… »)", not lava.can_cross() and lava.who_could() == lava.NOBODY)
	var party: Array = game.get("party")
	party.append(DinoS.create(&"saichania", 44, "Caillasse"))
	_check("un Saichania dans l'équipe : « mets-le en tête »", lava.who_could().begins_with("Caillasse (Pierre) a le cuir pour : mets-le en tête"),
		lava.who_could())
	party.pop_back()
	var box: Array = game.get("box")
	box.append(DinoS.create(&"allosaurus", 30, "Mastoc"))
	_check("au Cabinet : « va le chercher »", lava.who_could().contains("Mastoc (Feu)") and lava.who_could().contains("Cabinet"), lava.who_could())
	box.clear()
	party.insert(0, young)
	_check("un jeune en tête : « trop jeune »", lava.who_could().contains("trop jeune"), lava.who_could())
	party.pop_front()
	var lines: Array = lava.crossed_lines(DinoS.create(&"saichania", 44, "Caillasse"))
	_check("lave_franchie : 4 lignes, avec son nom", lines.size() == 4 and String(lines[0]["text"]).contains("Caillasse"))


# ------------------------------------------------------------------ la zone d'essai

func _make_zone() -> void:
	var builder = load("res://tools/zone_builder.gd")
	region = builder.region(&"test_lave", "Essai", "Coulées", Vector2i(42, 44), PLAN)
	region.set_meta(&"lave_cases", [FLOW_A])
	var img := Image.create_empty(PLAN[0].length(), PLAN.size(), false, Image.FORMAT_L8)
	for y in PLAN.size():
		for x in range(FLOW_B_X.x, FLOW_B_X.y + 1):
			img.set_pixel(x, y, Color.WHITE)
	region.set_meta(&"lave", img)
	region.set_meta(&"lave_retrait", [RETREAT])
	region.set_meta(&"lave_retrait_drapeau", RETREAT_FLAG)
	root.add_child(region)
	player = load("res://actors/player.tscn").instantiate()
	companion = load("res://actors/companion.tscn").instantiate()
	companion.player = player
	region.entities.add_child(player)
	region.entities.add_child(companion)
	player.surface_at = region.surface_at
	player.teleport(Vector2(3.5, ROW) * TILE)
	companion.stand_beside(player.global_position)
	if DisplayServer.get_name() != "headless":
		view = load("res://world/view3d/world_view.gd").new()
		root.add_child(view)
		view.show_zone(region, player)
	for i in 4:
		await physics_frame
	var f = lava.field(region)
	_check("la zone a sa lave (%d cases franchissables)" % (f.cell_count() if f else 0), f != null and f.cell_count() == FLOW_A.get_area() + 2 * PLAN.size())


func _x() -> float:
	return player.global_position.x / TILE


# ------------------------------------------------------------------ (b) à pied, bloquée

func _blocked() -> void:
	print("— (b) à pied avec Vif")
	var hp_before := _party_hp()
	await _walk(&"move_right", func() -> bool: return game.get_node("/root/Dialogue").get("active"), 2.0)
	var dialogue: Node = root.get_node("Dialogue")
	_check("Chloé s'arrête au bord de la coulée (x = %.2f)" % _x(), _x() < FLOW_A.position.x and _x() > FLOW_A.position.x - 1.0)
	_check("…et `lave_bloquee` lui dit pourquoi", dialogue.get("active") and player.get("_lava_told"))
	await _shot("lave_bloquee")
	await _close_dialogue()
	await _walk(&"move_right", func() -> bool: return false, 1.2)
	_check("une seule fois dans la zone", not dialogue.get("active") and _x() < FLOW_A.position.x)
	_check("aucun PV perdu", _party_hp() == hp_before)


# ------------------------------------------------------------------ (c) sur le dos d'un Saichania

func _crossing() -> void:
	print("— (c) un Saichania en tête")
	var saichania = DinoS.create(&"saichania", 44, "Caillasse")
	game.call("add_caught", saichania)
	var party: Array = game.get("party")
	game.call("set_lead", party.find(saichania))
	_check("le Saichania est en tête et peut passer", game.call("lead_dino") == saichania and lava.can_cross())
	var on := await _walk(&"move_right", func() -> bool: return player.get("lava_walker") != null, 2.5)
	_check("sur la coulée, Chloé monte sur son dos (x = %.2f)" % _x(), on and player.get("lava_walker") == saichania)
	_check("son dino la porte (le compagnon devient le Saichania)", companion.call("carrying") and companion.get("dino") == saichania)
	_check("`lave_franchie` la première fois (drapeau)", game.call("flag", &"lave_franchie") and root.get_node("Dialogue").get("active"))
	await _shot("lave_franchie")
	await _close_dialogue()
	var out := await _walk(&"move_right", func() -> bool: return _x() > FLOW_A.end.x + 0.8, 3.0)
	_check("de l'autre côté, elle redescend sur la roche (x = %.2f)" % _x(), out and player.get("lava_walker") == null and not companion.call("carrying"))
	var mid := await _walk(&"move_right", func() -> bool: return player.get("lava_walker") != null, 2.0)
	_check("la coulée dessinée en image (méta « lave ») se franchit aussi", mid)
	_check("…sans redire `lave_franchie`", not root.get_node("Dialogue").get("active"))
	await _shot("lave_sur_le_dos")
	await _walk(&"move_right", func() -> bool: return _x() > FLOW_B_X.y + 1.8, 3.0)
	_check("de nouveau à pied", player.get("lava_walker") == null)


# ------------------------------------------------------------------ (d) la lave qui se retire

func _retreat() -> void:
	print("— (d) la coulée qui se retire")
	await _walk(&"move_right", func() -> bool: return false, 1.5)
	_check("même sur le dos d'un dino de pierre, la lave profonde arrête Chloé (x = %.2f)" % _x(), _x() < RETREAT.position.x)
	var f = lava.field(region)
	_check("elle tient tant que le drapeau n'est pas posé", f.retreat_holds())
	game.call("set_flag", RETREAT_FLAG)
	await physics_frame
	await physics_frame
	_check("le drapeau posé : elle se retire", not f.retreat_holds())
	var passed := await _walk(&"move_right", func() -> bool: return _x() > RETREAT.end.x + 0.5, 2.5)
	_check("…et Chloé passe à pied (x = %.2f)" % _x(), passed and player.get("lava_walker") == null)


# ------------------------------------------------------------------ (e) la chaleur

func _heat() -> void:
	print("— (e) la chaleur légère")
	var heat = player.get("heat")
	var party: Array = game.get("party")
	game.call("set_lead", party.find(party.filter(func(x) -> bool: return x.nickname == "Vif")[0]))
	player.call("teleport", Vector2(FLOW_A.position.x - 0.7, ROW) * TILE)
	companion.call("stand_beside", player.global_position)
	heat.level = 0.0
	await create_timer(1.0).timeout
	_check("à pied près de la lave, la jauge monte (%.2f)" % heat.level, heat.level > 0.03 and heat.warmth() > 0.0)
	_check("…elle se voit (jauge et bords de l'écran)", heat.get("_gauge").visible and heat.get("_vignette").modulate.a >= 0.0)
	var hp_before := _party_hp()
	heat.level = 0.999
	var cool: Vector2 = heat.call("cool_spot")
	_check("une case fraîche où reculer existe", cool != Vector2.INF)
	await create_timer(2.5).timeout
	var d: float = lava.field(region).distance_tiles(player.global_position)
	_check("pleine : « Trop chaud ! », Chloé recule d'elle-même (à %.1f cases de la lave)" % d, d >= 3.0 and root.get_node_or_null("Toast") != null)
	_check("…sans perdre un PV", _party_hp() == hp_before)
	await _shot("chaleur_recule")
	var saichania = party.filter(func(x) -> bool: return x.nickname == "Caillasse")[0]
	game.call("set_lead", party.find(saichania))
	player.call("teleport", Vector2(FLOW_A.position.x + 1.5, ROW) * TILE)
	for i in 4:
		await physics_frame
	_check("sur le dos du Saichania, sur la lave même : pas de chaleur", player.get("lava_walker") != null and heat.warmth() == 0.0)


# ------------------------------------------------------------------ (f) les sauvages

func _wild_mask() -> void:
	var wild: Node = load("res://actors/wild_dino.tscn").instantiate()
	_check("les dinos sauvages heurtent la lave (couche %d dans leur masque)" % lava.LAYER, wild.collision_mask & lava.LAYER != 0)
	wild.free()


# ------------------------------------------------------------------ (g) les zones de l'agent carte

## Les zones du Volcan déjà construites : leur lave se lit (le contrat), jamais sur l'eau ni les bois.
func _built_zones() -> void:
	print("— (g) les zones construites (contrat de la lave)")
	for zone in ["champs_cendres", "forges_ombre", "coulees_lave", "sanctuaire_magma", "porte_cratere"]:
		var path := "res://regions/volcan/%s.tscn" % zone
		if not ResourceLoader.exists(path):
			print("   %s : pas encore construite" % zone)
			continue
		var r = load("res://world/region.gd").open_for_preview(path)
		var f = lava.field(r)
		if f == null or f.cell_count() == 0:
			print("   %s : pas de lave dans cette zone (%s)" % [zone, "pas de méta" if f == null else "masque vide"])
			r.free()
			continue
		var bad := 0
		for c: Vector2i in f.get("_cells"):
			var kind: StringName = r.surface_at((Vector2(c) + Vector2(0.5, 0.5)) * TILE)
			if kind == &"water" or kind == &"forest":
				bad += 1
		_check("%s : %d cases de lave lues, aucune sur l'eau ni les bois" % [zone, f.cell_count()], f.cell_count() > 0 and bad == 0,
			"%d sur l'eau ou les bois" % bad)
		r.free()


# ------------------------------------------------------------------ outils

func _party_hp() -> int:
	var total := 0
	for d in game.get("party"):
		total += d.hp
	return total


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


func _close_dialogue() -> void:
	var dialogue: Node = root.get_node("Dialogue")
	for i in 40:
		if not dialogue.get("active"):
			break
		_press(&"interact")
		await create_timer(0.25).timeout
	for i in 3:
		await physics_frame


func _press(action: StringName) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _check(what: String, ok: bool, detail := "") -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
