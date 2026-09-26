class_name Search
## Searching the island's scenery, and its amber pebbles (a bench or a campfire: see Rest).
##   A tree shaken: it sways, leaves fall; now and then a berry (at most once a day per tree),
##   and the amber pebble some trees hide.
##   A small stone turned over: what lives under it, or a pebble.
## Pebbles also lie in plain sight in nooks (Pickup of kind "galet") and under the ground
## (DigSpot, dug with Flair). Each one is a story flag "galet_<zone>_<n>"; how many a zone
## holds is Region.pebbles. Finding one teaches the whole party a little (exploring pays).

const TREES := ["arbre_rond", "fougere_arbre", "araucaria"]
const STONES := ["cailloux"]
const BERRY_CHANCE := 0.3
const XP_PEBBLE := 10
## After a search, a short pause before the next one (no frantic shaking).
const PAUSE_S := 0.3
const SHAKE_SFX := preload("res://assets/audio/sfx/feuillage.mp3")
const STONE_SFX := preload("res://assets/audio/sfx/pierre.mp3")
const PEBBLE_SFX := preload("res://assets/audio/sfx/galet.mp3")
const PEBBLE_PICTURE := preload("res://assets/art/props/galet.png")
const BERRY_PICTURE := preload("res://assets/art/ui/baie.png")
const LEAVES: Array[Color] = [Color(0.36, 0.62, 0.2), Color(0.55, 0.72, 0.25), Color(0.3, 0.5, 0.16), Color(0.72, 0.62, 0.22)]
const AMBER: Array[Color] = [Color(1, 0.78, 0.3), Color(1, 0.92, 0.6), Color(0.95, 0.6, 0.15)]
const UNDER_STONE := [
	"Des cloportes filent se cacher.",
	"Un petit scarabée brillant s'enfuit.",
	"Rien, juste de la terre fraîche.",
	"Un ver de terre se tortille, vexé.",
	"Une fourmi traîne une miette deux fois plus grosse qu'elle.",
]


static func can_search(prop: Prop) -> bool:
	return prop.kind in TREES or prop.kind in STONES or prop.kind in Rest.KINDS


static func search(prop: Prop, player: Player) -> void:
	if prop.kind in Rest.KINDS:
		await Rest.sit(prop, player)
		return
	player.face_towards(prop.global_position)
	var tree := prop.get_tree()
	var view := _view(tree)
	var id := "%s:%d:%d" % [Game.region_id, roundi(prop.position.x), roundi(prop.position.y)]
	var first_today: bool = Game.searched.get(id, 0) != Game.day
	if prop.kind in TREES:
		Audio.play_sfx(SHAKE_SFX, -3.0, 0.08)
		if view:
			view.nudge(prop, 1.0, 0.0, 0.9)
			view.burst(prop.global_position, LEAVES, 26, 2.6, 1.0)
		await tree.create_timer(0.5).timeout
		if prop.is_hiding():
			await found_pebble(prop, prop.hidden_pebble, prop.global_position)
		elif first_today and randf() < BERRY_CHANCE:
			Game.give_item("baie")
			if view:
				view.pop_up(prop.global_position, BERRY_PICTURE, 2.2)
			Toast.say(tree, "Une baie tombe de l'arbre ! (+1 baie)")
	else:
		Audio.play_sfx(STONE_SFX, -2.0, 0.06)
		if view:
			view.nudge(prop, 0.0, 0.35, 0.9)
		await tree.create_timer(0.45).timeout
		if prop.is_hiding():
			await found_pebble(prop, prop.hidden_pebble, prop.global_position)
		else:
			Toast.say(tree, UNDER_STONE.pick_random())
	Game.searched[id] = Game.day
	await tree.create_timer(PAUSE_S).timeout


## An amber pebble found at `at` (flag `flag`): counted, the party learns, the dino is glad.
static func found_pebble(node: Node, flag: StringName, at: Vector2) -> void:
	var tree := node.get_tree()
	Game.set_flag(flag)
	node.remove_from_group(&"secret")
	Audio.play_sfx(PEBBLE_SFX, -2.0)
	var view := _view(tree)
	if view:
		view.burst(at, AMBER, 14, 0.5, 0.3)
		view.pop_up(at, PEBBLE_PICTURE, 0.3)
	var region: Region = tree.current_scene.get("region") if tree.current_scene else null
	var total := region.pebbles if region else 0
	var count := Game.pebbles_found(String(Game.region_id))
	Toast.say(tree, "Galet d'ambre ! %d / %d" % [count, total] if total > 0 else "Galet d'ambre !")
	Game.award_team_xp(XP_PEBBLE)
	var companion := tree.get_first_node_in_group(&"companion") as Companion
	if companion:
		companion.rejoice()
	Save.save_game()


static func _view(tree: SceneTree) -> WorldView:
	return tree.get_first_node_in_group(&"world_view") as WorldView
