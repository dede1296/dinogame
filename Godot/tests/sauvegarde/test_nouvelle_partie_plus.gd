extends GdUnitTestSuite
## La Nouvelle partie+ (docs/post-game-plan.md § 4, docs/post-game-scenes.md § N), sans fenêtre, dans un
## dossier d'essai (user://test_gdunit_ng_plus : jamais la partie de Greg) :
## - ce qui est GARDÉ l'est : le Dinodex (vus, possédés, où), les os (objets et drapeaux os_*), les fossiles,
##   les pages lues (journal_lu), les récompenses de Roc déjà données, l'intro vue, le tutoriel des commandes ;
## - RIEN DE GARDÉ EN TROP : équipe, réserve, objets, histoire, horloge, jour, météo, géants, revanches,
##   insigne, espèces ressuscitées (leur œuf est à refaire), et la fin (la nouvelle partie n'est pas finie) ;
## - ng_plus vaut 1 puis 2 ; les pages lues s'additionnent ; les œufs déjà joués aussi ;
## - +2 niveaux aux dresseurs et aux Alphas, +1 aux sauvages, rien dans une première partie ;
## - l'emplacement de la partie finie n'est jamais touché ; refus si la partie n'est pas finie, sur
##   l'emplacement source, ou sur une partie sans « Écraser » ;
## - les anciennes sauvegardes (avant la Nouvelle partie+, avant les emplacements) se chargent comme avant ;
## - l'œuf déjà joué : « Celui-là, tu le connais. », choisissable ; le Dinodex : possédé à la partie d'avant ;
## - l'écran des emplacements : « Nouvelle partie+ » sur une partie finie seulement, puis la destination.

const DIR := "user://test_gdunit_ng_plus"
const SaveSlots := preload("res://ui/save_slots.gd")

var _saved_path: String
var _before_save: Callable
var _enabled: bool
var _screen: CanvasLayer
var _picked := -1


func before() -> void:
	_saved_path = Save.path
	_before_save = Save.before_save
	_enabled = Save.enabled
	Save.before_save = Callable()
	Save.enabled = false


func after() -> void:
	_wipe()
	DirAccess.remove_absolute(DIR)
	Save.path = _saved_path   # (back to the player's slot: his folder again)
	Save.before_save = _before_save
	Save.enabled = _enabled
	Game.new_game()


func before_test() -> void:
	_wipe()
	Save.path = DIR.path_join("save_1.json")   # (jamais la partie de Greg)
	Save.enabled = false
	_picked = -1
	Game.new_game()


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


## A game played to the end with Vif: everything a long game holds, kept or not.
static func _finished_game(starter := &"velociraptor") -> void:
	Game.new_game()
	var vif := Game.give_starter(starter)
	vif.level = 48
	vif.bond = 5
	Game.add_caught(Dino.create(&"triceratops", 40))
	for i in 5:
		Game.add_caught(Dino.create(&"protoceratops", 30))   # (the last two go to the reserve)
	Game.mark_seen(&"spinosaurus")
	Game.mark_seen(&"compsognathus")
	Game.region_id = &"terre_apex"
	Game.player_position = Vector2(400, 300)
	Game.has_position = true
	Game.day = 37
	Game.clock = 21.0 * 60.0
	Game.play_time = 30.0 * 3600.0
	Game.weather = &"rain"
	Game.egg = {"species": "pteranodon", "name": "Pépite", "steps": 120}
	Game.searched = {"arbre_1": 3}
	Game.explored = {"plaines": PackedByteArray([255, 128, 0])}
	for f: String in ["prologue_arrived", "prologue_done", "met_maia", "sceau_plaines", "insigne_gardienne", "post_game",
			"epilogue_fini", "fin_vue", "intro_vue", "tuto_commandes", "geant_4_reveille", "geant_4_oeil", "alpha_triceratops_jour",
			"sceau_plaines_eveille", "found_journal_1", "found_journal_2", "found_journal_40", "found_journal_ancien",
			"galet_plaines_1", "fossile_1", "fossile_2", "fossiles_rendus", "os_titanosaure_1", "os_titanosaure_3",
			"os_kronosaurus_2", "ressuscite_saltasaurus", "carnet_os", "helene_os_titanosaure", "dex_palier_10",
			"dex_region_plaines", "dex_complet", "maia_defi_6"]:
		Game.set_flag(StringName(f))
	Game.set_flag(&"revanche_gaspard", 12)
	for item: Array in [["collier", 7], ["baie", 3], ["piece", 500], ["selle", 1], ["os_titanosaure", 2],
			["os_kronosaurus", 1], ["fossile", 6], ["insigne_gardienne", 1], ["plume_helene", 1], ["larmes_vendues", 4]]:
		Game.items[item[0]] = item[1]


