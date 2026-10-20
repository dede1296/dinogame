class_name ApexObjectives
## Chapter 9 and the epilogue: what Chloé can do now (VolcanObjectives.main hands over to main() once
## Isaure and Maïa have been seen at the crater's door; Objectives._side calls side() from the dawn
## on). The chain of docs/chapitre-9-scenes.md « Objectifs »: the dawn (her hatchling in the party;
## rest) → Isaure → the gate → the Terre des Apex (page 39 on the side) → the bottom: Hélène → the
## Souverain (« Les Sceaux appellent les Alphas. L'Ambre clair quand il écoute. ») → the Cabinet
## (three days later) → the jetty (the next day) → the end. After it: the post-game's own list. The
## places are read from the zones (VolcanObjectives._at: a node's position in the zone's scene), else
## the names of ApexPlaces (Apex.place).

const A := preload("res://story/apex.gd")
const V := preload("res://story/volcan.gd")
const TITLES := {
	"aube_depart": "Le petit d'Hélène", "aube": "L'aube, devant la porte", "porte_apex": "Cinq Cœurs dans la porte",
	"terre_apex": "La Terre des Apex", "fond": "Au fond du cratère", "souverain": "Le Souverain",
	"cabinet_epilogue": "Trois jours plus tard", "marche": "Maïa, sur la marche", "jetee": "Demain, sur la jetée",
	"page_39": "La dernière page du bord", "geants": "Les géants du cratère", "dinodex": "Le Dinodex",
	"fossiles": "Les fossiles", "revanches": "Les revanches", "helene_cabinet": "Hélène au Cabinet", "nouvelle_partie": "Nouvelle partie+",
}
## The new zones' scenes when world.gd does not list them yet (the CARTE agent's).
const ZONE_SCENES := {&"terre_apex": "res://regions/apex/terre_apex.tscn", &"coeur_apex": "res://regions/apex/coeur_apex.tscn"}


static func _add(out: Array[Dictionary], id: String, text: String, zone: StringName, tile := Vector2.INF, is_main := false) -> void:
	out.append({"id": id, "title": TITLES.get(id, text), "text": text, "zone": zone, "tile": tile, "main": is_main})


## True once chapter 9's objectives take over (Isaure and Maïa seen at the door).
static func active() -> bool:
	return Game.flag(&"isaure_porte_vue") and Game.flag(&"maia_porte_vue")


## The main step, the most advanced first.
static func main(out: Array[Dictionary]) -> void:
	if Game.flag(&"epilogue_fini"):
		return
	if Game.flag(&"epilogue_cabinet"):
		_add(out, "jetee", "Demain, sur la jetée de Port-Ambre. Tout le village y sera. Hélène aussi.",
			A.PORT, A.place("JETEE_HELENE"), true)
		return
	if Game.flag(&"reserve_dite"):
		_add(out, "marche", "Maïa attend sur la marche du Cabinet. Elle compte les Compsognathus.",
			A.PORT, A.place("MARCHE_MAIA"), true)
		return
	if Game.flag(&"apex_fini"):
		_add(out, "cabinet_epilogue", "Trois jours plus tard. Hélène est au Cabinet, dans le fauteuil de Roc. Roc fait du thé.",
			A.CABINET, Objectives.spot(A.CABINET, "Fauteuil"), true)
		return
	if Game.flag(&"souverain_eveille") and not Game.flag(&"souverain_apaise"):
		_add(out, "souverain", "Le Souverain s'est réveillé, et il a peur. L'apaiser : parle-lui. (Astuce : les Sceaux appellent les Alphas. L'Ambre clair quand il écoute.)",
			A.COEUR, _at(A.COEUR, "Souverain", A.place("SOUVERAIN_PAROI")), true)
		return
	if Game.flag(&"apex_arrivee") or Game.flag(&"coeur_apex_arrivee"):
		_add(out, "fond", "Tout en bas du cratère, le grand bloc d'ambre. Hélène est dedans, contre lui. Isaure et Maïa attendent devant.",
			A.TERRE if not Game.flag(&"coeur_apex_arrivee") else A.COEUR,
			_at(A.TERRE, "SortieCoeur", A.place("SORTIE_COEUR")) if not Game.flag(&"coeur_apex_arrivee") else _at(A.COEUR, "BlocSouverain", A.place("BLOC")), true)
		return
	if Game.flag(&"apex_ouvert"):
		_add(out, "terre_apex", "La porte est ouverte. Isaure et Maïa sont passées devant : la Terre des Apex est derrière.",
			A.PORTE, _at(A.PORTE, "PortailApex", V.place("PORTAIL")), true)
		return
	if Game.flag(&"isaure_vaincue"):
		_add(out, "porte_apex", "Isaure a tenu parole : les quatre Cœurs sont dans ta sacoche. Décide de ce qu'on fait de cette porte.",
			A.PORTE, _at(A.PORTE, "IsaurePorte", V.place("ISAURE")), true)
		return
	if not A.starter_in_party():
		var d := A.starter()
		var where := "%s attend au Cabinet : fais-le venir (Roc, la réserve du Cabinet)." % d.nickname if d else "Il attend au Cabinet."
		_add(out, "aube_depart", "Isaure attend l'aube, et ton dino de départ dans l'équipe. " + where,
			A.CABINET, Objectives.spot(A.CABINET, "Roc"), true)
		return
	_add(out, "aube", "Isaure attend l'aube devant la porte du cratère. Soigne ton équipe : quand tu seras prête, va lui dire que c'est l'aube.",
		A.PORTE, _at(A.PORTE, "IsaurePorte", V.place("ISAURE")), true)


## The side steps: page 39 at the crater's rim; after the epilogue, the post-game's list.
static func side(out: Array[Dictionary]) -> void:
	if Game.flag(&"apex_arrivee") and not Game.flag(&"found_journal_39"):
		_add(out, "page_39", "Hélène a laissé un dernier cairn au bord du cratère, à gauche de l'entrée. Trois pierres noires.",
			A.TERRE, _at(A.TERRE, "Page39", A.place("CAIRN")))
	if not Game.flag(&"post_game"):
		return
	if not Game.flag(&"geants_reveilles"):   # (post-game, lot A : lequel ouvre l'œil, Hélène, avec qui s'asseoir)
		var g := ApexGeants.objective()
		_add(out, "geants", g["text"], g["zone"], _at(g["zone"], g["node"], g["tile"]))
	_add(out, "dinodex", "Le Dinodex : toutes les espèces de l'île. Roc compte avec toi.", A.CABINET, Objectives.spot(A.CABINET, "Roc"))
	var fossils := Fossiles.objective()   # (Sirocco, puis les os, puis Hélène ; story/fossiles.gd)
	_add(out, "fossiles", fossils["text"], fossils["zone"])
	_add(out, "revanches", Revanches.objective_text(), &"plaines", Vector2(100.8, 65.2))
	_add(out, "helene_cabinet", "Hélène au Cabinet, dans son fauteuil. Elle a des choses à t'apprendre.", A.CABINET, Objectives.spot(A.CABINET, "Fauteuil"))
	_add(out, "nouvelle_partie", "Nouvelle partie+ : recommencer l'île avec ce qu'on sait.", &"")


## Where node `node_name` stands in `zone` (tiles), read from the zone's scene (VolcanObjectives),
## the new zones' scenes too; `fallback` when the zone or the node is not there yet.
static func _at(zone: StringName, node_name: String, fallback: Vector2) -> Vector2:
	if ZONE_SCENES.has(zone) and not ResourceLoader.exists(ZONE_SCENES[zone]):
		return fallback
	return VolcanObjectives._at(zone, node_name, fallback)
