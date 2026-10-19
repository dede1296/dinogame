extends GdUnitTestSuite
## Les trois emplacements de sauvegarde (core/save_system.gd), sans fenêtre, dans un dossier d'essai
## (user://test_gdunit_emplacements : jamais la partie de Greg) :
## - trois parties indépendantes ; Save.save_game écrit dans l'emplacement actif, et lui seul ;
## - changer d'emplacement en jeu copie la partie en cours, qui s'y sauvegarde ensuite ;
## - écraser ou supprimer une partie est refusé sans confirmation (la partie écrasée est mise de côté) ;
## - l'ancienne save.json devient l'emplacement 1 sans perte (gardée en save.json.migre), ou le premier
##   libre si le 1 est pris ;
## - « Continuer » reprend le dernier emplacement utilisé (le plus récent lisible sinon) ;
## - un emplacement illisible ne gêne pas les autres ; has_save ; le résumé lu sans charger la partie.

const DIR := "user://test_gdunit_emplacements"
const SaveSlots := preload("res://ui/save_slots.gd")

var _saved_path: String
var _before_save: Callable
var _enabled: bool


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
	Game.new_game()


static func _wipe() -> void:
	var d := DirAccess.open(DIR)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)


## A game of its own: Chloé in `region`, her starter (`nickname`) at `level`, `minutes` played.
static func _play(region: StringName, level: int, minutes: float, nickname := "Vif") -> void:
	Game.new_game()
	var d := Game.give_starter(&"velociraptor")
	d.nickname = nickname
	d.level = level
	Game.region_id = region
	Game.play_time = minutes * 60.0
	Game.set_flag(&"prologue_done")


## The game in memory written into slot `n` (as a test tool would: not remembered as the last one).
static func _save_in(n: int) -> void:
	Save.path = Save.path_for(n)
	Save.save_game()


## Three games: the Plaines (Vif, 7), the Forêt (Plume, 15), the Marais (Écho, 22).
static func _three_games() -> void:
	_play(&"plaines", 7, 10.0, "Vif")
	_save_in(1)
	_play(&"foret", 15, 120.0, "Plume")
	_save_in(2)
	_play(&"marais", 22, 300.0, "Écho")
	_save_in(3)


static func _text(n: int) -> String:
	return FileAccess.get_file_as_string(Save.path_for(n))


static func _write(file: String, text: String) -> void:
	var out := FileAccess.open(file, FileAccess.WRITE)
	out.store_string(text)
	out.close()


## The date of slot `n`'s save, set by hand (to order the slots).
static func _stamp(n: int, unix: int) -> void:
	var data: Dictionary = JSON.parse_string(_text(n))
	data["saved_at"] = unix
	_write(Save.path_for(n), JSON.stringify(data))


# ------------------------------------------------------------------ the slots

func test_le_dossier_d_essai_jamais_celui_du_joueur() -> void:
	assert_str(Save.dir).is_equal(DIR)
	assert_str(Save.path).is_equal(DIR + "/save_1.json")
	assert_str(Save.path_for(3)).is_equal(DIR + "/save_3.json")
	# A tool's own file (tools/capture.gd): its slots live beside it, not in the player's folder.
	Save.path = "user://test_gdunit_outil.json"
	assert_str(Save.dir).is_equal("user://test_gdunit_outil_slots")
	assert_str(Save.path_for(2)).is_equal("user://test_gdunit_outil_slots/save_2.json")


func test_trois_emplacements_independants() -> void:
	# Arrange
	_three_games()
	# Act + Assert : each slot gives its own game back
	var want := {1: ["plaines", "Vif", 7], 2: ["foret", "Plume", 15], 3: ["marais", "Écho", 22]}
	for n: int in want:
		Game.new_game()
		assert_bool(Save.load_slot(n)).override_failure_message("emplacement %d : chargement" % n).is_true()
		assert_int(Save.slot).is_equal(n)
		assert_str(String(Game.region_id)).override_failure_message("emplacement %d : zone" % n).is_equal(want[n][0])
		assert_str(Game.lead_dino().nickname).is_equal(want[n][1])
		assert_int(Game.lead_dino().level).is_equal(want[n][2])


func test_save_game_ecrit_dans_l_emplacement_actif() -> void:
	# Arrange
	_three_games()
	var first := _text(1)
	var third := _text(3)
	assert_bool(Save.load_slot(2)).is_true()
	# Act : Chloé goes on, the game saves (any of the game's Save.save_game())
	Game.region_id = &"cote"
	assert_bool(Save.save_game()).is_true()
	# Assert : slot 2 only
	assert_str(String(Save.slot_summary(2)["region"])).is_equal("cote")
	assert_str(_text(1)).override_failure_message("l'emplacement 1 a bougé").is_equal(first)
	assert_str(_text(3)).override_failure_message("l'emplacement 3 a bougé").is_equal(third)


