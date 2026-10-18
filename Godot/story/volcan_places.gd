class_name VolcanPlaces
## Chapter 8, the Plaine Volcanique: where things are (tiles, x right, y down), shared by the zone plans
## (tools/zones/volcan_champs.gd, volcan_forges.gd, volcan_coulees.gd, volcan_sanctuaire.gd,
## volcan_porte.gd: each builds the zone named in its PATH) and the scenes (story/volcan*.gd). The values
## follow the maps; the plans check that each place is reached on foot from the way in (or, beyond a
## flow of lava, only on the back of a stone or fire dino).
## The zones go north, towards the volcano (the camera looks north: the volcano's flank and the crater's
## rim face the player): the Descente de Cendre comes down from the Arche du Vent (its north edge) onto
## the south edge of `champs_cendres`; its north edge leads to `forges_ombre` (south edge); the forges'
## platform, at its north edge, to `coulees_lave` (south edge); in the volcano's flank there, the faille
## into `sanctuaire_magma` (indoor); up the crater path (north-east of the coulées, open once
## « lave_retiree »), `porte_cratere` (south edge).
## THE LAVA: « rock » tiles, sunk 0.25 m, listed in each zone's meta « lave » (an Image, one pixel a tile):
## see tools/zones/volcan_canvas.gd and docs/zones/volcan.md (the contract with the mechanics).

## The arrival spawns of each zone (Spawns/<name>), by where Chloé comes from.
const SPAWN_ARCHE := &"DepuisArche"         # champs_cendres, from the Arche du Vent
const SPAWN_DEPUIS_VOLCAN := &"DepuisVolcan"  # arche_du_vent, back up the Descente
const SPAWN_CHAMPS := &"DepuisChamps"       # forges_ombre, from the fields
const SPAWN_FORGES := &"DepuisForges"       # champs_cendres (back from the forges) and coulees_lave (from them)
const SPAWN_COULEES := &"DepuisCoulees"     # forges_ombre, sanctuaire_magma, porte_cratere (from the coulées)
const SPAWN_SANCTUAIRE := &"DepuisSanctuaire"  # coulees_lave, out of the faille
const SPAWN_PORTE := &"DepuisPorte"         # coulees_lave, down the crater path

# ------------------------------------------------------------------ champs_cendres (90 x 70)
## The Descente de Cendre: the Arche's ridge of cinders comes out on the south edge (x 44-46, 14.4 m,
## Arche x = Champs x - 25), a hillside of ash going down north in lacets to the plain (6.4 m, row 48).
const ENTREE_ARCHE := Vector2(45.0, 66.5)
const SORTIE_ARCHE := Vector2(45.0, 69.5)
const DESCENTE := Vector2(44.0, 58.5)
## Its foot: the first fire, the sign (« Plaine Volcanique. Ne pas marcher sur ce qui est rouge… — H. »).
const PIED_DESCENTE := Vector2(45.0, 47.0)
const FEU_CHAMPS := Vector2(50.0, 45.5)
const PANNEAU_CHAMPS := Vector2(47.6, 47.4)
## The tracks (StoryTrigger « Traces », non-blocking, radius 2.5): round the flat stone with two hollows
## side by side (StoryProp « PierrePlate »), a bigger hollow and chewed reeds a little further (Caillou).
const TRACES := Vector2(42.0, 30.0)
const PIERRE_PLATE := Vector2(43.6, 28.6)
const CREUX_CAILLOU := Vector2(46.8, 27.6)
## The first corrupted dino: Numéro 3 (Styracosaurus) at the foot of an open cage (StoryProp
## « CageOuverte »), an overturned barrel of black amber by it (StoryProp « FutRenverse »).
const NUMERO_3 := Vector2(36.0, 21.8)
const CAGE_OUVERTE := Vector2(35.0, 19.8)
const FUT_RENVERSE := Vector2(32.8, 22.6)
## The cooled flows of the north-east (the Saichania's, by day), the ash dunes of the west.
const COULEES_REFROIDIES := Vector2(70.0, 20.0)
const DUNES := Vector2(18.0, 30.0)
## North edge: the way to the forges (x 44-46, 6.4 m; Forges x = Champs x - 4.5).
const SORTIE_FORGES := Vector2(45.0, 0.5)
const DEPUIS_FORGES := Vector2(45.0, 3.0)