## The game in memory written into slot `n` (as a test tool would: not remembered as the last one).
static func _save_in(n: int) -> void:
	Save.path = Save.path_for(n)
	Save.save_game()


static func _text(n: int) -> String:
	return FileAccess.get_file_as_string(Save.path_for(n))


static func _keys_with(prefix: String) -> Array:
	return Game.flags.keys().filter(func(k: String) -> bool: return k.begins_with(prefix))


# ------------------------------------------------------------------ what is kept

func test_garde_le_dinodex_les_os_les_pages_lues() -> void:
	# Arrange
	_finished_game()
	var previous := Game.to_dict()
	var seen := Game.dex_seen.duplicate()
	var caught := Game.dex_caught.duplicate()
	var where := Game.dex_where.duplicate()
	# Act
	var ok := Game.new_game_plus(previous)
	# Assert
	assert_bool(ok).is_true()
	assert_dict(Game.dex_seen).is_equal(seen)
	assert_dict(Game.dex_caught).is_equal(caught)
	assert_dict(Game.dex_where).is_equal(where)
	assert_int(Game.item_count("os_titanosaure")).is_equal(2)
	assert_int(Game.item_count("os_kronosaurus")).is_equal(1)
	assert_int(Game.item_count("fossile")).is_equal(6)
	for f in ["os_titanosaure_1", "os_titanosaure_3", "os_kronosaurus_2"]:
		assert_bool(Game.flag(StringName(f)) == true).override_failure_message("os gardé : %s" % f).is_true()
	assert_array(Game.pages_read_before()).contains_exactly_in_any_order(
		["found_journal_1", "found_journal_2", "found_journal_40", "found_journal_ancien"])
	assert_int(Game.ng_plus()).is_equal(1)
	for f in ["intro_vue", "tuto_commandes", "dex_palier_10", "dex_region_plaines", "dex_complet"]:
		assert_bool(Game.flag(StringName(f)) == true).override_failure_message("gardé : %s" % f).is_true()


func test_rien_de_garde_en_trop() -> void:
	# Arrange
	_finished_game()
	# Act
	Game.new_game_plus(Game.to_dict())
	# Assert : the party is empty before the prologue, the bag holds only the bones and the fossils
	assert_array(Game.party).is_empty()
	assert_array(Game.box).is_empty()
	assert_array(Game.items.keys()).contains_exactly_in_any_order(["os_titanosaure", "os_kronosaurus", "fossile"])
	assert_int(Game.coins()).is_equal(0)
	assert_int(Game.tears()).is_equal(0)
	assert_dict(Game.egg).is_empty()
	assert_int(Game.day).is_equal(1)
	assert_float(Game.clock).is_equal(Game.START_CLOCK)
	assert_float(Game.play_time).is_equal(0.0)
	assert_str(String(Game.weather)).is_equal("clear")
	assert_str(String(Game.region_id)).is_equal(String(Game.START_REGION))
	assert_bool(Game.has_position).is_false()
	assert_dict(Game.explored).is_empty()
	assert_dict(Game.searched).is_empty()
	# Every flag of the story starts again: the pages too (grey on the wall, never « found »)
	for f in ["prologue_arrived", "prologue_done", "starter", "maia_starter", "met_maia", "sceau_plaines", "insigne_gardienne",
			"post_game", "epilogue_fini", "fin_vue", "geant_4_reveille", "geant_4_oeil", "alpha_triceratops_jour",
			"sceau_plaines_eveille", "galet_plaines_1", "fossile_1", "fossiles_rendus", "ressuscite_saltasaurus",
			"carnet_os", "helene_os_titanosaure", "maia_defi_6", "revanche_gaspard"]:
		assert_bool(Game.flags.has(f)).override_failure_message("remis à zéro : %s" % f).is_false()
	assert_array(_keys_with("found_journal_")).is_empty()
	# Only the kept flags and the Nouvelle partie+'s own
	var allowed := ["intro_vue", "tuto_commandes", "dex_palier_10", "dex_region_plaines", "dex_complet", "os_titanosaure_1",
		"os_titanosaure_3", "os_kronosaurus_2", "ng_plus", "journal_lu", "oeufs_connus", "dex_partie_precedente"]
	assert_array(Game.flags.keys()).contains_exactly_in_any_order(allowed)


