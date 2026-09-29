extends RefCounted
## The Dinodex (29/09): opened from its button and with X, its pages (all, a region, a region
## not known yet, the uniques, the reserve), the sheets of a species not seen, seen, caught, a
## unique met; a dino of the reserve dragged onto the team with the mouse (and one dropped
## nowhere: nothing changes), brought in with the button when the team is full (who leaves?),
## the keyboard's focus; the party bar's portraits swapped with a finger (the dino following
## Chloé changes); a dino seen close by goes in the Dinodex.

## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/dinodex_equipe.gd

const H := "res://tools/scenarios/dinodex_outils.gd"
const STEPS := [
	[0.8, "static", [H, "setup"]], [0.9, "calm", 900.0], [0.9, "clock", 11.0], [0.95, "weather", &"clear"],
	[2.0, "shot", "dx01_hud"],
	[2.1, "static", [H, "open"]], [2.9, "shot", "dx02_ouverture_region"],
	[3.0, "static", [H, "page", "plaines"]], [3.6, "shot", "dx03_plaines"],
	[3.7, "static", [H, "page", "marais"]], [4.3, "shot", "dx04_region_inconnue"],
	[4.4, "static", [H, "entry", "parasaurolophus"]], [5.0, "shot", "dx05_fiche_pas_vu"],
	[5.1, "static", [H, "entry", "psittacosaurus"]], [5.7, "shot", "dx06_fiche_vu"],
	[5.8, "static", [H, "entry", "velociraptor"]], [6.4, "shot", "dx07_fiche_possede"],
	[6.5, "static", [H, "scroll_entry", 420]], [7.0, "shot", "dx08_fiche_possede_suite"],
	[7.1, "static", [H, "scroll_entry", 700]], [7.6, "shot", "dx09_fiche_possede_fin"],
	[7.7, "static", [H, "page", "uniques"]], [8.3, "shot", "dx10_uniques"],
	[8.4, "static", [H, "entry", "triceratops"]], [9.0, "shot", "dx11_unique_rencontre"],
	[9.1, "static", [H, "page", "reserve"]], [9.7, "shot", "dx12_reserve"],
	[9.8, "static", [H, "drag_nowhere", 0]], [10.3, "shot", "dx13_lache_ailleurs"],
	[10.4, "static", [H, "drag_begin", 0, 2]], [10.8, "shot", "dx14_glisse_vers_equipe"],
	[10.9, "static", [H, "drag_end", 2]], [11.5, "shot", "dx15_depose"],
	[11.6, "static", [H, "entry", "stegosaurus"]], [12.2, "static", [H, "scroll_entry", 300]], [12.6, "shot", "dx16_fiche_stego"],
	[12.7, "static", [H, "press", "Dans l'équipe"]], [13.2, "shot", "dx17_equipe_pleine"],
	[13.3, "static", [H, "pick_leaver", 4]], [13.9, "shot", "dx18_apres_choix"],
	[14.0, "static", [H, "page", "all"]], [14.3, "static", [H, "key", 4194321]], [14.5, "static", [H, "key", 4194321]],
	[14.9, "shot", "dx19_clavier"],
	[15.0, "press", "cancel"], [15.6, "shot", "dx20_ferme"],
	[15.7, "static", [H, "bar_drag_begin", 4, 0]], [16.1, "shot", "dx21_barre_glisse"],
	[16.2, "static", [H, "bar_drag_end", 0]], [17.2, "shot", "dx22_barre_apres"],
	[17.3, "wild", ["pachycephalosaurus", 10, Vector2(3, 0)]], [18.4, "shot", "dx23_vu_de_pres"],
	[18.5, "static", [H, "seen", "pachycephalosaurus"]],
	[18.7, "static", [H, "key", 88]], [19.5, "shot", "dx24_touche_x"],
	[19.6, "static", [H, "key", 88]], [20.2, "shot", "dx25_referme"],
	[20.3, "static", [H, "report"]], [20.4, "state", null],
]
