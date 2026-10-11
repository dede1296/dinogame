class_name PadFocus
extends RefCounted
## Rendre un écran piloté à la souris pilotable à la croix et à A, sans le réécrire : ses boutons
## deviennent focusables (le contour doré dit lequel est choisi) et, si le joueur est au clavier ou
## à la manette, l'un d'eux a déjà le focus — la croix n'a plus qu'à naviguer, A à valider.
## Pour qui est à la souris, rien ne change (aucun contour tant qu'on ne touche ni clavier ni manette).

const GOLD := Color(1, 0.86, 0.5)
const FOCUS_FILL := Color(0.22, 0.2, 0.15)


## `root` : l'écran. `prefer_in` : où prendre le premier focus (la liste, plutôt que les onglets du haut).
## `keep` : l'indice du bouton qui avait le focus avant que la liste soit refaite (-1 : le premier).
static func prepare(root: Node, prefer_in: Node = null, keep := -1) -> void:
	var buttons := _buttons(root)
	for button in buttons:
		button.focus_mode = Control.FOCUS_ALL
		if not button.has_theme_stylebox_override(&"focus"):
			button.add_theme_stylebox_override(&"focus", SettingsMenu._box(FOCUS_FILL, 12, 4, 0, GOLD))
	if not Prompts.navigating or buttons.is_empty():
		return
	var pool: Array[Button] = _buttons(prefer_in) if prefer_in else buttons
	if pool.is_empty():
		pool = buttons
	var picked := pool[clampi(keep, 0, pool.size() - 1)] if keep >= 0 else pool[0]
	picked.grab_focus.call_deferred()


## L'indice, parmi les boutons de `container`, de celui qui a le focus (-1 : aucun).
static func focused_index(container: Node) -> int:
	var owner := container.get_viewport().gui_get_focus_owner()
	return _buttons(container).find(owner) if owner else -1


## Les boutons visibles et utilisables sous `node`.
static func _buttons(node: Node) -> Array[Button]:
	var found: Array[Button] = []
	for child in node.find_children("*", "Button", true, false):
		var button := child as Button
		if _leaving(button):   # (a list being rebuilt: its old rows are still in the tree until the frame ends)
			continue
		if button.is_visible_in_tree() and not button.disabled and button.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			found.append(button)
	return found


## Is it, or one of its parents, about to be freed?
static func _leaving(node: Node) -> bool:
	while node:
		if node.is_queued_for_deletion():
			return true
		node = node.get_parent()
	return false
