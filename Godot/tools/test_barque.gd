extends SceneTree
## La barque de Maïa (11/10), 2e voyage rapide : (a) pas d'embarcadère utilisable avant que Maïa
## soit alliée ; (b) avec le drapeau, la barque attend à l'embarcadère, un clic sur elle y mène
## Chloé et l'utilise, le mot de Maïa la 1re fois, l'embarcadère est noté (quai_<zone>) ; (c) l'écran
## ne propose que les embarcadères connus, celui où l'on est grisé « Tu es ici » ; (e) « Rester ici »
## (B de la manette, puis clic) ne change rien ; (f) une destination a le focus d'emblée et A valide ;
## (d) la traversée : bonne zone, l'horloge avance, Chloé sur le quai, et la scène d'arrivée de la zone
## (le chant de la Voix au Marais) se joue avant que la barque accoste. Puis une capture de
## l'embarcadère de chacune des 4 zones.
##   godot --path Godot --script res://tools/test_barque.gd --resolution 1600x900 -- out=<dossier>
## Écrit PASS / FAIL, enregistre les captures, sort en 1 au moindre échec. Il faut une fenêtre.
## (Script compilé avant les autoloads : la barque et l'écran sont appelés par leur chemin.)

const WORLD := "res://world/world.tscn"
const BARQUE := "res://story/barque.gd"
const CAPTION := "Barque de Maïa : rien avant l'alliance ; embarcadère noté ; liste des connus (« tu es ici » grisé) ; Rester ici ; manette (focus, A) ; traversée (zone, horloge, arrivée) ; les 4 embarcadères"
const BUTTON_A := 0
const BUTTON_B := 1
const DPAD_UP := 11
const DPAD_DOWN := 12
const SPAWN := &"Embarcadere"
const BOAT := "BarqueMaia"
const CROSSING_MINUTES := 60.0
## L'histoire jusqu'à la fin du chapitre 6, sans l'alliance (les scènes d'arrivée déjà vues).
const LATE := ["prologue_done", "prologue_arrived", "tuto_commandes", "sceau_plaines", "maia_defi_1", "roc_parti_vu",
	"found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue",
	"camp_arrive", "brac_battu", "sceau_foret", "raptor_porte_vu", "masque_vu", "maia_defi_2", "marais_arrivee",
	"joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue",
	"spinosaure_battu", "sceau_marais", "coeur_1", "voix_coeur_chant", "roc_marais_vu", "maia_defi_3",
	"desert_arrivee", "sanctuaire_entre", "coeur_2", "maia_defi_4", "cote_annonce", "cote_ouverte", "cote_arrivee",
	"pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "barque_nuit_vue", "grottes_arrivee", "cache_vue",
	"barque_isaure_vue", "recif_arrivee", "sceau_cote", "coeur_3", "moustique_vu", "maia_guet_vue", "maia_enfuie",
	"monts_ouverts", "monts_arrivee", "forges_vues", "sceau_monts", "coeur_4", "maia_monts_vue", "maia_defi_5"]
## Une ligne de dialogue qui contient ce texte → la capture à faire pendant qu'elle est affichée.
const CROSSING_SHOTS := {"saute dans la barque": "barque_05_embarque", "glisse": "barque_06_au_large",
	"accoste": "barque_07_accoste", "et l'amarre": "barque_08_a_terre"}
## L'ordre des 4 embarcadères (captures barque_2<n>_<zone>).
const ZONES := [&"port_ambre", &"havre_dore", &"cote", &"marais"]
## Des bouts de répliques dont on retient le passage (_play_lines).
const WATCHED := ["Elle est à toi", "Moustique a mangé", "chante"]

