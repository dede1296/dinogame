class_name CieuxPlaces
## Chapter 7, the Cieux Éternels: where things are (tiles, x right, y down), shared by the zone plans
## (tools/zones/cieux.gd, nids_geants.gd, arche_du_vent.gd) and the scenes (story/cieux*.gd, which
## read these names through Cieux.place). The values follow the maps; the plans check each place
## below is reachable on foot (or, for ILOTS_VOL, only in flight).
## The three zones climb northwards, one above the other: the Monts' gully (their north edge) comes
## out on the south edge of `cieux`; the carved ramp at its north edge goes up into `nids_geants`
## (its south edge); the needle at the north edge of the nests leads to `arche_du_vent` (its south
## edge). Between the pitons, the void: the sea of clouds, CLOUDS m high in each zone (VIDE_SOUS: below
## it, a tile is the void, Region meta « vol_vide_sous »; where two zones meet, their clouds meet at
## the same height); the pitons' tops from 10.8 m (the arrival) to 16.2 m (the Arche's terrace).

## Each zone's sea of clouds (m), and the height under which a tile is the void (no landing).
const CLOUDS := {&"cieux": 8.4, &"nids_geants": 12.0, &"arche_du_vent": 12.0}
const VIDE_SOUS := {&"cieux": 10.0, &"nids_geants": 13.2, &"arche_du_vent": 13.2}
## The highest ground of each zone (m; its decor can stand 6 m higher): how high the flight goes.
const SOL_MAX := {&"cieux": 15.0, &"nids_geants": 15.0, &"arche_du_vent": 16.2}

# ------------------------------------------------------------------ cieux (100 x 86)
## The arrival from the Monts: their gully (Monts x 99-101) comes out on the south edge (x 71-73,
## Monts x = Cieux x + 28) along a ridge over the clouds, onto the Piton d'Arrivée (10.8 m):
## its terrace (7 x 6, level), the void all round but for the way back south.
const SPAWN_MONTS := &"DepuisMonts"
const SPAWN_NIDS := &"DepuisNids"
const ENTREE_MONTS := Vector2(72.5, 76.5)
const PITON_ARRIVEE := Vector2(72.0, 75.0)
const SORTIE_MONTS := Vector2(72.5, 85.5)
## The fire in the shelter of a rock (the terrace's south-west), the signs.
const FEU_ARRIVEE := Vector2(69.8, 77.2)
const PANNEAU_ENTREE := Vector2(75.6, 78.4)
const PANNEAU_PONT := Vector2(68.0, 71.0)
## The first liana bridge (the one that sways), straight west from the terrace to the Piton du Guet
## (11.4 m): its middle, and where it starts on the arrival side (the scene's trigger « PremierPont »).
const PREMIER_PONT := Vector2(62.0, 73.0)
const PREMIER_PONT_DEBUT := Vector2(66.5, 73.0)
## The pitons on foot: the Guet (11.4 m, the crossroads), the Mer de nuages to the west (10.8 m, its
## hollow full of clouds one walks on like a frozen lake, 10.4 m), the Vents (12 m), the Haut (12.6 m)
## under the carved ramp up to the nests; to the east, the Piton Fendu (12 m), the rhamphorhynchus'
## piton (11.4 m), and the Belvédère (13.2 m, the highest on foot: page 31, a bench).
const GUET := Vector2(52.0, 72.0)
const MER_DE_NUAGES := Vector2(25.0, 63.5)
const VENTS := Vector2(52.0, 50.0)
const HAUT := Vector2(46.0, 30.0)
const RHAMPHOS := Vector2(89.0, 70.0)
const FENDU := Vector2(79.0, 50.0)
const BELVEDERE := Vector2(76.0, 21.0)
const PAGE_31 := Vector2(76.8, 19.4)
const BANC_BELVEDERE := Vector2(73.8, 20.4)
const PANNEAU_BELVEDERE := Vector2(78.2, 21.4)
## The carved ramp up to the nests (north edge, x 45-47, through the Rempart).
const SORTIE_NIDS := Vector2(46.5, 0.5)
## Out of reach on foot (the Vol): page 33 on its islet in the sea of clouds, south-west of the Mer.
const ILOT_NUAGES := Vector2(8.0, 78.0)
const PAGE_33 := Vector2(8.0, 77.5)
## Two more for the Vol: a needle with a nest (an amber pebble), a balcony over the clouds (an old
## chest).
const AIGUILLE_AU_NID := Vector2(93.0, 36.0)
const BALCON_BRUMES := Vector2(18.0, 38.0)

