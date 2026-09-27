@tool
extends Pickup
## A page of Hélène's journal that is only there on full-moon nights (Game.is_full_moon):
## the Lisière's page 10, in the Forêt Jurassique. The rest of the time there is nothing
## to see nor to pick up where it lies; it glows again the next full moon.

var _taking := false


func _ready() -> void:
	super()
	if Engine.is_editor_hint() or is_queued_for_deletion():
		return
	_show(Game.is_full_moon())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _taking or is_queued_for_deletion():
		return
	var moon := Game.is_full_moon()
	if moon != visible:
		_show(moon)


func _show(on: bool) -> void:
	visible = on
	if on:
		add_to_group(&"interactable")
	else:
		remove_from_group(&"interactable")


func interact(player: Player) -> void:
	_taking = true
	await super(player)
