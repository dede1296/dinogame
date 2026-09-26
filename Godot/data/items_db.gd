class_name ItemsDB
## Chloé's things and the shops that sell them (Havre-Doré). Prices in pièces (Game.items
## "piece"). `kind`: "soin" (used on a dino), "capture", "cle" (a key item: kept once, never
## sold), "quete" (for a quest). `sell`: what the Comptoir gives back (0: cannot be sold).

const ICON := "res://assets/art/ui/%s"

const ITEMS := {
	"baie": {"name": "Baie", "icon": "baie", "kind": "soin", "price": 30, "sell": 12,
		"desc": "Rend 20 PV à un dino. Les dinos en raffolent."},
	"fougere": {"name": "Fougère curative", "icon": "fougere", "kind": "soin", "price": 90, "sell": 35,
		"desc": "Soigne complètement un dino. Recette de Mémé Pervenche."},
	"collier": {"name": "Collier d'ambre", "icon": "collier", "kind": "capture", "price": 60, "sell": 25,
		"desc": "Lancé sur un dino sauvage affaibli, il peut le convaincre de te suivre."},
	"bottes": {"name": "Bottes de marche", "icon": "bottes", "kind": "cle", "price": 400, "sell": 0,
		"desc": "Semelles d'ambre souple : Chloé marche plus vite partout."},
	"boucle": {"name": "Boucle d'ambre", "icon": "boucle", "kind": "quete", "price": 150, "sell": 0,
		"desc": "Une boucle taillée dans l'ambre, pour une selle solide."},
	"cuir": {"name": "Cuir mué", "icon": "cuir", "kind": "quete", "price": 0, "sell": 0,
		"desc": "Une peau de Parasaurolophus, perdue à la mue. Souple et solide."},
	"selle": {"name": "Selle de Joss", "icon": "selle", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Faite sur mesure. Un grand dino adulte peut porter Chloé."},
}

## shop id -> {name, keeper, stock: [item ids], sells: can Chloé sell here, tears: buys amber tears}
const SHOPS := {
	&"herboristerie": {"name": "Herboristerie Pervenche", "keeper": "Mémé Pervenche", "stock": ["baie", "fougere"], "sells": true},
	&"mercerie": {"name": "Mercerie « Au Fil d'Ambre »", "keeper": "Rosalie", "stock": ["collier", "bottes"], "sells": true},
	&"comptoir": {"name": "Comptoir d'Ambre", "keeper": "Maître Ferréol", "stock": ["boucle"], "sells": true, "tears": true},
}
## What the Comptoir pays for an amber tear (Roc would rather have them…).
const TEAR_PRICE := 40


static func item(id: String) -> Dictionary:
	return ITEMS.get(id, {"name": id, "icon": "ambre", "kind": "quete", "price": 0, "sell": 0, "desc": ""})


static func icon(id: String) -> Texture2D:
	var path: String = ICON % item(id)["icon"]
	return load(path + ".png") if ResourceLoader.exists(path + ".png") else load(path + ".webp")
