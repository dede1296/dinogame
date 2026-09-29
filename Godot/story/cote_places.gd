class_name CotePlaces
## Chapter 5, the Côte Préhistorique: every place the scenes and the objectives use, in tiles of
## the zone (Story.at() turns them into pixels). Aligned on the maps built by tools/zones/cote.gd
## (128 × 100 tiles, drawn by tools/maps/gen-cote.mjs, which checks each place is reachable),
## tools/zones/grottes_marines.gd (40 × 30) and tools/zones/recif_sanctuaire.gd (32 × 28), which
## read their places here. North is the sea: the Baie des Tortues (west), the Lagon behind its
## reef (centre), the Falaises à Ptéranodons (east); the way in from the Désert at the south-west,
## the way on to the Monts Gelés at the east edge. Also the spawns a lost battle takes Chloé back
## to, and the pages' flags.

# ------------------------------------------------------------------ spawns

## The côte's spawns (contract of the zone): from the Désert (south edge, x 18-22), out of the sea
## caves (the cove's beach), back up from the sanctuary (the sand bar by the pass), from the Monts
## (east edge, up on the top).
const SPAWN_DESERT := &"DepuisDesert"
const SPAWN_GROTTES := &"DepuisGrottes"
const SPAWN_RECIF := &"DepuisRecif"
const SPAWN_MONTS := &"DepuisMonts"
## The Désert's spawn from the Côte (tools/zones/desert.gd), and the spawns of the two small zones:
## the sea caves from the côte (their way in), from the sanctuary (the quay, up the sea tunnel),
## either end of their flooded passage (Plongée); the sanctuary from the côte (down from the
## pass) and from the sea caves (the tunnel).
const DESERT_SPAWN_COTE := &"DepuisCote"
const GROTTES_SPAWN_COTE := &"DepuisCote"
const GROTTES_SPAWN_RECIF := &"DepuisRecif"
const GROTTES_SPAWN_REMONTEE := &"Remontee"
const GROTTES_SPAWN_FOND := &"DepuisFond"
const RECIF_SPAWN_COTE := &"DepuisCote"
const RECIF_SPAWN_GROTTES := &"DepuisGrottes"
## Where a lost battle takes Chloé back to (the nearest way in to each fight).
const LOSE_PLAGE := SPAWN_DESERT
const LOSE_LAGON := SPAWN_DESERT
const LOSE_GROTTES := GROTTES_SPAWN_COTE
const LOSE_RECIF := RECIF_SPAWN_COTE

# ------------------------------------------------------------------ the côte (zone cote)

## The way in from the Désert: the gap in the rocks where the dunes start (south-west).
const ARRIVEE := Vector2(20.0, 91.0)
## The first sight of the sea: the top of the last dune (1.2 m), over the bay (the trail ends there).
const DUNE_MER := Vector2(19.0, 81.5)
## The Plage aux tortues (south shore of the Baie des Tortues): its middle, and the turtles'
## nests in the sand above the tide line (the second one is the StoryProp « NidTortues »).
const PLAGE_TORTUES := Vector2(20.0, 75.5)
const NIDS := [Vector2(11.5, 76.5), Vector2(16.0, 77.5), Vector2(21.0, 76.2), Vector2(34.2, 70.6)]
## The fishermen of « La Sardine » (Npcs « Gustave », « Firmin ») by their boat stranded at the
## water's edge and their net spread on the sand.
const PECHEURS := Vector2(26.5, 73.8)
const GUSTAVE := Vector2(26.0, 73.6)
const FIRMIN := Vector2(28.4, 74.2)
const SARDINE := Vector2(27.2, 71.3)
## The Cale des Anciens (west end of the beach): the carved steps going down into the bay, and
## the platform above them where page 24 lies.
const ANCIENS := Vector2(5.5, 71.5)
const CALE := Vector2(5.5, 75.0)
## The turtles' islet out in the bay (reached swimming).
const ILOT_TORTUES := Vector2(23.0, 57.0)
## The Pointe des Palmes (between the bay and the lagoon): its path, and its rocky tip facing
## the open sea (the Ichthyosaurs are seen from there).
const POINTE := Vector2(45.5, 45.0)
const POINTE_BOUT := Vector2(45.0, 32.5)
## The Lagon: its middle (water), its south shore (the meadow's edge), the islet with palms in it.
const LAGON := Vector2(68.0, 42.0)
const RIVE_LAGON := Vector2(70.0, 60.0)
const ILOT := Vector2(75.0, 42.5)
## The Plesiosaurus's spot: a sandy point jutting into the lagoon from its south shore (Chloé
## stands at its tip), the water just in front where the Plesiosaurus surfaces, and Joss
## (Npc « JossCote ») on the shore behind.
const BORD_PLESIOSAURE := Vector2(62.5, 51.6)
const PLESIOSAURE_EAU := Vector2(62.5, 50.1)
const JOSS := Vector2(60.0, 57.0)
## The reef closing the lagoon to the north (a ridge of rock 1 m out of the water), the pass
## through it (only « I. » knew it: page 21), the sand bar just inside the pass (where one comes
## back up from the sanctuary), and beyond the pass the place where one dives down to the
## sanctuary's reef (zone recif_sanctuaire; its blue glow, seen from afar at night).
const RECIF := Vector2(70.0, 27.0)
const PASSE := Vector2(68.5, 27.0)
const BANC_PASSE := Vector2(73.5, 29.5)
const ACCES_RECIF := Vector2(68.5, 20.5)
const LUEUR_RECIF := Vector2(68.5, 21.0)
## The boat without a lantern seen at night: from the open sea, through the pass, across the
## lagoon into the cove of the sea caves (water all along).
const BARQUE_NUIT := [Vector2(66.0, 6.0), Vector2(68.5, 26.0), Vector2(89.5, 32.0)]
## The Falaises à Ptéranodons (east): the headland over the sea (4.8 m), its north ledges where
## the colony nests (out of reach: where the camera shows them), the foot of the cliffs by the
## lagoon (the east beach), the first terrace (2.4 m, up its ramp) and the top (4.8 m).
const FALAISES := Vector2(110.0, 14.0)
const COLONIE_VUE := Vector2(110.0, 10.0)
const PIED_FALAISES := Vector2(88.0, 50.0)
const TERRASSE := Vector2(97.5, 62.5)
const SOMMET := Vector2(110.0, 48.0)
## Maïa on the top by the colony (Npc « MaiaFalaises », Caillou next to her).
const MAIA_FALAISES := Vector2(108.5, 14.5)
## The sea caves: the little shingle beach at the back of the cove (reached swimming) and the
## cave's dark mouth at the back of a notch in the headland's south face (zone grottes_marines).
const ANSE_GROTTES := Vector2(93.0, 28.2)
const ENTREE_GROTTES := Vector2(93.0, 25.0)
## Maïa's lookout: the first terrace's corner over the cove (2.4 m), where she sees everything
## (the cave's mouth, the lagoon, the pass): Maïa there (Npc « MaiaGuet »), and Hélène's box in a
## niche at the foot of the rock face behind (StoryProp « BoiteHelene »: page 23).
const BELVEDERE := Vector2(98.0, 30.5)
const MAIA_GUET := Vector2(97.6, 29.6)
const BOITE_HELENE := Vector2(100.5, 27.4)
## The ruined lighthouse on the headland (a building to assemble in 3D later: not there yet).
const PHARE := Vector2(117.0, 13.0)
## The way on to the Monts Gelés (east edge, up on the top: closed for now).
const SORTIE_MONTS := Vector2(127.0, 58.0)
## The way back to the Désert (south edge).
const SORTIE_DESERT := Vector2(19.5, 99.0)