func test_nouvelle_partie_plus_deux_fois() -> void:
	# Arrange : a first NG+, played to its end with Écho, a new page found
	_finished_game()
	Game.new_game_plus(Game.to_dict())
	Game.give_starter(&"parasaurolophus")
	Game.set_flag(&"found_journal_6")
	Game.set_flag(&"found_journal_ancien_voix")
	Game.set_flag(&"fin_vue")
	# Act
	assert_bool(Game.new_game_plus(Game.to_dict())).is_true()
	# Assert : 2, the pages of both games, both eggs
	assert_int(Game.ng_plus()).is_equal(2)
	assert_array(Game.pages_read_before()).contains_exactly_in_any_order(["found_journal_1", "found_journal_2",
		"found_journal_40", "found_journal_ancien", "found_journal_6", "found_journal_ancien_voix"])
	assert_bool(Game.egg_known(&"velociraptor")).is_true()
	assert_bool(Game.egg_known(&"parasaurolophus")).is_true()
	assert_bool(Game.egg_known(&"ankylosaurus")).is_false()


func test_refus_si_la_partie_n_est_pas_finie() -> void:
	# Arrange : a long game, the end not seen
	_finished_game()
	Game.flags.erase("fin_vue")
	var previous := Game.to_dict()
	# Act
	var ok := Game.new_game_plus(previous)
	# Assert : refused, the game in memory untouched
	assert_bool(ok).is_false()
	assert_str(String(Game.region_id)).is_equal("terre_apex")
	assert_int(Game.party.size()).is_equal(5)
	assert_bool(Game.new_game_plus({})).is_false()
	assert_bool(Game.new_game_plus({"flags": "abîmé"})).is_false()


func test_un_premier_jeu_n_est_pas_une_nouvelle_partie_plus() -> void:
	assert_int(Game.ng_plus()).is_equal(0)
	assert_array(Game.pages_read_before()).is_empty()
	assert_bool(Game.egg_known(&"velociraptor")).is_false()
	assert_bool(Game.owned_before(&"velociraptor")).is_false()
	for kind: StringName in [&"trainer", &"alpha", &"wild"]:
		assert_int(Game.level_bonus(kind)).is_equal(0)


# ------------------------------------------------------------------ stronger foes

func test_plus_deux_niveaux_aux_dresseurs_et_alphas_plus_un_aux_sauvages() -> void:
	# Arrange
	_finished_game()
	Game.new_game_plus(Game.to_dict())
	# Act + Assert : the kinds, read from a battle's rules
	assert_str(String(Game.foe_kind({"trainer": "Maïa", "catch": false, "run": false}))).is_equal("trainer")
	assert_str(String(Game.foe_kind({"catch": false, "run": false, "size": 1.6}))).is_equal("alpha")
	assert_str(String(Game.foe_kind({}))).is_equal("wild")
	assert_str(String(Game.foe_kind({"lose_spawn": "x", "lesson": ["…"]}))).is_equal("wild")
	assert_int(Game.level_bonus(&"trainer")).is_equal(2)
	assert_int(Game.level_bonus(&"alpha")).is_equal(2)
	assert_int(Game.level_bonus(&"wild")).is_equal(1)
	assert_int(Game.level_bonus(&"autre")).is_equal(0)