# ------------------------------------------------------------------ forges_ombre (80 x 60)
## The way in at the south edge (x 39-42, 6.4 m), the camp in the hollow at the volcano's foot.
const ENTREE_FORGES := Vector2(40.5, 56.5)
const SORTIE_CHAMPS := Vector2(40.5, 59.5)
const FEU_FORGES := Vector2(34.5, 52.0)
## Léonce on a barrel by the way in, his mask on his knee; two more masks sitting by the barrels (one
## asleep): gone once the grande forge is out.
const LEONCE := Vector2(44.6, 50.2)
const MASQUES_OS: Array[Vector2] = [Vector2(48.0, 46.8), Vector2(50.2, 50.6)]
## The three small forges (StoryProps « Forge1..3 »), each guarded by its numbered dino, who turns
## against it once calmed: Numéro 7 (Saichania) knocks the first over, Numéro 11 (Allosaurus) tears the
## bellows off the second, Numéro 12 (Majungasaurus) pushes the big barrel into the third.
const FORGE_1 := Vector2(15.0, 41.0)
const NUMERO_7 := Vector2(17.2, 43.8)
const FORGE_2 := Vector2(26.0, 32.0)
const NUMERO_11 := Vector2(28.0, 34.8)
const SOUFFLET := Vector2(24.0, 32.6)
const FORGE_3 := Vector2(64.0, 37.0)
const NUMERO_12 := Vector2(61.8, 39.8)
const FUT_FORGE_3 := Vector2(66.2, 37.4)
## The barricade of cages (StoryProp « Barricade ») closing the notch up to the platform (9.4 m, x 39-41),
## gone once « barricade_tombee »; its fallen cages beside it then.
const BARRICADE := Vector2(40.5, 25.3)
const BARRICADE_TOMBEE := Vector2(36.4, 26.4)
const RAMPE_PLATEAU := Vector2(40.5, 22.0)
## Brac's camp at the top of the notch: Brac (his pose « sitting on a cage », brac_assis_cage.png, has the
## cage in it), his fire and pot, Mastoc, Cabosse and Grognon round him, Fournaise in his pen (the front
## fence opens: « brac_volcan_vu »), his tent; his mask in the ash once he has gone (« MasqueBrac »).
const BRAC := Vector2(42.0, 17.2)
const FEU_BRAC := Vector2(37.8, 16.6)
const MARMITE := Vector2(36.6, 15.4)
const MASTOC := Vector2(45.8, 18.8)
const CABOSSE := Vector2(35.0, 19.0)
const GROGNON := Vector2(46.6, 15.2)
const FOURNAISE := Vector2(52.0, 17.8)
const MASQUE_BRAC := Vector2(43.4, 18.8)
const TENTE_BRAC := Vector2(30.6, 11.6)
## Dame Suie at the foot of the grande forge (its front foot; « GrandeForge », the wheel of its draught
## in the picture): her bench (StoryProp « Etabli »), her vials, her gloves left on it once she has gone
## (« Gants »: drawn on the bench's top), Mandragore and the sledge on wheels (gone with her: « suie_partie »).
const GRANDE_FORGE := Vector2(40.0, 7.6)
const SUIE := Vector2(46.4, 11.0)
const ETABLI := Vector2(46.4, 9.4)
const FIOLES := Vector2(48.6, 9.7)
const GANTS := Vector2(46.6, 9.46)
const MANDRAGORE := Vector2(51.0, 10.0)
const TRAINEAU := Vector2(53.8, 10.2)
## North edge: the way to the coulées (x 55-57, 9.4 m; closed until « suie_partie »).
const SORTIE_COULEES := Vector2(56.5, 0.5)
const DEPUIS_COULEES_FORGES := Vector2(56.5, 3.0)

