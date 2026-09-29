extends RefCounted
## Chapter 6 mechanics: what the colour blend at the edges costs (WorldView.TINT_BLEND), at the
## Marais' edge towards the Forêt, medium graphics, vsync off: with it, then without. See
## tools/capture.gd.

const HERE := "res://tools/scenarios/meca_teintes_perf.gd"
const STEPS := [
	[0.5, "flags", ["sceau_plaines", "havre_arrive", "selle", "foret_arrivee", "maia_defi_1", "sceau_foret", "maia_defi_2", "marais_arrivee", "joss_marais_vu"]],
	[0.55, "talk", true], [0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"], [1.4, "zone", &"marais"],
	[3.6, "calm", 900.0], [3.9, "weather", &"clear"], [4.0, "tp", Vector2(115.5, 70)], [4.1, "calm", 900.0],
	[4.2, "quality", 1], [4.3, "vsync", false], [8.0, "perf", "MOYENNE avec fondu"],
	[8.1, "static", [HERE, "sans", "@player"]], [12.0, "perf", "MOYENNE sans fondu"],
	[12.1, "static", [HERE, "avec", "@player"]], [16.0, "perf", "MOYENNE avec fondu (bis)"], [16.1, "state", null],
]


static func sans(player: Node2D) -> int:
	return _count(player, 0)


static func avec(player: Node2D) -> int:
	return _count(player, -1)


## Sets tint_edge_count on every ground and water material of the view (-1: back as built).
static func _count(player: Node2D, count: int) -> int:
	var view := player.get_tree().get_first_node_in_group(&"world_view") as WorldView
	var done := 0
	for n in view.find_children("*", "MeshInstance3D", true, false):
		var mat := (n as MeshInstance3D).material_override as ShaderMaterial
		if mat == null or mat.get_shader_parameter("tint_edges") == null:
			continue
		if not mat.has_meta(&"tint_count"):
			mat.set_meta(&"tint_count", mat.get_shader_parameter("tint_edge_count"))
		mat.set_shader_parameter("tint_edge_count", mat.get_meta(&"tint_count", 0) if count < 0 else count)
		done += 1
	return done
