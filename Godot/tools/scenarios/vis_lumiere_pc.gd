extends Node
## Steps for tools/capture.gd: la lumière du PC — la même vue, météo fixée à « clair », à l'aube, à
## midi et au crépuscule, à trois endroits de la Prairie (herbe, lisière d'arbres, falaises).
## Se lance deux fois (avant/après) en ne changeant que le code, avec le même scénario.
const STEPS := [
	[0.8, "calm", 300.0], [0.85, "weather", &"clear"],
	[0.9, "clock", 7.0], [1.0, "tp", Vector2(104.0, 63.3)], [3.0, "shot", "a_crane_aube"], [3.1, "perf", "crane_aube"],
	[3.2, "clock", 12.5], [3.3, "weather", &"clear"], [4.8, "shot", "b_crane_midi"],
	[4.9, "clock", 18.6], [5.0, "weather", &"clear"], [6.6, "shot", "c_crane_crepuscule"], [6.7, "perf", "crane_crepuscule"],
	[6.8, "clock", 7.2], [6.85, "weather", &"clear"], [6.9, "tp", Vector2(47.0, 70.0)], [8.8, "shot", "d_arbres_aube"],
	[8.9, "clock", 18.4], [8.95, "weather", &"clear"], [10.6, "shot", "e_arbres_crepuscule"],
	[10.7, "clock", 7.4], [10.75, "weather", &"clear"], [10.8, "tp", Vector2(93.0, 33.0)], [12.6, "shot", "f_falaises_aube"],
	[12.7, "perf", "falaises_aube"],
]
