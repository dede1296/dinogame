extends GdUnitTestSuite
## Les pas de cendre : sur les zones du volcan et de l'Apex, Chloé marche sur la cendre.


func test_sur_la_cendre_les_pas_sont_ceux_de_la_cendre() -> void:
	assert_str(String(Player.step_kind(&"grass", false, false, true))).is_equal("ash")
	assert_str(String(Player.step_kind(&"path", false, false, true))).is_equal("ash")


func test_hors_des_zones_de_cendre_rien_ne_change() -> void:
	assert_str(String(Player.step_kind(&"grass", false))).is_equal("grass")
	assert_str(String(Player.step_kind(&"path", false))).is_equal("path")
	assert_str(String(Player.step_kind(&"grass", true))).is_equal("snow")


func test_la_neige_et_la_glace_priment_sur_la_cendre() -> void:
	assert_str(String(Player.step_kind(&"grass", true, false, true))).is_equal("snow")
	assert_str(String(Player.step_kind(&"sand", false, true, true))).is_equal("ice")


func test_les_sept_zones_de_cendre_existent_et_les_six_pas_se_chargent() -> void:
	var zones: Array = (load("res://world/world.gd") as Script).get_script_constant_map()["ASH_ZONES"]
	assert_int(zones.size()).is_equal(7)
	var world_zones: Dictionary = (load("res://world/world.gd") as Script).get_script_constant_map()["ZONES"]
	for z in zones:
		assert_bool(world_zones.has(z)).is_true()
	for i in 6:
		assert_bool(ResourceLoader.exists("res://assets/audio/footsteps/cendre0%d.ogg" % i)).is_true()
