class_name Session3D
extends Node
## A game of the 3D version (docs/migration-3d.md, phase 5): the 2.5D's game state, saves, HUD and
## screens, unchanged, around a 3D zone (Zone3D) — what world.gd does for the 2.5D:
## - the game: the 3D's own save (user://save_3d.json, the 2.5D's format: the 2.5D's save is never
##   written over), loaded if there is one, else a new game with Vif (as world.gd launched alone);
##   Chloé's position kept in the 2.5D's units (pixels of the zone), so the save reads the same;
## - the HUD: the zone's banner, the party bar, the clock, the purse, the buttons of the settings,
##   the map and the Dinodex (M, X), the game's own screens;
## - Chloé's lead dino walking with her (Dinosaur3D.companion), changed when the party changes;
## - the zone's music and sounds; new wild dinos when the part of the day changes;
## - the meetings with the wild dinos (Encounters3D);
## - the frames/s, CPU and GPU times on screen, F3 (the Debug Menu plugin: here, not an autoload,
##   so the mobile game never has it).

const SAVE_PATH := "user://save_3d.json"
const PX := 48.0
const STARTER := &"velociraptor"
const DEBUG_MENU := "res://addons/debug_menu/debug_menu.tscn"

var zone: Zone3D
var hud: CanvasLayer
var encounters: Encounters3D
var companion: Dinosaur3D


## Before the zone is built: the game (loaded or new), and where Chloé stands in it (Vector3.INF:
## at the zone's arrival point).
func begin() -> Vector3:
	if Save.path == Save.PATH:   # (the test tool sets a file of its own: kept)
		Save.path = SAVE_PATH
	if not Game.in_game:
		if not (Save.has_save() and Save.load_game()):
			Game.new_game()
			Game.give_starter(STARTER)
			Game.set_flag(&"prologue_done")
		Game.in_game = true
	Game.region_id = zone.zone_id
	return Vector3.INF


## Where the save left Chloé in this zone (its 2.5D position), or Vector3.INF.
func saved_spot() -> Vector3:
	if not Game.has_position or Game.region_id != zone.zone_id:
		return Vector3.INF
	return zone.source.to_3d(Game.player_position)


## Once the zone is built: the HUD, the companion, the meetings, the sounds, the saves.
func after_build() -> void:
	var region := zone.source.region
	Game.zone_level = roundi((region.levels.x + region.levels.y) / 2.0)
	Game.set_climate({"rain": region.rain_chance, "mist": region.mist_chance, "storm": region.storm_chance,
		"sandstorm": region.sandstorm_chance, "snow": region.snow_chance, "blizzard": region.blizzard_chance})
	_build_hud(region)
	encounters = Encounters3D.new()
	encounters.name = "Encounters"
	encounters.zone = zone
	add_child(encounters)
	_place_companion()
	Game.party_changed.connect(_place_companion)
	Game.phase_changed.connect(_on_phase_changed)
	Audio.play_music(region.music)
	Audio.play_ambience(region.ambience_id)
	Save.before_save = _store_position
	Save.enabled = true


func _exit_tree() -> void:
	Save.enabled = false
	Save.before_save = Callable()


## Chloé's position for the save, in the 2.5D's units (pixels of the zone).
func _store_position() -> void:
	var at := zone.player.global_position
	Game.player_position = Vector2(at.x, at.z) / zone.source.scale * PX
	Game.has_position = true
	Game.region_id = zone.zone_id


func _build_hud(region: Region) -> void:
	hud = CanvasLayer.new()
	hud.name = "Hud"
	hud.layer = 10
	add_child(hud)
	var banner := ZoneBanner.new()
	hud.add_child(banner)
	banner.show_zone(region.zone_name if region.zone_name != "" else region.display_name,
		region.display_name if region.zone_name != "" else "")
	MapScreen.add_open_button(hud, _open_map)
	DexScreen.ensure_action()
	DexScreen.add_open_button(hud, _open_dex)
	hud.add_child(PartyBar.new())
	hud.add_child(ClockBadge.new())
	hud.add_child(PurseBadge.new())
	if ResourceLoader.exists(DEBUG_MENU):
		add_child(load(DEBUG_MENU).instantiate())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"map"):
		get_viewport().set_input_as_handled()
		_open_map()
	elif event.is_action_pressed(DexScreen.ACTION):
		get_viewport().set_input_as_handled()
		_open_dex()
	elif event.is_action_pressed(Input3D.MENU) and _free_to_open():
		get_viewport().set_input_as_handled()
		SettingsMenu.open(self, true)   # Start on the gamepad (Greg, 05/10): the settings, as the menu button


func _free_to_open() -> bool:
	return not zone.player.busy and not get_tree().paused and not Dialogue.active


## The zone's map (the 2.5D's), Chloé where she stands on it (in tiles).
func _open_map() -> void:
	if not _free_to_open():
		return
	var at := zone.player.global_position / zone.source.scale
	MapScreen.open(self, zone.source.region, WorldView.map_layers_for(zone.source.region), Vector2(at.x, at.z),
		Encounters3D.WORLD.ZONES)


func _open_dex() -> void:
	if _free_to_open():
		DexScreen.open(self)


## Chloé's lead dino at her side (if its species has a 3D sheet); a new lead takes its place.
func _place_companion() -> void:
	var lead := Game.lead_dino()
	if companion and is_instance_valid(companion):
		if lead and companion.dino == lead:
			return
		companion.queue_free()
		companion = null
	if lead == null:
		return
	companion = Dinosaur3D.companion(lead, zone.player)
	if companion == null:
		return
	var behind := zone.player.global_position - zone.player.facing() * 1.5
	companion.position = behind + Vector3(0, 0.3, 0)
	zone.add_child(companion)


## A new part of the day (dawn, day, dusk, night): the dinos out are the ones of that time (as the
## 2.5D's _spawn_roamers).
func _on_phase_changed(_phase: StringName) -> void:
	if not zone.player.busy and not get_tree().paused:
		zone.respawn_dinos()
		for d in zone.dinos:
			encounters.watch(d)
