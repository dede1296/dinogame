extends GdUnitTestSuite
## Les os des trois squelettes légendaires (docs/post-game-plan.md § 2, post-game-scenes.md F2), sans
## fenêtre : quinze drapeaux uniques, cinq par squelette, trois objets jamais vendus ; deux crânes
## examinés (posés par le code), treize os enfouis dans les scènes des zones (un nœud OsEnfoui par os,
## à sa case, avec son objet et la page qui le montre) ; chaque case : du sol où l'on marche (jamais
## de l'eau), atteinte à pied depuis les entrées de la zone (le banc de vase du Marais : à la nage) ;
## creuser : l'objet, le drapeau, le compte du toast, le Dinodex « vu », rien deux fois ; l'os enfoui ne
## se montre qu'avec le Flair, le jeu fini et la page de sa bête donnée.

const F := preload("res://story/fossiles.gd")
const DF := preload("res://data/dialogue_fossiles.gd")
const B := preload("res://tools/zone_builder.gd")
const SPOT := preload("res://world/os_enfoui.gd")
const SAVE_PATH := "user://test_gdunit_fossiles_os.json"
const SWIM_ONLY := [&"marais"]

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
	Game.give_starter(&"velociraptor")


# ------------------------------------------------------------------ la table

func test_quinze_drapeaux_cinq_par_squelette() -> void:
	assert_int(F.BONES.size()).is_equal(15)
	for beast in F.BEASTS:
		for i in 5:
			var flag := F.flag_of(beast, i)
			assert_bool(F.BONES.has(flag)).override_failure_message("%s manque" % flag).is_true()
			assert_str(String(F.beast_of(flag))).is_equal(String(beast))
			assert_int(F.piece_of(flag)).is_equal(i)


func test_deux_cranes_examines_treize_enfouis() -> void:
	var looked: Array = F.BONES.keys().filter(func(k: StringName) -> bool: return F.BONES[k][2] == "look")
	assert_array(looked.map(func(k: StringName) -> String: return String(k))).contains_exactly_in_any_order(
		["os_titanosaure_1", "os_kronosaurus_1"])
	assert_str(String(F.BONES[&"os_titanosaure_1"][0])).is_equal("terre_apex")
	assert_str(String(F.BONES[&"os_kronosaurus_1"][0])).is_equal("recif_sanctuaire")
	assert_int(F.BONES.size() - looked.size()).is_equal(13)
	var zones := {}
	for k: StringName in F.BONES:
		zones[F.BONES[k][0]] = true
	var world_zones: Dictionary = (load("res://world/world.gd") as GDScript).get_script_constant_map()["ZONES"]
	for z: StringName in zones:
		assert_bool(world_zones.has(z)).override_failure_message("zone inconnue : %s" % z).is_true()
	assert_bool(zones.has(&"coeur_apex")).override_failure_message("rien au Cœur des Apex").is_false()
	assert_int(zones.size()).override_failure_message("zones : %s" % [zones.keys()]).is_equal(13)


func test_trois_objets_jamais_vendus() -> void:
	for id: String in ["os_titanosaure", "os_kronosaurus", "os_gigantoraptor", "carnet_os"]:
		assert_bool(ItemsDB.ITEMS.has(id)).override_failure_message("%s absent d'ItemsDB (patch_B.md)" % id).is_true()
		var it := ItemsDB.item(id)
		assert_int(int(it["sell"])).override_failure_message("%s se vend" % id).is_equal(0)
		assert_int(int(it["price"])).override_failure_message("%s s'achète" % id).is_equal(0)


# ------------------------------------------------------------------ les scènes des zones

func test_os_enfouis_dans_les_scenes() -> void:
	var zones: Dictionary = (load("res://world/world.gd") as GDScript).get_script_constant_map()["ZONES"]
	for flag: StringName in F.BONES:
		var bone: Array = F.BONES[flag]
		if bone[2] != "dig":
			continue
		var r: Region = Region.open_for_preview(zones[bone[0]])
		var spot := r.get_node_or_null("Entities/Enfoui" + String(flag).to_pascal_case())
		assert_object(spot).override_failure_message("%s : pas de nœud dans %s (zone à régénérer)" % [flag, bone[0]]).is_not_null()
		if spot:
			assert_object(spot.get_script()).is_same(SPOT)
			assert_str(String(spot.get("pebble"))).is_equal(String(flag))
			assert_str(String(spot.get("item_id"))).is_equal(F.item_of(F.beast_of(flag)))
			assert_str(String(spot.get("show_flag"))).is_equal(String(F.SHOWN_BY[F.beast_of(flag)]))
			assert_vector((spot as Node2D).position).is_equal_approx(B.cell(bone[1].x, bone[1].y), Vector2(0.5, 0.5))
		r.free()


