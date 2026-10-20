extends GdUnitTestSuite
## Brac sur la jetée (docs/post-game-scenes.md § B, post-game-plan.md § 5), sans fenêtre : ce que joue
## une parole à Brac selon l'histoire (rien avant qu'il parte ; « Le phare qui boude » une fois, puis
## ses répliques ; le matin de la jetée ; « Le partage » une fois, de jour seulement ; ses répliques de
## gardien) ; les bulles et les drapeaux de chaque scène (jamais plus de 10 d'affilée) ; ses trois bêtes
## présentées avec leurs vraies espèces (celles de son équipe des forges) ; une ligne par bête et pour
## le panneau BARC, Mastoc de jour et de nuit ; les images ou leur repli ; tout posé sur la jetée, loin
## de l'embarcadère de la barque de Maïa ; la table des drapeaux du document confrontée au code.

const BJ := preload("res://story/brac_jetee.gd")
const DB := preload("res://data/dialogue_brac.gd")
const DOC := "res://docs/post-game-scenes.md"
const TABLE_TITLE := "## Carte des drapeaux, objets, événements"
const SCRIPTS := ["res://story/brac_jetee.gd", "res://data/dialogue_brac.gd"]
const PORT := "res://regions/port/port_ambre.tscn"
const SAVE_PATH := "user://test_gdunit_brac_jetee.json"
const MAX_BULLES := 10
const TILE := 48.0
## Les images du lot A' (livrées le 20/10) ; tant que Prop.KINDS ne connaît pas un genre, le jeu prend un
## repli (ou rien, pour le sandwich).
const ATTENDUES := ["props/sandwich.png", "props/panneau_barc.png", "characters/brac_gardien.png"]

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
	Game.give_starter(&"parasaurolophus")
	Game.clock = 11.0 * 60.0


static func bulles(steps: Array) -> int:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("text") or s.has("text_fn")).size()


static func drapeaux(steps: Array) -> Array:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("flag")).map(func(s: Dictionary) -> String: return String(s["flag"]))


static func textes(steps: Array) -> String:
	return " ".join(steps.filter(func(s: Dictionary) -> bool: return s.has("text")).map(func(s: Dictionary) -> String: return String(s["text"])))


static func _apres_la_fin() -> void:
	for f in [&"brac_parti", &"epilogue_cabinet", &"epilogue_port", &"epilogue_fini", &"post_game"]:
		Game.set_flag(f)


# ------------------------------------------------------------------ ce que joue une parole à Brac

func test_rien_avant_que_brac_parte() -> void:
	assert_bool(BJ.takes_over()).is_false()
	assert_str(String(BJ.moment())).override_failure_message("Brac n'est pas encore sur la jetée").is_empty()
	await BJ.talk(null)   # (rien ne joue : pas de bulle, pas d'attente)
	assert_bool(Game.flag(&"brac_jetee_vu")).is_false()


func test_le_phare_une_fois_puis_ses_repliques() -> void:
	Game.set_flag(&"brac_parti")
	assert_bool(BJ.takes_over()).is_true()
	assert_str(String(BJ.moment())).is_equal("phare")
	Game.set_flag(&"brac_jetee_vu")
	assert_str(String(BJ.moment())).override_failure_message("la scène vue : une réplique par visite").is_equal("avant")
	Game.set_flag(&"epilogue_cabinet")
	assert_str(String(BJ.moment())).override_failure_message("le matin de la jetée : la scène de l'épilogue").is_equal("jetee")


func test_le_phare_ne_joue_plus_le_matin_de_la_jetee() -> void:
	Game.set_flag(&"brac_parti")
	Game.set_flag(&"epilogue_cabinet")
	assert_str(String(BJ.moment())).override_failure_message("jamais vu, mais l'épilogue a commencé").is_equal("jetee")