func test_un_adversaire_renforce_une_seule_fois() -> void:
	# Arrange
	_finished_game()
	Game.new_game_plus(Game.to_dict())
	var foe := Dino.create(&"triceratops", 12, "Tricératops Alpha")
	foe.hp = roundi(foe.max_hp() * 0.5)
	# Act
	Game.strengthen(foe, &"alpha")
	Game.strengthen(foe, &"alpha")   # (a scene that fights it again: never twice)
	# Assert : two levels up, the moves of its new level, the same share of its HP, the same name
	var same := Dino.create(&"triceratops", 14)
	assert_int(foe.level).is_equal(14)
	assert_array(foe.moves.map(func(m: Dictionary) -> StringName: return m["id"])) \
		.is_equal(same.moves.map(func(m: Dictionary) -> StringName: return m["id"]))
	var half := roundi(foe.max_hp() * 0.5)
	assert_int(foe.hp).is_between(half - 1, half + 1)
	assert_int(foe.max_hp()).is_equal(same.max_hp())
	assert_str(foe.nickname).is_equal("Tricératops Alpha")
	# A wild one: one level; in a first game: nothing.
	var wild := Dino.create(&"protoceratops", 5)
	Game.strengthen(wild, &"wild")
	assert_int(wild.level).is_equal(6)
	Game.new_game()
	var first := Dino.create(&"protoceratops", 5)
	Game.strengthen(first, &"trainer")
	assert_int(first.level).is_equal(5)


# ------------------------------------------------------------------ the egg, the Dinodex

func test_l_oeuf_deja_joue_se_reconnait_et_se_choisit() -> void:
	# Arrange
	_finished_game(&"velociraptor")
	Game.new_game_plus(Game.to_dict())
	# Act
	var known := Prologue.hatchling_text(&"velociraptor")
	var other := Prologue.hatchling_text(&"ankylosaurus")
	# Assert : the one played says so, the others not; chosen all the same, Chloé's thought
	assert_str(known).contains("Il s'appelle Vif.").ends_with(Prologue.KNOWN_HATCHLING)
	assert_str(Prologue.KNOWN_HATCHLING).is_equal("Celui-là, tu le connais.")
	assert_str(other).not_contains(Prologue.KNOWN_HATCHLING)
	assert_array(Prologue.chosen_again_lines(&"velociraptor")).has_size(1)
	assert_str(String(Prologue.chosen_again_lines(&"velociraptor")[0]["who"])).is_equal("Chloé")
	assert_array(Prologue.chosen_again_lines(&"ankylosaurus")).is_empty()
	var vif := Game.give_starter(&"velociraptor")
	assert_object(vif).is_not_null()
	assert_str(String(Game.flag(&"starter"))).is_equal("velociraptor")
	# A first game: nothing said.
	Game.new_game()
	assert_str(Prologue.hatchling_text(&"velociraptor")).not_contains(Prologue.KNOWN_HATCHLING)


func test_le_dinodex_dit_possede_a_la_partie_precedente() -> void:
	# Arrange
	_finished_game()
	Game.new_game_plus(Game.to_dict())
	# Assert : owned before, not seen-only ones; caught again in this game: no longer « before »
	assert_bool(Game.owned_before(&"triceratops")).is_true()
	assert_bool(Game.owned_before(&"protoceratops")).is_true()
	assert_bool(Game.owned_before(&"spinosaurus")).override_failure_message("vu seulement").is_false()
	assert_str(String(DexDB.status(&"triceratops"))).is_equal(String(DexDB.CAUGHT))
	Game.add_caught(Dino.create(&"triceratops", 8))
	assert_bool(Game.owned_before(&"triceratops")).is_false()
	Game.give_starter(&"velociraptor")
	assert_bool(Game.owned_before(&"velociraptor")).is_false()
	assert_bool(Game.owned_before(&"protoceratops")).is_true()


# ------------------------------------------------------------------ the slots

func test_l_emplacement_de_la_partie_finie_n_est_pas_touche() -> void:
	# Arrange : the finished game in slot 1
	_finished_game()
	_save_in(1)
	var finished := _text(1)
	Save.path = Save.path_for(3)
	Game.new_game()
	# Act
	var ok := Save.start_new_game_plus(1, 2)
	# Assert : slot 2 holds the NG+, active and remembered; slot 1 byte for byte the same
	assert_bool(ok).is_true()
	assert_str(_text(1)).override_failure_message("la partie finie a bougé").is_equal(finished)
	assert_int(Save.slot).is_equal(2)
	assert_int(Save.remembered_slot()).is_equal(2)
	var summary := Save.slot_summary(2)
	assert_str(String(summary["state"])).is_equal(Save.READY)
	assert_bool(summary["finished"]).override_failure_message("la nouvelle partie n'est pas finie").is_false()
	assert_str(String(summary["region"])).is_equal(String(Game.START_REGION))
	assert_bool(Save.slot_summary(1)["finished"]).is_true()
	# Loaded back: the same NG+
	Game.new_game()
	assert_bool(Save.load_slot(2)).is_true()
	assert_int(Game.ng_plus()).is_equal(1)
	assert_int(Game.item_count("os_titanosaure")).is_equal(2)
	assert_array(Game.party).is_empty()


