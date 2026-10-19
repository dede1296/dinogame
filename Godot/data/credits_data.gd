class_name CreditsData
extends RefCounted
## Les crédits du jeu, prêts pour l'écran de crédits. Tiré de docs/credits.md (à tenir en phase).
## SECTIONS : tableau de {"title": String, "lines": Array[String]}. Une ligne vide ("") est un espacement.
## Une ligne qui commence par "## " est un sous-titre. Les textes sont en français, tels qu'affichés.
## À vérifier par Greg avant sortie : voir docs/licences-audit.md (ElevenLabs gratuit, Stable Audio, nano-banana).

const GAME_TITLE := "Ambrelune"
const POWERED_BY_STABILITY := "Powered by Stability AI"
## Texte de la licence de la police, à garder avec le fichier (assets/fonts/Caveat-OFL.txt).
const FONT_LICENSE_FILE := "res://assets/fonts/Caveat-OFL.txt"

const SECTIONS := [
	{
		"title": "Création",
		"lines": [
			"Ambrelune",
			"",
			"Un jeu créé par",
			"Grégory Cuypers",
			"Création, histoire, direction du jeu",
		],
	},
	{
		"title": "Outils",
		"lines": [
			"Ambrelune a été fabriqué avec l'aide d'outils d'intelligence artificielle.",
			"Grégory Cuypers a imaginé le jeu, l'histoire et les personnages, et a dirigé chaque étape.",
			"",
			"Code et écriture : Claude, par Anthropic",
			"Images : nano-banana (modèle d'image Gemini de Google)",
			"Sons et ambiances : Stable Audio Open 1.0, par Stability AI, et ElevenLabs",
			"Voix de quelques personnages : ElevenLabs",
			"Images retouchées en local : ComfyUI",
			"Moteur : Godot Engine",
			"",
			"Powered by Stability AI",
		],
	},
	{
		"title": "Assets et licences",
		"lines": [
			"## Bruitages et pas",
			"Pas sur le sol : « RPG Audio » de Kenney (www.kenney.nl), domaine public (CC0)",
			"Bruitages (portes, coups, pièces, pages, verre, pierre) : packs sonores de Kenney (www.kenney.nl), domaine public (CC0)",
			"",
			"## Icônes de touches et de manettes",
			"« Input Prompts » de Kenney (www.kenney.nl), domaine public (CC0)",
			"",
			"## Polices",
			"Caveat, par The Caveat Project Authors, licence SIL Open Font 1.1",
			"",
			"## Musiques",
			"Les musiques sont composées pour le jeu (synthétiseur du jeu).",
			"",
			"## Ambiances, cris et pas de neige",
			"Générés avec ElevenLabs et Stable Audio Open 1.0 pour le jeu.",
			"",
			"## Voix",
			"Les voix du prologue sont générées avec ElevenLabs.",
			"",
			"## Images",
			"Les décors, personnages, dinosaures et objets sont dessinés pour le jeu avec nano-banana, sous la direction de Grégory Cuypers.",
		],
	},
	{
		"title": "Moteur et bibliothèques",
		"lines": [
			"Ambrelune utilise Godot Engine, © 2014-présent Godot Engine contributors, © 2007-2014 Juan Linietsky, Ariel Manzur, licence MIT.",
			"https://godotengine.org",
			"Godot embarque d'autres bibliothèques libres (FreeType, HarfBuzz, libogg, libvorbis, zlib, mbedTLS, et d'autres).",
			"Leurs licences complètes sont dans l'écran « Licences ».",
		],
	},
	{
		"title": "Remerciements",
		"lines": [
			"Chloé, pour qui ce jeu existe.",
			"Kenney, pour ses assets libres.",
			"La communauté Godot.",
			"Les joueurs et les joueuses.",
		],
	},
]

## À ajouter à la section « Moteur et bibliothèques » SEULEMENT si le dossier demo/ reste dans l'export
## (crédit obligatoire, CC BY 4.0). Plus simple : l'exclure de l'export.
const OPTIONAL_LIMBOAI_LINE := "Éléments d'interface de démonstration du plugin LimboAI : © 2024 Aleksandra Snitsaruk, licence CC BY 4.0"

## Mentions du moteur, lues à l'exécution pour l'écran « Licences » :
## Engine.get_license_text(), Engine.get_license_info(), Engine.get_copyright_info().
const ENGINE_LICENSE_NOTE := "Les licences de Godot et de ses bibliothèques sont fournies par le moteur (Engine.get_license_text / get_license_info / get_copyright_info)."


## Toutes les lignes à plat, titres de section compris (utile pour un test ou un défilement simple).
static func flat_lines() -> Array[String]:
	var out: Array[String] = []
	for section: Dictionary in SECTIONS:
		out.append(String(section["title"]))
		for line in section["lines"]:
			out.append(String(line))
		out.append("")
	return out