func test_le_partage_de_jour_une_fois_puis_le_gardien() -> void:
	_apres_la_fin()
	assert_str(String(BJ.moment())).override_failure_message("11 h : le partage").is_equal("partage")
	Game.clock = 6.0 * 60.0
	assert_str(String(BJ.moment())).override_failure_message("l'aube compte comme le jour").is_equal("partage")
	Game.clock = 22.0 * 60.0
	assert_bool(BJ.is_night()).is_true()
	assert_str(String(BJ.moment())).override_failure_message("22 h : il travaille, pas de partage").is_equal("gardien")
	Game.clock = 11.0 * 60.0
	Game.set_flag(&"brac_sandwich_partage")
	assert_str(String(BJ.moment())).override_failure_message("partagé : ses répliques de gardien").is_equal("gardien")


func test_le_partage_sans_avoir_vu_le_phare() -> void:
	_apres_la_fin()
	assert_bool(Game.flag(&"brac_jetee_vu")).is_false()
	assert_str(String(BJ.moment())).is_equal("partage")


# ------------------------------------------------------------------ B1, le phare qui boude

func test_le_phare_dix_bulles_et_son_drapeau() -> void:
	for roc: bool in [true, false]:
		var lines := DB.phare(roc)
		assert_int(bulles(lines)).override_failure_message("roc_brac_parti=%s" % roc).is_equal(10)
		assert_array(drapeaux(lines)).contains_exactly(["brac_jetee_vu"])
		assert_str(String(lines[2]["text"])).contains("J'ai levé le sandwich. Ils ont regardé. J'ai reposé le sandwich.")
		assert_str(String(lines[2].get("cue", ""))).override_failure_message("le sandwich se lève à cette bulle").is_equal("leve")


func test_le_phare_selon_ce_que_chloe_a_entendu() -> void:
	var heard := DB.phare(true)
	assert_str(String(heard[1]["who"])).is_equal("Chloé")
	assert_str(String(heard[1]["text"])).contains("Roc a dit")
	assert_str(String(heard[2]["text"])).override_failure_message("Léonce est sur le ponton, derrière Brac : il l'a vu de dos") \
		.contains("Léonce me voit de dos")
	var not_heard := DB.phare(false)
	assert_str(textes(not_heard)).override_failure_message("sans Roc, personne ne parle de lui").not_contains("Roc")
	assert_str(String(not_heard[1]["text"])).contains("sandwich")


func test_les_trois_betes_avec_leurs_vraies_especes() -> void:
	var said := textes(DB.phare(true))
	for pair: Array in [["Mastoc", "Allosaure"], ["Cabosse", "Stygimoloch"], ["Grognon", "Majungasaurus"]]:
		assert_str(said).contains(pair[0]).contains(pair[1])
	assert_str(said).override_failure_message("Mastoc était petit dans la Forêt : pas « le plus vieux »").not_contains("le plus vieux")
	# Les mêmes que son équipe des forges (VolcanBattles.brac_team), et des espèces que le jeu connaît.
	for m: Array in VolcanBattles.brac_team():
		var key := String(m[2]).to_lower()
		if BJ.SPECIES.has(key):
			assert_str(String(BJ.SPECIES[key])).override_failure_message("%s" % m[2]).is_equal(String(m[0]))
	for k: String in BJ.SPECIES:
		assert_bool(SpeciesDB.PATHS.has(BJ.SPECIES[k])).override_failure_message("%s : espèce inconnue" % k).is_true()


func test_ses_repliques_avant_la_fin() -> void:
	assert_int(DB.avant_pool(false).size()).is_equal(3)
	var after_crater := DB.avant_pool(true)
	assert_int(after_crater.size()).is_equal(2)
	assert_str(" ".join(after_crater)).override_failure_message("le cratère fini : plus de « Quand tu auras fini »").not_contains("Quand tu auras fini")
	var said: Array = []
	for i in 3:
		said.append(ForetCamp.next_line(&"brac_jetee_avant_n", DB.avant_pool(false)))
	assert_array(said).contains_exactly_in_any_order(DB.AVANT)


