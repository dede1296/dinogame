class_name ApexPlaces
## Chapter 9, la Terre des Apex, and the epilogue: where things are (tiles, x right, y down), shared by
## the zone plans (tools/zones/apex_terre.gd builds `terre_apex`, apex_coeur.gd `coeur_apex`; the
## raccord in tools/zones/volcan_porte.gd; the epilogue's additions in tools/zones/cabinet.gd and
## port_ambre.gd) and the scenes (story/apex*.gd, story/epilogue.gd). The plans check that each place
## is reached on foot from the way in (docs/zones/apex.md).
## THE WAY: porte_cratere (chapter 8: VolcanPlaces keeps the portal, Isaure, Maïa, Caillou, the camp,
## page 38) → through the portal, once « apex_ouvert » → terre_apex, entered by its NORTH edge: Chloé
## stands on the rim's ledge, the crater below her, towards the camera (the camera looks north: the
## crater's walls face it). A trail winds down in a spiral (west along the ledge, down the west wall,
## round the floor by the south and the east) to the hole in the middle of the floor, the fond: a ramp
## goes down into it along its east side → coeur_apex, entered by the north edge too: the corridor goes
## down along the east wall into the round hall, the bloc in its north half.

## The arrival spawns (Spawns/<name>) of each zone, by where Chloé comes from.
const SPAWN_APEX := &"DepuisApex"     # porte_cratere, back out of the portal
const SPAWN_PORTE := &"DepuisPorte"   # terre_apex, through the portal
const SPAWN_COEUR := &"DepuisCoeur"   # terre_apex, back up the ramp from the fond
const SPAWN_TERRE := &"DepuisTerre"   # coeur_apex, down from the crater
## The duel against Isaure lost: Chloé gets up by Hélène's camp (porte_cratere).
const LOSE_AUBE := &"DevantCamp"

# ------------------------------------------------------------------ porte_cratere, l'aube (50 x 40)
## (The chapter 8 zone: VolcanPlaces.PORTAIL, TORCHES, ISAURE, MAIA, CAILLOU, CAMP_HELENE, PAGE_38.)
## Chloé facing Isaure, the portal behind her.
const AUBE_CHLOE := Vector2(25.0, 12.8)
## Where Chloé lays the five Cœurs in their hollows (at hand height on the portal).
const DEVANT_PORTAIL := Vector2(25.0, 7.6)
## The way through (the exit « VersTerreApex », open once « apex_ouvert »), and where Chloé comes back
## out of it (« DepuisApex »).
const SORTIE_APEX := Vector2(25.0, 6.8)
const DEPUIS_APEX := Vector2(25.0, 8.9)
## The duel lost: by Hélène's camp (spawn « DevantCamp »).
const DEVANT_CAMP := Vector2(17.4, 10.4)
## Isaure's four (Hauban, Bouline, Étrave, Carène: spawned by the scenes at the whistle, chapitre-9-scenes.md
## 1 b): asleep behind the rocks along the crater's sides, then lined up east of her (her side), and back.
const DINOS_ISAURE_CACHES: Array[Vector2] = [Vector2(44.2, 9.4), Vector2(45.2, 13.0), Vector2(44.6, 16.4), Vector2(43.4, 19.8)]
const DINOS_ISAURE_RANG: Array[Vector2] = [Vector2(28.8, 11.6), Vector2(33.2, 12.2), Vector2(36.4, 14.4), Vector2(32.2, 16.0)]

