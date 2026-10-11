extends Node
## Steps for tools/capture.gd: opens the island map (M) and takes its picture — it reads the
## region atlas pixel by pixel, which a compressed picture would have broken.
const STEPS := [
	[1.5, "shot", "00_jeu"],
	[2.0, "press", "map"],
	[4.0, "shot", "01_carte"],
	[4.2, "press", "cancel"],
	[5.0, "shot", "02_retour"],
]
