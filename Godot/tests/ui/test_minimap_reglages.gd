extends GdUnitTestSuite
## La mini-carte et la direction de l'objectif, côté réglages et commandes, sans fenêtre : les choix
## retenus dans les réglages (Quality.pref, jamais écrits ici sur le disque), la touche et le bouton
## de la manette (remappables, au tutoriel, dans la page Commandes), le texte de la ligne de direction
## de l'aide de quête, et l'écran « libre » (ni scène, ni dialogue) qui seul montre la mini-carte.

const UNSET := "(pas de réglage)"

var _saved := {}


## The player's own settings, put back after each test (in memory only: nothing is written here).
func before_test() -> void:
	for key in [Minimap.PREF_MODE, Minimap.PREF_ZOOM, QuestTracker.PREF_DIRECTION]:
		_saved[key] = Quality.pref(Minimap.PREF_SECTION, key, UNSET)


func after_test() -> void:
	for key: String in _saved:
		Quality.set_pref(Minimap.PREF_SECTION, key, null if _saved[key] is String and _saved[key] == UNSET else _saved[key], false)
	Story.playing = 0
	Dialogue.active = false


func test_les_deux_reglages_dans_la_meme_section() -> void:
	assert_str(QuestTracker.PREF_SECTION).is_equal(Minimap.PREF_SECTION)


func test_mode_retenu_dans_les_reglages() -> void:
	Minimap.set_pref_mode(MinimapMath.Mode.LARGE, false)
	assert_int(Minimap.pref_mode()).is_equal(MinimapMath.Mode.LARGE)
	Minimap.set_pref_mode(MinimapMath.Mode.HIDDEN, false)
	assert_int(Minimap.pref_mode()).is_equal(MinimapMath.Mode.HIDDEN)
	Minimap.set_pref_mode(42, false)   # (un réglage abîmé : la petite)
	assert_int(Minimap.pref_mode()).is_equal(MinimapMath.Mode.SMALL)


func test_par_defaut_petite_sur_ordinateur() -> void:
	Quality.set_pref(Minimap.PREF_SECTION, Minimap.PREF_MODE, null, false)
	var expected := MinimapMath.Mode.SMALL if Screen.on_computer() else MinimapMath.Mode.HIDDEN
	assert_int(Minimap.pref_mode()).is_equal(expected)


func test_zoom_retenu_et_borne() -> void:
	Minimap.set_pref_zoom(2, false)
	assert_int(Minimap.pref_zoom()).is_equal(2)
	Minimap.set_pref_zoom(-5, false)
	assert_int(Minimap.pref_zoom()).is_equal(0)
	Quality.set_pref(Minimap.PREF_SECTION, Minimap.PREF_ZOOM, null, false)
	assert_int(Minimap.pref_zoom()).is_equal(MinimapMath.ZOOM_DEFAULT)


func test_la_direction_se_masque_et_revient() -> void:
	Quality.set_pref(Minimap.PREF_SECTION, QuestTracker.PREF_DIRECTION, null, false)
	assert_bool(QuestTracker.direction_shown()).is_true()   # (par défaut : visible)
	QuestTracker.set_direction_shown(false, false)
	assert_bool(QuestTracker.direction_shown()).is_false()
	QuestTracker.set_direction_shown(true, false)
	assert_bool(QuestTracker.direction_shown()).is_true()


func test_texte_de_la_direction() -> void:
	var here := Vector2(10, 10)
	assert_str(QuestTracker.direction_text({}, here)).is_equal("")
	assert_str(QuestTracker.direction_text({"tile": Vector2.INF, "via": &"", "kind": ""}, here)).is_equal("")
	assert_str(QuestTracker.direction_text({"tile": Vector2(10, 52), "via": &"", "kind": ""}, here)).is_equal("42 m")
	assert_str(QuestTracker.direction_text({"tile": Vector2(11, 10), "via": &"", "kind": ""}, here)).is_equal("ici")
	var out := {"tile": Vector2(10, 28), "via": &"havre_dore", "kind": "sortie", "dest": &"havre_dore"}
	assert_str(QuestTracker.direction_text(out, here)).is_equal("18 m · sortie : Havre-Doré")
	var door := {"tile": Vector2(10, 15), "via": &"cabinet", "kind": "entrée", "dest": &"cabinet"}
	assert_str(QuestTracker.direction_text(door, here)).is_equal("5 m · entrée : Cabinet du Pr Roc")
	var lost := {"tile": Vector2.INF, "via": &"cote", "kind": ""}
	assert_str(QuestTracker.direction_text(lost, here)).is_equal("vers Côte Préhistorique")


func test_la_touche_et_le_bouton_de_la_mini_carte() -> void:
	Minimap.ensure_action()
	assert_bool(InputMap.has_action(Minimap.ACTION)).is_true()
	var key := false
	var pad := false
	for e in InputMap.action_get_events(Minimap.ACTION):
		key = key or (e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_TAB)
		pad = pad or (e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == JOY_BUTTON_DPAD_DOWN)
	assert_bool(key).override_failure_message("Tab").is_true()
	assert_bool(pad).override_failure_message("croix ↓").is_true()
	assert_bool(InputMap.has_action(Minimap.ZOOM_IN)).is_true()
	assert_bool(InputMap.has_action(Minimap.ZOOM_OUT)).is_true()


func test_remappable_au_tutoriel_et_dans_les_commandes() -> void:
	Minimap.ensure_action()
	var remappable := KeyRemap.actions().map(func(a: Array) -> StringName: return a[0])
	assert_bool(Minimap.ACTION in remappable).override_failure_message("Touches").is_true()
	var tutorial := false
	for page: Array in ControlsTutorial.PAGES:
		for row: Array in page[1]:
			tutorial = tutorial or Minimap.ACTION in row[1]
	assert_bool(tutorial).override_failure_message("tutoriel").is_true()
	var controls := SettingsMenu.CONTROLS.any(func(c: Array) -> bool: return c.size() > 3 and Minimap.ACTION in c[3])
	assert_bool(controls).override_failure_message("page Commandes").is_true()


func test_l_ecran_libre_seulement_sans_scene_ni_dialogue() -> void:
	assert_bool(Minimap.screen_free(null)).is_true()
	Story.playing = 1
	assert_bool(Minimap.screen_free(null)).is_false()
	Story.playing = 0
	Dialogue.active = true
	assert_bool(Minimap.screen_free(null)).is_false()
	Dialogue.active = false
	assert_bool(Minimap.screen_free(null)).is_true()
