extends RefCounted
## Le temps d'un changement de zone (le creux d'images par seconde des Cieux) : le blocage du chargement,
## en ms, pour Pitons → Nids → Pitons → Nids → Pitons (les reliefs déjà mesurés sont réutilisés).
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/zone_change_test.gd titre="Durée d'un changement de zone dans les Cieux"

const SELF := "res://tools/scenarios/zone_change_test.gd"
const VIS := "res://tools/scenarios/vis_cieux.gd"
const FLAGS := ["prologue_done", "tuto_commandes", "cieux_ouverts", "cieux_arrivee", "pont_lianes_vu", "vol_obtenu"]

const STEPS := [
	[0.5, "flags", FLAGS], [0.55, "talk", true], [0.6, "clock", 11.0], [0.7, "weather", &"clear"],
	[1.0, "static", [SELF, "aller", "cieux|DepuisMonts"]], [3.0, "static", [SELF, "aller", "nids_geants|DepuisCieux"]],
	[5.0, "static", [SELF, "aller", "cieux|DepuisMonts"]], [7.0, "static", [SELF, "aller", "nids_geants|DepuisCieux"]],
	[9.0, "static", [SELF, "aller", "cieux|DepuisMonts"]], [11.0, "state", null],
]


static func aller(arg: String) -> String:
	var parts := arg.split("|")
	var t0 := Time.get_ticks_usec()
	var vis: GDScript = load(VIS)
	vis.call("entrer", parts[0], parts[1])
	var line := "ZONE %s : %.0f ms" % [parts[0], (Time.get_ticks_usec() - t0) / 1000.0]
	print(line)
	return line
