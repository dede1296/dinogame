class_name DesertPlaces
## Chapter 4, the Désert Aride: every place the scenes and the objectives use, in tiles of the
## zone (Story.at() turns them into pixels). All to be aligned on the map built by
## tools/zones/desert.gd (and tools/zones/sanctuaire_vents.gd for the sanctuary): the values
## here are first guesses for a map of about 120 × 100 tiles, south-east entry, sanctuary in the
## north. Also the spawns a lost battle takes Chloé back to, and the fossils' flags.

# ------------------------------------------------------------------ spawns (zone desert)

## The desert's spawns (contract of the zone): from the Marais (south-east), in front of the
## sanctuary's door, from the Côte (north).
const SPAWN_MARAIS := &"DepuisMarais"
const SPAWN_SANCTUAIRE := &"DepuisSanctuaire"
const SPAWN_COTE := &"DepuisCote"
## Where a lost battle takes Chloé back to: Brac and the Carnotaurus (the canyon des Vents
## starts next to the sanctuary), Maïa at the oasis (near the road north).
## L'arrivée la plus proche de chaque combat.
const LOSE_BRAC := SPAWN_SANCTUAIRE
const LOSE_MAIA := SPAWN_COTE

# ------------------------------------------------------------------ the Marais (zone marais)

## The Marais's way north to the Désert (the first objective of the chapter).
## INF : pas de repère fixe (le repère vient de spot(&"marais", "DepuisDesert")).
const MARAIS_NORD := Vector2.INF

# ------------------------------------------------------------------ the Désert (zone desert)

## The entry canyon (south-east), where the cart's tracks are first seen. (Aligné sur tools/zones/desert.gd.)
const ENTREE := Vector2(102.0, 94.0)
## Tante Sirocco, in front of her tent at the edge of the Cimetière des Géants (Npc « Sirocco »).
## (Aligné sur tools/zones/desert.gd.)
const SIROCCO := Vector2(85.6, 67.6)
## The middle of the Cimetière des Géants (the fossils' objective). (Aligné sur tools/zones/desert.gd.)
const CIMETIERE := Vector2(74.5, 73.0)
## The walled canyon (west): the fallen rocks (Obstacle « RempartEboulis ») and the Vieux
## Rempart behind them (DinoNpc « VieuxRempart »). (Aligné sur tools/zones/desert.gd.)
const REMPART_EBOULIS := Vector2(28.5, 58.8)
const VIEUX_REMPART := Vector2(20.5, 32.0)
## The sanctuary des Vents (north): its door (StoryProp « PorteVents »; the scenes use the
## node when it is there), the square in front (StoryTrigger « brac_sanctuaire », radius ~3;
## Chloé is brought back in front of the door at the spawn « DepuisSanctuaire »), and the
## mouth of the canyon des Vents where Brac flees (west). (Aligné sur tools/zones/desert.gd.)
const PORTE_VENTS := Vector2(60.5, 3.0)
const PLACE_SANCTUAIRE := Vector2(60.5, 10.0)
const CANYON_VENTS := Vector2(49.0, 9.5)
## Where Brac and the chained Carnotaurus stand in front of the door, and where the freed
## Carnotaurus roars and lies down afterwards: offsets from the door (tiles; the door faces south).
const BRAC_PORTE := Vector2(-2.0, 2.5)
const CARNO_PORTE := Vector2(1.5, 2.0)
const CARNO_GARDE := Vector2(2.5, 1.5)
## The three moments of the chase in the canyon des Vents (StoryTriggers « poursuite_1 » … 3,
## radius ~2.5, in this order from the sanctuary towards the dead end). (Aligné sur tools/zones/desert.gd.)
const POURSUITES := [Vector2(45.0, 11.2), Vector2(35.0, 15.0), Vector2(25.5, 12.6)]
## The dead end: Brac (Npc « BracDesert »), his cart (StoryProp « ChariotBrac »), the
## Carnotaurus once free (DinoNpc « CarnotaurusRouge »; the scene puts it next to the cart when
## the zone has none yet: CARNO_CHARIOT, tiles from the cart), and where Brac climbs away. (Aligné sur tools/zones/desert.gd.)
const BRAC_DESERT := Vector2(15.5, 12.4)
const CHARIOT := Vector2(12.6, 8.2)
const CARNO := Vector2(17.8, 7.6)
const CARNO_CHARIOT := Vector2(5.2, -0.6)
const BRAC_FUITE := Vector2(8.5, 3.5)
## The oasis (north-east): Maïa (Npc « MaiaOasis »), where she goes afterwards (her camp under
## the palms), the dune Chloé climbs at dusk, and the road north to the Côte. (Aligné sur tools/zones/desert.gd.)
const OASIS := Vector2(99.0, 31.0)
const MAIA_OASIS := Vector2(93.2, 30.2)
const MAIA_AWAY := Vector2(105.0, 28.6)
const DUNE := Vector2(103.5, 14.5)
const SORTIE_COTE := Vector2(100.0, 1.0)