var _out := "user://test_barque"
var _failed := 0
var _game: Node
var _barque   # (story/barque.gd, appelé dynamiquement)


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_barque.json")
	_game = root.get_node("Game")
	_game.call("new_game")
	_game.call("give_starter", &"velociraptor")
	for f: String in LATE:
		_game.call("set_flag", StringName(f))
	_game.set("region_id", &"port_ambre")
	_game.set("arrival", SPAWN)
	_game.set("clock", 11.0 * 60.0)
	_game.set("time_scale", 0.0)   # (l'horloge ne bouge que par la traversée : on la mesure exactement)
	_barque = load(BARQUE)
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	while current_scene == null or current_scene.get("region") == null:   # (le monde se charge)
		await process_frame
	await _wait(1.5)
	await _before_alliance()
	await _first_use()
	await _list_and_stay()
	await _crossing_with_pad()
	await _crossing_with_arrival_scene()
	_weather_lines()
	await _four_landings()
	banner.queue_free()
	print("TEST barque : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


# ------------------------------------------------------------------ (a) avant l'alliance

func _before_alliance() -> void:
	print("— (a) sans maia_alliee")
	_check("la zone est Port-Ambre", _zone() == &"port_ambre", str(_zone()))
	_check("sans maia_alliee, pas de barque à l'embarcadère", _boat() == null)
	_check("Chloé arrive au point « Embarcadere »", _player().global_position.distance_to(_spawn()) < 4.0)
	await _shot("barque_00_avant_alliance")
	_barque.use(null)
	await _wait(0.8)
	_check("sans maia_alliee, utiliser la barque ne fait rien",
		_screen() == null and not _dialogue_active() and not _game.call("flag", &"quai_port_ambre") and not _player().get("busy"))


# ------------------------------------------------------------------ (b) la 1re fois

func _first_use() -> void:
	print("— (b) la 1re fois, au clic")
	_game.call("set_flag", &"maia_alliee")
	await _goto(&"port_ambre")
	var boat := _boat()
	_check("avec maia_alliee, la barque est amarrée à l'embarcadère", boat != null and boat.is_in_group(&"interactable"))
	if boat == null:
		return
	_check("depuis le quai, la touche d'interaction vise la barque", _player().call("nearest_interactable") == boat,
		str(_player().call("nearest_interactable")))
	await _shot("barque_01_port_ambre")
	# un clic sur la barque depuis plus haut sur le ponton : Chloé y va, puis l'utilise
	_player().call("teleport", _spawn() + Vector2(-30.0, -150.0))
	current_scene.get("companion").call("stand_beside", _player().global_position)
	await _wait(2.0)
	var clicks := _clicks()
	var at: Vector2 = clicks.call("screen_point", boat) if clicks else Vector2.INF
	_check("la barque se dessine à l'écran", at != Vector2.INF, str(at))
	_click(at)
	var used := false
	for i in 40:
		await _wait(0.2)
		if _dialogue_active():
			used = true
			break
	_check("un clic sur la barque : Chloé y va et l'utilise", used)
	_check("elle l'utilise depuis le ponton (pas dans l'eau)",
		current_scene.get("region").call("surface_at", _player().global_position) != &"water")
	await _wait(1.0)
	await _shot("barque_02_clic")
	var seen := await _play_lines({"Elle est à toi": "barque_03_le_mot"}, func() -> bool: return _scene_done())
	_check("le mot de Maïa s'est affiché (la 1re fois)", seen.has("Elle est à toi") and seen.has("Moustique a mangé"))
	_check("drapeau barque_maia_prete", _game.call("flag", &"barque_maia_prete"))
	_check("l'embarcadère de Port-Ambre est noté (quai_port_ambre)", _game.call("flag", &"quai_port_ambre"))
	_check("un seul embarcadère connu : pas d'écran de choix", not seen.has("écran"))
	_check("après : Chloé est libre", not _player().get("busy") and not _dialogue_active())


# ------------------------------------------------------------------ (c) la liste, (e) rester ici

func _list_and_stay() -> void:
	print("— (c) la liste, (e) rester ici")
	_game.call("set_flag", &"quai_havre_dore")
	_game.call("set_flag", &"quai_cote")
	_player().call("teleport", _spawn())
	await _wait(0.6)
	var clock: float = _game.get("clock")
	var screen := await _open_screen()
	_check("l'écran de choix s'ouvre", screen != null)
	if screen == null:
		return
	var rows := _rows(screen)
	print("   écran : ", rows)
	_check("titre de la barque", _labels(screen).has("Où met-on le cap ?"))
	_check("seulement les embarcadères connus (pas le Marais)", rows.size() == 4 and _row_names(rows) == ["Port-Ambre", "Havre-Doré", "Côte Préhistorique", "Rester ici"],
		str(_row_names(rows)))
	_check("Port-Ambre grisé « Tu es ici. »", rows[0]["disabled"] and rows[0]["under"] == "Tu es ici.")
	var focus := root.gui_get_focus_owner()
	_check("(f) une destination a le focus d'emblée (Havre-Doré)", focus is Button and _name_of(focus) == "Havre-Doré", str(focus))
	await _shot("barque_04_ecran")
	_tap(BUTTON_B)
	await _wait(0.6)
	_check("(e) B : l'écran se ferme", _screen() == null)
	await _play_lines({}, func() -> bool: return _scene_done())
	# la souris : « Rester ici »
	screen = await _open_screen()
	var stay := _button(screen, "Rester ici")
	_check("le bouton « Rester ici » est là", stay != null)
	if stay:
		await _mouse_click(stay.get_global_rect().get_center())
	await _wait(0.6)
	_check("(e) clic sur « Rester ici » : l'écran se ferme", _screen() == null)
	await _play_lines({}, func() -> bool: return _scene_done())
	_check("(e) rester : même zone, même heure, Chloé libre", _zone() == &"port_ambre" and is_equal_approx(_game.get("clock"), clock)
		and not _player().get("busy"), "zone %s, %.1f → %.1f min" % [_zone(), clock, _game.get("clock")])


# ------------------------------------------------------------------ (f) manette, (d) la traversée

func _crossing_with_pad() -> void:
	print("— (f) à la manette, (d) Port-Ambre → Havre-Doré")
	var clock: float = _game.get("clock")
	var screen := await _open_screen()
	if screen == null:
		_check("l'écran s'ouvre", false)
		return
	_tap(DPAD_DOWN)
	await _wait(0.3)
	_check("(f) la croix descend sur Côte Préhistorique", _name_of(root.gui_get_focus_owner()) == "Côte Préhistorique")
	_tap(DPAD_UP)
	await _wait(0.3)
	_tap(BUTTON_A)
	await _wait(0.4)
	_check("(f) A valide : l'écran se ferme", _screen() == null)
	await _play_lines(CROSSING_SHOTS, func() -> bool: return _zone() == &"havre_dore" and _scene_done())
	_check_arrival(&"havre_dore", clock)


## Havre-Doré → Marais, choisi à la souris ; au Marais, le chant de la Voix (scène d'arrivée de la
## zone, story/marais.gd) se joue d'abord, puis Chloé amarre la barque.
func _crossing_with_arrival_scene() -> void:
	print("— (d) Havre-Doré → Marais, avec la scène d'arrivée du Marais")
	_game.call("set_flag", &"quai_marais")
	_game.call("set_flag", &"voix_coeur_chant", false)
	_game.call("set_weather", &"clear")
	_player().call("teleport", _spawn())
	await _wait(0.6)
	var clock: float = _game.get("clock")
	var screen := await _open_screen()
	var row := _button(screen, "Marais Brumeux") if screen else null
	_check("le Marais est proposé", row != null)
	if row == null:
		return
	await _mouse_click(row.get_global_rect().get_center())
	await _play_lines({"chante": "barque_09_chant_marais", "amarre la barque": "barque_10_amarre_marais"},
		func() -> bool: return _zone() == &"marais" and _scene_done())
	_check("la scène d'arrivée du Marais s'est jouée (voix_coeur_chant)", _game.call("flag", &"voix_coeur_chant"))
	_check_arrival(&"marais", clock)


func _check_arrival(zone: StringName, clock_before: float) -> void:
	var gone: float = fposmod(float(_game.get("clock")) - clock_before, 1440.0)
	_check("(d) arrivée dans la bonne zone", _zone() == zone, str(_zone()))
	_check("(d) l'horloge a avancé de la traversée", is_equal_approx(gone, CROSSING_MINUTES), "%.1f min" % gone)
	_check("(d) Chloé sur le quai, à côté de la barque", _player().global_position.distance_to(_spawn()) < 40.0,
		"%.0f px" % _player().global_position.distance_to(_spawn()))
	var boat := _boat()
	_check("(d) la barque est revenue à son amarre", boat != null and boat.global_position.distance_to(_moored(boat)) < 1.0)
	_check("(d) Chloé et son dino visibles, libres ; plus de doublure dans la barque",
		_player().modulate.a > 0.99 and current_scene.get("companion").modulate.a > 0.99 and not _player().get("busy")
		and _entities().get_node_or_null("ChloeBarque") == null)
	_check("(d) plus aucune scène en cours, jeu pas en pause", _story_playing() == 0 and not paused and _screen() == null)
	print("   heure %.2f, jour %d, météo %s" % [float(_game.get("clock")) / 60.0, _game.get("day"), _game.get("weather")])


## La réplique de la traversée suit le temps qu'il fait et l'heure (pluie, brume, nuit, jour).
func _weather_lines() -> void:
	print("— la traversée selon la météo et l'heure")
	var clock: float = _game.get("clock")
	var cases := [[&"rain", 11.0, "pluie"], [&"mist", 11.0, "brume"], [&"clear", 23.0, "nuit"], [&"clear", 11.0, "côte"]]
	for c: Array in cases:
		_game.call("set_weather", c[0])
		_game.set("clock", float(c[1]) * 60.0)
		var text: String = _barque._on_the_way()
		var expected: String = {"pluie": "pluie", "brume": "brume", "nuit": "eau noire", "côte": "le long de la côte"}[c[2]]
		_check("traversée par %s à %dh : « %s… »" % [c[0], c[1], text.left(40)], text.contains(expected))
	_game.set("clock", clock)
	_game.call("set_weather", &"clear")


# ------------------------------------------------------------------ captures des 4 embarcadères

func _four_landings() -> void:
	print("— captures des embarcadères")
	_game.call("set_weather", &"clear")
	for zone: StringName in ZONES:
		await _goto(zone)
		var boat := _boat()
		_check("%s : la barque et le point d'arrivée sont là" % zone, boat != null and _spawn() != Vector2.INF)
		if boat:
			_player().call("face_towards", boat.global_position)
			_check("%s : depuis le quai, la touche vise la barque" % zone, _player().call("nearest_interactable") == boat,
				str(_player().call("nearest_interactable")))
		await _wait(0.8)
		await _shot("barque_2%d_%s" % [ZONES.find(zone), zone])


# ------------------------------------------------------------------ outils : jeu

## Change de zone (comme le debug), arrivée au point « Embarcadere », dinos sauvages calmés.
func _goto(zone: StringName) -> void:
	var world = current_scene
	await world.goto_zone(zone, SPAWN)
	await _wait(2.0)
	for n in _entities().get_children():
		if n.has_method("calm_down"):
			n.call("calm_down", 900.0)
	await _play_lines({}, func() -> bool: return _scene_done())


## Utilise la barque à la touche d'interaction et attend l'écran de choix (null s'il ne vient pas).
func _open_screen() -> Node:
	_press(&"interact")
	for i in 30:
		await _wait(0.2)
		if _screen():
			await _wait(0.3)
			return _screen()
		if _dialogue_active():
			_press(&"interact")
	return null


## Fait défiler les répliques (deux appuis par réplique, ~1,1 s ; jamais quand rien n'est affiché :
## on interagirait avec la barque) jusqu'à `done`, au plus 90 s. `shots` : texte d'une réplique →
## capture faite pendant qu'elle s'affiche. Rend ce qu'on a vu passer (« lettre », « écran », les
## textes de WATCHED).
func _play_lines(shots: Dictionary, done: Callable) -> Dictionary:
	var seen := {}
	var last := ""
	var waited := 0.0
	while waited < 90.0:
		if _screen():
			seen["écran"] = true
		if _letter():
			seen["lettre"] = true
			await _wait(1.2)
			_press(&"interact")
			await _wait(0.6)
			waited += 1.8
			continue
		if _dialogue_active():
			var text := _line()
			if text != last:
				last = text
				print("   » ", text)
				for key: String in WATCHED:
					if text.contains(key):
						seen[key] = true
				for key: String in shots:
					if text.contains(key) and not seen.has("capture:" + key):
						seen["capture:" + key] = true
						await _wait(1.6)
						await _shot(shots[key])
			_press(&"interact")   # (un appui à la fois : le suivant peut tomber sur une lettre)
			await _wait(0.55)
			waited += 0.55
			continue
		if done.call():
			break
		await _wait(0.2)
		waited += 0.2
	return seen


func _scene_done() -> bool:
	return _story_playing() == 0 and not _dialogue_active() and _letter() == null and _screen() == null \
		and not _player().get("busy")


func _story_playing() -> int:
	return int(load("res://story/story.gd").get("playing"))


func _zone() -> StringName:
	var region = current_scene.get("region")
	return region.region_id if region else &""


func _player() -> Node2D:
	return current_scene.get("player")


func _entities() -> Node:
	return current_scene.get("region").get_node("Entities")


func _boat() -> Node2D:
	return _entities().get_node_or_null(BOAT)


func _spawn() -> Vector2:
	var marker := current_scene.get("region").get_node_or_null(NodePath("Spawns/" + String(SPAWN))) as Node2D
	return marker.global_position if marker else Vector2.INF


## Où la barque est amarrée dans la scène de la zone (là où le générateur l'a mise).
func _moored(boat: Node2D) -> Vector2:
	var scene: PackedScene = load(current_scene.get("region").scene_file_path)
	var state := scene.get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) == boat.name:
			for p in state.get_node_property_count(i):
				if state.get_node_property_name(i, p) == &"position":
					return state.get_node_property_value(i, p)
	return Vector2.INF