# ------------------------------------------------------------------ B2, le partage

func test_le_partage_six_bulles_et_son_drapeau() -> void:
	var lines := DB.partage()
	assert_int(bulles(lines)).is_equal(6)
	assert_array(drapeaux(lines)).contains_exactly(["brac_sandwich_partage"])
	assert_str(textes(lines)).contains("Ils me regardent. Pas le sandwich. Moi.").contains("en quatre").contains("meilleur sandwich du monde")


# ------------------------------------------------------------------ B3, les bêtes et le panneau

func test_une_ligne_par_bete_mastoc_de_jour_et_de_nuit() -> void:
	# (Un dino ne se couche que s'il dort : de jour il dort, de nuit il veille, debout.)
	assert_str(DB.bete(&"mastoc_jetee", false)).contains("Mastoc").contains("dort au pied de la lanterne")
	assert_str(DB.bete(&"mastoc_jetee", true)).contains("Mastoc").contains("allumée").contains("Il ne dort pas")
	assert_str(DB.bete(&"mastoc_jetee", true)).not_contains("couché")
	assert_str(DB.bete(&"cabosse_jetee", false)).contains("Cabosse")
	assert_str(DB.bete(&"grognon_jetee", true)).contains("Grognon")
	assert_str(DB.bete(&"autre_chose", false)).is_empty()
	assert_array(BJ.BEASTS.keys().map(func(e: StringName) -> String: return String(e))) \
		.contains_exactly_in_any_order(["mastoc_jetee", "cabosse_jetee", "grognon_jetee"])


func test_le_panneau_barc() -> void:
	assert_str(DB.PANNEAU).contains("BARC").contains("Roc")
	assert_str(String(BJ.PANNEAU_EVENT)).is_equal("panneau_barc")


# ------------------------------------------------------------------ la mise en scène, les règles

func test_les_scenes_restent_courtes() -> void:
	for lines: Array in [DB.phare(true), DB.phare(false), DB.partage()]:
		assert_int(bulles(lines)).is_less_equal(MAX_BULLES)


func test_les_gestes_ne_vont_pas_a_la_boite_de_dialogue() -> void:
	var plain := BJ.staged(DB.phare(true), {})
	assert_bool(plain.any(func(s: Dictionary) -> bool: return s.has("cue"))).is_false()
	var moved := BJ.staged(DB.phare(true), {"leve": func() -> void: pass, "mer": func() -> void: pass})
	assert_int(bulles(moved)).is_equal(10)
	assert_int(moved.filter(func(s: Dictionary) -> bool: return s.has("text_fn")).size()).is_equal(2)
	assert_bool(moved.any(func(s: Dictionary) -> bool: return s.has("cue"))).is_false()
	assert_array(drapeaux(moved)).contains_exactly(["brac_jetee_vu"])


func test_les_images_ou_leur_repli() -> void:
	assert_str(BJ.thing_kind(BJ.PANNEAU_KINDS)).override_failure_message("le panneau : le sien ou un panneau de l'île").is_not_empty()
	assert_str(BJ.thing_kind(BJ.LANTERNE_KINDS)).override_failure_message("la grande lanterne de la jetée").is_not_empty()
	assert_str(BJ.thing_kind(["pas_une_image"])).is_empty()
	var missing := ATTENDUES.filter(func(p: String) -> bool: return not ResourceLoader.exists("res://assets/art/" + p))
	assert_array(missing).override_failure_message("images du lot A' manquantes : %s" % [missing]).is_empty()
	for k: String in ["sandwich", "panneau_barc"]:
		if not Prop.KINDS.has(k):
			prints("   %s : image livrée, pas encore dans Prop.KINDS (patch_E § 7) : repli en attendant" % k)


