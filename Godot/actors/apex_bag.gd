class_name ApexBag
extends RefCounted
## Ce qui entre et sort du sac et de l'équipe de Chloé au chapitre 9 et à l'épilogue (docs/chapitre-9-scenes.md,
## « Carte des drapeaux, objets, événements ») : les scènes (story/apex*.gd, story/epilogue.gd) l'appellent au bon
## moment et posent elles-mêmes leurs drapeaux. Les drapeaux coeur_1 à coeur_5 restent vrais : seuls les objets
## bougent.
##   les Cœurs rendus par Isaure (return_hearts : coeur_1 à 4 reviennent), puis posés dans la porte (hearts_in_door :
##   les cinq quittent le sac) ; le dino de départ monté à Lien 5 (starter_full_bond) ; Moustique rendu à Maïa
##   (moustique_leaves : il quitte l'équipe ou la réserve) ; le masque en carton, les moufles, la lettre (take) ;
##   l'insigne de gardienne (give_insigne).

const HEARTS_ISAURE: Array[String] = ["coeur_1", "coeur_2", "coeur_3", "coeur_4"]
const HEARTS: Array[String] = ["coeur_1", "coeur_2", "coeur_3", "coeur_4", "coeur_5"]
const MOUSTIQUE := "Moustique"
const MOUSTIQUE_SPECIES := &"dimorphodon"
const INSIGNE := "insigne_gardienne"


## Isaure a perdu son pari : les quatre Cœurs repassent dans la sacoche de Chloé (ceux qui n'y sont pas déjà).
## Retourne combien sont revenus.
static func return_hearts() -> int:
	var back := 0
	for id in HEARTS_ISAURE:
		if Game.item_count(id) == 0:
			Game.give_item(id)
			back += 1
	return back


## Chloé pose les cinq Cœurs dans la porte : ils quittent le sac (les drapeaux coeur_n restent).
static func hearts_in_door() -> void:
	for id in HEARTS:
		take(id)


## Un objet quitte le sac (tous les exemplaires). Retourne combien il y en avait.
static func take(id: String) -> int:
	var had := Game.item_count(id)
	if had > 0:
		Game.items.erase(id)
	return had


## L'insigne de gardienne (une fois).
static func give_insigne() -> void:
	if Game.item_count(INSIGNE) == 0:
		Game.give_item(INSIGNE)


## Le dino de départ monté à 5 cœurs par l'histoire (« il se met entre Chloé et le Souverain »). Retourne les cœurs
## gagnés (0 : il y était déjà, ou il n'y a pas de dino de départ) ; la barre d'équipe montre « +♥ ».
static func starter_full_bond() -> int:
	var d := Game.starter_dino()
	if d == null:
		return 0
	return Game.add_bond(d, Dino.MAX_BOND - d.bond)


## Moustique (le Dimorphodon de Maïa, confié au chapitre 7) retourne à Maïa : il quitte l'équipe ou la réserve.
## Jamais le dernier dino de l'équipe (Chloé n'est jamais seule : il passe alors après un dino de la réserve).
## Retourne vrai s'il était là.
static func moustique_leaves() -> bool:
	var d := moustique()
	if d == null:
		return false
	if Game.party.has(d):
		if Game.party.size() == 1:
			if Game.box.is_empty():
				return false
			Game.party.append(Game.box.pop_front())
		Game.party.erase(d)
		Game.party_changed.emit()
	else:
		Game.box.erase(d)
	return true


## Moustique dans l'équipe ou la réserve, ou null.
static func moustique() -> Dino:
	for d: Dino in Game.party + Game.box:
		if d.nickname == MOUSTIQUE and d.species().id == MOUSTIQUE_SPECIES:
			return d
	return null
