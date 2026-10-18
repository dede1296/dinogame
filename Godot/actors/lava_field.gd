class_name LavaField
extends Node2D
## La lave d'une zone (Lava) : ses cases, lues dans les métas de la zone (Lava.META, META_CELLS,
## META_RETREAT), les murs qui arrêtent Chloé à pied (un StaticBody2D sur Lava.LAYER, les cases
## voisines fondues en grands rectangles comme les falaises de Region), et la distance de chaque case
## à la lave (la chaleur, Heat). La lave « qui se retire » (META_RETREAT) est un mur du monde (couche
## 1 : personne ne passe, même un dino de pierre ou de feu) tant que son drapeau est faux ; posé, le
## mur disparaît, et ses cases redeviennent de la roche ordinaire.

## Jusqu'où (cases) on mesure la distance à la lave : la chaleur se sent un peu au-delà.
const REACH_TILES := 4
const SOLID_LAYER := 1

var region: Node
var _tile := Vector2(48, 48)
var _size := Vector2i.ZERO
var _cells := {}      # Vector2i -> true : la lave qu'un dino de pierre ou de feu franchit
var _retreat := {}    # Vector2i -> true : la lave que personne ne franchit, jusqu'au drapeau
var _retreat_flag: StringName = Lava.RETREAT_FLAG
var _distance := PackedFloat32Array()   # par case, distance (cases) à la lave franchissable
var _retreat_body: StaticBody2D


## À appeler avant de l'ajouter à la zone `r` (une Region).
func setup(r: Node) -> void:
	region = r
	if r.has_method(&"tile_size") and r.get(&"terrain") != null:
		_tile = r.call(&"tile_size")
		_size = r.call(&"map_size")
	_cells = cells_of(r.get_meta(Lava.META, null), r.get_meta(Lava.META_CELLS, []))
	if r.has_meta(Lava.META_RETREAT):
		var meta = r.get_meta(Lava.META_RETREAT)
		_retreat = cells_of(meta if meta is Image else null, meta if meta is Array else [])
		_retreat_flag = StringName(r.get_meta(Lava.META_RETREAT_FLAG, Lava.RETREAT_FLAG))
	_measure()


func _ready() -> void:
	_add_body(_cells, Lava.LAYER, "Coulees")
	if not _retreat.is_empty() and not Game.flag(_retreat_flag):
		_retreat_body = _add_body(_retreat, SOLID_LAYER, "CouleesProfondes")
		Game.flag_changed.connect(_on_flag)


## Les cases de lave d'une image (blanc ≥ 0,5) et d'une liste de Rect2i (en cases).
static func cells_of(image: Image, rects: Array) -> Dictionary:
	var out := {}
	if image:
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x, y).r >= 0.5:
					out[Vector2i(x, y)] = true
	for r in rects:
		var rect: Rect2i = r if r is Rect2i else Rect2i(r)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				out[Vector2i(x, y)] = true
	return out


func cell_of(world_pos: Vector2) -> Vector2i:
	return Vector2i(((world_pos - _origin()) / _tile).floor())


## Où est la zone dans le monde (à l'origine hors de l'arbre : une zone ouverte pour la regarder).
func _origin() -> Vector2:
	var r := region as Node2D
	return r.global_position if r and r.is_inside_tree() else Vector2.ZERO


## De la lave (franchissable, ou celle qui ne s'est pas encore retirée) à cette position ?
func is_lava(world_pos: Vector2) -> bool:
	var c := cell_of(world_pos)
	return _cells.has(c) or (_retreat_body != null and _retreat.has(c))


## De la lave franchissable sur le dos d'un dino de pierre ou de feu (pas celle qui se retire) ?
func is_crossable(world_pos: Vector2) -> bool:
	return _cells.has(cell_of(world_pos))


func cell_count() -> int:
	return _cells.size()


## La lave du chemin du cratère tient-elle encore ?
func retreat_holds() -> bool:
	return _retreat_body != null


