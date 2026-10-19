extends GdUnitTestSuite
## L'écran des emplacements (ui/save_slots.gd), sans fenêtre, dans un dossier d'essai
## (user://test_gdunit_ecran_emplacements : jamais la partie de Greg) : trois cartes, « Vide » et
## « Illisible » ; en « Charger », seules les parties lisibles se choisissent ; en « Nouvelle partie »,
## une partie n'est écrasée qu'après « Oui, écraser » (« Annuler » revient aux cartes) ; « Supprimer »
## demande aussi ; en jeu (« Sauvegarder dans… »), l'emplacement actuel ne se choisit pas ; le menu titre
## passe par le choix d'emplacement avant la nouvelle partie. Les boutons sont pressés par leur signal.

const DIR := "user://test_gdunit_ecran_emplacements"
const SaveSlots := preload("res://ui/save_slots.gd")

var _saved_path: String
var _before_save: Callable
var _screen: CanvasLayer
var _picked := -1


func before() -> void:
	_saved_path = Save.path
	_before_save = Save.before_save
	Save.before_save = Callable()


func after() -> void:
	_wipe()
	DirAccess.remove_absolute(DIR)
	Save.path = _saved_path
	Save.before_save = _before_save
	Game.new_game()


func before_test() -> void:
	_wipe()
	Save.path = DIR.path_join("save_1.json")   # (jamais la partie de Greg)
	_picked = -1


func after_test() -> void:
	if is_instance_valid(_screen):
		_screen.queue_free()
	await await_idle_frame()


static func _wipe() -> void:
	var d := DirAccess.open(DIR)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)


## Slot 1: a game in the Plaines; slot 2: damaged; slot 3: empty.
static func _slots() -> void:
	Game.new_game()
	Game.give_starter(&"velociraptor")
	Game.region_id = &"plaines"
	Save.path = Save.path_for(1)
	Save.save_game()
	var out := FileAccess.open(Save.path_for(2), FileAccess.WRITE)
	out.store_string("{ abîmée")
	out.close()


func _open(mode: SaveSlots.Mode) -> SaveSlots:
	_screen = SaveSlots.open(self, mode)
	var screen := _screen as SaveSlots
	screen.chosen.connect(func(n: int) -> void: _picked = n)
	await await_idle_frame()
	return screen


static func _words(node: Node) -> String:
	var all := PackedStringArray()
	for label in node.find_children("*", "Label", true, false):
		all.append((label as Label).text)
	return " | ".join(all)


func test_trois_cartes_vide_et_illisible_en_charger() -> void:
	# Arrange
	_slots()
	# Act
	var screen := await _open(SaveSlots.Mode.LOAD)
	# Assert
	assert_str(_words(screen.card_of(1))).contains("Prairie du Grand Crâne").contains("Vif · niveau 5")
	assert_str(_words(screen.card_of(2))).contains("Illisible")
	assert_str(_words(screen.card_of(3))).contains("Vide")
	for label in screen.card_of(1).find_children("*", "Label", true, false):
		assert_float((label as Label).size.y).override_failure_message("« %s » sans hauteur : invisible" % label.text).is_greater(0.0)
	assert_bool(screen.card_of(1).disabled).is_false()
	assert_bool(screen.card_of(2).disabled).override_failure_message("une partie illisible ne se charge pas").is_true()
	assert_bool(screen.card_of(3).disabled).is_true()
	assert_object(screen.find_child("Delete1", true, false)).is_not_null()
	assert_object(screen.find_child("Delete2", true, false)).override_failure_message("une sauvegarde abîmée se supprime").is_not_null()
	assert_object(screen.find_child("Delete3", true, false)).is_null()
	screen.card_of(1).pressed.emit()
	assert_int(_picked).is_equal(1)


func test_nouvelle_partie_demande_avant_d_ecraser() -> void:
	# Arrange
	_slots()
	var screen := await _open(SaveSlots.Mode.NEW)
	# Act : a game in slot 1 → the question, nothing chosen yet
	screen.card_of(1).pressed.emit()
	# Assert
	assert_bool(screen.asking).is_true()
	assert_int(_picked).is_equal(-1)
	assert_str(_words(screen)).contains("Écraser la partie de l'emplacement 1 ?")
	(screen.find_child("No", true, false) as Button).pressed.emit()
	assert_bool(screen.asking).override_failure_message("« Annuler » revient aux cartes").is_false()
	assert_int(_picked).is_equal(-1)
	screen.card_of(1).pressed.emit()
	(screen.find_child("Yes", true, false) as Button).pressed.emit()
	assert_int(_picked).is_equal(1)


