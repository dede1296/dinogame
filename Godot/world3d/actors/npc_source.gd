class_name NpcSource
extends RefCounted
## The people of a 2.5D zone, read as the plan of the 3D one — the DATA layer of the 3D NPCs
## (docs/migration-3d.md, « Npc/DinoNpc → Npc3D »), next to ZoneSource.props() and .habitats().
## Nothing is written down twice: the name, the sheet, the dialogue or the story scene, the way
## they face and where they stand all come from the `Npc` nodes of the 2.5D zone itself
## (actors/npc.tscn, placed by tools/zones/<zone>.gd), read out of the tree like the rest.
## Who is there depends on the story flags, as in the 2.5D (`Npc.present`).

const NPC_SCRIPT := preload("res://actors/npc.gd")
## The 2.5D's four ways of facing, in the 3D zone (ZoneSource maps zone x → X and zone y → Z).
const FACING := {
	"down": Vector3(0, 0, 1), "up": Vector3(0, 0, -1), "right": Vector3(1, 0, 0), "left": Vector3(-1, 0, 0),
}


## The people of `src` the story puts there now: [{name, display_name, sheet, dialogue_id, event,
## facing (Vector3), tint, at (Vector3, on the 2.5D's relief)}], ready for Npc3D.create().
static func read(src: ZoneSource) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if src == null or src.region == null:
		return out
	for node in src.region.entities.get_children():
		if node.get_script() != NPC_SCRIPT:
			continue
		var npc: Node2D = node
		if not npc.call(&"present"):   # the show_flag / hide_flag of the story, as in the 2.5D
			continue
		out.append({
			"name": String(npc.name),
			"display_name": String(npc.display_name),
			"sheet": npc.sheet as Texture2D,
			"dialogue_id": npc.dialogue_id as StringName,
			"event": npc.event as StringName,
			"facing": FACING.get(String(npc.facing), Vector3(0, 0, 1)) as Vector3,
			"tint": npc.tint as Color,
			"at": src.to_3d(_zone_position(npc)),
		})
	return out


## A node's position in the zone (px), out of the tree: its parents' transforms up to the region
## (the same walk as ZoneSource._zone_position, which is private to it).
static func _zone_position(node: Node2D) -> Vector2:
	var t := Transform2D.IDENTITY
	var n: Node = node
	while n != null and not (n is Region):
		if n is Node2D:
			t = (n as Node2D).transform * t
		n = n.get_parent()
	return t.origin