# ------------------------------------------------------------------ terre_apex (80 x 70)
## The way in at the north edge (x 39-41), on the rim's ledge (16.2 m, as the esplanade of the portal).
const TERRE_ENTREE := Vector2(40.5, 3.2)
const SORTIE_PORTE_TERRE := Vector2(40.5, 0.3)
## The ledge's edge over the crater (« le bord »): Isaure and Maïa a few steps ahead, stopped, looking down;
## Caillou behind them (all gone down once « apex_arrivee »: they wait in coeur_apex).
const LE_BORD := Vector2(40.5, 10.4)
const ISAURE_ARRIVEE := Vector2(39.2, 9.2)
const MAIA_ARRIVEE := Vector2(41.9, 9.5)
const CAILLOU_ARRIVEE := Vector2(45.6, 8.0)
## Hélène's last cairn, on the ledge left of the way in, against the rim (three black stones on a flat one),
## page 39 under it.
const CAIRN := Vector2(33.5, 7.4)
const PAGE_39 := Vector2(34.4, 7.8)
## The Roi des Cieux, perched high on the rim (out of reach), east of the way in; his shadow circles over
## the crater (ROI_CIEL, for the scenes).
const ROI_PERCHE := Vector2(49.5, 2.2)
const ROI_CIEL := Vector2(40.0, 30.0)
## The spiral trail, from the way in to the top of the ramp (the scenes may walk Isaure and Maïa down it):
## along the ledge westwards, down the west wall, round the floor by the south and the east.
const SPIRALE: Array[Vector2] = [
	Vector2(40.5, 0.0), Vector2(40.5, 8.0), Vector2(33.0, 9.2), Vector2(25.0, 12.5), Vector2(17.0, 16.0),
	Vector2(13.5, 19.0), Vector2(10.5, 26.0), Vector2(9.5, 33.0), Vector2(11.0, 39.0),
	Vector2(15.0, 46.0), Vector2(21.0, 53.0), Vector2(29.0, 58.0), Vector2(40.0, 60.0), Vector2(51.0, 58.0), Vector2(58.0, 53.5),
	Vector2(63.0, 47.0), Vector2(65.0, 40.0), Vector2(62.0, 32.5), Vector2(55.0, 28.0), Vector2(50.0, 31.0), Vector2(47.5, 34.2),
]
## The foot of the west wall (where the spiral reaches the floor).
const PIED_PAROI := Vector2(11.5, 40.0)
## The four blocks of the sleeping giants (StoryProps « BlocGeant1..4 », their front foot): (1) a paw and
## claws like scythes, on the floor under the west wall; (2) a neck round the block, on the floor at the foot
## of the north wall; (3) plates and spikes, at the end of the ledge's east arm; (4) the small one with
## Hélène's feather, on the floor, south-east.
const BLOCS_GEANTS: Array[Vector2] = [Vector2(17.0, 30.0), Vector2(26.0, 20.0), Vector2(67.0, 20.5), Vector2(57.5, 47.5)]
## Where to stand to look at each (in front of it, on its south side).
const DEVANT_BLOCS: Array[Vector2] = [Vector2(17.0, 31.6), Vector2(26.0, 21.6), Vector2(67.0, 22.2), Vector2(57.5, 49.0)]
## The fond: the hole in the middle of the floor (its walls 5.5 m), the bloc seen from above in it (and,
## once he is calm, the Souverain lying before what is left of it); the ramp down into it along its east
## side, the exit at its foot (« VersCoeurApex »).
const FOND := Vector2(40.0, 44.0)
const BLOC_LOIN := Vector2(38.5, 43.0)
const SOUVERAIN_LOIN := Vector2(38.5, 46.6)
const RAMPE_HAUT := Vector2(47.5, 35.2)
const RAMPE_BAS := Vector2(47.5, 43.6)
const SORTIE_COEUR := Vector2(47.5, 44.3)
const DEPUIS_COEUR := Vector2(47.5, 34.4)

# ------------------------------------------------------------------ coeur_apex (50 x 40)
## The way in at the north edge (x 41-43), the corridor down along the east wall into the round hall (open
## to the sky, its walls veined with amber; the walls of its south half are low: the camera sees in).
const COEUR_ENTREE := Vector2(42.5, 3.0)
const SORTIE_TERRE_COEUR := Vector2(42.5, 0.3)
const COULOIR_BAS := Vector2(41.0, 21.0)
const SALLE := Vector2(24.0, 21.0)
## The bloc (StoryProp « BlocSouverain », its front foot): the Souverain lying in it, eyes open, Hélène
## against his flank (in the picture: HELENE_AMBRE), her hand flat on him; MAIN_HELENE: where Isaure lays
## her hand on the amber, on Hélène's.
const BLOC := Vector2(24.0, 16.0)
const HELENE_AMBRE := Vector2(22.2, 15.8)
const MAIN_HELENE := Vector2(22.2, 17.2)
## Waiting before the bloc when Chloé comes in: Isaure (her hand on it), Maïa beside her, Caillou behind.
const ISAURE := Vector2(22.2, 17.9)
const MAIA := Vector2(20.0, 19.0)
const CAILLOU := Vector2(16.6, 21.2)
## Chloé before the bloc; where her dino tries (claws, charge, song).
const CHLOE_BLOC := Vector2(25.6, 19.6)
const ESSAIS := Vector2(25.4, 17.6)
## The rock where Maïa pulls her mother and Hélène (west of the bloc, his tail's side), the sheltered side
## of it (south-west: seen by the camera), and Caillou holding the line between it and him.
const ROCHER_ABRI := Vector2(12.8, 18.4)
const ABRI := Vector2(12.0, 20.6)
const ISAURE_ABRI := Vector2(11.2, 20.6)
const HELENE_ABRI := Vector2(12.0, 21.2)
const MAIA_ABRI := Vector2(13.6, 21.0)
const CAILLOU_REMPART := Vector2(16.8, 18.8)
## Awake (« souverain_eveille »): he has backed against the north wall, north-east of what is left of the
## bloc (not behind it: it would hide him), trembling (DinoNpc « Souverain »).
const SOUVERAIN_PAROI := Vector2(31.5, 12.4)
## The fight, before the battle screen: Chloé, her dino between her and him (facing north-east).
const AIRE_COMBAT := Vector2(28.0, 19.6)
const COMBAT_CHLOE := Vector2(26.4, 23.6)
const COMBAT_DINO := Vector2(28.0, 21.4)
## Calm (« souverain_apaise »): he lies down in the middle of the hall, before what is left of the bloc
## (DinoNpc « SouverainCouche »); the Roi lands at the east edge of the hall (ROI_POSE), circling first
## (ROI_CIEL_COEUR).
const SOUVERAIN_COUCHE := Vector2(24.0, 19.6)
const ROI_POSE := Vector2(35.0, 17.4)
const ROI_CIEL_COEUR := Vector2(24.0, 6.0)

