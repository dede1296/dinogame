extends RefCounted
## Test scenario (tools/capture.gd -- scenario_file=…): the two cages of Brac's camp, with the
## maddened dinos inside them.
const STEPS := [
	[0.8, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "foret_arrivee",
		"mur_camp_brise", "camp_arrive"]],
	[0.85, "calm", 900.0],
	[0.9, "zone", &"camp_ombre"],
	[2.6, "tp", Vector2(25.5, 8.4)],
	[3.8, "shot", "cage_deinonychus"],
	[3.9, "tp", Vector2(6.2, 14.9)],
	[5.1, "shot", "cage_dilophosaurus"],
]
