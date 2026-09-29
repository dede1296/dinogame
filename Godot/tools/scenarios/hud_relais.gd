extends RefCounted
## A whole battle where Vif is knocked out and another goes in (auto: the first standing), then
## where the one in battle has no power points left (« Se débattre »). See tools/capture.gd.

const STEPS := [
	[0.9, "give", "compsognathus"], [1.0, "tp", Vector2(60.0, 62.0)], [1.05, "hurt", [0, 2]], [1.1, "pp", [1, 0]],
	[1.3, "battle", [&"protoceratops", 5]], [1.4, "auto", true],
	[60.0, "auto", false], [60.2, "shot", "hr_fin"], [60.3, "party", null],
]
