extends Node
## Steps for tools/capture.gd: the battle's new juice — the hit flash in the move's colour, the
## ghosts behind a lunge, the K.O. and the capture that burn away, and the black-amber veins on a
## corrupted dino whose species has no drawn corrupted sheet.
const STEPS := [
	[1.0, "battle", [&"protoceratops", 3]],
	[2.6, "shot", "00_intro"],
	[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"],
	[6.1, "act", {"type": "move", "index": 0}],
	[6.28, "shot", "01_bond_fantomes"],
	[6.52, "shot", "02_coup_encaisse"],
	[7.5, "press", "interact"], [8.5, "press", "interact"], [9.5, "press", "interact"],
	[10.5, "press", "interact"], [11.5, "press", "interact"],
	# Le sauvage à 1 PV : le coup suivant le met K.O. et on voit la peinture se consumer.
	[12.3, "hurt", [-1, 1]],
	[12.5, "act", {"type": "move", "index": 0}],
	[13.05, "shot", "03_ko_consume"],
	[14.0, "press", "interact"], [15.0, "press", "interact"], [16.0, "press", "interact"],
	[17.0, "press", "interact"], [18.0, "press", "interact"], [19.0, "press", "interact"],
	[20.0, "press", "interact"],
	# Un dino corrompu d'une espèce sans planche dessinée : les veines viennent du shader.
	[21.0, "battle_corrupt", ["protoceratops", 5]],
	[23.4, "shot", "04_corrompu_veines"],
	[24.0, "press", "interact"], [25.0, "press", "interact"], [26.0, "press", "interact"],
	# La capture : le collier aspire, la peinture se consume en ambre.
	[27.0, "battle", [&"psittacosaurus", 3]],
	[29.0, "press", "interact"], [30.0, "press", "interact"], [31.0, "press", "interact"],
	[32.0, "act", {"type": "catch"}],
	[33.3, "shot", "05_capture_ambre"],
	[33.6, "shot", "06_capture_apres"],
]
