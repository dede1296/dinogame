extends GdUnitTestSuite
## Le parcours de sécurité, la chaîne des chapitres 6 → 9 (sans fenêtre, rien n'est joué ni affiché) : à
## chaque étape majeure, la partie est remise dans l'état d'un joueur arrivé là (les drapeaux que les
## scènes ont posés, les objets, l'équipe, la zone où Chloé se tient ; puis les ouvertures que
## Story._on_zone_entered recalcule en entrant dans une zone : Monts/Cieux/Volcan.update_access), et on
## vérifie :
## - l'objectif principal (Objectives.current) : jamais vide avant la fin, celui qu'on attend à ce moment
##   (l'enchaînement de MontsObjectives → CieuxObjectives → VolcanObjectives → ApexObjectives) ; sa zone
##   existe, son repère est dans la carte de sa zone ;
## - il n'est pas impossible : depuis là où Chloé se tient, on atteint À PIED sa zone et son repère
##   (tests/parcours/outils_parcours.gd : le relief, la lave sur le dos du dino de tête, la lave qui se
##   retire, les décors de l'histoire présents, et les sorties ouvertes de toute l'île) ;
## - les huit portes de la chaîne (outils_parcours.gd GATES) : ouvertes quand elles doivent l'être,
##   fermées sinon ; fermées, leur dialogue de refus existe (DialogueDB.lines n'est pas vide).
## Un écart est un résultat : rien n'est corrigé ici.

const U := preload("res://tests/parcours/outils_parcours.gd")
const SAVE_PATH := "user://test_gdunit_parcours_chaine.json"

## Ce qu'un joueur a posé aux chapitres 1 à 5 (les routes, les Sceaux, les Cœurs, les pages ; de quoi
## que Objectives._main passe jusqu'au chapitre 6 : CoteObjectives.main → MontsObjectives.main).
const BASE := [
	&"prologue_arrived", &"prologue_done", &"maia_left", &"tuto_commandes", &"met_maia",
	&"ecaille_bosquet", &"ecaille_grotte", &"ecaille_falaises", &"crane_ouvert", &"sceau_plaines",
	&"maia_defi_1", &"roc_parti_vu", &"havre_arrive", &"selle_demandee", &"selle", &"gaspard_battu", &"lilou_battu",
	&"foret_arrivee", &"griffe_grise_vu", &"clairiere_vue", &"mur_camp_brise", &"camp_arrive", &"sbire_camp_1_battu",
	&"sbire_camp_2_battu", &"brac_battu", &"sceau_foret", &"masque_vu", &"maia_pont_vue", &"maia_defi_2",
	&"tiroir_flaire", &"ambre_noir_tiroir", &"marais_arrivee", &"joss_marais_vu", &"gilet_nage", &"porte_voix_ouverte",
	&"voix_rencontree", &"dame_suie_battue", &"temple_ouvert", &"temple_arrive", &"temple_vanne_1", &"temple_vanne_2",
	&"temple_vanne_3", &"fresques_vues", &"sceau_marais", &"coeur_1", &"roc_marais_vu", &"maia_defi_3",
	&"desert_arrivee", &"sirocco_vue", &"brac_desert_vu", &"brac_desert_battu", &"sanctuaire_ouvert", &"sceau_desert",
	&"coeur_2", &"maia_defi_4", &"cote_annonce", &"cote_ouverte", &"cote_arrivee", &"pecheurs_vus", &"joss_cote_vu",
	&"cache_vue", &"passeur_battu", &"masque_plongee", &"passe_recif", &"mosasaure_battu", &"coeur_3", &"sceau_cote",
	&"moustique_vu", &"maia_enfuie", &"roc_sceau_cote", &"roc_carte_intacte", &"roc_isaure",
	&"found_journal_1", &"found_journal_2", &"found_journal_3", &"found_journal_4", &"found_journal_5", &"found_journal_6",
	&"found_journal_7", &"found_journal_8", &"found_journal_9", &"found_journal_10", &"found_journal_11", &"found_journal_12",
	&"found_journal_13", &"found_journal_14", &"found_journal_15", &"found_journal_16", &"found_journal_17",
	&"found_journal_18", &"found_journal_19", &"found_journal_20", &"found_journal_21", &"found_journal_22",
	&"found_journal_23", &"found_journal_24", &"found_journal_25",
]

