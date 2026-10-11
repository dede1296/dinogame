extends RefCounted
## Les ombres aplaties, genre par genre (FlatShadows) : ce que chaque décor jette au sol quand le
## soleil (ou la lune) l'éclaire. Les genres sont ceux de Prop.KINDS, plus les touffes des cases
## d'herbes hautes (TUFT) et les personnages (CHARACTER). Un genre que la table ne cite pas a une
## ombre déduite de Prop.KINDS (for_kind) : un autre agent y ajoute des genres sans passer ici.
##
## strength : force (1 : une ombre pleine ; 0 : aucune) ;
## length   : longueur (× celle que donne le soleil ; < 1 : plus courte, une plante souple) ;
## blur     : flou en plus (m), une chose aux bords flous (des herbes, un filet) ;
## turn     : 1 = l'image se tourne face au soleil pour jeter son ombre (une chose ronde : un arbre,
##            un rocher, un dino), 0 = une planche vue de face (une clôture, une barque, un mur) ;
## grass    : false = son ombre reste au ras du sol dans les herbes hautes (les herbes elles-mêmes).
##
## Les « aucune » (strength 0) : ce qui est déjà couché au sol (nénuphars sur l'eau, os à plat,
## flaques, nattes, coquillages, peau de mue…), ce qui est accroché à un mur (foot négatif : lanterne,
## affiche, chapeau, stalactites, frise, corde le long de la falaise), les portes et parois posées
## contre une falaise (l'ombre traverserait la roche), et les barreaux d'une cage (la cage derrière
## jette déjà l'ombre).

const TUFT := "touffe"
const CHARACTER := "personnage"
const DEFAULTS := {"strength": 1.0, "length": 1.0, "blur": 0.0, "turn": 1.0, "grass": true}
## Une image plus large que haute de ce rapport est une planche vue de face (sans entrée ici).
const WIDE := 1.6

