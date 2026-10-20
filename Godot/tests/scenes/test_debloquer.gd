extends GdUnitTestSuite
## « Se débloquer » (story/unstick.gd, le menu du jeu), sans fenêtre, sur une situation bloquée fabriquée : une
## scène qui a pris Chloé (Story.lock) et attend une réplique qui ne répond plus, une autre réplique en file,
## une scène automatique en attente, l'écran resté noir. release_all : tout se ferme, plus rien ne tient Chloé,
## Story.playing revient à 0, la file est vide, l'écran revient ; let_go : la scène lâchée finit sans montrer
## ses répliques ni poser leurs drapeaux, puis la boîte remarche. (Le reste — la zone remise, ses scènes
## rejouées — demande le monde : tools/scenarios/scenes_joss_nuit.gd.)
## Et le menu : « Se débloquer » est dans le menu du jeu (pas sur l'écran titre), avec sa confirmation.

const SAVE_PATH := "user://test_gdunit_scenes_debloquer.json"
const MAX_FRAMES := 900

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)


func after() -> void:
	_clean()
	Save.path = _saved_path
	Game.new_game()


func before_test() -> void:
	Game.new_game()
	Game.region_id = &"havre_dore"
	_clean()


func _clean() -> void:
	Dialogue.skip_lines = false
	Dialogue.abort()
	Scenes.reset()
	Scenes.forget_stale()
	Story.playing = 0
	Router.clear()


func _until(done: Callable) -> bool:
	for i in MAX_FRAMES:
		if done.call():
			return true
		await get_tree().process_frame
	return false


## La scène qui se bloque : elle prend Chloé, dit une réplique (jamais avancée), puis une autre.
func _stuck_scene(got: Dictionary) -> void:
	await Story.hold(func() -> void:
		Story.lock(true)
		await Dialogue.run([{"text": "Une réplique qui ne répond plus."}, {"flag": &"test_bloque_vu"}])
		await Dialogue.run([{"text": "La suite de la scène."}, {"flag": &"test_suite_vue"}])
		got["fin"] = true
		Story.lock(false))


func test_se_debloquer_remet_tout_en_etat() -> void:
	var got := {}
	_stuck_scene(got)
	(func() -> void:
		await Dialogue.run([{"text": "Une autre réplique, en file."}])
		got["autre"] = true).call()
	Scenes.request("phase:havre_dore", &"havre_dore", func() -> void: got["nuit"] = true)
	await Router.fade_out(0.01)
	assert_bool(Scenes.busy()).is_true()
	assert_int(Story.playing).is_equal(1)
	assert_int(Scenes.waiting()).is_equal(1)
	assert_int(Dialogue.pending()).is_equal(2)

	Unstick.release_all(get_tree())
	assert_bool(Dialogue.active).override_failure_message("la boîte reste ouverte").is_false()
	assert_int(Dialogue.pending()).is_equal(0)
	assert_int(Story.playing).override_failure_message("Story.playing pas remis à 0").is_equal(0)
	assert_int(Scenes.waiting()).override_failure_message("la file n'est pas vidée").is_equal(0)
	assert_bool(Scenes.holds_player()).is_false()
	assert_bool(Router.is_busy()).is_false()
	assert_float((Router.get("_curtain") as ColorRect).color.a).override_failure_message("l'écran reste noir").is_equal(0.0)
	assert_bool(get_tree().paused).is_false()

	await Unstick.let_go(get_tree())
	assert_bool(got.get("fin", false)).override_failure_message("la scène lâchée n'a pas fini").is_true()
	assert_bool(got.has("autre")).is_true()
	assert_bool(got.has("nuit")).override_failure_message("la scène en file d'avant le déblocage a joué quand même").is_false()
	assert_bool(Game.flag(&"test_bloque_vu") or Game.flag(&"test_suite_vue")) \
		.override_failure_message("des répliques jamais lues ont posé leurs drapeaux").is_false()
	assert_bool(Scenes.busy()).is_false()
	assert_bool(Dialogue.skip_lines).is_false()
	assert_int(Story.playing).is_equal(0)
	# Tout remarche : une réplique s'affiche, une scène automatique part.
	(func() -> void: await Dialogue.run([{"text": "Ça remarche."}])).call()
	assert_str(Dialogue.shown_text()).is_equal("Ça remarche.")
	Dialogue.abort()


func test_une_scene_lachee_qui_ne_finit_jamais_n_est_attendue_qu_un_temps() -> void:
	var tree := get_tree()
	var slow := func() -> void:   # (elle attend 1,5 s : plus que ce qu'on lui laisse ici)
		await Story.hold(func() -> void: await tree.create_timer(1.5).timeout)
	slow.call()
	assert_bool(Scenes.busy()).is_true()
	Unstick.release_all(tree)
	Scenes._stale_until_ms = Time.get_ticks_msec() + 200   # (au lieu de SKIP_MAX_S : le test va vite)
	var t0 := Time.get_ticks_msec()
	await Unstick.let_go(tree)
	assert_int(Time.get_ticks_msec() - t0).is_less(1000)
	assert_bool(Scenes.busy()).is_false()
	await tree.create_timer(1.5).timeout   # (elle finit enfin : son verrou d'avant ne compte plus)
	assert_bool(Scenes.busy()).is_false()
	assert_int(Story.playing).is_equal(0)


func test_le_menu_du_jeu_propose_se_debloquer_avec_confirmation() -> void:
	var menu := SettingsMenu.new()
	menu.in_game = true
	add_child(menu)
	get_tree().paused = false   # (le menu met le jeu en pause : pas les tests)
	await get_tree().process_frame
	assert_int(SettingsMenu.open_count).is_equal(1)
	var labels := _buttons(menu)
	assert_array(labels).contains(["Se débloquer"])
	menu.call(&"_show", "debloquer")
	await get_tree().process_frame
	labels = _buttons(menu)
	assert_array(labels).contains_exactly(["Non, continuer", "Oui, se débloquer"])
	var focused := menu.get_viewport().gui_get_focus_owner() as Button
	assert_str(focused.text if focused else "").override_failure_message("au clavier ou à la manette, le premier bouton n'a pas le focus").is_equal("Non, continuer")
	menu.queue_free()   # (pas _close : il enregistre les préférences de Greg)
	await get_tree().process_frame
	assert_int(SettingsMenu.open_count).is_equal(0)
	var title := SettingsMenu.new()   # (l'écran titre : pas de « Se débloquer »)
	add_child(title)
	get_tree().paused = false
	await get_tree().process_frame
	assert_array(_buttons(title)).not_contains(["Se débloquer"])
	title.queue_free()
	await get_tree().process_frame


func _buttons(menu: Node) -> Array:
	return menu.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return not b.is_queued_for_deletion()) \
		.map(func(b: Button) -> String: return b.text)
