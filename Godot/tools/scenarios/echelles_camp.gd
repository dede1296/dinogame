extends RefCounted
## The new sizes: the camp of the Ombre Noire, Brac and his henchmen, the caged dinos and the
## Utahraptor's pen. See tools/capture.gd.

const STEPS := [
	[0.8, "calm", 900.0], [0.82, "camera_distance", 12.0], [0.85, "weather", &"clear"], [0.9, "clock", 11.0],
	[0.95, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "foret_arrivee", "camp_arrive", "lettre_scellee"]],
	[1.0, "zone", &"camp_ombre"],
	[2.5, "tp", Vector2(20.0, 13.2)], [2.6, "hold", "move_up"], [2.65, "hold", ""], [4.2, "shot", "k0_brac"],
	[4.3, "tp", Vector2(21.0, 17.9)], [5.8, "shot", "k1_sbires"],
	[5.9, "tp", Vector2(30.5, 10.6)], [7.4, "shot", "k2_utahraptor"],
	[7.5, "tp", Vector2(25.5, 8.0)], [9.0, "shot", "k3_cage_deinonychus"],
	[9.1, "tp", Vector2(8.0, 14.2)], [10.6, "shot", "k4_cage_dilophosaurus"],
	[10.7, "camera_distance", 20.0], [10.8, "tp", Vector2(20.0, 14.0)], [12.3, "shot", "k5_camp_vue"],
]