# ------------------------------------------------------------------ the sea caves (zone grottes_marines)

## The way in (from the cove, south), the first cave (dry: tide pools, amber crystals), the blue
## pool at its back where one dives into the flooded passage (Plongée), the small pool in the
## inner cave where one comes up, the smugglers' cache (crates of black amber, the Passeur by
## them), page 21 under « H. + I. » carved in the rock, Isaure's boat moored at the stone quay,
## the sea tunnel out of the inner cave (north-east: Isaure's way to the sanctuary).
const GROTTES_ENTREE := Vector2(20.0, 27.0)
const GROTTES_SALLE := Vector2(20.0, 19.0)
const GROTTES_PLONGEE := Vector2(20.0, 13.0)
const GROTTES_REMONTEE := Vector2(19.5, 6.6)
const CACHE := Vector2(8.0, 4.2)
const PASSEUR := Vector2(23.0, 5.2)
const PAGE_21 := Vector2(12.5, 2.4)
const GRAVURE := Vector2(12.5, 1.1)
const QUAI := Vector2(25.0, 4.0)
const BARQUE := Vector2(30.0, 4.2)
const TUNNEL_MER := Vector2(35.5, 1.0)

# ------------------------------------------------------------------ the sanctuary (zone recif_sanctuaire)

## Where Chloé comes down (south: from the pass; south-west: the tunnel from the caves), the
## Mosasaure Abyssal (middle of the sand arena), the altar of the third Cœur on its dais (back,
## north; StoryProp « Autel », event « coeur_recif »), page 22 beside it.
const RECIF_ARRIVEE := Vector2(16.0, 24.0)
const RECIF_TUNNEL := Vector2(3.5, 24.5)
const MOSASAURE := Vector2(16.0, 13.5)
const AUTEL := Vector2(16.0, 4.6)
const PAGE_22 := Vector2(27.4, 4.7)   # (up on the spire by the altar: the bubble column takes Chloé there)

# ------------------------------------------------------------------ pages

## The Côte's journal pages and roughly where Hélène left them (a direction, not the place), for
## the objectives: [flag, zone, tiles, hint]. Page 23 is in Hélène's box at the lookout (found
## with Maïa); page 25 lies on the lagoon's bottom (Plongée), the others are Pickups « PageNN ».
const PAGES := [
	[&"found_journal_21", &"grottes_marines", PAGE_21, "dans la cache des grottes marines"],
	[&"found_journal_22", &"recif_sanctuaire", PAGE_22, "sur le piton de roche, près de l'autel du récif"],
	[&"found_journal_23", &"cote", BOITE_HELENE, "au belvédère des falaises"],
	[&"found_journal_24", &"cote", CALE, "à la cale des Anciens, au bout de la plage aux tortues"],
	[&"found_journal_25", &"cote", Vector2(80.5, 36.5), "au fond du lagon (Plongée)"],
]


const TILE := 48.0
## The zones' scenes when world.gd does not list them yet (its ZONES comes first).
const ZONE_SCENES := {
	&"cote": "res://regions/cote/cote.tscn",
	&"grottes_marines": "res://regions/cote/grottes_marines.tscn",
	&"recif_sanctuaire": "res://regions/cote/recif_sanctuaire.tscn",
	&"desert": "res://regions/desert/desert.tscn",
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