const KINDS := {
	# Chloé, les dinos, les PNJ : leur image tournée face au soleil ; dans les herbes hautes, au ras
	# du sol (avancée par-dessus les touffes, elle passerait sur leurs propres jambes).
	"personnage": {"grass": false},
	# Herbes et fleurs : une ombre courte et très légère ; presque rien pour les fleurs.
	"touffe": {"strength": 0.32, "length": 0.55, "blur": 0.05, "grass": false},
	"hautes_herbes": {"strength": 0.4, "length": 0.6, "blur": 0.05, "grass": false},
	"fougeres": {"strength": 0.55, "length": 0.75, "blur": 0.03},
	"fleurs_roses": {"strength": 0.22, "length": 0.6, "blur": 0.03},
	"fleurs_violettes": {"strength": 0.22, "length": 0.6, "blur": 0.03},
	"prele": {"strength": 0.3, "length": 0.7, "blur": 0.03},
	"oyats": {"strength": 0.3, "length": 0.6, "blur": 0.04},
	"roseaux": {"strength": 0.5, "length": 0.85, "blur": 0.04},
	"roseaux_secs": {"strength": 0.45, "length": 0.8, "blur": 0.04},
	"fougere_cendre": {"strength": 0.4, "length": 0.7, "blur": 0.03},
	"algues": {"strength": 0.2, "length": 0.5, "blur": 0.05},
	"varech": {"strength": 0.35, "length": 0.8, "blur": 0.06},
	"herbier": {"strength": 0.2, "length": 0.5, "blur": 0.05},
	# Clôtures et piquets : la planche telle qu'elle est plantée (de face).
	"cloture": {"strength": 0.9, "turn": 0.0},
	"cloture_brisee": {"strength": 0.85, "turn": 0.0},
	"pieu_corde": {"strength": 0.9},
	"panneau": {"strength": 0.9, "turn": 0.5},
	# Le port : les barques sur l'eau (une ombre douce et courte, sur l'eau même), le filet tendu,
	# le séchoir à poissons ; la passerelle suspendue entre deux arbres géants.
	"barque": {"strength": 0.55, "length": 0.4, "blur": 0.06, "turn": 0.0},
	"filet": {"strength": 0.75, "blur": 0.03, "turn": 0.2},
	"sechoir": {"strength": 0.8, "turn": 0.6},
	"passerelle": {"strength": 0.6, "blur": 0.08, "turn": 0.0},
	"banc": {"turn": 0.6},
	# Bas et ronds : une petite bosse de terre retournée.
	"monticule": {"strength": 0.5, "length": 0.5, "blur": 0.03},
	# Grands décors : la planche telle qu'on la voit (ils sont larges et souvent près d'une paroi).
	"grand_crane": {"strength": 0.8, "turn": 0.3},
	"crane_geant_desert": {"strength": 0.8, "turn": 0.3},
	"squelette_geant": {"strength": 0.8, "turn": 0.3},
	"arche_rocheuse": {"strength": 0.7, "turn": 0.0},
	"abri_roche": {"strength": 0.6, "turn": 0.0},
	"rempart_eboulis": {"strength": 0.7, "turn": 0.0},
	"nid_geant": {"strength": 0.8, "turn": 0.5},
	"mur_fissure": {"strength": 0.5, "turn": 0.0},
	"mur_glace": {"strength": 0.5, "turn": 0.0},
	# Meubles contre un mur (dedans) : une ombre légère, de face.
	"bibliotheque": {"strength": 0.5, "turn": 0.0},
	"etagere_bocaux": {"strength": 0.5, "turn": 0.0},
	# Les maisons montrées en images (qualité sans modèles 3D) : la façade, de face.
	"maison_blanche": {"strength": 0.9, "turn": 0.0}, "maison_jaune": {"strength": 0.9, "turn": 0.0},
	"maison_port": {"strength": 0.9, "turn": 0.0}, "cabinet": {"strength": 0.9, "turn": 0.0},
	"havre_herboristerie": {"strength": 0.9, "turn": 0.0}, "havre_mercerie": {"strength": 0.9, "turn": 0.0},
	"havre_relais": {"strength": 0.9, "turn": 0.0}, "havre_comptoir": {"strength": 0.9, "turn": 0.0},
	"havre_sellerie": {"strength": 0.9, "turn": 0.0}, "havre_entrepot": {"strength": 0.9, "turn": 0.0},
	"havre_maison_1": {"strength": 0.9, "turn": 0.0}, "havre_maison_2": {"strength": 0.9, "turn": 0.0},
	"havre_maison_3": {"strength": 0.9, "turn": 0.0}, "havre_maison_4": {"strength": 0.9, "turn": 0.0},
	"cabane_pilotis": {"strength": 0.9, "turn": 0.0}, "maison_3d": {"strength": 0.9, "turn": 0.0},
	"phare_ruine": {"strength": 0.9, "turn": 0.5},
	# Aucune : couché au sol, sur l'eau, ou à plat.
	"nenuphars": {"strength": 0.0}, "os_dino": {"strength": 0.0}, "coquillages": {"strength": 0.0},
	"nid_tortue": {"strength": 0.0}, "nid_tortue_vide": {"strength": 0.0}, "peau_mue": {"strength": 0.0},
	"fougeres_ecrasees": {"strength": 0.0}, "natte_fouilles": {"strength": 0.0}, "flaque_ronde": {"strength": 0.0},
	# Aucune : accroché à un mur ou à une paroi.
	"frise_masques": {"strength": 0.0}, "corde_falaise": {"strength": 0.0}, "lanterne_crochet": {"strength": 0.0},
	"crochet_vide": {"strength": 0.0}, "stalactites_glace": {"strength": 0.0}, "chapeau_helene": {"strength": 0.0},
	"affiche_adn": {"strength": 0.0}, "griffe_fossile": {"strength": 0.0},
	# Aucune : posé contre une falaise ou un mur (l'ombre passerait dans la roche).
	"porte_ambre": {"strength": 0.0}, "porte_temple": {"strength": 0.0}, "porte_vents": {"strength": 0.0},
	"porte_givre": {"strength": 0.0}, "porte_givre_1": {"strength": 0.0}, "porte_givre_2": {"strength": 0.0},
	"porte_givre_3": {"strength": 0.0}, "fresque": {"strength": 0.0}, "mur_cabinet": {"strength": 0.0},
	# Aucune : les barreaux devant le dino d'une cage (la cage derrière jette l'ombre).
	"barreaux_cage": {"strength": 0.0},
}


## L'ombre d'un genre : {strength, length, blur, turn, grass}. `picture` : la taille de son image
## (px), pour reconnaître une planche (plus large que haute) quand la table ne le dit pas.
static func for_kind(kind: String, picture := Vector2.ONE) -> Dictionary:
	if KINDS.has(kind):
		return DEFAULTS.merged(KINDS[kind], true)
	var out := DEFAULTS.duplicate()
	var def: Dictionary = Prop.KINDS.get(kind, {})
	var solid: Variant = def.get("solid", 0.0)
	var walk_through := not (solid is Vector2) and float(solid) <= 0.0
	if float(def.get("foot", 0.0)) < 0.0:   # accroché au mur, au-dessus de son point au sol
		out["strength"] = 0.0
	elif walk_through and float(def.get("shadow", 0.0)) <= 0.0:   # une plante souple, une chose plate
		out["strength"] = 0.45
		out["length"] = 0.7
		out["blur"] = 0.03
	if def.get("float", false):   # sur l'eau : douce et courte
		out["strength"] = float(out["strength"]) * 0.6
		out["length"] = 0.6
	if picture.x > picture.y * WIDE or (solid is Vector2 and solid.x > solid.y * 3.0):
		out["turn"] = 0.3   # une planche large vue de face
	return out