# ------------------------------------------------------------------ coulees_lave (80 x 60)
## The way in at the south edge (x 39-41, 9.4 m), the black rock, the cooled flows (the Saichania's).
const ENTREE_COULEES := Vector2(40.5, 56.5)
const SORTIE_FORGES_COULEES := Vector2(40.5, 59.5)
const FEU_COULEES := Vector2(34.5, 53.0)
const COULEES_REFROIDIES_OUEST := Vector2(15.0, 51.0)
const COULEES_REFROIDIES_EST := Vector2(66.0, 52.0)
## The first flow: a river of lava across the whole zone (rows ~40-43); its trigger « PremiereCoulee » on
## the south bank where the trail meets it, the sign beside (« La lave, ça se regarde de loin… — H. »).
const PREMIERE_COULEE := Vector2(40.5, 45.0)
const PREMIERE_COULEE_TRAVERSEE := Vector2(40.5, 41.2)
const PANNEAU_LAVE := Vector2(43.4, 45.6)
## Beyond it (on a stone or fire dino): the flows, a lake of lava with its black rock in the middle (page
## 36 in an iron box, only on such a dino), the volcano's flank at the north.
const COULEES := Vector2(40.5, 30.0)
const LAC_DE_LAVE := Vector2(29.5, 27.5)
const ROCHER_36 := Vector2(29.5, 27.3)
const PAGE_36 := Vector2(29.2, 27.6)
## The faille into the sanctuary (a CaveMouth at the back of its notch in the flank; « On n'entre pas sans
## frapper. Ici, c'est lui qui frappe. — H. » engraved beside it).
const FAILLE := Vector2(40.5, 8.2)
const DEVANT_FAILLE := Vector2(40.5, 11.5)
const GRAVURE_FAILLE := Vector2(43.2, 12.8)
## The crater path: a cut up the flank (north-east, x 63-65, 9.8 m up to 12.6 m at the north edge); lava
## fills its lower part (rows 4-10, meta « lave_retrait »: nobody passes, not even on a dino) and its exit
## is closed until « lave_retiree » (« la lave se retire du chemin du cratère, comme une marée »).
const PIED_CHEMIN_CRATERE := Vector2(64.5, 11.5)
const LAVE_CRATERE := Vector2(64.5, 7.0)
const SORTIE_PORTE := Vector2(64.5, 0.5)
const DEPUIS_PORTE := Vector2(64.5, 2.5)
## Where the Daspletosaurus come out at night (the flows' black rock, beyond the first one).
const DASPLETOS := Vector2(52.0, 30.0)

# ------------------------------------------------------------------ sanctuaire_magma (48 x 42, indoor)
## Up the faille's corridor from the south edge (x 23-25) into a round hall of obsidian (centre 24, 17;
## 28 x 22), a ring of lava along its walls; the warm spring at the corridor's mouth (its water trembles:
## « flaque_tremble »), the black altar in the middle, the wall of glass with the lava running in it at the
## back (north), the T-Rex de Magma before it; page 35 in a crack of the glass behind the altar (once
## « trex_magma_battu »).
const SANCTUAIRE_ENTREE := Vector2(24.5, 37.0)
const SORTIE_COULEES_SANCTUAIRE := Vector2(24.5, 41.5)
const SALLE := Vector2(24.0, 17.0)
const VASQUE := Vector2(21.4, 26.0)
const AUTEL_MAGMA := Vector2(24.0, 17.6)
const LAVE_PAROI := Vector2(24.0, 8.4)
const TREX_MAGMA := Vector2(24.0, 11.4)
## After the fight he lies down by the altar (the scenes move him there).
const TREX_COUCHE := Vector2(27.6, 16.4)
const PAGE_35 := Vector2(28.4, 9.8)

# ------------------------------------------------------------------ porte_cratere (50 x 40)
## The way in at the south edge (x 23-25, 12.6 m), the crater path up in lacets (two ramps: east, then
## west) to the esplanade (16.2 m) before the rim's wall, the portal of the Terre des Apex in it.
const PORTE_ENTREE := Vector2(24.5, 37.0)
const SORTIE_COULEES_PORTE := Vector2(24.5, 39.5)
const LACET_1 := Vector2(37.0, 29.5)
const LACET_2 := Vector2(12.0, 21.5)
const ESPLANADE := Vector2(25.0, 14.0)
## The portal (StoryProp « PortailApex »: wood and iron, five hollows; « apex_bloque »), its two torches.
const PORTAIL := Vector2(25.0, 6.4)
const TORCHES: Array[Vector2] = [Vector2(20.4, 7.0), Vector2(29.6, 7.0)]
## Isaure facing the portal (her back to Chloé), Maïa on a stone beside (her pose « on a stone »,
## maia_pierre.png, has the stone in it), Caillou lying behind.
const ISAURE := Vector2(25.0, 10.4)
const MAIA := Vector2(20.2, 11.8)
const CAILLOU := Vector2(31.0, 9.6)
## Hélène's camp against the wall (StoryProp « CampHelene »: lantern, blanket, cairn, all in its picture),
## page 38 under the cairn, three steps from Isaure.
const CAMP_HELENE := Vector2(15.4, 7.8)
const PAGE_38 := Vector2(14.6, 9.0)

# ------------------------------------------------------------------ the five zones
## Their sizes (tiles) and the height of their plain (m).
const TAILLES := {&"champs_cendres": Vector2i(90, 70), &"forges_ombre": Vector2i(80, 60), &"coulees_lave": Vector2i(80, 60),
	&"sanctuaire_magma": Vector2i(48, 42), &"porte_cratere": Vector2i(50, 40)}
