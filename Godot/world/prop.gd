@tool
class_name Prop
extends StaticBody2D
## A piece of scenery (tree, rock, flowers…). Place it in a region's Entities node and
## pick its `kind` in the Inspector: sprite, shadow, collision and sway come from KINDS.
## The node's origin is where the object touches the ground (for Y-sorting).

const SWAY := preload("res://world/shaders/sway.gdshader")
const ART := "res://assets/art/props/%s.png"

## scale: sprite scale; foot: fraction of the sprite height below the ground point;
## solid: collision radius (float) or box size (Vector2), 0 = walk through; solid_poly (optional):
## the foot's outline instead (px from the ground point, convex), for a model turned 3/4;
## sway: sway strength in px (0 = rigid); shadow: shadow width in px (0 = none).
## Things made for people (barrels, benches, stalls, lanterns, furniture…) stand at Chloé's
## scale (1.50 m: ×0.70 on 28/09, docs/direction-artistique.md « Échelle »); nature and houses
## as drawn.
const KINDS := {
	"arbre_rond": {"scale": 0.62, "foot": 0.05, "solid": 16.0, "sway": 1.2, "shadow": 120.0},
	"araucaria": {"scale": 0.62, "foot": 0.03, "solid": 11.0, "sway": 1.5, "shadow": 80.0},
	"fougere_arbre": {"scale": 0.6, "foot": 0.03, "solid": 11.0, "sway": 2.5, "shadow": 90.0},
	"buisson": {"scale": 0.4, "foot": 0.08, "solid": 24.0, "sway": 0.8, "shadow": 96.0},
	"rocher": {"scale": 0.42, "foot": 0.1, "solid": Vector2(96, 34), "sway": 0.0, "shadow": 100.0},
	"cailloux": {"scale": 0.3, "foot": 0.1, "solid": 16.0, "sway": 0.0, "shadow": 50.0},
	"tronc": {"scale": 0.42, "foot": 0.15, "solid": Vector2(104, 30), "sway": 0.0, "shadow": 104.0},
	"ronces": {"scale": 0.34, "foot": 0.05, "solid": 20.0, "sway": 1.5, "shadow": 60.0},
	"hautes_herbes": {"scale": 0.24, "foot": 0.05, "solid": 0.0, "sway": 3.0, "shadow": 0.0},
	"fougeres": {"scale": 0.26, "foot": 0.06, "solid": 0.0, "sway": 3.0, "shadow": 0.0},
	"fleurs_roses": {"scale": 0.2, "foot": 0.06, "solid": 0.0, "sway": 2.0, "shadow": 0.0},
	"fleurs_violettes": {"scale": 0.2, "foot": 0.06, "solid": 0.0, "sway": 2.0, "shadow": 0.0},
	"panneau": {"scale": 0.21, "foot": 0.04, "solid": 5.6, "sway": 0.0, "shadow": 25.2},
	"cloture": {"scale": 0.245, "foot": 0.08, "solid": Vector2(49, 8.4), "sway": 0.0, "shadow": 0.0},
	"ambre": {"scale": 0.26, "foot": 0.08, "solid": 0.0, "sway": 0.0, "shadow": 22.0},
	"souche": {"scale": 0.3, "foot": 0.12, "solid": 16.0, "sway": 0.0, "shadow": 56.0},
	# Port-Ambre (the buildings' origin is the middle of their facade's foot).
	"maison_blanche": {"model": "res://assets/models/volumes/maison_blanche.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(265, 239), "sway": 0.0, "shadow": 0.0},
	"maison_jaune": {"model": "res://assets/models/volumes/maison_jaune.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(229, 238), "sway": 0.0, "shadow": 0.0},
	"maison_port": {"model": "res://assets/models/volumes/maison_port.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(235, 206), "sway": 0.0, "shadow": 0.0},
	"cabinet": {"model": "res://assets/models/volumes/cabinet.glb",
		"scale": 0.68, "foot": 0.02, "solid": Vector2(284, 256), "sway": 0.0, "shadow": 0.0},
	# Havre-Doré: its own shops and houses (tools/modeles3d/maisons.py, like Port-Ambre's).
	"havre_herboristerie": {"model": "res://assets/models/volumes/havre_herboristerie.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(268, 256), "sway": 0.0, "shadow": 0.0},
	"havre_mercerie": {"model": "res://assets/models/volumes/havre_mercerie.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(245, 210), "sway": 0.0, "shadow": 0.0},
	"havre_relais": {"model": "res://assets/models/volumes/havre_relais.glb",
		"scale": 0.68, "foot": 0.02, "solid": Vector2(274, 289), "sway": 0.0, "shadow": 0.0},
	"havre_comptoir": {"model": "res://assets/models/volumes/havre_comptoir.glb",
		"scale": 0.68, "foot": 0.02, "solid": Vector2(298, 272), "sway": 0.0, "shadow": 0.0},
	"havre_sellerie": {"model": "res://assets/models/volumes/havre_sellerie.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(258, 246), "sway": 0.0, "shadow": 0.0},
	"havre_entrepot": {"model": "res://assets/models/volumes/havre_entrepot.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(391, 214), "sway": 0.0, "shadow": 0.0},
	"havre_maison_1": {"model": "res://assets/models/volumes/havre_maison_1.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(272, 236), "sway": 0.0, "shadow": 0.0},
	"havre_maison_2": {"model": "res://assets/models/volumes/havre_maison_2.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(218, 217), "sway": 0.0, "shadow": 0.0},
	"havre_maison_3": {"model": "res://assets/models/volumes/havre_maison_3.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(272, 236), "sway": 0.0, "shadow": 0.0},
	"havre_maison_4": {"model": "res://assets/models/volumes/havre_maison_4.glb",
		"scale": 0.62, "foot": 0.02, "solid": Vector2(258, 227), "sway": 0.0, "shadow": 0.0},
	"barque": {"scale": 0.385, "foot": 0.12, "solid": 0.0, "sway": 0.0, "shadow": 0.0, "float": true},
	"caisses": {"scale": 0.252, "foot": 0.08, "solid": Vector2(49, 21), "sway": 0.0, "shadow": 56.0},
	"tonneau": {"scale": 0.294, "foot": 0.05, "solid": 12.6, "sway": 0.0, "shadow": 32.2},
	"filet": {"scale": 0.371, "foot": 0.05, "solid": Vector2(70, 11.2), "sway": 0.7, "shadow": 0.0},
	"bitte": {"scale": 0.252, "foot": 0.08, "solid": 7.0, "sway": 0.0, "shadow": 21.0},
	"lanterne": {"scale": 0.455, "foot": 0.03, "solid": 5.6, "sway": 0.0, "shadow": 21.0, "light": true},
	"casiers": {"scale": 0.315, "foot": 0.08, "solid": Vector2(49, 21), "sway": 0.0, "shadow": 56.0},
	"cordage": {"scale": 0.273, "foot": 0.1, "solid": 0.0, "sway": 0.0, "shadow": 35.0},
	"banc": {"scale": 0.336, "foot": 0.06, "solid": Vector2(53.2, 11.2), "sway": 0.0, "shadow": 49.0},
	"sechoir": {"scale": 0.42, "foot": 0.04, "solid": Vector2(56, 8.4), "sway": 0.42, "shadow": 0.0},
	"ancre": {"scale": 0.294, "foot": 0.08, "solid": 14.0, "sway": 0.0, "shadow": 39.2},
	"bac_fleurs": {"scale": 0.266, "foot": 0.06, "solid": 9.8, "sway": 0.7, "shadow": 28.0},
	# Inside the Cabinet.
	"bureau": {"scale": 0.21, "foot": 0.08, "solid": Vector2(77, 25.2), "sway": 0.0, "shadow": 77.0},
	"bibliotheque": {"scale": 0.252, "foot": 0.03, "solid": Vector2(63, 16.8), "sway": 0.0, "shadow": 0.0},
	"couveuse": {"scale": 0.196, "foot": 0.05, "solid": 15.4, "sway": 0.0, "shadow": 42.0, "light": true},
	"fougere_pot": {"scale": 0.154, "foot": 0.05, "solid": 9.8, "sway": 1.05, "shadow": 28.0},
	"lampe": {"scale": 0.21, "foot": 0.03, "solid": 5.6, "sway": 0.0, "shadow": 21.0, "light": true},
	"fauteuil": {"scale": 0.196, "foot": 0.06, "solid": 15.4, "sway": 0.0, "shadow": 39.2},
	"etabli": {"scale": 0.21, "foot": 0.06, "solid": Vector2(56, 18.2), "sway": 0.0, "shadow": 63.0},
	# Plaines: the amber door, the scales and the Grand Crâne; the Grotte des Échos.
	"porte_ambre": {"scale": 0.33, "foot": 0.01, "solid": Vector2(96, 30), "sway": 0.0, "shadow": 0.0},
	"ecaille": {"scale": 0.15, "foot": 0.05, "solid": 0.0, "sway": 0.0, "shadow": 26.0},
	"serrure": {"scale": 0.15, "foot": 0.05, "solid": 14.0, "sway": 0.0, "shadow": 36.0},
	"stalagmite": {"scale": 0.32, "foot": 0.04, "solid": 16.0, "sway": 0.0, "shadow": 50.0},
	"cristaux": {"scale": 0.18, "foot": 0.08, "solid": 16.0, "sway": 0.0, "shadow": 50.0, "light": true},
	"rocher_grotte": {"scale": 0.24, "foot": 0.08, "solid": 34.0, "sway": 0.0, "shadow": 80.0},
	"grand_crane": {"scale": 0.48, "foot": 0.02, "solid": Vector2(192, 30), "sway": 0.0, "shadow": 0.0},
	"socle": {"scale": 0.224, "foot": 0.06, "solid": 16.8, "sway": 0.0, "shadow": 44.8},
	"mur_cabinet": {"scale": 0.5, "foot": 0.0, "solid": Vector2(171, 60), "sway": 0.0, "shadow": 0.0},
	# Searching the island (provisional pictures: tools/draw-placeholders.mjs).
	"galet": {"scale": 0.11, "foot": 0.12, "solid": 0.0, "sway": 0.0, "shadow": 16.0},
	"monticule": {"scale": 0.26, "foot": 0.12, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	"etal_fruits": {"scale": 0.35, "foot": 0.03, "solid": Vector2(84, 21), "sway": 0.0, "shadow": 84.0},
	"etal_poisson": {"scale": 0.35, "foot": 0.03, "solid": Vector2(84, 21), "sway": 0.0, "shadow": 84.0},
	"feu_camp": {"scale": 0.0834, "foot": 0.07, "solid": 16.8, "sway": 0.0, "shadow": 42.0},
	# Forêt Jurassique.
	"fougere_geante": {"scale": 0.5, "foot": 0.04, "solid": 0.0, "sway": 2.0, "shadow": 110.0},
	"tronc_mousse": {"scale": 0.42, "foot": 0.15, "solid": Vector2(130, 28), "sway": 0.0, "shadow": 140.0},
	"champignons": {"scale": 0.2, "foot": 0.06, "solid": 0.0, "sway": 0.0, "shadow": 24.0},
	"rocher_mousse": {"scale": 0.34, "foot": 0.1, "solid": Vector2(100, 36), "sway": 0.0, "shadow": 108.0},
	"souche_geante": {"scale": 0.3, "foot": 0.12, "solid": 44.0, "sway": 0.0, "shadow": 110.0},
	"arbre_geant": {"scale": 0.47, "foot": 0.04, "solid": 40.0, "sway": 0.0, "shadow": 240.0},
	"os_dino": {"scale": 0.27, "foot": 0.12, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	# Le camp de l'Ombre Noire (Forêt, étape 2) : Brac, ses cages, et la brèche du Masque.
	"mur_fissure": {"scale": 0.19, "foot": 0.0, "solid": Vector2(180, 70), "sway": 0.0, "shadow": 0.0},
	# A real 3D model (tools/modeles3d/maisons.py + tentes.py): the picture, seen in 3/4, turned so
	# that the camera sees it as drawn; its foot a diamond (solid_poly; solid: its bounding box).
	"tente": {"model": "res://assets/models/volumes/tente.glb",
		"scale": 0.37, "foot": 0.05, "solid": Vector2(163, 166), "sway": 0.0, "shadow": 130.0,
		"solid_poly": [Vector2(-82, -68), Vector2(10, 0), Vector2(82, -98), Vector2(-10, -166)]},
	"cage": {"scale": 0.4185, "foot": 0.05, "solid": Vector2(121.5, 54), "sway": 0.0, "shadow": 121.5},
	# The front bars of a cage, in front of the dino it holds (the cage picture behind it).
	"barreaux_cage": {"scale": 0.4185, "foot": 0.03, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	"caisse_ambre_noir": {"scale": 0.175, "foot": 0.06, "solid": Vector2(35, 15.4), "sway": 0.0, "shadow": 35.0},
	"table_papiers": {"scale": 0.175, "foot": 0.05, "solid": Vector2(59.5, 21), "sway": 0.0, "shadow": 70.0},
	# A real 3D model (maisons.py + pieux.py): round stakes, 2.1 m, their rope in volume.
	"palissade": {"model": "res://assets/models/volumes/palissade.glb",
		"scale": 0.42, "foot": 0.05, "solid": Vector2(80, 30), "sway": 0.0, "shadow": 40.0},
	# Suspendue entre deux arbre_geant : pas de collision (on ne marche pas dessus, juste le décor).
	"passerelle": {"scale": 0.233, "foot": 0.18, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	# Marais Brumeux (chapitre 3).
	"roseaux": {"scale": 0.32, "foot": 0.04, "solid": 0.0, "sway": 2.5, "shadow": 0.0},
	"arbre_noye": {"scale": 0.5, "foot": 0.08, "solid": 34.0, "sway": 1.0, "shadow": 200.0},
	"nenuphars": {"scale": 0.24, "foot": 0.35, "solid": 0.0, "sway": 0.0, "shadow": 0.0, "float": true},
	"cabane_pilotis": {"model": "res://assets/models/volumes/cabane_pilotis.glb",
		"scale": 0.42, "foot": 0.06, "solid": Vector2(164, 162), "sway": 0.0, "shadow": 0.0},
	"statue_dino": {"scale": 0.4, "foot": 0.04, "solid": 26.0, "sway": 0.0, "shadow": 80.0},
	"colonne": {"scale": 0.32, "foot": 0.06, "solid": 16.0, "sway": 0.0, "shadow": 60.0},
	"vanne": {"scale": 0.3, "foot": 0.06, "solid": 18.0, "sway": 0.0, "shadow": 50.0},
	"fresque": {"scale": 0.4, "foot": 0.02, "solid": Vector2(130, 24), "sway": 0.0, "shadow": 0.0},
	"porte_temple": {"scale": 0.42, "foot": 0.01, "solid": Vector2(140, 34), "sway": 0.0, "shadow": 0.0},
	"racines": {"scale": 0.3, "foot": 0.12, "solid": Vector2(110, 26), "sway": 0.0, "shadow": 90.0},
	# Désert Aride (chapitre 4).
	"os_geant": {"scale": 0.36, "foot": 0.08, "solid": Vector2(80, 24), "sway": 0.0, "shadow": 70.0},
	"crane_geant_desert": {"scale": 0.48, "foot": 0.03, "solid": Vector2(180, 40), "sway": 0.0, "shadow": 0.0},
	"rocher_canyon": {"scale": 0.42, "foot": 0.1, "solid": Vector2(110, 38), "sway": 0.0, "shadow": 108.0},
	# Rocher du canyon des Vents gravé « PAR OÙ ?! » (~1,5 m) : montré pendant la scène de Brac
	# (Stage.prop), pas posé dans la zone.
	"rocher_grave": {"scale": 0.177, "foot": 0.1, "solid": Vector2(58.0, 19.0), "sway": 0.0, "shadow": 57.0},
	"arche_rocheuse": {"scale": 0.55, "foot": 0.02, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	"palmier_oasis": {"scale": 0.56, "foot": 0.03, "solid": 12.0, "sway": 1.8, "shadow": 90.0},
	"nid_oviraptor": {"scale": 0.22, "foot": 0.1, "solid": 0.0, "sway": 0.0, "shadow": 20.0},
	"totem_vents": {"scale": 0.34, "foot": 0.05, "solid": 18.0, "sway": 0.0, "shadow": 55.0},
	"buisson_sec": {"scale": 0.32, "foot": 0.08, "solid": 16.0, "sway": 1.0, "shadow": 70.0},
	"tente_nomade": {"model": "res://assets/models/volumes/tente_nomade.glb",   # (3D, like the camp's tent)
		"scale": 0.47, "foot": 0.05, "solid": Vector2(158, 166), "sway": 0.0, "shadow": 120.0,
		"solid_poly": [Vector2(-77, -67), Vector2(16, 0), Vector2(71, -81), Vector2(79, -102),
			Vector2(-20, -166), Vector2(-79, -78)]},
	"porte_vents": {"scale": 0.37, "foot": 0.01, "solid": Vector2(150, 34), "sway": 0.0, "shadow": 0.0},
	"chariot_cage": {"scale": 0.37, "foot": 0.06, "solid": Vector2(140, 55), "sway": 0.0, "shadow": 110.0},
	"rempart_eboulis": {"scale": 0.29, "foot": 0.0, "solid": Vector2(320, 90), "sway": 0.0, "shadow": 0.0},
	"squelette_geant": {"scale": 0.52, "foot": 0.08, "solid": Vector2(190, 64), "sway": 0.0, "shadow": 0.0},
	"puits_oasis": {"scale": 0.238, "foot": 0.06, "solid": Vector2(45.5, 23.8), "sway": 0.0, "shadow": 35.0},
	# Le Clos Blanc (zone d'essai) : un vrai modèle 3D (Blender), peint par ComfyUI + LoRA
	# (peintures projetées dessus). "model" : la vue 3D pose ce modèle au lieu d'une image ;
	# l'image du même nom ne sert qu'à le voir dans l'éditeur 2D. Collision = son emprise au sol.
	"maison_3d": {"model": "res://assets/models/maison_3d.glb", "scale": 0.64, "foot": 0.02,
		"solid": Vector2(307, 230), "sway": 0.0, "shadow": 0.0},
	# Côte Préhistorique : récif du Sanctuaire.
	"benitier": {"scale": 0.55, "foot": 0.05, "solid": Vector2(110, 44), "sway": 0.0, "shadow": 130.0, "light": true},
	# The ruined lighthouse on the Pointe aux Ptéranodons (maisons.py: a round tower, its broken top);
	# its origin at the front foot of the tower, its foot a 12-sided polygon.
	"phare_ruine": {"model": "res://assets/models/volumes/phare_ruine.glb",
		"scale": 0.5, "foot": 0.007, "solid": Vector2(182, 188), "sway": 0.0, "shadow": 0.0,
		"solid_poly": [Vector2(0, 0), Vector2(46, -12), Vector2(79, -46), Vector2(91, -91), Vector2(79, -137),
			Vector2(46, -170), Vector2(0, -182), Vector2(-46, -170), Vector2(-79, -137), Vector2(-91, -91),
			Vector2(-79, -46), Vector2(-46, -12)]},
	# « Détails vivants » (29/09, tools/art-jobs/vivants_decor.mjs): what the texts describe.
	# The Côte's shore and reef (the kinds tools/zones/cote.gd was waiting for).
	"coquillages": {"scale": 0.132, "foot": 0.3, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	"algues": {"scale": 0.127, "foot": 0.3, "solid": 0.0, "sway": 0.3, "shadow": 0.0},
	"bois_flotte": {"scale": 0.217, "foot": 0.2, "solid": Vector2(100, 22), "sway": 0.0, "shadow": 100.0},
	"rocher_cote": {"scale": 0.26, "foot": 0.1, "solid": Vector2(80, 30), "sway": 0.0, "shadow": 90.0},
	"rocher_recif": {"scale": 0.273, "foot": 0.12, "solid": Vector2(90, 32), "sway": 0.0, "shadow": 90.0},
	"oyats": {"scale": 0.154, "foot": 0.08, "solid": 0.0, "sway": 2.5, "shadow": 0.0},
	"nid_pteranodon": {"scale": 0.23, "foot": 0.15, "solid": 0.0, "sway": 0.0, "shadow": 60.0},
	"nid_tortue": {"scale": 0.166, "foot": 0.3, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	"boite_fer": {"scale": 0.16, "foot": 0.1, "solid": 12.0, "sway": 0.0, "shadow": 40.0},
	"gravure_hi": {"scale": 0.21, "foot": 0.12, "solid": Vector2(60, 14), "sway": 0.0, "shadow": 60.0},
	"palmier_cote": {"scale": 0.48, "foot": 0.02, "solid": 11.0, "sway": 1.8, "shadow": 90.0},
	"masque_pierre": {"scale": 0.197, "foot": 0.05, "solid": 18.0, "sway": 0.0, "shadow": 50.0},
	# Under the sea (Récif du Sanctuaire; Examine.UNDERWATER_LINES has "varech" and "corail").
	"varech": {"scale": 0.207, "foot": 0.04, "solid": 0.0, "sway": 2.5, "shadow": 0.0},
	"corail": {"scale": 0.19, "foot": 0.12, "solid": 28.0, "sway": 0.0, "shadow": 70.0},
	"corail_branches": {"scale": 0.188, "foot": 0.08, "solid": 20.0, "sway": 0.3, "shadow": 50.0},
	"anemones": {"scale": 0.13, "foot": 0.1, "solid": 0.0, "sway": 1.5, "shadow": 40.0},
	"eponges": {"scale": 0.144, "foot": 0.08, "solid": 14.0, "sway": 0.0, "shadow": 40.0},
	"herbier": {"scale": 0.106, "foot": 0.1, "solid": 0.0, "sway": 2.5, "shadow": 0.0},
	# Relics and traces of the story (the altar of the Cœurs, the temple's statue, the guardians'
	# carved stones, the Alpha's clearing, the moulted skin).
	"autel": {"scale": 0.15, "foot": 0.06, "solid": 16.8, "sway": 0.0, "shadow": 44.0},
	"statue_spinosaure": {"scale": 0.337, "foot": 0.05, "solid": 30.0, "sway": 0.0, "shadow": 90.0},
	"pierre_gravee": {"scale": 0.195, "foot": 0.15, "solid": Vector2(56, 16), "sway": 0.0, "shadow": 60.0},
	"pierre_plate": {"scale": 0.208, "foot": 0.12, "solid": Vector2(52, 16), "sway": 0.0, "shadow": 56.0},
	"pieu_corde": {"scale": 0.229, "foot": 0.03, "solid": 5.6, "sway": 0.0, "shadow": 20.0},
	"peau_mue": {"scale": 0.18, "foot": 0.2, "solid": 0.0, "sway": 0.3, "shadow": 0.0},
	"fougeres_ecrasees": {"scale": 0.22, "foot": 0.15, "solid": 0.0, "sway": 1.5, "shadow": 0.0},
	# People's things, at Chloé's scale (Sirocco's mat, Dame Suie's basket, the henchmen's tools,
	# Hélène's observation table, the Cabinet's specimen shelf); the Désert's fossils.
	"natte_fouilles": {"scale": 0.16, "foot": 0.25, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	"vertebre": {"scale": 0.135, "foot": 0.1, "solid": 18.0, "sway": 0.0, "shadow": 50.0},
	"cotes_sable": {"scale": 0.264, "foot": 0.15, "solid": Vector2(80, 18), "sway": 0.0, "shadow": 80.0},
	"panier_fioles": {"scale": 0.074, "foot": 0.06, "solid": 0.0, "sway": 0.0, "shadow": 16.0},
	"outils_mine": {"scale": 0.103, "foot": 0.05, "solid": 8.0, "sway": 0.0, "shadow": 30.0, "light": true},
	"table_observation": {"scale": 0.145, "foot": 0.04, "solid": Vector2(40, 14), "sway": 0.0, "shadow": 45.0},
	"etagere_bocaux": {"scale": 0.2, "foot": 0.03, "solid": Vector2(70, 16.8), "sway": 0.0, "shadow": 0.0},
	# Plants of the Mesozoic for each milieu (docs/direction-artistique.md « Détails vivants »).
	"prele": {"scale": 0.122, "foot": 0.06, "solid": 0.0, "sway": 2.5, "shadow": 0.0},
	"cycas": {"scale": 0.264, "foot": 0.06, "solid": 12.0, "sway": 1.2, "shadow": 90.0},
	"ginkgo": {"scale": 0.41, "foot": 0.02, "solid": 11.0, "sway": 1.5, "shadow": 90.0},
	"roseaux_secs": {"scale": 0.224, "foot": 0.1, "solid": 0.0, "sway": 2.0, "shadow": 0.0},
	"conifere_sec": {"scale": 0.249, "foot": 0.06, "solid": 14.0, "sway": 0.8, "shadow": 70.0},
	"rocher_lichen": {"scale": 0.261, "foot": 0.08, "solid": Vector2(84, 30), "sway": 0.0, "shadow": 95.0},
	# For the zones to come: Monts Gelés, Cieux Éternels, Plaine Volcanique, Terre des Apex.
	"sapin_neige": {"scale": 0.515, "foot": 0.04, "solid": 14.0, "sway": 0.8, "shadow": 90.0},
	"buisson_givre": {"scale": 0.183, "foot": 0.12, "solid": 18.0, "sway": 0.6, "shadow": 60.0},
	"rocher_neige": {"scale": 0.278, "foot": 0.06, "solid": Vector2(84, 30), "sway": 0.0, "shadow": 95.0},
	"pin_tordu": {"scale": 0.397, "foot": 0.1, "solid": 16.0, "sway": 1.0, "shadow": 80.0},
	"tronc_calcine": {"scale": 0.31, "foot": 0.08, "solid": 16.0, "sway": 0.0, "shadow": 70.0},
	"fougere_cendre": {"scale": 0.147, "foot": 0.12, "solid": 0.0, "sway": 2.0, "shadow": 0.0},
	"bennettitale": {"scale": 0.24, "foot": 0.08, "solid": 12.0, "sway": 1.2, "shadow": 80.0},
	"magnolia": {"scale": 0.466, "foot": 0.02, "solid": 12.0, "sway": 1.2, "shadow": 100.0},
	"prele_geante": {"scale": 0.657, "foot": 0.03, "solid": 10.0, "sway": 1.5, "shadow": 60.0},
	"nid_geant": {"scale": 0.553, "foot": 0.04, "solid": 40.0, "sway": 0.0, "shadow": 0.0},
	"liane_tronc": {"scale": 0.53, "foot": 0.04, "solid": 24.0, "sway": 0.5, "shadow": 110.0},
	# Passe de finition (29/09, tools/art-jobs/finition.mjs): objects held during a scene (small,
	# readable, real size noted here though the integrator spawns them, not a zone), and the
	# missing fixed scenery of chapters 1-5.
	"boite_fer_blanc": {"scale": 0.043, "foot": 0.12, "solid": 4.0, "sway": 0.0, "shadow": 11.0},
	"piege_machoires": {"scale": 0.069, "foot": 0.3, "solid": Vector2(20, 8), "sway": 0.0, "shadow": 15.0},
	"tube_cuivre": {"scale": 0.049, "foot": 0.4, "solid": 0.0, "sway": 0.0, "shadow": 7.0},
	"boite_ronde": {"scale": 0.063, "foot": 0.15, "solid": 5.0, "sway": 0.0, "shadow": 14.0},
	"registre": {"scale": 0.055, "foot": 0.25, "solid": 0.0, "sway": 0.0, "shadow": 8.0},
	# Not read through Prop.KINDS in play (story/desert_sanctuaire.gd loads the file directly and
	# rotates it in place of its drawn wheel, PAINTED_WHEEL); kept here only for the record.
	"roue_chariot": {"scale": 0.5, "foot": 0.5, "solid": 20.0, "sway": 0.0, "shadow": 60.0},
	# The falaise's small Dimorphodon nest (Plaines) and Chipie's lined bush (replaces the
	# "buisson"/"rocher" stand-ins of tools/zones/plaines.gd at the same tiles, same collision).
	"nid_dimorphodon": {"scale": 0.07, "foot": 0.15, "solid": 0.0, "sway": 0.0, "shadow": 16.0},
	"buisson_nid": {"scale": 0.24, "foot": 0.08, "solid": 15.0, "sway": 0.8, "shadow": 59.0},
	"rocher_oeuf": {"scale": 0.243, "foot": 0.1, "solid": Vector2(72, 26), "sway": 0.0, "shadow": 58.0},
	# The frieze of bone masks over the amber door of the Temple (tools/zones/marais.gd), mounted
	# above the doorway: no ground collision, no shadow.
	"frise_masques": {"scale": 0.139, "foot": -2.05, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	# The rope hanging down the cliff where Brac climbs away (Sanctuaire des Vents), mounted on
	# the rock face: no ground collision, no shadow.
	"corde_falaise": {"scale": 0.189, "foot": 0.02, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	# The turtles' nest once it is empty (cote_lagon.gd: the integrator swaps it in once
	# "tortues_sauvees"); same footprint as "nid_tortue".
	"nid_tortue_vide": {"scale": 0.108, "foot": 0.12, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	# The Cabinet's wall lantern and its hook, empty once "sa vieille lanterne a disparu du
	# crochet" (tools/zones/cabinet.gd, flag "roc_dehors"); the kettle on its little stove.
	# Wall-mounted (foot negative: prop.gd's offset = -h/2 + h*foot, world_view.gd matches for 3D):
	# the whole small picture floats above its ground anchor, bottom edge at ~1.3 m up the wall.
	"lanterne_crochet": {"scale": 0.045, "foot": -2.6, "solid": 0.0, "sway": 0.0, "shadow": 0.0, "light": true},
	"crochet_vide": {"scale": 0.05, "foot": -6.2, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	"bouilloire_poele": {"scale": 0.115, "foot": 0.04, "solid": 10.0, "sway": 0.0, "shadow": 22.0},
	# Chapitre 6 (Les Monts Gelés), tools/art-jobs/monts.mjs: glacier and ice-cave decor. Sizes
	# checked against the K≈45 rule (docs/direction-artistique.md « Tailles réelles »).
	# bloc_glace: interior alpha lowered by the job (~60%) so a sleeping dino behind shows through.
	"bloc_glace": {"scale": 0.154, "foot": 0.05, "solid": 32.0, "sway": 0.0, "shadow": 64.0},
	"oeufs_glace": {"scale": 0.087, "foot": 0.1, "solid": 0.0, "sway": 0.0, "shadow": 20.0},
	# mur_glace: an Obstacle to break with Charge (~2 m), like a wall — no shadow, like mur_fissure.
	"mur_glace": {"scale": 0.206, "foot": 0.05, "solid": Vector2(100, 34), "sway": 0.0, "shadow": 0.0},
	# Hangs from a cave ceiling: no ground collision, no shadow, negative foot (prop.gd docstring)
	# floats the whole picture above its ground anchor — map/mécaniques retunes the exact hang
	# height once placed against the real cave ceiling.
	"stalactites_glace": {"scale": 0.121, "foot": -1.2, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	"cristaux_glace": {"scale": 0.114, "foot": 0.08, "solid": 22.0, "sway": 0.0, "shadow": 45.0, "light": true},
	# porte_givre: the sanctuary door (4 m high, 3.3 m wide, front-on), flush with the ground like porte_ambre/porte_temple.
	"porte_givre": {"scale": 0.361, "foot": 0.01, "solid": Vector2(158, 34), "sway": 0.0, "shadow": 0.0},
	# The same door with 1, 2, 3 Cœurs in its hollows (same picture size: swapped in place, see
	# story/monts_col.gd); hollows at x ∓0.49 m from its middle, 2.15 m (top) and 1.14 m (bottom) up.
	"porte_givre_1": {"scale": 0.361, "foot": 0.01, "solid": Vector2(158, 34), "sway": 0.0, "shadow": 0.0},
	"porte_givre_2": {"scale": 0.361, "foot": 0.01, "solid": Vector2(158, 34), "sway": 0.0, "shadow": 0.0},
	"porte_givre_3": {"scale": 0.361, "foot": 0.01, "solid": Vector2(158, 34), "sway": 0.0, "shadow": 0.0},
	"traineau_suie": {"scale": 0.170, "foot": 0.05, "solid": Vector2(72, 26), "sway": 0.0, "shadow": 50.0},
	"fioles_suie": {"scale": 0.091, "foot": 0.06, "solid": Vector2(25, 10), "sway": 0.0, "shadow": 18.0},
	# A single empty vial of Dame Suie's (29/09, demande de l'utilisateur), ~15 cm tall: checked
	# against the K≈45 rule (docs/direction-artistique.md « Tailles réelles » — fiole_vide.png is
	# 115x415, 415*0.01627/45 ≈ 0.150 m). Rounded glass bottom: sinks a bit into its ground point.
	"fiole_vide": {"scale": 0.01627, "foot": 0.15, "solid": 0.0, "sway": 0.0, "shadow": 12.0},
	# abri_roche: a snow-capped rock overhang where Bertille camps, not a building — open
	# underneath like arche_rocheuse (no blocking collision, no shadow).
	"abri_roche": {"scale": 0.327, "foot": 0.0, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	"statue_cryolophosaure": {"scale": 0.236, "foot": 0.02, "solid": 30.0, "sway": 0.0, "shadow": 85.0},
	# Clins d'œil à Jurassic Park (29/09, agent A, tools/art-jobs/jurassique.mjs). Sizes checked
	# against the K≈45 rule (docs de l'agent, <scratchpad>/jp/PLAN.md « Tailles réelles »). Placement
	# and story wiring: agent B (world/examine.gd, tools/zones/*, docs/histoire.md « Clins d'œil »).
	# griffe_fossile: sits on furniture (Roc's desk) — no ground collision, like registre/panier_fioles.
	# foot -3.1 (demande d'agent B, 29/09) : la monte de ~0,85 m à l'écran pour qu'elle repose SUR le
	# plateau du bureau (devant le microscope) plutôt que par terre à son pied.
	"griffe_fossile": {"scale": 0.0278, "foot": -3.1, "solid": 0.0, "sway": 0.0, "shadow": 10.0},
	# chapeau_helene: wall-mounted (Cabinet), foot négatif (prop.gd docstring) — bottom edge floats
	# ~1.3 m up the wall (same wall height as lanterne_crochet); exact hang height retuned once placed
	# against the real Cabinet wall geometry.
	"chapeau_helene": {"scale": 0.054, "foot": -2.6, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	# affiche_adn ("Monsieur ADN explique...", 29/09, NOUVELLE DIRECTION — remplace affiche_ambre):
	# wall-mounted, same Cabinet wall as chapeau_helene; foot négatif, bottom edge floats ~1.0 m up.
	"affiche_adn": {"scale": 0.09, "foot": -0.83, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	# canne_roc: leaning against the armchair, thin — walk-through like other small handheld props.
	"canne_roc": {"scale": 0.0793, "foot": 0.05, "solid": 0.0, "sway": 0.0, "shadow": 8.0},
	# ambre_moustique: the hidden Forêt trouvaille (same footprint as "ambre"; also ui/ambre_moustique.png).
	"ambre_moustique": {"scale": 0.02184, "foot": 0.1, "solid": 0.0, "sway": 0.0, "shadow": 10.0},
	# voiture_arbre (29/09, NOUVELLE DIRECTION — remplace barque_arbre, déplacée du Marais à la Forêt):
	# édité depuis arbre_geant.png lui-même et recalé à sa même hauteur réelle (scale 1.0 : la mise à
	# l'échelle réelle est déjà appliquée à l'image par le job, voir tools/art-jobs/jurassique.mjs) —
	# mêmes solid/shadow que "arbre_geant" (le même tronc).
	"voiture_arbre": {"scale": 0.5, "foot": 0.04, "solid": 40.0, "sway": 0.0, "shadow": 240.0},   # (~6 m: the car up in the branches, seen by the camera)
	# cloture_brisee: broken from the inside — no collision (the gap is meant to be walked through),
	# no shadow, like the intact "cloture".
	"cloture_brisee": {"scale": 0.3982, "foot": 0.06, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	# banderole_fouilles: two poles + cloth over Sirocco's dig — decorative, no collision. Refaite
	# 29/09 (NOUVELLE DIRECTION, style réf. film) — texte composé en SVG dans le job (accents garantis).
	"banderole_fouilles": {"scale": 0.2616, "foot": 0.03, "solid": 0.0, "sway": 0.0, "shadow": 20.0},
	# creme_raser: refaite 29/09 (NOUVELLE DIRECTION) — bombe à spirale de barbier, plus haute et plus
	# fine que l'ancienne boîte de fer-blanc ; même cache (grottes marines), comme boite_fer_blanc.
	"creme_raser": {"scale": 0.01895, "foot": 0.12, "solid": 4.0, "sway": 0.0, "shadow": 10.0},
	# coffre_comptoir: like caisse_ambre_noir (no such chest existed before).
	"coffre_comptoir": {"scale": 0.0867, "foot": 0.06, "solid": Vector2(40, 18), "sway": 0.0, "shadow": 38.0},
	# table_cuisine: same footprint as table_observation (outdoor furniture, Havre-Doré).
	"table_cuisine": {"scale": 0.1147, "foot": 0.04, "solid": Vector2(40, 14), "sway": 0.0, "shadow": 45.0},
	# flaque_ronde: flat ground decal (Sanctuaire de Givre) — walk-through, no shadow. Image écrasée à
	# 55% de sa hauteur + éclaircie de 15% (demande d'agent B, 29/09 : se lisait comme une flaque
	# debout, trop sombre contre la glace) ; foot 0.25 comme "natte_fouilles" (même idée d'objet plat).
	"flaque_ronde": {"scale": 0.0879, "foot": 0.25, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	# crottes_triceratops (29/09, PERSONNAGES CLINS D'ŒIL — la quête du Dr Sablier, Plaines) : grosse
	# pile, ~0,9 m — solid/shadow comme "rocher_mousse" (un tas au sol de taille comparable).
	"crottes_triceratops": {"scale": 0.1005, "foot": 0.08, "solid": Vector2(70, 26), "sway": 0.0, "shadow": 85.0},
}

@export_enum("arbre_rond", "araucaria", "fougere_arbre", "buisson", "rocher", "cailloux", "tronc", "ronces",
	"hautes_herbes", "fougeres", "fleurs_roses", "fleurs_violettes", "panneau", "cloture", "ambre", "souche",
	"maison_blanche", "maison_jaune", "maison_port", "cabinet", "barque", "caisses", "tonneau", "filet", "bitte",
	"lanterne", "casiers", "cordage", "banc", "sechoir", "ancre", "bac_fleurs",
	"bureau", "bibliotheque", "couveuse", "fougere_pot", "lampe", "fauteuil", "etabli", "mur_cabinet", "socle",
	"porte_ambre", "ecaille", "serrure", "stalagmite", "cristaux", "rocher_grotte", "grand_crane",
	"galet", "monticule", "feu_camp", "etal_fruits", "etal_poisson",
	"fougere_geante", "tronc_mousse", "champignons", "rocher_mousse", "souche_geante", "arbre_geant", "os_dino",
	"mur_fissure", "tente", "cage", "caisse_ambre_noir", "table_papiers", "palissade", "passerelle",
	"roseaux", "arbre_noye", "nenuphars", "cabane_pilotis", "statue_dino", "colonne", "vanne", "fresque", "porte_temple", "racines", "os_geant", "crane_geant_desert", "rocher_canyon", "rocher_grave", "arche_rocheuse", "palmier_oasis", "nid_oviraptor", "totem_vents", "buisson_sec", "tente_nomade",
	"porte_vents", "chariot_cage", "rempart_eboulis", "squelette_geant", "puits_oasis",
	"barreaux_cage", "maison_3d",
	"havre_herboristerie", "havre_mercerie", "havre_relais", "havre_comptoir", "havre_sellerie", "havre_entrepot",
	"havre_maison_1", "havre_maison_2", "havre_maison_3", "havre_maison_4", "benitier", "phare_ruine",
	"coquillages", "algues", "bois_flotte", "rocher_cote", "rocher_recif", "oyats", "nid_pteranodon", "nid_tortue",
	"boite_fer", "gravure_hi", "palmier_cote", "masque_pierre", "varech", "corail", "corail_branches", "anemones",
	"eponges", "herbier", "autel", "statue_spinosaure", "pierre_gravee", "pierre_plate", "pieu_corde", "peau_mue",
	"fougeres_ecrasees", "natte_fouilles", "vertebre", "cotes_sable", "panier_fioles", "outils_mine",
	"table_observation", "etagere_bocaux", "prele", "cycas", "ginkgo", "roseaux_secs", "conifere_sec", "rocher_lichen",
	"sapin_neige", "buisson_givre", "rocher_neige", "pin_tordu", "tronc_calcine", "fougere_cendre", "bennettitale",
	"magnolia", "prele_geante", "nid_geant", "liane_tronc",
	"boite_fer_blanc", "piege_machoires", "tube_cuivre", "boite_ronde", "registre", "roue_chariot",
	"nid_dimorphodon", "buisson_nid", "rocher_oeuf", "frise_masques", "corde_falaise", "nid_tortue_vide",
	"lanterne_crochet", "crochet_vide", "bouilloire_poele",
	"bloc_glace", "oeufs_glace", "mur_glace", "stalactites_glace", "cristaux_glace", "porte_givre", "porte_givre_1", "porte_givre_2", "porte_givre_3",
	"traineau_suie", "fioles_suie", "abri_roche", "statue_cryolophosaure", "fiole_vide",
	"griffe_fossile", "chapeau_helene", "affiche_adn", "canne_roc", "ambre_moustique", "voiture_arbre",
	"cloture_brisee", "banderole_fouilles", "creme_raser", "coffre_comptoir", "table_cuisine", "flaque_ronde",
	"crottes_triceratops")
var kind := "arbre_rond":
	set(value):
		kind = value
		_build()
@export var flip := false:
	set(value):
		flip = value
		_build()
## A tree or a stone hiding an amber pebble: its story flag (see Search).
@export var hidden_pebble: StringName

var sprite: Sprite2D
var _shape: CollisionShape2D
var _shadow: Sprite2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if not Engine.is_editor_hint():
		Quality.changed.connect(_build)
		# Plain scenery that can be searched (a tree shaken, a stone turned over, a bench).
		if kind == "feu_camp":
			add_to_group(&"fire")   # heard crackling nearby (world.gd, AmbienceDB)
		if get_script() == Prop and Search.can_search(self):
			add_to_group(&"interactable")
			if hidden_pebble != &"" and not Game.flag(hidden_pebble):
				add_to_group(&"secret")
		# Plain scenery with something to say about it (a closed house, a barrel…).
		elif get_script() == Prop and Examine.has(kind):
			add_to_group(&"interactable")
			set_meta(&"reach_bonus", Examine.REACH.get(kind, 10.0))
	_build()


## Searching this piece of scenery, or looking at it (Search, Examine).
func interact(player: Player) -> void:
	if Search.can_search(self):
		await Search.search(self, player)
	else:
		await Examine.look(self, player)


## Still hides an amber pebble (the companion senses it).
func is_hiding() -> bool:
	return hidden_pebble != &"" and not Game.flag(hidden_pebble)


func _build() -> void:
	if not is_inside_tree():
		return
	var def: Dictionary = KINDS.get(kind, {})
	if def.is_empty():
		return
	if sprite == null:
		_shadow = Shadow.make(self)
		sprite = Sprite2D.new()
		add_child(sprite)
		_shape = CollisionShape2D.new()
		add_child(_shape)
	var tex: Texture2D = load(ART % kind)
	sprite.texture = tex
	sprite.scale = Vector2.ONE * def["scale"]
	sprite.flip_h = flip
	var h := tex.get_height()
	sprite.offset = Vector2(0, -h / 2.0 + h * def["foot"])
	if def["sway"] > 0.0 and (Engine.is_editor_hint() or Quality.setting(&"sway_props")):
		var mat := ShaderMaterial.new()
		mat.shader = SWAY
		mat.set_shader_parameter("strength", def["sway"])
		mat.set_shader_parameter("push_strength", def["sway"] * 3.0)
		sprite.material = mat
	else:
		sprite.material = null
	Shadow.fit(_shadow, def["shadow"])
	var solid: Variant = def["solid"]
	var outline := PackedVector2Array(def.get("solid_poly", []))
	if not outline.is_empty():   # a model's foot that is no box (a tent turned 3/4: a diamond)
		var points := outline
		if flip:   # mirrored (same winding)
			points = PackedVector2Array()
			for i in range(outline.size() - 1, -1, -1):
				points.append(Vector2(-outline[i].x, outline[i].y))
		var poly := ConvexPolygonShape2D.new()
		poly.points = points
		_shape.shape = poly
		_shape.position = Vector2.ZERO
	elif solid is Vector2:
		var box := RectangleShape2D.new()
		box.size = solid
		_shape.shape = box
		_shape.position = Vector2(0, -solid.y / 2.0 + 6)
	elif solid > 0.0:
		var circle := CircleShape2D.new()
		circle.radius = solid
		_shape.shape = circle
		_shape.position = Vector2.ZERO
	_shape.disabled = not (solid is Vector2 or solid > 0.0)