func test_aucun_os_sous_l_eau_tous_atteints() -> void:
	var zones: Dictionary = (load("res://world/world.gd") as GDScript).get_script_constant_map()["ZONES"]
	for flag: StringName in F.BONES:
		var bone: Array = F.BONES[flag]
		var zone: StringName = bone[0]
		var r: Region = Region.open_for_preview(zones[zone])
		var c := Vector2i((bone[1] as Vector2).floor())
		var data := r.terrain.get_cell_tile_data(c)
		var kind := String(data.get_custom_data("terrain")) if data else "?"
		assert_bool(kind in B.WALKABLE).override_failure_message("%s (%s %s) : terrain %s" % [flag, zone, c, kind]).is_true()
		var swim := zone in SWIM_ONLY or zone == &"recif_sanctuaire"
		var reach := {}
		for s: Node in r.get_node("Spawns").get_children():
			reach.merge(B._reachable(r, Vector2i(((s as Node2D).position / 48.0).floor()), swim))
		assert_bool(reach.has(c)).override_failure_message("%s (%s %s) : hors d'atteinte depuis les entrées" % [flag, zone, c]).is_true()
		r.free()


# ------------------------------------------------------------------ creuser

func test_creuser_un_os_compte_et_jamais_deux_fois() -> void:
	assert_bool(F.dig(&"os_titanosaure_2")).override_failure_message("le premier os de la bête").is_true()
	assert_int(Game.item_count("os_titanosaure")).is_equal(1)
	assert_bool(Game.flag(&"os_titanosaure_2")).is_true()
	assert_bool(Game.dex_seen.has("saltasaurus")).override_failure_message("le Dinodex voit la bête").is_true()
	assert_str(F.toast(&"os_titanosaure_2")).is_equal("Un os du Titanosaure d'Or ! Il en reste 4.")
	assert_bool(F.dig(&"os_titanosaure_2")).is_false()
	assert_int(Game.item_count("os_titanosaure")).override_failure_message("un os donné deux fois").is_equal(1)
	assert_bool(F.dig(&"os_titanosaure_3")).override_failure_message("pas le premier").is_false()
	assert_str(F.toast(&"os_titanosaure_3")).is_equal("Un os du Titanosaure d'Or ! Il en reste 3.")
	for f: StringName in [&"os_titanosaure_1", &"os_titanosaure_4", &"os_titanosaure_5"]:
		F.dig(f)
	assert_int(F.found(&"titanosaure")).is_equal(5)
	assert_str(F.toast(&"os_titanosaure_5")).starts_with("Le dernier os du Titanosaure d'Or")
	assert_int(Game.item_count("os_titanosaure")).is_equal(5)
	assert_bool(F.dig(&"os_inconnu_1")).is_false()


func test_la_pensee_du_premier_os_nomme_qui_porte() -> void:
	var line: Array = DF.first_bone(&"kronosaurus", "Nessie")
	assert_int(line.size()).is_equal(1)
	assert_str(String(line[0]["text"])).contains("Nessie le porte")
	assert_str(String(DF.first_bone(&"gigantoraptor", "")[0]["text"])).contains("huit mètres")
	assert_str(String(DF.skull(&"kronosaurus", "Nessie")[0]["text"])).contains("Nessie le pousse du museau")


func test_l_os_enfoui_se_montre_avec_flair_jeu_fini_et_page() -> void:
	var spot: Node2D = auto_free(SPOT.new())
	spot.set("pebble", &"os_kronosaurus_2")
	spot.set("item_id", "os_kronosaurus")
	spot.set("show_flag", &"isaure_pari_gagne")
	add_child(spot)
	assert_bool(spot.visible).override_failure_message("sans Flair").is_false()
	Game.add_caught(Dino.create(&"compsognathus", 10))
	assert_bool(spot.visible).override_failure_message("Flair, mais le jeu n'est pas fini").is_false()
	Game.set_flag(&"post_game")
	Game.set_flag(&"carnet_terre")
	assert_bool(spot.visible).override_failure_message("la page de la terre ne montre pas la mer").is_false()
	Game.set_flag(&"isaure_pari_gagne")
	assert_bool(spot.visible).override_failure_message("Flair, jeu fini, pari gagné").is_true()
	assert_bool(spot.call(&"is_hiding")).is_true()
	Game.set_flag(&"os_kronosaurus_2")
	assert_bool(spot.call(&"is_hiding")).is_false()
