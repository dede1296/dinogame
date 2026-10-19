extends SceneTree
## Le seul test avec fenêtre des mécaniques du chapitre 9 : l'écran du combat du Souverain, joué comme le ferait un
## doigt (BattleHud.tap). Le fond du Cœur des Apex (apex.jpg) et ses grains d'ambre ; « Sceaux » à la place de Fuir ;
## la liste des cinq Sceaux ; Cheminée qui paraît à côté de lui ; l'Ambre clair au Sac, « Quand il écoute » ; puis, à
## deux tiers de calme, le dernier geste de Vif et la goutte : apaisé. Captures dans out=.
##   godot --path Godot --script res://tests/apex/mecaniques/fenetre_combat_souverain.gd --resolution 1600x900 -- out=<dossier> [titre=…]
## (Script compilé avant les autoloads : le combat et les dinos sont chargés par leur chemin.)

const CAPTION := "Chapitre 9 : le combat du Souverain à l'écran (fond des Apex, commande Sceaux, Cheminée, Ambre clair à 2/3, dernier geste de Vif)"
const SCENE := "res://battle/battle_scene.gd"
const LOOK := "res://battle/battle_apex.gd"
const BATTLES := "res://battle/apex_battles.gd"
const DINO := "res://game/dino.gd"
const FIVE := ["sceau_marais", "sceau_desert", "sceau_cote", "sceau_monts", "sceau_volcan"]

var _out := "user://fenetre_combat_souverain"
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
	root.get_node("Save").set("path", "user://fenetre_combat_souverain_save.json")   # (jamais la partie de Greg)
	_game = root.get_node("Game")
	_game.call("new_game")
	_game.call("set_flag", &"prologue_done")
	_game.call("set_flag", &"tuto_commandes")
	_game.call("set_flag", &"starter", "velociraptor")
	_game.set("region_id", &"coeur_apex")
	var dino = load(DINO)
	var party: Array = _game.get("party")
	party.clear()
	var vif = dino.create(&"velociraptor", 48, "Vif")
	vif.bond = 5
	party.append(dino.create(&"plesiosaurus", 47, "Nessie"))
	party.append(vif)
	for id: String in FIVE:
		_game.call("give_item", id)
	_game.call("give_item", "antidote_ambre")
	await _battle()
	banner.queue_free()
	print("TEST combat du Souverain à l'écran : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


func _battle() -> void:
	var battles = load(BATTLES)
	var scene: CanvasLayer = load(SCENE).new()
	root.add_child(scene)
	var done := [false, ""]
	var runner := func() -> void:
		done[1] = await scene.call("run", battles.souverain(), battles.souverain_rules())
		done[0] = true
	runner.call()
	var hud = await _wheel(scene)
	var backdrop: TextureRect = scene.get("_backdrop")
	_check("le fond du Cœur des Apex (%s)" % backdrop.texture.resource_path.get_file(), backdrop.texture.resource_path.get_file() in ["apex.jpg", "grotte.jpg"])
	var looks: Array = scene.find_children("*", "Control", true, false).filter(func(c: Control) -> bool:
		return c.get_script() != null and c.get_script().resource_path == LOOK)
	_check("…et ses grains d'ambre", looks.size() == 1 and looks[0].find_children("*", "CPUParticles2D", true, false).size() > 0)
	var engine = scene.get("engine")
	_check("le moteur du dernier combat (jauge %d)" % engine.calm_full, engine.get_script().resource_path.ends_with("apex_engine.gd") and engine.calm_full == 300)
	_check("« Sceaux » à la place de Fuir", hud.get("sceaux_button").visible and not hud.get("run_button").visible)
	await _shot("01_roue_sceaux")
	_check("la liste des Sceaux s'ouvre", hud.call("tap", "sceaux"))
	await create_timer(0.5).timeout
	await _shot("02_liste_des_cinq_sceaux")
	_check("Cheminée s'appelle (Sceau du Volcan)", hud.call("tap", "sceau:sceau_volcan"))
	await create_timer(1.3).timeout
	await _shot("03_cheminee_paralt")
	hud = await _wheel(scene)
	_check("…une seule fois", hud.call("tap", "sceaux") and not hud.call("tap", "sceau:sceau_volcan"))
	hud.call("show_panel", "wheel")
	_check("le Sac s'ouvre : l'Ambre clair y est", hud.call("tap", "sac"))
	await create_timer(0.5).timeout
	await _shot("04_sac_ambre_quand_il_ecoute")
	_check("trop tôt : Chloé range la fiole", hud.call("tap", "item:antidote_ambre"))
	hud = await _wheel(scene)
	_check("…la dose est toujours là", _game.call("item_count", "antidote_ambre") == 1)
	engine.calm = engine.threshold()
	_check("à deux tiers, l'Ambre clair se verse", hud.call("tap", "sac") and hud.call("tap", "item:antidote_ambre"))
	await create_timer(1.6).timeout
	await _shot("05_dernier_geste_de_vif")
	for i in 60:
		if done[0]:
			break
		await create_timer(0.25).timeout
		_press(&"interact")
	_check("le Souverain est apaisé (%s)" % done[1], done[0] and done[1] == "calmed")
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