# ------------------------------------------------------------------ the Cabinet, three days later (16 x 11)
## Hélène in Roc's armchair (story/foret_fin.gd ARMCHAIR_SEAT), the little table before it (« TableThe »),
## the blue cup on it once « tasse_bleue » (« TasseBleue »; taken from the top of the great shelf: TASSE_ETAGERE),
## the case of notebooks on the desk (« CaisseCarnets », once « carnets_rendus »).
const CABINET_HELENE := Vector2(9.4, 3.65)
const CABINET_TABLE := Vector2(9.4, 5.1)
const TASSE_BLEUE := Vector2(9.75, 5.16)
const TASSE_ETAGERE := Vector2(3.3, 1.95)
const CAISSE_CARNETS := Vector2(4.75, 3.06)
## Roc with the teapot; Isaure on the threshold (the door, south), then at the table, Hélène across it
## (« IsaureCabinet », once « tasse_bleue »); the starter lies down by the incubator.
const CABINET_ROC := Vector2(7.6, 4.9)
const CABINET_SEUIL := Vector2(8.0, 9.9)
const CABINET_ISAURE := Vector2(10.9, 5.6)
const CABINET_COUVEUSE := Vector2(13.4, 4.2)

# ------------------------------------------------------------------ Port-Ambre, the next day (40 x 24)
## 4 d, outside the Cabinet: Maïa on its step, Caillou across the street (« MaiaMarche », « CaillouRuelle »).
const MARCHE_MAIA := Vector2(32.8, 9.0)
const RUELLE_CAILLOU := Vector2(27.4, 10.5)
## 5, the jetty: Hélène (on Roc's arm) at the foot of the pier, facing the village gathered on the quay;
## Chloé on the pier's head; Dame Suie at the back; Isaure by her boat (on the pier, east side); Brac at the
## end of the pier on his cage (« BracJetee », chapter 8), Mastoc beside him, Cabosse and Grognon on the quay.
const JETEE_HELENE := Vector2(19.6, 15.3)
const JETEE_ROC := Vector2(20.7, 15.0)
const JETEE_CHLOE := Vector2(19.5, 17.6)
const JETEE_MAIA := Vector2(18.4, 16.4)
const JETEE_CAILLOU := Vector2(22.0, 12.9)
const JETEE_ISAURE := Vector2(20.55, 19.7)
const JETEE_SUIE := Vector2(15.8, 12.6)
const JETEE_HAMON := Vector2(22.4, 15.6)
const JETEE_JOSS := Vector2(22.9, 14.3)
const JETEE_LEONCE := Vector2(18.6, 18.6)   # (« Leonce », chapter 8, on the pontoon)
const JETEE_GUSTAVE := Vector2(16.6, 16.6)
const JETEE_FIRMIN := Vector2(14.2, 16.4)
const JETEE_ROSALIE := Vector2(15.4, 15.6)
const JETEE_PERVENCHE := Vector2(16.4, 14.6)
const JETEE_BRAC := Vector2(18.6, 22.3)     # (« BracJetee », chapter 8)
const JETEE_MASTOC := Vector2(19.7, 21.0)
const JETEE_CABOSSE := Vector2(12.4, 16.3)
const JETEE_GROGNON := Vector2(10.2, 16.1)
## 5 e, page 40: the end of the pier, where Chloé landed on the first day (the prologue's « Depart »).
const JETEE_BOUT := Vector2(19.4, 21.6)

# ------------------------------------------------------------------ the two zones
## Their sizes (tiles) and their heights (m): the ledge, the crater's floor, the hole; the hall.
const TAILLES := {&"terre_apex": Vector2i(80, 70), &"coeur_apex": Vector2i(50, 40)}
const H_BORD := 16.2
const H_FOND := 4.0
const H_TROU := -1.5
const H_SALLE := -3.0