func test_refus_sur_la_source_ou_sans_confirmation() -> void:
	# Arrange : 1 finished, 2 an ordinary game, 3 empty
	_finished_game()
	_save_in(1)
	var finished := _text(1)
	Game.new_game()
	Game.give_starter(&"ankylosaurus")
	Game.region_id = &"foret"
	_save_in(2)
	var ordinary := _text(2)
	# Act + Assert
	assert_bool(Save.start_new_game_plus(1, 1, true)).override_failure_message("jamais sur la partie finie").is_false()
	assert_bool(Save.start_new_game_plus(1, 2)).override_failure_message("écraser sans « Oui »").is_false()
	assert_bool(Save.start_new_game_plus(2, 3)).override_failure_message("la partie 2 n'est pas finie").is_false()
	assert_bool(Save.start_new_game_plus(3, 2, true)).override_failure_message("un emplacement vide").is_false()
	assert_bool(Save.start_new_game_plus(1, 4, true)).is_false()
	assert_bool(Save.start_new_game_plus(0, 2, true)).is_false()
	assert_str(_text(1)).is_equal(finished)
	assert_str(_text(2)).is_equal(ordinary)
	assert_bool(FileAccess.file_exists(Save.path_for(3))).is_false()
	assert_str(String(Game.region_id)).override_failure_message("la partie en mémoire intacte").is_equal("foret")
	# « Oui, écraser » : slot 2 replaced, its old game put aside, never lost
	assert_bool(Save.start_new_game_plus(1, 2, true)).is_true()
	assert_str(FileAccess.get_file_as_string(Save.path_for(2) + Save.OLD_COPY)).is_equal(ordinary)
	assert_int(Game.ng_plus()).is_equal(1)


func test_la_nouvelle_partie_plus_survit_a_la_sauvegarde() -> void:
	# Arrange : a NG+ played a little (JSON gives numbers back as floats)
	_finished_game()
	Game.new_game_plus(Game.to_dict())
	Game.give_starter(&"ankylosaurus")
	_save_in(2)
	# Act
	Game.new_game()
	assert_bool(Save.load_slot(2)).is_true()
	# Assert
	assert_int(Game.ng_plus()).is_equal(1)
	assert_int(Game.level_bonus(&"trainer")).is_equal(2)
	assert_array(Game.pages_read_before()).contains(["found_journal_1"])
	assert_bool(Game.egg_known(&"velociraptor")).is_true()
	assert_bool(Game.owned_before(&"triceratops")).is_true()
	assert_bool(Game.owned_before(&"ankylosaurus")).is_false()


# ------------------------------------------------------------------ the old saves

func test_une_ancienne_sauvegarde_se_charge_comme_avant() -> void:
	# Arrange : a save written before the Nouvelle partie+ (no ng_plus, no journal_lu…), and before the slots
	_finished_game()
	var old := {"version": Save.VERSION, "saved_at": 1760000000, "game": Game.to_dict()}
	_write(DIR.path_join("save.json"), JSON.stringify(old))
	Game.new_game()
	# Act
	var went := Save.migrate()
	# Assert : migrated as before, loaded as before, a first game; then a NG+ can start from it
	assert_int(went).is_equal(1)
	assert_bool(Save.load_slot(1)).is_true()
	assert_int(Game.ng_plus()).is_equal(0)
	assert_int(Game.level_bonus(&"wild")).is_equal(0)
	assert_int(Game.party.size()).is_equal(5)
	assert_str(String(Game.region_id)).is_equal("terre_apex")
	assert_bool(Save.slot_summary(1)["finished"]).is_true()
	var migrated := _text(1)
	assert_bool(Save.start_new_game_plus(1, 3)).is_true()
	assert_str(_text(1)).is_equal(migrated)
	assert_int(Game.ng_plus()).is_equal(1)


static func _write(file: String, text: String) -> void:
	var out := FileAccess.open(file, FileAccess.WRITE)
	out.store_string(text)
	out.close()


# ------------------------------------------------------------------ the slots screen