## À combien de cases de la lave est cette position (0 dessus ; REACH_TILES + 1 au-delà) ?
func distance_tiles(world_pos: Vector2) -> float:
	var c := cell_of(world_pos)
	if _distance.is_empty() or c.x < 0 or c.y < 0 or c.x >= _size.x or c.y >= _size.y:
		return 0.0 if _cells.has(c) else REACH_TILES + 1.0
	return _distance[c.y * _size.x + c.x]


## Le centre d'une case, dans le monde.
func cell_center(c: Vector2i) -> Vector2:
	return _origin() + (Vector2(c) + Vector2(0.5, 0.5)) * _tile


## La distance de chaque case à la lave, en pas de case (8 voisins), jusqu'à REACH_TILES.
func _measure() -> void:
	if _size == Vector2i.ZERO:
		for c: Vector2i in _cells:
			_size = Vector2i(maxi(_size.x, c.x + 1), maxi(_size.y, c.y + 1))
	_distance.resize(_size.x * _size.y)
	_distance.fill(REACH_TILES + 1.0)
	var front: Array[Vector2i] = []
	for c: Vector2i in _cells:
		if c.x >= 0 and c.y >= 0 and c.x < _size.x and c.y < _size.y:
			_distance[c.y * _size.x + c.x] = 0.0
			front.append(c)
	var i := 0
	while i < front.size():
		var c := front[i]
		i += 1
		var here := _distance[c.y * _size.x + c.x]
		if here >= REACH_TILES:
			continue
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n := c + Vector2i(dx, dy)
				var step := 1.41 if dx != 0 and dy != 0 else 1.0
				if n.x < 0 or n.y < 0 or n.x >= _size.x or n.y >= _size.y or (dx == 0 and dy == 0):
					continue
				if _distance[n.y * _size.x + n.x] > here + step:
					_distance[n.y * _size.x + n.x] = here + step
					front.append(n)


## Un mur sur ces cases : les cases voisines d'une rangée en un rectangle, prolongé vers le bas tant
## que la rangée suivante a le même (comme Region._add_cliffs).
func _add_body(cells: Dictionary, layer: int, body_name: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = layer
	body.collision_mask = 0
	add_child(body)
	for rect: Rect2i in runs(cells):
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(rect.size) * _tile
		shape.shape = box
		shape.position = (Vector2(rect.position) + Vector2(rect.size) * 0.5) * _tile
		body.add_child(shape)
	return body


## Les cases en rectangles : des bandes horizontales, fondues avec celles du dessous de même largeur.
static func runs(cells: Dictionary) -> Array[Rect2i]:
	var rows := {}   # y -> [x…] triés
	for c: Vector2i in cells:
		if not rows.has(c.y):
			rows[c.y] = []
		rows[c.y].append(c.x)
	var ys := rows.keys()
	ys.sort()
	var open := {}   # Vector2i(x0, x1) -> Rect2i en cours
	var out: Array[Rect2i] = []
	var last_y := -1000000
	for y: int in ys:
		var xs: Array = rows[y]
		xs.sort()
		var here := {}
		var start: int = xs[0]
		for k in range(1, xs.size() + 1):
			if k < xs.size() and xs[k] == xs[k - 1] + 1:
				continue
			here[Vector2i(start, xs[k - 1])] = true
			if k < xs.size():
				start = xs[k]
		for span: Vector2i in open.keys():
			if not here.has(span) or y != last_y + 1:
				out.append(open[span])
				open.erase(span)
		for span: Vector2i in here:
			if open.has(span):
				var r: Rect2i = open[span]
				open[span] = Rect2i(r.position, Vector2i(r.size.x, r.size.y + 1))
			else:
				open[span] = Rect2i(span.x, y, span.y - span.x + 1, 1)
		last_y = y
	for span: Vector2i in open:
		out.append(open[span])
	return out


## Le drapeau du chemin du cratère : la lave se retire, le mur disparaît.
func _on_flag(id: StringName, value: Variant) -> void:
	if id != _retreat_flag or not value or _retreat_body == null:
		return
	_retreat_body.queue_free()
	_retreat_body = null
	Game.flag_changed.disconnect(_on_flag)
