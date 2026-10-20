extends SceneTree
## Le seul test avec fenêtre des revanches (patch_C.md appliqué) : l'écran d'une revanche et d'un combat sauvage après
## la fin, joué comme le ferait un doigt (BattleHud.tap). La revanche du Tricératops Alpha : « Sceaux » à la place de
## Fuir, la liste des sept (le sien grisé : « Pas contre lui-même »), Cheminée appelé (il paraît), une seule fois, la
## leçon « Il est chez lui », et sa chute (« Il s'arrête. Il a vu. »). Un combat sauvage : Fuir reste, les Sceaux sont au
## Sac (une carte qui ouvre leur liste). Captures dans out=.
##   godot --path Godot --script res://tests/apex/revanches/fenetre_sceaux_libres.gd --resolution 1600x900 -- out=<dossier>
## (Script compilé avant les autoloads : le combat, les dinos et les tables sont chargés par leur chemin.)

const CAPTION := "Revanches : les Sceaux libres à l'écran (revanche du Tricératops : la roue, la liste, Cheminée ; combat sauvage : le Sac)"
const SCENE := "res://battle/battle_scene.gd"
const DINO := "res://game/dino.gd"
const REVANCHES := "res://battle/revanche_battles.gd"
const ENGINE := "res://battle/apex_engine.gd"

var _out := "user://fenetre_sceaux_libres"
var _caption := CAPTION
var _failed := 0
var _game: Node


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
	root.get_node("Save").set("path", "user://fenetre_sceaux_libres_save.json")   # (jamais la partie de Greg)
	_game = root.get_node("Game")
	_game.call("new_game")
	for f in [&"prologue_done", &"tuto_commandes", &"post_game"]:
		_game.call("set_flag", f)
	_game.call("set_flag", &"starter", "velociraptor")
	_game.call("give_item", "insigne_gardienne")
	_game.call("give_item", "baie", 3)
	var engine_script = load(ENGINE)
	for s: Dictionary in engine_script.LIBRES:
		_game.call("set_flag", engine_script.woken_flag(s["id"]))
	var dino = load(DINO)
	var party: Array = _game.get("party")
	party.clear()
	var vif = dino.create(&"velociraptor", 50, "Vif")
	vif.bond = 5
	party.append(vif)
	party.append(dino.create(&"plesiosaurus", 49, "Nessie"))
	_game.set("region_id", &"plaines")
	await _revanche()
	_game.call("heal_party")
	await _sauvage()
	banner.queue_free()
	print("TEST Sceaux libres à l'écran : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


func _revanche() -> void:
	var table = load(REVANCHES)
	var scene: CanvasLayer = load(SCENE).new()
	root.add_child(scene)
	var done := [false, ""]
	var runner := func() -> void:
		done[1] = await scene.call("run", table.alpha(&"plaines"), table.alpha_rules(&"plaines"))
		done[0] = true
	runner.call()
	var hud = await _wheel(scene)
	var engine = scene.get("engine")
	_check("les Sceaux libres dans la revanche", engine.get("libres") != null)
	_check("il est chez lui (attaque +2)", engine.stages["foe"]["atk"] == 2)
	_check("« Sceaux » à la place de Fuir", hud.get("sceaux_button").visible and not hud.get("run_button").visible)
	await _shot("01_revanche_roue_sceaux")
	_check("la liste des Sceaux s'ouvre", hud.call("tap", "sceaux"))
	await create_timer(0.5).timeout
	_check("le sien grisé (pas contre lui-même)", not hud.call("tap", "sceau:sceau_plaines"))
	await _shot("02_revanche_liste_des_sept")
	_check("Cheminée s'appelle", hud.call("tap", "sceau:sceau_volcan"))
	await create_timer(1.3).timeout
	await _shot("03_cheminee_parait")
	hud = await _wheel(scene)
	_check("…une seule fois", hud.call("tap", "sceaux") and not hud.call("tap", "sceau:sceau_volcan"))
	hud.call("show_panel", "wheel")
	engine.foe.hp = 1
	_check("un coup", hud.call("tap", "attaquer") and hud.call("tap", "move:0"))
	for i in 40:
		await create_timer(0.25).timeout
		var said: String = hud.get("message").text
		if said.contains("Il s'arrête"):
			await _shot("04_il_s_arrete_il_a_vu")
			var foe: CanvasItem = scene.get("_foe_sprite")
			_check("il s'arrête : il reste là, il ne se dissout pas", foe.modulate.a > 0.9)
			break
		if done[0]:
			break
		_press(&"interact")
	for i in 60:
		if done[0]:
			break
		await create_timer(0.25).timeout
		_press(&"interact")
	_check("la revanche gagnée (%s)" % done[1], done[0] and done[1] == "win")
	scene.queue_free()


func _sauvage() -> void:
	var dino = load(DINO)
	var scene: CanvasLayer = load(SCENE).new()
	root.add_child(scene)
	var runner := func() -> void:
		await scene.call("run", dino.create(&"protoceratops", 30), {})
	runner.call()
	var hud = await _wheel(scene)
	_check("Fuir reste dans un combat sauvage", hud.get("run_button").visible and not hud.get("sceaux_button").visible)
	_check("le Sac s'ouvre", hud.call("tap", "sac"))
	await create_timer(0.5).timeout
	await _shot("05_sauvage_sac_sceaux")
	_check("la carte « Sceaux » ouvre leur liste", hud.call("tap", "sac_sceaux"))
	await create_timer(0.5).timeout
	await _shot("06_sauvage_liste")
	scene.queue_free()


## Fait défiler les répliques jusqu'à la roue ; rend le BattleHud.
func _wheel(scene: CanvasLayer):
	var hud = null
	for i in 60:
		await create_timer(0.25).timeout
		hud = scene.get("_hud")
		if hud and hud.call("is_open"):
			return hud
		_press(&"interact")
	_check("la roue revient", false)
	return hud


func _press(action: StringName) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _check(what: String, ok: bool) -> void:
	if not ok:
		_failed += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", what])


func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