func _dialogue_active() -> bool:
	return root.get_node("Dialogue").get("active")


func _line() -> String:
	var box = root.get_node("Dialogue").get("_text")
	return box.text if box else ""


func _clicks() -> Node:
	for node in current_scene.get_children():
		if node.has_method("screen_point") and node.has_method("pick"):
			return node
	return null


# ------------------------------------------------------------------ outils : écrans

func _screen() -> Node:
	return _root_child("voyage_screen.gd")


func _letter() -> Node:
	return _root_child("letter_view.gd")


func _root_child(script_file: String) -> Node:
	for n in root.get_children():
		var s: Script = n.get_script()
		if s and s.resource_path.ends_with(script_file) and not n.is_queued_for_deletion():
			return n
	return null


## Les lignes de l'écran : nom, ligne du dessous, grisée.
func _rows(screen: Node) -> Array:
	var out := []
	for b in screen.find_children("*", "Button", true, false):
		var labels := b.find_children("*", "Label", true, false)
		out.append({"name": _name_of(b), "under": (labels[1] as Label).text if labels.size() > 1 else "",
			"disabled": (b as Button).disabled})
	return out


func _row_names(rows: Array) -> Array:
	return rows.map(func(r: Dictionary) -> String: return r["name"])


func _name_of(b: Node) -> String:
	if not b is Button:
		return ""
	var labels := b.find_children("*", "Label", true, false)
	return (labels[0] as Label).text if not labels.is_empty() else (b as Button).text


func _labels(under: Node) -> Array:
	return under.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)


func _button(under: Node, text: String) -> Button:
	for b in under.find_children("*", "Button", true, false):
		if _name_of(b) == text:
			return b
	return null


# ------------------------------------------------------------------ outils : entrées

func _press(action: StringName) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _tap(button: int) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button as JoyButton
		event.pressed = pressed
		Input.parse_input_event(event)
	Input.flush_buffered_events()


func _move_mouse(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	Input.flush_buffered_events()


## Un clic dans le monde (comme tools/test_clic.gd).
func _click(at: Vector2) -> void:
	_move_mouse(at)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
	Input.flush_buffered_events()


## Un clic sur un bouton d'écran (comme tools/test_manette.gd : appui et relâché séparés).
func _mouse_click(at: Vector2) -> void:
	_move_mouse(at)
	await _wait(0.1)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await _wait(0.1)


# ------------------------------------------------------------------ outils : test

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


func _shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
