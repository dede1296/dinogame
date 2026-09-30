extends RefCounted
## Visual check (30/09): Bardane home in Mémé Pervenche's lane (between the herbalist's and the
## haberdashery, walls at x 8.8 and 11.0), and tied to her stake at Brac's camp.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_chevre.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "foret_arrivee", "mur_camp_brise",
		"camp_arrive", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu",
		"oeuf_vole_apaise", "cage_ouverte", "utah_lecon", "sceau_foret", "cages_ouvertes"]],
	[0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "no_help", null], [1.2, "zone", &"havre_dore"],
	[3.4, "tp", Vector2(9.8, 12.6)], [3.6, "face", Vector2(0, -1)], [4.4, "shot", "h1_devant"],
	[4.6, "tp", Vector2(11.2, 11.6)], [4.8, "face", Vector2(-1, 0)], [5.6, "shot", "h2_de_cote"],
	[7.2, "state", null],
]
