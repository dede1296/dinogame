class_name French
## Little rules of French for lines built with a name inside: « l'Ankylosaurus » but « le
## Protoceratops », « d'Écho » but « de Bastion », « du Protoceratops sauvage ».

const VOWELS := "aeiouyàâäéèêëîïôöùûüh"   # h: silent in the island's names (Hélène)


## « l'Allosaurus », « le Protoceratops ».
static func le(noun: String) -> String:
	return ("l'" if _vowel(noun) else "le ") + noun


## « de » before a name or a group: « d'Écho », « de Bastion », « du Protoceratops sauvage »
## (from « le … »), « de l'Allosaurus sauvage ».
static func de(words: String) -> String:
	if words.begins_with("le "):
		return "du " + words.substr(3)
	if words.begins_with("les "):
		return "des " + words.substr(4)
	if words.begins_with("la ") or words.begins_with("l'"):
		return "de " + words
	return ("d'" if _vowel(words) else "de ") + words


static func _vowel(word: String) -> bool:
	return word != "" and VOWELS.contains(word.substr(0, 1).to_lower())