func test_nouvelle_partie_sur_un_emplacement_vide_sans_question() -> void:
	_slots()
	var screen := await _open(SaveSlots.Mode.NEW)
	screen.card_of(3).pressed.emit()
	assert_int(_picked).is_equal(3)


func test_echap_revient_de_la_question_puis_sort() -> void:
	_slots()
	var screen := await _open(SaveSlots.Mode.NEW)
	screen.card_of(2).pressed.emit()
	assert_str(_words(screen)).contains("Remplacer la sauvegarde abîmée de l'emplacement 2 ?")
	screen.back()
	assert_bool(screen.asking).is_false()
	assert_int(_picked).is_equal(-1)
	screen.back()
	assert_int(_picked).override_failure_message("B / Échap sur les cartes : retour (0)").is_equal(0)


func test_supprimer_demande_puis_vide_l_emplacement() -> void:
	_slots()
	var screen := await _open(SaveSlots.Mode.LOAD)
	(screen.find_child("Delete1", true, false) as Button).pressed.emit()
	assert_str(_words(screen)).contains("Supprimer la partie de l'emplacement 1 ?")
	assert_str(String(Save.slot_summary(1)["state"])).override_failure_message("rien d'effacé avant « Oui »").is_equal(Save.READY)
	(screen.find_child("Yes", true, false) as Button).pressed.emit()
	assert_str(String(Save.slot_summary(1)["state"])).is_equal(Save.EMPTY)
	assert_bool(screen.asking).is_false()
	assert_bool(screen.card_of(1).disabled).is_true()
	assert_int(_picked).override_failure_message("l'écran reste ouvert").is_equal(-1)


func test_sauvegarder_dans_pas_l_emplacement_actuel() -> void:
	_slots()
	Save.path = Save.path_for(1)
	var screen := await _open(SaveSlots.Mode.SAVE_TO)
	assert_bool(screen.card_of(1).disabled).override_failure_message("l'emplacement actuel").is_true()
	assert_str(_words(screen.card_of(1))).contains("actuel")
	assert_object(screen.find_child("Delete1", true, false)).override_failure_message("on ne supprime pas la partie en cours").is_null()
	assert_bool(screen.card_of(3).disabled).is_false()
	screen.card_of(3).pressed.emit()
	assert_int(_picked).is_equal(3)


func test_ouvert_a_la_souris_puis_la_croix_prend_la_derniere_partie() -> void:
	# Arrange : slot 1 the last one played; the screen opened with the mouse (no focus)
	_slots()
	Save.load_slot(1)
	var was := Prompts.navigating
	Prompts.navigating = false
	var screen := await _open(SaveSlots.Mode.LOAD)
	assert_object(screen.get_viewport().gui_get_focus_owner()).override_failure_message("à la souris : aucun contour").is_null()
	# Act : the cross (→)
	Prompts.navigating = true
	var right := InputEventAction.new()
	right.action = &"ui_right"
	right.pressed = true
	screen._unhandled_input(right)
	await await_idle_frame()
	# Assert
	assert_object(screen.get_viewport().gui_get_focus_owner()).is_same(screen.card_of(1))
	Prompts.navigating = was


func test_le_menu_titre_passe_par_les_emplacements() -> void:
	var boot := FileAccess.get_file_as_string("res://scenes/boot/boot.gd")
	var at_choice := boot.find("_choose_slot(SaveSlots.Mode.NEW)")
	var at_new := boot.find("Game.new_game()")
	var at_slot := boot.find("Save.start_new_game(n, true)")
	assert_int(at_choice).override_failure_message("Nouvelle partie demande l'emplacement").is_greater(0)
	assert_int(at_new).is_greater(at_choice)
	assert_int(at_slot).override_failure_message("la nouvelle partie devient l'emplacement actif").is_greater(at_new)
	assert_str(boot).contains("Save.continue_slot()").contains("\"Charger une partie\"").contains("Save.migrate()")
	assert_str(FileAccess.get_file_as_string("res://ui/settings_menu.gd")).contains("\"Changer d'emplacement\"")