## Les étapes, dans l'ordre de l'histoire. Chacune ajoute à la précédente : « plus » (drapeaux), « objets »
## (id -> nombre, négatif : retiré), « equipe » ([espèce, niveau, nom] attrapés), « boite » (noms envoyés au
## Cabinet), « quitte » (noms partis), « tete » (le dino mis en tête). Chloé se tient dans « zone », à
## l'arrivée « depuis ». « main » : l'objectif principal attendu (""= aucun : la fin) ; « ouvertes » : les
## portes de la chaîne ouvertes (les autres fermées).
const STAGES := [
	# ---- Chapitre 6, les Monts Gelés (MontsObjectives)
	{"nom": "ch6 : Maïa enfuie, pas de manteau", "zone": &"cote", "depuis": &"DepuisGrottes", "plus": [],
		"main": "manteau", "ouvertes": []},
	{"nom": "ch6 : le manteau acheté", "zone": &"cote", "depuis": &"DepuisGrottes", "plus": [&"joss_manteau_vu"],
		"objets": {"manteau_duvet": 1}, "main": "monts", "ouvertes": ["monts"]},
	{"nom": "ch6 : arrivée aux Monts", "zone": &"monts", "depuis": &"DepuisCote", "plus": [&"monts_arrivee"],
		"main": "bertille", "ouvertes": ["monts"]},
	{"nom": "ch6 : Bertille vue", "zone": &"monts", "depuis": &"DepuisCote", "plus": [&"bertille_vue", &"grelot_vu"],
		"main": "glacier", "ouvertes": ["monts"]},
	{"nom": "ch6 : le glacier, personne pour charger", "zone": &"monts", "depuis": &"DepuisCote", "plus": [&"glacier_arrivee"],
		"main": "charge", "ouvertes": ["monts"]},
	{"nom": "ch6 : un Tricératops attrapé (charge)", "zone": &"monts", "depuis": &"DepuisCote", "plus": [],
		"equipe": [[&"triceratops", 30, "Corne"]], "main": "grottes", "ouvertes": ["monts"]},
	{"nom": "ch6 : les grottes de glace", "zone": &"grottes_glace", "depuis": &"DepuisMonts",
		"plus": [&"mur_glace_1_brise", &"mur_glace_2_brise", &"grelot_rentre", &"grottes_glace_arrivee"],
		"main": "suie", "ouvertes": ["monts"]},
	{"nom": "ch6 : Dame Suie battue", "zone": &"grottes_glace", "depuis": &"DepuisMonts",
		"plus": [&"suie_monts_vue", &"suie_indice", &"suie_monts_battue", &"suie_monts_partie", &"found_journal_26"],
		"main": "dormeurs", "ouvertes": ["monts"]},
	{"nom": "ch6 : les dormeurs réveillés", "zone": &"monts", "depuis": &"DepuisGrottes", "plus": [&"dormeurs_reveilles", &"found_journal_29"],
		"main": "col", "ouvertes": ["monts"]},
	{"nom": "ch6 : Roc au col", "zone": &"monts", "depuis": &"DepuisGrottes",
		"plus": [&"blizzard_col", &"roc_col_vu", &"roc_innocente", &"porte_givre_vue", &"found_journal_28"],
		"main": "porte", "ouvertes": ["monts"]},
	{"nom": "ch6 : la porte de givre fondue", "zone": &"monts", "depuis": &"DepuisGrottes", "plus": [&"sanctuaire_givre_ouvert"],
		"main": "sanctuaire", "ouvertes": ["monts", "givre"]},
	{"nom": "ch6 : le sanctuaire de Givre", "zone": &"sanctuaire_givre", "depuis": &"DepuisMonts", "plus": [&"sanctuaire_givre_arrivee"],
		"main": "titan", "ouvertes": ["monts", "givre"]},
	{"nom": "ch6 : le Titan battu", "zone": &"sanctuaire_givre", "depuis": &"DepuisMonts",
		"plus": [&"titan_parle", &"titan_battu", &"found_journal_27"], "main": "coeur_4", "ouvertes": ["monts", "givre"]},
	{"nom": "ch6 : le quatrième Cœur", "zone": &"monts", "depuis": &"DepuisSanctuaire", "plus": [&"coeur_4", &"sceau_monts"],
		"objets": {"sceau_monts": 1}, "main": "maia_5", "ouvertes": ["monts", "givre"]},
	{"nom": "ch6 FIN : Maïa alliée", "zone": &"monts", "depuis": &"DepuisSanctuaire",
		"plus": [&"maia_monts_vue", &"maia_defi_5", &"maia_alliee", &"masque_rendu", &"found_journal_30", &"forges_vues"],
		"main": "harnais", "ouvertes": ["monts", "givre"], "fin": 6},
	# ---- Chapitre 7, les Cieux Éternels (CieuxObjectives)
	{"nom": "ch7 : le harnais, pas de grand ptérosaure", "zone": &"havre_dore", "depuis": &"DepuisPort", "plus": [&"harnais_vol"],
		"objets": {"harnais_vol": 1}, "main": "porteur", "ouvertes": ["monts", "givre"]},
	{"nom": "ch7 : un Ptéranodon adulte attrapé", "zone": &"cote", "depuis": &"DepuisGrottes", "plus": [],
		"equipe": [[&"pteranodon", 40, "Plume"]], "main": "cieux", "ouvertes": ["monts", "givre", "cieux"]},
	{"nom": "ch7 : arrivée aux Cieux", "zone": &"cieux", "depuis": &"DepuisMonts", "plus": [&"maia_cieux_plan", &"cieux_arrivee"],
		"main": "nids", "ouvertes": ["monts", "givre", "cieux"]},
	{"nom": "ch7 : les nids géants", "zone": &"nids_geants", "depuis": &"DepuisCieux",
		"plus": [&"pont_lianes_vu", &"found_journal_31", &"nids_arrivee"], "main": "roi", "ouvertes": ["monts", "givre", "cieux"]},
	{"nom": "ch7 : le Roi, le Sceau et le Vol", "zone": &"nids_geants", "depuis": &"DepuisCieux",
		"plus": [&"quetzal_roi_parle", &"quetzal_roi_confiance", &"quetzal_roi_battu", &"sceau_cieux", &"vol_obtenu", &"found_journal_32"],
		"objets": {"sceau_cieux": 1}, "main": "arche", "ouvertes": ["monts", "givre", "cieux", "arche"]},
	{"nom": "ch7 : l'Arche du Vent", "zone": &"arche_du_vent", "depuis": &"DepuisNids", "plus": [&"arche_arrivee"],
		"main": "masque", "ouvertes": ["monts", "givre", "cieux", "arche"]},
	{"nom": "ch7 FIN : le masque est tombé", "zone": &"arche_du_vent", "depuis": &"DepuisNids",
		"plus": [&"arche_piege", &"masque_arche_battu", &"coeurs_voles", &"masque_tombe", &"moustique_confie", &"masque_carton_confie",
			&"found_journal_34"],
		"objets": {"masque_carton": 1}, "equipe": [[&"dimorphodon", 36, "Moustique"]],
		"main": "descente", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan"], "fin": 7},
	# ---- Chapitre 8, la Plaine Volcanique (VolcanObjectives)
	{"nom": "ch8 : les champs de cendre", "zone": &"champs_cendres", "depuis": &"DepuisArche",
		"plus": [&"descente_cendre", &"cendres_arrivee", &"traces_vues"], "main": "corrompu",
		"ouvertes": ["monts", "givre", "cieux", "arche", "volcan"]},
	{"nom": "ch8 : Numéro 3 apaisé", "zone": &"champs_cendres", "depuis": &"DepuisArche", "plus": [&"premier_corrompu_volcan"],
		"main": "forges", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan"]},
	{"nom": "ch8 : les forges", "zone": &"forges_ombre", "depuis": &"DepuisChamps", "plus": [&"forges_arrivee", &"leonce_vu"],
		"main": "petites_forges", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan"]},
	{"nom": "ch8 : deux petites forges éteintes", "zone": &"forges_ombre", "depuis": &"DepuisChamps",
		"plus": [&"forge_1_eteinte", &"forge_2_eteinte"], "main": "petites_forges", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan"]},
	{"nom": "ch8 : la barricade tombée", "zone": &"forges_ombre", "depuis": &"DepuisChamps",
		"plus": [&"forge_3_eteinte", &"petites_forges_eteintes", &"barricade_tombee"], "main": "brac",
		"ouvertes": ["monts", "givre", "cieux", "arche", "volcan"]},
	{"nom": "ch8 : Brac vaincu", "zone": &"forges_ombre", "depuis": &"DepuisChamps", "plus": [&"brac_volcan_vu", &"brac_vaincu"],
		"main": "suie", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan"]},
	{"nom": "ch8 : Dame Suie partie", "zone": &"forges_ombre", "depuis": &"DepuisChamps",
		"plus": [&"brac_parti", &"masque_brac_vu", &"suie_volcan_vue", &"suie_alliee", &"grande_forge_eteinte", &"found_journal_37", &"suie_partie"],
		"objets": {"antidote_ambre": 1, "lettre_isaure": 1}, "main": "coulees",
		"ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees"]},
	{"nom": "ch8 : les coulées, un Saichania en tête", "zone": &"coulees_lave", "depuis": &"DepuisForges", "plus": [&"coulees_arrivee"],
		"boite": ["Corne"], "equipe": [[&"saichania", 44, "Caillasse"]], "tete": "Caillasse", "main": "coulees",
		"ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees"]},
	{"nom": "ch8 : la lave franchie", "zone": &"coulees_lave", "depuis": &"DepuisForges", "plus": [&"lave_franchie", &"found_journal_36"],
		"main": "sanctuaire", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees"]},
	{"nom": "ch8 : le sanctuaire de Magma", "zone": &"sanctuaire_magma", "depuis": &"DepuisCoulees", "plus": [&"sanctuaire_magma_arrivee"],
		"main": "trex", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees"]},
	{"nom": "ch8 : le T-Rex de Magma battu", "zone": &"sanctuaire_magma", "depuis": &"DepuisCoulees",
		"plus": [&"flaque_tremble", &"trex_magma_parle", &"trex_magma_battu"], "main": "coeur",
		"ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees"]},
	{"nom": "ch8 : le cinquième Cœur, la lave retirée", "zone": &"coulees_lave", "depuis": &"DepuisSanctuaire",
		"plus": [&"sceau_volcan", &"coeur_5", &"found_journal_35", &"lave_retiree"], "objets": {"sceau_volcan": 1, "coeur_5": 1},
		"main": "porte", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte"]},
	{"nom": "ch8 : la porte du cratère", "zone": &"porte_cratere", "depuis": &"DepuisCoulees", "plus": [&"porte_arrivee"],
		"main": "isaure", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte"]},
	{"nom": "ch8 FIN : Isaure et Maïa devant la porte", "zone": &"porte_cratere", "depuis": &"DepuisCoulees",
		"plus": [&"found_journal_38", &"isaure_porte_vue", &"marche_refuse", &"lettre_isaure_donnee", &"maia_porte_vue", &"apex_bloque"],
		"objets": {"lettre_isaure": -1}, "main": "aube", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte"],
		"fin": 8},
	# ---- Chapitre 9, la Terre des Apex, et l'épilogue (ApexObjectives)
	{"nom": "ch9 : le duel d'Isaure gagné", "zone": &"porte_cratere", "depuis": &"DepuisCoulees",
		"plus": [&"apex_aube", &"isaure_pari", &"isaure_aveu_oeuf", &"isaure_vaincue"], "main": "porte_apex",
		"ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte"]},
	{"nom": "ch9 : la porte ouverte", "zone": &"porte_cratere", "depuis": &"DepuisCoulees",
		"plus": [&"apex_decision", &"coeurs_rendus", &"apex_ouvert"], "objets": {"coeur_5": -1}, "main": "terre_apex",
		"ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte", "apex"]},
	{"nom": "ch9 : la Terre des Apex", "zone": &"terre_apex", "depuis": &"DepuisPorte", "plus": [&"apex_arrivee"],
		"main": "fond", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte", "apex"]},
	{"nom": "ch9 : le bloc, les trois essais", "zone": &"coeur_apex", "depuis": &"DepuisTerre",
		"plus": [&"found_journal_39", &"bloc_geant_vu", &"coeur_apex_arrivee", &"helene_vue", &"essai_griffes", &"essai_charge", &"essai_chant", &"essais_finis"],
		"main": "fond", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte", "apex"]},
	{"nom": "ch9 : le Souverain réveillé", "zone": &"coeur_apex", "depuis": &"DepuisTerre",
		"plus": [&"goutte_noire", &"souverain_eveille", &"helene_sortie", &"caillou_rempart", &"starter_lien_5"], "main": "souverain",
		"ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte", "apex"]},
	{"nom": "ch9 : le Souverain apaisé", "zone": &"coeur_apex", "depuis": &"DepuisTerre", "plus": [&"souverain_apaise"],
		"objets": {"antidote_ambre": -1}, "main": "fond", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte", "apex"]},
	{"nom": "ch9 : Hélène, le Cabinet trois jours plus tard", "zone": &"cabinet", "depuis": &"Depart",
		"plus": [&"helene_liberee", &"helene_reveillee", &"moustique_rendu", &"masque_carton_rendu", &"masque_carton_pris", &"apex_fini"],
		"objets": {"masque_carton": -1}, "quitte": ["Moustique"], "main": "cabinet_epilogue",
		"ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte", "apex"]},
	{"nom": "ch9 : le thé, la tasse bleue", "zone": &"cabinet", "depuis": &"Depart",
		"plus": [&"isaure_cabinet", &"tasse_bleue", &"lettre_lue", &"reserve_dite"], "main": "marche",
		"ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte", "apex"]},
	{"nom": "ch9 : la marche, demain la jetée", "zone": &"port_ambre", "depuis": &"DepuisCabinet", "plus": [&"epilogue_cabinet"],
		"main": "jetee", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte", "apex"]},
	{"nom": "ch9 FIN : la page 40", "zone": &"port_ambre", "depuis": &"DepuisCabinet",
		"plus": [&"epilogue_port", &"reserve_annoncee", &"brac_gardien", &"gardiennes_nommees", &"masque_carton_porte", &"found_journal_40",
			&"page_40", &"epilogue_fini", &"post_game"],
		"objets": {"insigne_gardienne": 1}, "main": "", "ouvertes": ["monts", "givre", "cieux", "arche", "volcan", "coulees", "porte", "apex"],
		"fin": 9},
]
## Les objectifs principaux sans repère sur la carte, admis (leur texte dit où aller) : [id, pourquoi].
const NO_MARKER_OK := {"porteur": "un Ptéranodon des falaises de la Côte : un dino à trouver, pas un lieu"}

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)


func after() -> void:
	Save.path = _saved_path
	Game.new_game()
	U.free_all()


# ------------------------------------------------------------------ l'état d'une étape

## The game as a player has it at stage `index` (all the stages before it included).
static func apply(index: int) -> void:
	Game.new_game()
	Game.give_starter(&"velociraptor")
	var vif := Dino.create(&"velociraptor", 40, "Vif")
	vif.bond = 5
	Game.party[0] = vif
	Game.add_caught(Dino.create(&"baryonyx", 30, "Remous"))   # (le nageur du chapitre 3 : la Côte se traverse à la nage)
	Game.give_item(Swim.ITEM)
	for f: StringName in BASE:
		Game.set_flag(f)
	for i in index + 1:
		var s: Dictionary = STAGES[i]
		for f: StringName in s.get("plus", []):
			Game.set_flag(f)
		var items: Dictionary = s.get("objets", {})
		for id: String in items:
			Game.items[id] = maxi(0, Game.item_count(id) + int(items[id]))
		for who: String in s.get("boite", []):
			var d := _named(who)
			Game.party.erase(d)
			Game.box.append(d)
		for who: String in s.get("quitte", []):
			var d := _named(who)
			Game.party.erase(d)
			Game.box.erase(d)
		for d: Array in s.get("equipe", []):
			Game.add_caught(Dino.create(d[0], d[1], d[2]))
		if s.has("tete"):
			Game.set_lead(Game.party.find(_named(s["tete"])))
	var here: Dictionary = STAGES[index]
	Game.region_id = here["zone"]
	# (entering a zone: Story._on_zone_entered recomputes the ways up and down)
	Monts.update_access()
	Cieux.update_access()
	Volcan.update_access()


static func _named(who: String) -> Dino:
	for d: Dino in Game.party + Game.box:
		if d.nickname == who:
			return d
	return null


static func mains() -> Array:
	return Objectives.current().filter(func(o: Dictionary) -> bool: return o["main"])


static func stage_name(i: int) -> String:
	return "[%d] %s" % [i, STAGES[i]["nom"]]


# ------------------------------------------------------------------ l'objectif principal

func test_objectif_principal_a_chaque_etape() -> void:
	var gaps: Array[String] = []
	for i in STAGES.size():
		apply(i)
		var want: String = STAGES[i]["main"]
		var got := mains()
		var all := Objectives.current()
		if want == "":
			if not got.is_empty():
				gaps.append("%s : un objectif principal après la fin (%s)" % [stage_name(i), got[0]["id"]])
			if all.is_empty():
				gaps.append("%s : plus aucun objectif (même pas l'après)" % stage_name(i))
			continue
		if got.is_empty():
			gaps.append("%s : AUCUN objectif principal (attendu « %s »)" % [stage_name(i), want])
			continue
		var o: Dictionary = got[0]
		if o["id"] != want:
			gaps.append("%s : objectif « %s » au lieu de « %s »" % [stage_name(i), o["id"], want])
		if String(o["text"]).strip_edges() == "":
			gaps.append("%s : objectif « %s » sans texte" % [stage_name(i), o["id"]])
		prints("   %s → %s (%s %s)" % [stage_name(i), o["id"], o["zone"], o["tile"]])
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()


func test_reperes_dans_leur_zone() -> void:
	var gaps: Array[String] = []
	var paths := U.paths()
	for i in STAGES.size():
		apply(i)
		for o: Dictionary in Objectives.current():
			var z: StringName = o["zone"]
			var tile: Vector2 = o["tile"]
			if z == &"":
				if o["main"]:
					gaps.append("%s : objectif principal « %s » sans zone" % [stage_name(i), o["id"]])
				continue
			if not paths.has(z):
				gaps.append("%s : « %s » dans une zone inconnue %s" % [stage_name(i), o["id"], z])
				continue
			if tile == Vector2.INF:
				if o["main"] and not NO_MARKER_OK.has(o["id"]):
					gaps.append("%s : objectif principal « %s » sans repère (%s)" % [stage_name(i), o["id"], z])
				continue
			var size := Vector2(U.zone(z).map_size())
			if not Rect2(Vector2.ZERO, size).has_point(tile):
				gaps.append("%s : « %s » : repère %s hors de %s (%s)" % [stage_name(i), o["id"], tile, z, size])
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()


## Never impossible: from where Chloé stands, her main objective's zone and marker are reached on foot.
func test_objectif_principal_atteint_a_pied() -> void:
	var gaps: Array[String] = []
	var t0 := Time.get_ticks_msec()
	for i in STAGES.size():
		apply(i)
		var got := mains()
		if got.is_empty():
			continue
		var here: Dictionary = STAGES[i]
		var start := U.spawn_px(U.zone(here["zone"]), here["depuis"])
		if start == Vector2.INF:
			gaps.append("%s : pas d'arrivée %s dans %s" % [stage_name(i), here["depuis"], here["zone"]])
			continue
		var walked := U.walk_island(here["zone"], U.tile_of(start))
		for o: Dictionary in got:
			var why := U.objective_reached(walked, o)
			if why != "":
				gaps.append("%s : « %s » : %s (Chloé à %s/%s, en tête %s)" % [stage_name(i), o["id"], why, here["zone"], here["depuis"],
					Game.lead_dino().nickname])
	prints("   marche sur l'île, %d étapes : %d ms" % [STAGES.size(), Time.get_ticks_msec() - t0])
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()


## The dawn waits for her own hatchling: left at the Cabinet, the objective sends her there (Roc), and
## she walks there from the crater's door (back over the lava, on the Saichania's back).
func test_aube_le_petit_au_cabinet() -> void:
	var at := -1
	for i in STAGES.size():
		if String(STAGES[i]["nom"]).begins_with("ch8 FIN"):
			at = i
	apply(at)
	var vif := _named("Vif")
	Game.party.erase(vif)
	Game.box.append(vif)
	var got := mains()
	assert_int(got.size()).override_failure_message("le petit au Cabinet : aucun objectif principal").is_greater(0)
	if got.is_empty():
		return
	assert_str(String(got[0]["id"])).is_equal("aube_depart")
	var start := U.spawn_px(U.zone(&"porte_cratere"), &"DepuisCoulees")
	var walked := U.walk_island(&"porte_cratere", U.tile_of(start))
	assert_str(U.objective_reached(walked, got[0])).override_failure_message("aube_depart : %s" % U.objective_reached(walked, got[0])).is_empty()


## Witnesses that the walking does block (else « reached » would prove nothing): the ice walls before a
## dino that charges, the barricade before it falls, the lava without a dino of stone or fire in the lead,
## the lava of the crater's path before it goes back.
func test_temoins_la_marche_bloque_ce_qui_doit_l_etre() -> void:
	var gaps: Array[String] = []
	var idx := func(prefix: String) -> int:
		for i in STAGES.size():
			if String(STAGES[i]["nom"]).begins_with(prefix):
				return i
		return -1
	var from := func(z: StringName, spawn: StringName) -> Vector2i:
		return U.tile_of(U.spawn_px(U.zone(z), spawn))
	var node_px := func(z: StringName, n: String) -> Vector2:
		return (U.zone(z).entities.get_node(n) as Node2D).position
	# The ice walls (MurGlace1, 2) close the glacier's end until a dino charges.
	apply(idx.call("ch6 : le glacier"))
	var caves := MontsPlaces.ENTREE_GROTTES * U.TILE
	if U.near(U.reach(&"monts", from.call(&"monts", &"DepuisCote")), caves, U.MARKER_REACH):
		gaps.append("monts : l'entrée des grottes atteinte sans dino qui charge (les murs de glace ne ferment rien)")
	apply(idx.call("ch6 : un Tricératops"))
	if not U.near(U.reach(&"monts", from.call(&"monts", &"DepuisCote")), caves, U.MARKER_REACH):
		gaps.append("monts : l'entrée des grottes pas atteinte avec un Tricératops")
	# The barricade closes Brac's terrace until it falls.
	apply(idx.call("ch8 : deux petites forges"))
	var brac: Vector2 = node_px.call(&"forges_ombre", "BracVolcan")
	if U.near(U.reach(&"forges_ombre", from.call(&"forges_ombre", &"DepuisChamps")), brac, U.MARKER_REACH):
		gaps.append("forges : Brac atteint avant que la barricade tombe")
	apply(idx.call("ch8 : la barricade"))
	if not U.near(U.reach(&"forges_ombre", from.call(&"forges_ombre", &"DepuisChamps")), brac, U.MARKER_REACH):
		gaps.append("forges : Brac pas atteint, la barricade tombée")
	# The lava: Vif in the lead stops at the first flow; the Saichania in the lead crosses.
	apply(idx.call("ch8 : les coulées"))
	var rift := Volcan.place("FAILLE") * U.TILE
	var start: Vector2i = from.call(&"coulees_lave", &"DepuisForges")
	if not U.near(U.reach(&"coulees_lave", start), rift, U.MARKER_REACH):
		gaps.append("coulées : la faille pas atteinte sur le dos du Saichania")
	Game.set_lead(Game.party.find(_named("Vif")))
	if U.near(U.reach(&"coulees_lave", start), rift, U.MARKER_REACH):
		gaps.append("coulées : la faille atteinte à pied, Vif en tête (la lave n'arrête rien)")
	# The crater's path: closed by the deep lava until « lave_retiree ».
	apply(idx.call("ch8 : le T-Rex"))
	var r := U.zone(&"coulees_lave")
	var up := U.exit_named(r, "VersPorteCratere")
	if U.at_exit(r, U.reach(&"coulees_lave", start), up):
		gaps.append("coulées : la sortie vers la porte atteinte avant que la lave se retire")
	apply(idx.call("ch8 : le cinquième Cœur"))
	if not U.at_exit(r, U.reach(&"coulees_lave", start), up):
		gaps.append("coulées : la sortie vers la porte pas atteinte, la lave retirée")
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()


# ------------------------------------------------------------------ les portes

func test_portes_ouvertes_et_fermees_au_bon_moment() -> void:
	var gaps: Array[String] = []
	for i in STAGES.size():
		apply(i)
		var open: Array = STAGES[i]["ouvertes"]
		for g: String in U.GATES:
			var gate: Array = U.GATES[g]
			var e := U.exit_named(U.zone(gate[0]), gate[1])
			if e == null:
				gaps.append("%s : la sortie %s/%s n'existe pas" % [stage_name(i), gate[0], gate[1]])
				continue
			if e.required_flag != gate[2]:
				gaps.append("%s : %s/%s attend « %s » au lieu de « %s »" % [stage_name(i), gate[0], gate[1], e.required_flag, gate[2]])
			var want: bool = g in open
			if e.is_open() != want:
				gaps.append("%s : la porte « %s » (%s/%s, %s) est %s au lieu d'être %s" % [stage_name(i), g, gate[0], gate[1], gate[2],
					"ouverte" if e.is_open() else "fermée", "ouverte" if want else "fermée"])
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()


## A closed gate says why (its blocked_dialogue has lines), at every stage where it is closed.
func test_portes_fermees_disent_pourquoi() -> void:
	var gaps: Array[String] = []
	for i in STAGES.size():
		apply(i)
		for g: String in U.GATES:
			var gate: Array = U.GATES[g]
			var e := U.exit_named(U.zone(gate[0]), gate[1])
			if e == null or e.is_open():
				continue
			if e.blocked_dialogue == &"":
				gaps.append("%s : « %s » fermée sans dialogue de refus" % [stage_name(i), g])
				continue
			var lines: Array = DialogueDB.lines(e.blocked_dialogue)
			if lines.is_empty():
				gaps.append("%s : « %s » fermée : le dialogue « %s » est vide" % [stage_name(i), g, e.blocked_dialogue])
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()


## Every exit of every zone leads to an arrival that exists in the zone it opens on.
func test_chaque_sortie_arrive_quelque_part() -> void:
	var gaps: Array[String] = []
	var paths := U.paths()
	for id: StringName in paths:
		var r := U.zone(id)
		if r == null:
			gaps.append("%s : zone introuvable (%s)" % [id, paths[id]])
			continue
		for e in r.exits():
			if not paths.has(e.target_zone):
				gaps.append("%s/%s → zone inconnue %s" % [id, e.name, e.target_zone])
				continue
			if U.spawn_px(U.zone(e.target_zone), e.target_spawn) == Vector2.INF:
				gaps.append("%s/%s → %s : pas d'arrivée « %s »" % [id, e.name, e.target_zone, e.target_spawn])
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()