func test_changer_d_emplacement_copie_la_partie() -> void:
	# Arrange : slot 1 played, Chloé has gone on since its last save
	_play(&"plaines", 8, 30.0)
	_save_in(1)
	assert_bool(Save.load_slot(1)).is_true()
	Game.region_id = &"desert"
	# Act : « Sauvegarder dans… » the empty slot 3
	assert_bool(Save.switch_slot(3)).override_failure_message("un emplacement vide : sans question").is_true()
	# Assert : the game as it is now, in slot 3, which is the one from now on
	assert_int(Save.slot).is_equal(3)
	assert_int(Save.remembered_slot()).is_equal(3)
	assert_str(String(Save.slot_summary(3)["region"])).is_equal("desert")
	assert_str(String(Save.slot_summary(1)["region"])).override_failure_message("l'ancien emplacement garde sa partie").is_equal("plaines")
	Game.region_id = &"monts"
	Save.save_game()
	assert_str(String(Save.slot_summary(3)["region"])).override_failure_message("les sauvegardes suivantes vont dans le 3").is_equal("monts")
	assert_str(String(Save.slot_summary(1)["region"])).is_equal("plaines")


func test_ecraser_ou_supprimer_demande_confirmation() -> void:
	# Arrange
	_three_games()
	assert_bool(Save.load_slot(1)).is_true()
	var second := _text(2)
	# Act + Assert : without « Oui », nothing moves
	assert_bool(Save.switch_slot(2)).override_failure_message("écraser sans confirmation").is_false()
	assert_bool(Save.start_new_game(2)).override_failure_message("nouvelle partie sur une partie, sans confirmation").is_false()
	assert_bool(Save.delete_slot(2)).override_failure_message("supprimer sans confirmation").is_false()
	assert_int(Save.slot).is_equal(1)
	assert_str(_text(2)).is_equal(second)
	# Confirmed: slot 2 takes the game of slot 1; its old game is put aside, not lost.
	assert_bool(Save.switch_slot(2, true)).is_true()
	assert_int(Save.slot).is_equal(2)
	assert_str(String(Save.slot_summary(2)["region"])).is_equal("plaines")
	assert_str(FileAccess.get_file_as_string(Save.path_for(2) + Save.OLD_COPY)).is_equal(second)
	assert_bool(Save.delete_slot(3, true)).is_true()
	assert_str(String(Save.slot_summary(3)["state"])).is_equal(Save.EMPTY)
	# In game, never the slot being played (it would be written again at once).
	Save.enabled = true
	assert_bool(Save.delete_slot(2, true)).is_false()
	Save.enabled = false


# ------------------------------------------------------------------ the save from before the slots

func test_l_ancienne_sauvegarde_devient_l_emplacement_1_sans_perte() -> void:
	# Arrange : a save.json as the game wrote it before the slots
	_play(&"havre_dore", 9, 45.0)
	var legacy := JSON.stringify({"version": Save.VERSION, "saved_at": 1760000000, "game": Game.to_dict()})
	_write(DIR.path_join("save.json"), legacy)
	Game.new_game()
	Save.path = Save.path_for(2)   # (whatever was active)
	# Act
	var went := Save.migrate()
	# Assert : slot 1, the very same text; save.json kept as save.json.migre; slot 1 is the one now
	assert_int(went).is_equal(1)
	assert_str(_text(1)).override_failure_message("la copie diffère de l'ancienne sauvegarde").is_equal(legacy)
	assert_bool(FileAccess.file_exists(DIR.path_join("save.json"))).is_false()
	assert_str(FileAccess.get_file_as_string(DIR.path_join("save.json.migre"))).override_failure_message("l'ancien fichier perdu").is_equal(legacy)
	assert_int(Save.slot).is_equal(1)
	assert_int(Save.remembered_slot()).is_equal(1)
	assert_int(Save.continue_slot()).is_equal(1)
	assert_bool(Save.load_slot(1)).is_true()
	assert_str(String(Game.region_id)).is_equal("havre_dore")
	assert_int(Game.lead_dino().level).is_equal(9)
	# Once only.
	assert_int(Save.migrate()).is_equal(0)
	assert_str(_text(1)).is_equal(legacy)


