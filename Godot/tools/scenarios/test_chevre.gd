extends RefCounted
## Check (29/09, clin d'œil): Mémé Pervenche's goat — she says it was taken (Havre-Doré), Chloé
## finds it tied to a stake at Brac's camp, and once Brac is beaten only the chewed rope is left;
## back at Havre-Doré the goat is home and Pervenche thanks her.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_chevre.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "vu_herboristerie", "foret_arrivee",
		"mur_camp_brise", "camp_arrive", "sbire_camp_1_battu", "sbire_camp_2_battu"]],
	[0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "dlog", true], [1.12, "no_help", null], [1.14, "auto", true], [1.2, "zone", &"havre_dore"],
	# Pervenche: her goat is missing
	[3.2, "tp", Vector2(6.0, 10.6)], [3.4, "face", Vector2(0, -1)], [3.8, "press", "interact"],
	[5.0, "shot", "c1_pervenche_cherche"], [9.5, "shot", "c2_pourquoi"],
	# the camp: tied to the stake
	[12.0, "zone", &"camp_ombre"], [14.0, "tp", Vector2(28.9, 15.3)], [14.2, "face", Vector2(0, -1)],
	[15.0, "shot", "c3_attachee"], [15.4, "press", "interact"], [16.6, "shot", "c4_parle"],
	[20.0, "shot", "c5_appat"], [24.0, "shot", "c6_tiens_bon"],
	# Brac beaten: the empty rope
	[26.0, "flags", ["brac_battu", "sceau_foret"]], [26.2, "zone", &"foret"], [28.0, "zone", &"camp_ombre"],
	[30.0, "tp", Vector2(28.0, 16.4)], [30.2, "hold", "move_up"], [31.0, "hold", ""],
	[32.2, "shot", "c7_corde_rongee"], [35.0, "shot", "c8_plus_la"], [38.0, "shot", "c9_sabots"],
	# home: Pervenche thanks her
	[41.0, "zone", &"havre_dore"], [43.0, "tp", Vector2(10.9, 6.8)], [43.2, "face", Vector2(0, -1)],
	[44.0, "shot", "c10_rentree"],
	[44.4, "tp", Vector2(6.0, 10.6)], [44.6, "face", Vector2(0, -1)], [45.0, "press", "interact"],
	[46.2, "shot", "c11_merci"], [50.0, "shot", "c12_bardane"], [55.0, "shot", "c13_baies"],
	[57.0, "state", null],
]
