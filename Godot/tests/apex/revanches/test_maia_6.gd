extends GdUnitTestSuite
## Le défi n° 6 de Maïa (docs/post-game-scenes.md R1), sans fenêtre : son équipe (son œuf, Pouce, Moustique, puis
## Caillou le dernier) et leurs niveaux (ceux que dit sa réplique d'avant), ses règles (MAIA_RULES : le Crâne, la musique
## des rivales), une fois par jour, ce qu'ApexAutour.maia sait trouver (A.from_battles, A.battles_const), le tableau du
## Relais une fois gagné.

const SAVE_PATH := "user://test_gdunit_maia_6_save.json"
const A := preload("res://story/apex.gd")

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)


func after() -> void:
	Save.path = _saved_path
	Game.new_game()


func before_test() -> void:
	Game.new_game()
	Game.set_flag(&"prologue_done")
	Game.set_flag(&"post_game")
	Game.set_flag(&"maia_starter", "parasaurolophus")
	Game.day = 9


func test_son_equipe_et_ses_niveaux() -> void:
	var team := ApexBattles.maia_team()
	var species: Array = team.map(func(m: Array) -> StringName: return m[0])
	assert_array(species).is_equal([&"parasaurolophus", &"iguanodon", &"dimorphodon", &"triceratops"])
	var names: Array = team.map(func(m: Array) -> String: return m[2])
	assert_array(names).is_equal(["Clairon", "Pouce", "Moustique", "Caillou"])
	var levels: Array = team.map(func(m: Array) -> int: return m[1])
	assert_array(levels).override_failure_message("niveaux %s" % [levels]).is_equal([50, 50, 50, 51])
	assert_str(String(team[-1][2])).override_failure_message("Caillou n'est pas le dernier").is_equal("Caillou")
	for m: Array in team:
		var opts: Dictionary = m[3] if m.size() > 3 else {}
		assert_bool(opts.get("corrupted", false)).is_false()


func test_sa_replique_dit_ses_niveaux() -> void:
	var said := String(DialogueRevanches.maia_before()[0]["text"])
	assert_str(said).contains("cinquante, tous les trois")
	assert_str(said).contains("Caillou, cinquante et un")
	var three := ApexBattles.maia_team().slice(0, 3).all(func(m: Array) -> bool: return m[1] == 50)
	assert_bool(three).override_failure_message("« tous les trois » à 50 : faux").is_true()
	assert_int(ApexBattles.maia_team()[-1][1]).is_equal(51)


func test_sans_son_oeuf_trois_dinos() -> void:
	Game.set_flag(&"maia_starter", false)
	var team := ApexBattles.maia_team()
	assert_int(team.size()).is_equal(3)
	assert_str(String(team[-1][2])).is_equal("Caillou")


func test_ses_regles() -> void:
	var rules: Dictionary = ApexBattles.MAIA_RULES
	assert_str(String(rules["lose_spawn"])).is_equal("Crane")
	assert_bool(rules["music"] is AudioStream).is_true()
	assert_str((rules["music"] as AudioStream).resource_path).ends_with("rivale.ogg")
	assert_bool(rules.has("catch") or rules.has("run")).override_failure_message("Story.duel les pose déjà").is_false()


func test_apex_autour_le_trouve() -> void:
	var team = A.from_battles(&"maia_team", [], null)
	assert_bool(team is Array).override_failure_message("ApexAutour.maia ne trouve pas maia_team").is_true()
	assert_int((team as Array).size()).is_equal(4)
	var rules: Dictionary = A.battles_const("MAIA_RULES", {})
	assert_str(String(rules.get("lose_spawn", ""))).is_equal("Crane")


func test_une_fois_par_jour() -> void:
	assert_bool(Revanches.maia_can()).is_true()
	Game.set_flag(&"maia_defi_6_jour", Game.day)
	assert_bool(Revanches.maia_can()).override_failure_message("deux fois le même jour").is_false()
	Game.day += 1
	assert_bool(Revanches.maia_can()).is_true()


func test_le_tableau_du_relais() -> void:
	assert_str(Revanches.relais_line()).is_empty()
	Game.set_flag(&"maia_defi_6")
	assert_str(Revanches.relais_line()).contains("pour l'instant")
	assert_str(Revanches.relais_line()).contains("Maïa")


func test_ses_mots() -> void:
	assert_int(DialogueRevanches.maia_before().size()).is_equal(3)
	assert_int(DialogueRevanches.maia_won().size()).is_equal(3)
	assert_int(DialogueRevanches.maia_lost().size()).is_equal(2)
	assert_str(String(DialogueRevanches.maia_won()[0]["text"])).contains("De peu")