func test_la_migration_n_ecrase_jamais_un_emplacement_pris() -> void:
	# Arrange : slot 1 already holds a game, a save.json.migre is already there
	_play(&"plaines", 5, 10.0)
	_save_in(1)
	var first := _text(1)
	_play(&"foret", 11, 60.0)
	var legacy := JSON.stringify({"version": Save.VERSION, "saved_at": 1760000000, "game": Game.to_dict()})
	_write(DIR.path_join("save.json"), legacy)
	_write(DIR.path_join("save.json.migre"), "ancien")
	# Act
	var went := Save.migrate()
	# Assert : the first free slot, nothing overwritten, both old files kept
	assert_int(went).is_equal(2)
	assert_str(_text(1)).is_equal(first)
	assert_str(_text(2)).is_equal(legacy)
	assert_str(FileAccess.get_file_as_string(DIR.path_join("save.json.migre"))).is_equal("ancien")
	assert_str(FileAccess.get_file_as_string(DIR.path_join("save.json.migre2"))).is_equal(legacy)
	# Every slot taken: save.json stays where it is, untouched.
	_save_in(3)
	_write(DIR.path_join("save.json"), legacy.replace("foret", "cote"))
	assert_int(Save.migrate()).is_equal(0)
	assert_bool(FileAccess.file_exists(DIR.path_join("save.json"))).is_true()


# ------------------------------------------------------------------ « Continuer »

func test_continuer_reprend_le_dernier_emplacement_utilise() -> void:
	# Arrange : three games, the last one played: slot 2
	_three_games()
	assert_bool(Save.load_slot(2)).is_true()
	# Act : the game is started again (the active slot: whatever; save_meta.json says 2)
	Save.path = Save.path_for(1)
	Game.new_game()
	var n := Save.continue_slot()
	# Assert
	assert_int(n).is_equal(2)
	assert_bool(Save.load_slot(n)).is_true()
	assert_str(String(Game.region_id)).is_equal("foret")
	# Slot 2 damaged: the most recently saved game that can be read.
	_stamp(1, 1760000000)
	_stamp(3, 1760009999)
	_write(Save.path_for(2), "{ pas du json")
	assert_int(Save.continue_slot()).is_equal(3)


# ------------------------------------------------------------------ a damaged slot

func test_un_emplacement_illisible_ne_gene_pas_les_autres() -> void:
	# Arrange
	_three_games()
	_write(Save.path_for(2), "{ pas du json")
	assert_bool(Save.load_slot(1)).is_true()
	# Assert : slot 2 unreadable, slots 1 and 3 fine
	assert_str(String(Save.slot_summary(2)["state"])).is_equal(Save.UNREADABLE)
	assert_str(String(Save.slot_summary(1)["state"])).is_equal(Save.READY)
	assert_str(String(Save.slot_summary(3)["state"])).is_equal(Save.READY)
	assert_bool(Save.load_slot(2)).override_failure_message("un emplacement illisible ne se charge pas").is_false()
	assert_int(Save.slot).override_failure_message("l'emplacement actif ne change pas").is_equal(1)
	assert_str(String(Game.region_id)).override_failure_message("la partie en cours intacte").is_equal("plaines")
	assert_bool(Save.load_slot(3)).is_true()
	assert_bool(Save.has_save()).is_true()
	# It can be overwritten (once confirmed) or deleted.
	assert_bool(Save.start_new_game(2)).is_false()
	Game.new_game()
	assert_bool(Save.start_new_game(2, true)).is_true()
	assert_str(String(Save.slot_summary(2)["state"])).is_equal(Save.READY)
	# A save of a newer version of the game: unreadable too, never loaded.
	_write(Save.path_for(1), JSON.stringify({"version": Save.VERSION + 1, "game": {}}))
	assert_str(String(Save.slot_summary(1)["state"])).is_equal(Save.UNREADABLE)


func test_un_json_valide_mais_abime_dit_illisible_sans_planter() -> void:
	# Arrange : valid JSON, wrong types (a version that is not a number, a play time null, a level as text)
	_write(Save.path_for(1), JSON.stringify({"version": {}, "game": "rien"}))
	_write(Save.path_for(2), JSON.stringify({"version": 1, "saved_at": "hier", "game": {"region": 7, "play_time": null,
		"party": [{"level": "dix", "nickname": "Vif"}]}}))
	_write(DIR.path_join(Save.META_FILE), JSON.stringify({"slot": "deux"}))
	# Act
	var first := Save.slot_summary(1)
	var second := Save.slot_summary(2)
	# Assert
	assert_str(String(first["state"])).is_equal(Save.UNREADABLE)
	assert_str(String(second["state"])).is_equal(Save.READY)
	assert_float(float(second["play_time"])).is_equal(0.0)
	assert_int(int(second["lead_level"])).is_equal(1)
	assert_str(String(second["region"])).is_equal(String(Game.START_REGION))
	assert_int(Save.remembered_slot()).is_equal(0)
	assert_int(Save.continue_slot()).is_equal(2)