## La planche de nuit : la même grille que brac.png (4 × 4), la même hauteur d'image.
func test_la_planche_de_gardien_a_la_grille_de_brac() -> void:
	var night := load("res://assets/art/characters/%s.png" % BJ.NIGHT_SHEET) as Texture2D
	var day := load("res://assets/art/characters/brac.png") as Texture2D
	assert_object(night).is_not_null()
	if night and day:
		assert_int(night.get_height()).is_equal(day.get_height())
		assert_int(night.get_width() % 4).is_equal(0)
		assert_int(night.get_height() % 4).is_equal(0)


## Mastoc et les objets sur les planches de la jetée ; Cabosse et Grognon sur le quai, à terre (pas dans
## l'eau, pas sur la jetée qu'ils bloqueraient) ; tous loin de l'embarcadère de la barque et de Léonce.
func test_tout_est_a_sa_place_loin_de_l_embarcadere() -> void:
	var r := Region.open_for_preview(PORT)
	var brac := r.get_node_or_null("Entities/BracJetee") as Node2D
	var dock := r.get_node_or_null("Ponton") as Node2D
	var landing := r.get_node_or_null("Spawns/Embarcadere") as Node2D
	var leonce := r.get_node_or_null("Entities/Leonce") as Node2D
	for n in [brac, dock, landing, leonce]:
		assert_object(n).is_not_null()
	if brac and dock and landing and leonce:
		var planks := Rect2(dock.position / TILE, dock.get("size"))
		for k: String in BJ.AROUND:
			var at: Vector2 = BJ.spot(k, brac.position) / TILE
			var on_pier: bool = k in BJ.ON_PIER
			assert_bool(planks.has_point(at)).override_failure_message("%s : %s, jetée %s" % [k, at, planks]).is_equal(on_pier)
			if not on_pier:
				var ground := String(r.terrain.get_cell_tile_data(Vector2i(at.floor())).get_custom_data("terrain"))
				assert_bool(ground in Story.OPEN_GROUND).override_failure_message("%s sur « %s »" % [k, ground]).is_true()
			assert_float(at.distance_to(landing.position / TILE)).override_failure_message("%s sur le chemin de la barque" % k).is_greater(1.5)
			assert_float(at.distance_to(leonce.position / TILE)).override_failure_message("%s sur Léonce" % k).is_greater(1.4)
	r.free()


# ------------------------------------------------------------------ la table du document, le code

func test_les_scripts_se_compilent() -> void:
	for p: String in SCRIPTS:
		var script := load(p) as GDScript
		assert_object(script).override_failure_message("%s ne se charge pas" % p).is_not_null()
		if script:
			assert_bool(script.can_instantiate()).override_failure_message("%s ne compile pas" % p).is_true()


func test_les_drapeaux_des_scenes_b_sont_dans_le_code() -> void:
	var code := ""
	for p: String in SCRIPTS:
		code += FileAccess.get_file_as_string(p)
	var rows := _rows_b()
	assert_int(rows.size()).override_failure_message("les lignes B1-B3 de la table").is_equal(3)
	var missing: Array[String] = []
	for flag: String in rows.reduce(func(acc: Array, r: Array) -> Array: return acc + r, []):
		if not code.contains("\"%s\"" % flag):
			missing.append(flag)
	assert_array(missing).override_failure_message("drapeaux de la table absents du code : %s" % [missing]).is_empty()


## Les drapeaux (colonne 2) des lignes « B… » de la table du document.
func _rows_b() -> Array:
	var out: Array = []
	var text := FileAccess.get_file_as_string(DOC)
	var at := text.find(TABLE_TITLE)
	if at < 0:
		return out
	var tick := RegEx.create_from_string("`([a-z0-9_]+)`")
	var started := false
	for line in text.substr(at).split("\n").slice(1):
		if not line.begins_with("|"):
			if started:
				break   # (the table is over: the next tables of the document are not this one)
			continue
		started = true
		var cells := line.split("|")
		if cells.size() < 5 or not cells[1].strip_edges().begins_with("B"):
			continue
		out.append(tick.search_all(cells[2]).map(func(m: RegExMatch) -> String: return m.get_string(1)))
	return out
