extends RefCounted
## Helpers of the goat's scenario (« static » command of tools/capture.gd): Mémé Pervenche's own
## scene called without going through her shop menu (the test's auto mode would buy berries), and
## where the quest stands.


static func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## What Pervenche says about her goat: she is looking for her, or she thanks Chloé.
static func pervenche() -> String:
	Havre._goat(_tree().current_scene.get("region").entities.get_node_or_null("Pervenche"))
	return "Mémé Pervenche parle de sa chèvre"


## Is the goat's picture in the zone (tied at the camp, or home at Havre-Doré)?
static func here() -> String:
	var entities: Node = _tree().current_scene.get("region").entities
	var seen := []
	for n in entities.get_children():
		if n is Prop and (n as Prop).kind == "chevre":
			seen.append("%s en %s" % [n.name, (n as Node2D).global_position / 48.0])
	return "chèvre visible : %s" % ("aucune" if seen.is_empty() else ", ".join(seen))


static func report() -> String:
	var out := []
	for flag: StringName in [&"chevre_volee_dite", &"chevre_vue", &"chevre_partie_vue", &"chevre_rendue"]:
		out.append("%s=%s" % [flag, Game.flag(flag)])
	return " ".join(out) + " | baies : %d" % Game.item_count("baie")