func test_deux_ecrasements_gardent_les_deux_anciennes_parties() -> void:
	# Arrange : 20 h in slot 1
	_play(&"foret", 30, 1200.0)
	_save_in(1)
	var long_game := _text(1)
	# Act : a new game on slot 1, confirmed; then again
	Game.new_game()
	assert_bool(Save.start_new_game(1, true)).is_true()
	var fresh := _text(1)
	assert_bool(Save.start_new_game(1, true)).is_true()
	# Assert : neither is lost
	assert_str(FileAccess.get_file_as_string(Save.path_for(1) + Save.OLD_COPY)).is_equal(long_game)
	assert_str(FileAccess.get_file_as_string(Save.path_for(1) + Save.OLD_COPY + "2")).is_equal(fresh)


func test_une_migration_deja_copiee_ne_change_pas_la_derniere_partie() -> void:
	# Arrange : save.json already copied into slot 2 (its renaming failed), slot 3 played since
	var legacy := JSON.stringify({"version": Save.VERSION, "saved_at": 1760000000, "game": Game.to_dict()})
	_write(DIR.path_join("save.json"), legacy)
	_write(Save.path_for(2), legacy)
	_play(&"cote", 18, 90.0)
	_save_in(3)
	assert_bool(Save.load_slot(3)).is_true()
	# Act
	var went := Save.migrate()
	# Assert : renamed now, nothing copied twice, the last game played is still slot 3
	assert_int(went).is_equal(2)
	assert_bool(FileAccess.file_exists(DIR.path_join("save.json"))).is_false()
	assert_bool(FileAccess.file_exists(Save.path_for(1))).is_false()
	assert_int(Save.remembered_slot()).is_equal(3)
	assert_int(Save.slot).is_equal(3)


func test_has_save_au_moins_un_emplacement() -> void:
	assert_bool(Save.has_save()).is_false()
	_play(&"plaines", 5, 1.0)
	_save_in(3)
	assert_bool(Save.has_save()).is_true()
	Save.path = Save.path_for(1)
	assert_bool(Save.delete_slot(3, true)).is_true()
	assert_bool(Save.has_save()).is_false()


# ------------------------------------------------------------------ the summary

func test_le_resume_d_un_emplacement_sans_charger_la_partie() -> void:
	# Arrange : a game running (its objective worked out), then the end seen in another slot
	_play(&"plaines", 12, 192.0)
	Save.enabled = true
	var objective := ""
	for o: Dictionary in Objectives.current():
		if o["main"]:
			objective = String(o["title"])
			break
	_save_in(1)
	Save.enabled = false
	Game.set_flag(&"fin_vue")
	_save_in(2)
	Game.new_game()
	var now := int(Time.get_unix_time_from_system())
	# Act
	var s := Save.slot_summary(1)
	# Assert
	assert_str(objective).override_failure_message("un objectif principal au départ").is_not_empty()
	assert_str(String(s["state"])).is_equal(Save.READY)
	assert_str(String(s["region"])).is_equal("plaines")
	assert_str(String(s["region_name"])).is_equal("Prairie du Grand Crâne")
	assert_str(String(s["objective"])).is_equal(objective)
	assert_str(String(s["lead_name"])).is_equal("Vif")
	assert_int(int(s["lead_level"])).is_equal(12)
	assert_float(float(s["play_time"])).is_equal_approx(11520.0, 0.01)
	assert_int(int(s["saved_at"])).is_between(now - 10, now + 1)
	assert_bool(s["finished"]).is_false()
	assert_bool(Save.slot_summary(2)["finished"]).is_true()
	assert_str(String(Save.slot_summary(3)["state"])).is_equal(Save.EMPTY)
	assert_str(String(Game.region_id)).override_failure_message("le résumé ne charge pas la partie").is_equal(String(Game.START_REGION))
	# The words of the screens.
	assert_str(SaveSlots.short_line(s)).is_equal("Prairie du Grand Crâne · 3 h 12")
	assert_str(SaveSlots.time_text(30.0)).is_equal("moins d'une minute")
	assert_str(SaveSlots.time_text(12.0 * 60.0)).is_equal("12 min")
	assert_str(SaveSlots.time_text(3600.0 + 5.0 * 60.0)).is_equal("1 h 05")
	assert_str(SaveSlots.date_text(0)).is_empty()
	assert_str(SaveSlots.date_text(now)).starts_with("le ")
