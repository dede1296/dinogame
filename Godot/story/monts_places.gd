class_name MontsPlaces
## Chapter 6, the Monts Gelés: where things are (tiles, x right, y down), shared by the zone plans
## (tools/zones/monts.gd, grottes_glace.gd, sanctuaire_givre.gd) and the scenes (story/monts*.gd).
## The scenes use the names; the values follow the maps (tools/maps/gen-monts.mjs draws the big
## zone, 130 x 110 tiles, and checks each place below is reachable).
## The Monts climb from the south (the valley, 3.6 m) to the north (the glacier, 6 m) and the east
## (the col, 7.2 then 8.4 m), under the peaks (12.6 m) along the north and east edges. West: the way
## in from the Côte (4.8 m, the level of its clifftops; the Côte's row = the Monts' row + 28).

# ------------------------------------------------------------------ monts (the big zone)
## The way in from the Côte (west edge, x 0, rows 28-32: the trail from the Côte's clifftops goes
## on here, conifers either side), and the way back.
const ENTREE_COTE := Vector2(2.5, 30.0)
const SPAWN_COTE := &"DepuisCote"
const SPAWN_GROTTES := &"DepuisGrottes"
const SPAWN_SANCTUAIRE := &"DepuisSanctuaire"
## The Vallée des Troupeaux (south-west, 3.6 m): its middle, the herds' meadow, Bertille by her
## shelter (a dark hollow at the back of a notch dug into the south face of a rocky knoll: ABRI is
## the hollow) and her fire in front of it, the frozen lake (ice, walkable).
const VALLEE := Vector2(32.0, 72.0)
const TROUPEAU := Vector2(40.0, 66.0)
const BERTILLE := Vector2(22.5, 58.4)
const ABRI := Vector2(20.5, 55.0)
const FEU_BERTILLE := Vector2(20.5, 59.6)
const LAC_GELE := Vector2(40.0, 86.0)
## Page 30: a low rise at the valley's south-west, where one looks out over the island at night.
const PAGE_30 := Vector2(10.5, 95.0)
## The glacier (centre-north, 6 m, ice): where one steps onto it (its south part), its two ice
## walls (Charge: each one plugs the only way over a crevasse), the caves' mouth at the back of a
## notch in the peaks' face (north band), page 29 among the séracs of its middle band.
const GLACIER := Vector2(46.0, 34.0)
const MURS_GLACE: Array[Vector2] = [Vector2(57.0, 27.6), Vector2(67.0, 17.6)]
const ENTREE_GROTTES := Vector2(66.0, 6.0)
const PAGE_29 := Vector2(84.0, 20.5)
## The Col des Tempêtes (east): its top (8.4 m, reached from the glacier's south-east by a ramp to
## its terrace, 7.2 m, and a second ramp), where Roc comes out of the blizzard; page 28.
const COL := Vector2(110.0, 20.0)
const ROC_COL := Vector2(106.0, 24.0)
const PAGE_28 := Vector2(121.0, 14.5)
## The frost door of the sanctuary, at the back of its notch in the north face of the col (its
## foot, half a tile in front of the notch's back face); the closed way up to the Cieux (a gully
## north-west of the col, to the north edge).
const PORTE_GIVRE := Vector2(114.5, 7.55)
const SORTIE_CIEUX := Vector2(100.5, 0.5)
## Where Maïa comes back (before her challenge): on the col, in front of the door.
const MAIA_RETOUR := Vector2(109.5, 12.5)
## Grelot, Bertille's smallest Pachyrhinosaurus: at the foot of the first ice wall (on the way in
## side), then home by Bertille.
const GRELOT := Vector2(58.6, 29.8)
const GRELOT_VALLEE := Vector2(25.4, 60.2)

# ------------------------------------------------------------------ grottes_glace
## The way in (south edge), the Salle des stalactites (the first hall), the corridor up to Hélène's
## reserve (north): the sleepers in their ice blocks along its back wall, the eggs in the ice at
## its middle; Dame Suie at work by her vials, her sled at the reserve's east side; the ice wall
## (Charge) closing a side passage off the first hall (north-west), Hélène's little room behind it
## (page 26).
const GROTTES_ENTREE := Vector2(20.0, 35.0)
const SPAWN_GROTTES_DEPUIS_MONTS := &"DepuisMonts"
const SALLE := Vector2(20.0, 24.0)
const RESERVE := Vector2(24.5, 8.0)
const SUIE := Vector2(27.0, 9.4)
const FIOLES := Vector2(29.2, 8.2)
const TRAINEAU := Vector2(32.6, 11.0)
## Mandragore, Dame Suie's Therizinosaurus, harnessed in front of the sled.
const MANDRAGORE := Vector2(29.4, 11.9)
const DORMEURS: Array[Vector2] = [Vector2(15.0, 4.6), Vector2(19.5, 3.4), Vector2(29.5, 3.4), Vector2(34.0, 4.6)]
const OEUFS := Vector2(24.5, 3.0)
const MUR_GROTTES := Vector2(5.0, 19.6)
const CHAMBRE_HELENE := Vector2(5.0, 10.0)
const PAGE_26 := Vector2(3.5, 9.0)

# ------------------------------------------------------------------ sanctuaire_givre
## The way in (south edge: the ice corridor behind the frost door), the Cryolophosaure Titan in the
## middle of the round hall, the altar of the fourth Cœur at its back, page 27 beside it.
const SANCTUAIRE_ENTREE := Vector2(16.0, 31.0)
const SPAWN_SANCTUAIRE_DEPUIS_MONTS := &"DepuisMonts"
const TITAN := Vector2(16.0, 11.0)
const AUTEL := Vector2(16.0, 4.6)
const PAGE_27 := Vector2(24.0, 6.0)