## Slot 1: a finished game; slot 2: a game being played; slot 3: empty.
static func _slots() -> void:
	_finished_game()
	_save_in(1)
	Game.new_game()
	Game.give_starter(&"ankylosaurus")
	Game.region_id = &"foret"
	_save_in(2)


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


func test_le_bouton_seulement_sur_une_partie_finie() -> void:
	# Arrange
	_slots()
	for mode: SaveSlots.Mode in [SaveSlots.Mode.LOAD, SaveSlots.Mode.NEW]:
		# Act
		var screen := await _open(mode)
		# Assert
		var plus := screen.find_child("Plus1", true, false) as Button
		assert_object(plus).override_failure_message("mode %d : le bouton sur la partie finie" % mode).is_not_null()
		assert_str(plus.text).is_equal("Nouvelle partie+")
		assert_bool(plus.disabled).is_false()
		assert_object(screen.find_child("Plus2", true, false)).override_failure_message("partie pas finie").is_null()
		assert_object(screen.find_child("Plus3", true, false)).is_null()
		screen.queue_free()
		await await_idle_frame()
	# In game (« Sauvegarder dans… »): never.
	Save.path = Save.path_for(2)
	var in_game := await _open(SaveSlots.Mode.SAVE_TO)
	assert_object(in_game.find_child("Plus1", true, false)).is_null()


func test_choisir_la_destination_puis_confirmer() -> void:
	# Arrange
	_slots()
	var screen := await _open(SaveSlots.Mode.LOAD)
	# Act : « Nouvelle partie+ » under slot 1
	(screen.find_child("Plus1", true, false) as Button).pressed.emit()
	# Assert : the destination, the finished game not pickable
	assert_int(_picked).is_equal(-1)
	assert_str(_words(screen)).contains("Nouvelle partie+").contains("Le Dinodex, les os et les pages déjà lues restent.")
	assert_bool(screen.card_of(1).disabled).override_failure_message("pas sur la partie finie").is_true()
	assert_str(_words(screen.card_of(1))).contains(SaveSlots.PLUS_SOURCE)
	assert_bool(screen.card_of(3).disabled).is_false()
	assert_object(screen.find_child("Delete2", true, false)).override_failure_message("pas de « Supprimer » ici").is_null()
	# An empty slot: asked all the same, the finished game said untouched
	screen.card_of(3).pressed.emit()
	assert_bool(screen.asking).is_true()
	assert_str(_words(screen)).contains("Recommencer dans l'emplacement 3 ?") \
		.contains("La partie finie de l'emplacement 1 n'est pas touchée.")
	(screen.find_child("No", true, false) as Button).pressed.emit()
	assert_bool(screen.asking).is_false()
	assert_bool(screen.card_of(1).disabled).override_failure_message("« Annuler » : toujours la destination").is_true()
	screen.card_of(3).pressed.emit()
	(screen.find_child("Yes", true, false) as Button).pressed.emit()
	assert_int(_picked).is_equal(3)
	assert_int(screen.plus_from).is_equal(1)


func test_destination_occupee_demande_d_ecraser() -> void:
	_slots()
	var screen := await _open(SaveSlots.Mode.NEW)
	(screen.find_child("Plus1", true, false) as Button).pressed.emit()
	screen.card_of(2).pressed.emit()
	assert_str(_words(screen)).contains("Écraser la partie de l'emplacement 2 ?") \
		.contains("Nouvelle partie+").contains("La partie finie de l'emplacement 1 n'est pas touchée.")
	(screen.find_child("Yes", true, false) as Button).pressed.emit()
	assert_int(_picked).is_equal(2)
	assert_int(screen.plus_from).is_equal(1)


func test_retour_de_la_destination_aux_cartes() -> void:
	_slots()
	var screen := await _open(SaveSlots.Mode.LOAD)
	(screen.find_child("Plus1", true, false) as Button).pressed.emit()
	screen.back()
	assert_int(_picked).override_failure_message("B : retour aux cartes, pas hors de l'écran").is_equal(-1)
	assert_bool(screen.card_of(1).disabled).override_failure_message("en « Charger », la partie finie se charge").is_false()
	assert_object(screen.find_child("Plus1", true, false)).is_not_null()
	assert_int(screen.plus_from).is_equal(0)
	screen.card_of(1).pressed.emit()
	assert_int(_picked).override_failure_message("charger la partie finie, toujours possible").is_equal(1)
	assert_int(screen.plus_from).is_equal(0)
