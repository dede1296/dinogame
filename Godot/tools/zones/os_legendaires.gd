extends RefCounted
## The post-game's legendary bones (lot B, docs/post-game-plan.md § 2) buried in a zone: one mound
## (world/os_enfoui.gd, a DigSpot found with Flair) per bone of story/fossiles.gd BONES whose zone is
## this one and which is dug up (« dig »; the two skulls one looks at are placed by the story's code).
## Called at the end of a zone's plan (desert, plaines, monts, champs_cendres, cote, grottes_marines,
## marais, havre_dore, grotte_echos, foret, cieux), so the rebuilt scene only gains these nodes.

const B := preload("res://tools/zone_builder.gd")
const FOSSILES := "res://story/fossiles.gd"
const SPOT := "res://world/os_enfoui.gd"


## Buries the bones of zone `zone` under root's Entities (named « EnfouiOs<Beast><n> »).
static func bury(root: Node, zone: StringName) -> void:
	var fossiles: GDScript = load(FOSSILES)
	var bones: Dictionary = fossiles.get_script_constant_map()["BONES"]
	var shown_by: Dictionary = fossiles.get_script_constant_map()["SHOWN_BY"]
	var spot_script: GDScript = load(SPOT)
	var parent: Node = root.get_node_or_null("Entities")
	for flag: StringName in bones:
		var bone: Array = bones[flag]
		if bone[0] != zone or bone[2] != "dig":
			continue
		var beast: StringName = fossiles.beast_of(flag)
		var spot: Node2D = spot_script.new()
		spot.name = "Enfoui" + String(flag).to_pascal_case()
		spot.set("pebble", flag)
		spot.set("item_id", fossiles.item_of(beast))
		spot.set("show_flag", shown_by[beast])
		spot.position = B.cell(bone[1].x, bone[1].y)
		(parent if parent else root).add_child(spot, true)