# ------------------------------------------------------------------ nids_geants (70 x 60)
## The way in from the Cieux: the carved way goes on across the south edge (x 33-35, Cieux x = Nids
## x + 12) through the last of the Rempart to the Aire des Plumes (13.8 m): the fire under a fallen
## nest, the sign.
const NIDS_ENTREE := Vector2(34.5, 50.0)
const SPAWN_CIEUX := &"DepuisCieux"
const SPAWN_ARCHE := &"DepuisArche"
const SORTIE_CIEUX := Vector2(34.5, 59.5)
const FEU_NIDS := Vector2(28.0, 48.0)
const PANNEAU_NIDS := Vector2(38.8, 50.6)
## The nests (14.4 m, up a ramp): « as big as boats », between them the young Quetzalcoatlus and the
## Tapejara; page 32 in a crack of rock by an empty nest.
const NIDS := Vector2(36.0, 32.0)
const NIDS_BRANCHES: Array[Vector2] = [Vector2(26.0, 31.5), Vector2(33.5, 28.0), Vector2(43.0, 28.5), Vector2(47.5, 34.0)]
const JEUNES_QUETZAL: Array[Vector2] = [Vector2(29.5, 34.0), Vector2(39.5, 31.5), Vector2(44.5, 36.5)]
const TAPEJARAS: Array[Vector2] = [Vector2(23.5, 35.0), Vector2(36.5, 35.5)]
const PAGE_32 := Vector2(45.6, 36.4)
## The Grand Nid at the top (15 m, up a second ramp): its level square (9 x 7, nothing on it,
## x 19-27, y 9-15), the Roi at its north edge facing the way in (south), Hélène's old harness two
## tiles from him.
const GRAND_NID := Vector2(23.0, 12.0)
const ROI := Vector2(23.0, 9.6)
const VIEUX_HARNAIS := Vector2(25.6, 10.0)
## The needle at the north edge (15 m, its top 5 x 5; a liana bridge from the Grand Nid): the way to
## the Arche du Vent on its north border (closed until the Vol: « arche_bloquee »).
const AIGUILLE := Vector2(43.0, 5.0)
const SORTIE_ARCHE := Vector2(43.0, 0.5)
## For the Vol only: an old nest on its own piton (a curing fern in it).
const NID_OUBLIE := Vector2(59.0, 19.0)

# ------------------------------------------------------------------ arche_du_vent (56 x 44)
## The landing platform at the south edge (15 m: the needle's top, Nids x = Arche x + 15), a ramp up
## to the terrace (16.2 m).
const ARCHE_ENTREE := Vector2(28.0, 40.5)
const SORTIE_NIDS_ARCHE := Vector2(28.0, 43.5)
const PANNEAU_ARCHE := Vector2(31.2, 40.4)
## The terrace under and in front of the arch: its middle, level and bare over 12 x 10 tiles
## (x 22-33, y 16-25); the arch's foot (its picture stands there, ~8 m wide); the Masque two tiles
## north of the middle; the Roi lands on its east border; the obsidian mask, after the scene, one tile
## south-west of the middle.
const ARCHE := Vector2(28.0, 21.0)
const ARCHE_PIED := Vector2(28.0, 18.4)
const MASQUE := Vector2(28.0, 19.0)
const BORD_ROI := Vector2(38.5, 21.5)
const MASQUE_OBSIDIENNE := Vector2(27.0, 22.0)
## Behind the arch, north-west: the path of cinders going down towards the Plaine Volcanique (2 tiles
## wide, ~13 long, 16.2 m down to 14.4 m; its exit at the north edge closed: « volcan_bloque »).
const DESCENTE_CENDRE := Vector2(20.0, 11.0)
const SORTIE_VOLCAN := Vector2(20.0, 0.5)
## Hélène's post: a cairn of flat stones and an iron box east of the arch, page 34.
const CAIRN := Vector2(36.5, 16.5)
const PAGE_34 := Vector2(37.4, 17.2)
## The fire in the shelter of the arch's west pillar (out of the terrace's square).
const FEU_ARCHE := Vector2(19.5, 19.0)

# ------------------------------------------------------------------ for the Vol
## Level open ground, clear, at least 5 x 5, where one lands well (the mechanics may offer them).
const ATTERRISSAGES_CIEUX: Array[Vector2] = [Vector2(72.5, 75.0), Vector2(52.0, 72.0), Vector2(25.0, 63.5), Vector2(52.0, 50.0),
	Vector2(46.0, 30.0), Vector2(79.0, 50.0), Vector2(89.0, 70.0), Vector2(76.0, 21.0)]
const ATTERRISSAGES_NIDS: Array[Vector2] = [Vector2(34.5, 48.0), Vector2(36.0, 32.0), Vector2(23.0, 12.0), Vector2(43.0, 5.0)]
const ATTERRISSAGES_ARCHE: Array[Vector2] = [Vector2(28.0, 40.5), Vector2(28.0, 21.0)]
## The places reached only in flight (neither needed by the story nor dangerous): zone, tile.
const ILOTS_VOL := [
	[&"cieux", Vector2(8.0, 78.0)], [&"cieux", Vector2(93.0, 36.0)], [&"cieux", Vector2(18.0, 38.0)],
	[&"nids_geants", Vector2(59.0, 19.0)],
]