# ------------------------------------------------------------------ the sanctuary (zone sanctuaire_vents)

## The altar of the second Cœur (StoryProp « Autel », event « coeur_vents ») and the way in.
## (Aligné sur tools/zones/sanctuaire_vents.gd.)
const AUTEL := Vector2(15.5, 8.0)
const SANCTUAIRE_ENTREE := Vector2(15.5, 21.6)

# ------------------------------------------------------------------ fossils and pages

## The six fossils buried in the Cimetière des Géants (ZoneBuilder.buried_item(…, "fossile",
## flag)), with where Tante Sirocco feels each one (her hint when Chloé asks). Suggested spots,
## where tools/zones/desert.gd buries them, so the hints stay true.
const FOSSILS := [
	[&"fossile_1", Vector2(74.2, 71.3), "sous le grand crâne, au milieu du cimetière"],
	[&"fossile_2", Vector2(66.6, 77.0), "entre les côtes du grand squelette"],
	[&"fossile_3", Vector2(83.4, 69.5), "au pied d'un os géant, pas loin de ma tente"],
	[&"fossile_4", Vector2(77.2, 83.8), "au bord du lac de sel, au sud du cimetière"],
	[&"fossile_5", Vector2(61.3, 67.2), "à l'ombre de l'arche de pierre, à l'ouest"],
	[&"fossile_6", Vector2(70.7, 61.8), "sous un buisson sec, tout au nord du cimetière"],
]
## Fossils Tante Sirocco asks for (of the six).
const FOSSILS_WANTED := 5
## The Désert's journal pages (Pickups « Page17 » … « Page20 ») and roughly where Hélène hid
## them (a direction, not the place), for the objectives.
const PAGES := [
	[&"found_journal_17", "dans le Cimetière des Géants"],
	[&"found_journal_18", "dans le sanctuaire des Vents"],
	[&"found_journal_19", "à l'oasis"],
	[&"found_journal_20", "au fond du canyon muré"],
]


const TILE := 48.0
## The zones' scenes when world.gd does not list them yet (its ZONES comes first).
const ZONE_SCENES := {
	&"desert": "res://regions/desert/desert.tscn",
	&"sanctuaire_vents": "res://regions/desert/sanctuaire_vents.tscn",
	&"marais": "res://regions/marais/marais.tscn",
}
## Nodes' places in each zone, read once from the zone's scene (see spot).
static var _spots: Dictionary = {}


## Where node `node_name` stands in zone `zone` (tiles), read from the zone's scene, so the
## markers follow the map when it changes; `fallback` (the constants above) when the zone or
## the node is not there (yet).
static func spot(zone: StringName, node_name: String, fallback: Vector2) -> Vector2:
	if not _spots.has(zone):
		_spots[zone] = _read_spots(zone)
	return (_spots[zone] as Dictionary).get(node_name, fallback)


static func _read_spots(zone: StringName) -> Dictionary:
	var out := {}
	var zones: Dictionary = (load("res://world/world.gd") as Script).get_script_constant_map().get("ZONES", {})
	var path: String = zones.get(zone, ZONE_SCENES.get(zone, ""))
	if path == "" or not ResourceLoader.exists(path):
		return out
	var scene := load(path) as PackedScene
	if scene == null:
		return out
	var state := scene.get_state()
	for i in state.get_node_count():
		for p in state.get_node_property_count(i):
			if state.get_node_property_name(i, p) == &"position":
				out[String(state.get_node_name(i))] = (state.get_node_property_value(i, p) as Vector2) / TILE
				break
	return out


## How many of the six fossils Chloé has dug up (their flags, not the item: fossils may be
## used elsewhere later).
static func fossils_found() -> int:
	var n := 0
	for f: Array in FOSSILS:
		if Game.flag(f[0]):
			n += 1
	return n


## Where the next fossil still buried is (Sirocco's hint), or "" when all are found.
static func next_fossil_hint() -> String:
	for f: Array in FOSSILS:
		if not Game.flag(f[0]):
			return f[2]
	return ""
