class_name Ropes
extends RefCounted
## Les cordes des ponts de lianes (11/10, retour de Greg : « aux nids géants, aucune corde ne relie les
## piquets ») : le garde-corps qui court d'un poteau à l'autre, de chaque côté du tablier.
##
## Déclarées dans la zone : un nœud `Cordes` (enfant de la racine de la zone) dont la métadonnée
## `paires` liste les poteaux à relier, par leur nom dans Entities : [["PilierPont1", "PilierPont3"], …]
## (les générateurs des Cieux l'écrivent : tools/zones/cieux_decor.gd bridge_posts, ropes). Un poteau
## déplacé dans l'éditeur emporte sa corde ; une paire dont un poteau manque n'est pas dessinée.
##
## Dessinées par la vue (WorldView.show_zone) : UN maillage pour toute la zone, des rubans tournés vers
## la caméra (corde.gdshader : torsade peinte, contour brun, éclairée comme un cylindre), chaque corde
## tendue entre les deux poteaux à la hauteur où leur image dessine sa corde (ATTACH : ~1 m au-dessus
## du tablier), avec un affaissement en chaînette (SAG de la distance). Ses bouts passent derrière
## l'image du poteau (on la voit nouée, sans clignotement). Aucune collision (rien en 2D) : le pont
## reste praticable. Son ombre aplatie, fine (ombre_corde.gdshader, FlatShadows), quand la qualité
## en a ; en Basse, les cordes restent, sans ombre.

const NODE := "Cordes"
const META := &"paires"
## L'affaissement au milieu : cette part de la distance entre les deux poteaux.
const SAG := 0.08
## Plus longue qu'un écart de poteaux (3 m), plus courte que ça : sinon une erreur de déclaration.
const MAX_SPAN := 7.0
## Des points le long de chaque corde : tant par mètre, jamais moins de MIN_POINTS.
const POINTS_PER_M := 4.0
const MIN_POINTS := 9
## Où l'image d'un poteau dessine sa corde : part de sa hauteur depuis le haut de l'image.
const ATTACH := {"pilier_pont_1": 0.306, "pilier_pont_2": 0.27, "pieu_corde": 0.36, "poteau_lianes": 0.36}
const ATTACH_DEFAULT := 0.3
## Les bouts noués : sur tant de mètres depuis chaque poteau, la corde passe derrière son image.
const TIE_REACH := 0.45
const TIE_FADE := 0.25
## Les images debout sont étirées d'autant (WorldView.STRETCH, billboard.gdshader).
const STRETCH := 1.15
const ROPE_SHADER := preload("res://world/view3d/corde.gdshader")
const SHADOW_SHADER := "res://world/view3d/ombre_corde.gdshader"
## Le genre des ombres (shadow_kinds.gd).
const SHADOW_KIND := "corde_pont"


## Les paires déclarées dans `region` (noms de nœuds d'Entities), telles quelles ; [] sans `Cordes`.
static func pairs(region: Node) -> Array:
	var holder := region.get_node_or_null(NODE)
	if holder == null:
		return []
	return holder.get_meta(META, [])


## Les deux poteaux d'une paire déclarée (un Array ou un PackedStringArray : l'inspecteur de l'éditeur
## écrit l'un ou l'autre), null pour un nom qui ne désigne pas un décor de la zone.
static func posts(region: Node, pair: Variant) -> Array:
	var entities := region.get_node_or_null("Entities")
	var out: Array = []
	for name_: Variant in pair:
		var n: Node = entities.get_node_or_null(NodePath(String(name_))) if entities and name_ != null else null
		out.append(n if n is Prop else null)
	return out


## Le point (3D, m) où la corde est nouée au poteau `post` : au droit de son point au sol, posé comme
## la vue pose son image (`hm` : le relief de la zone), à la hauteur où l'image dessine sa corde.
static func tie_point(hm: HeightMap, post: Prop) -> Vector3:
	var at := hm.to_3d(post.position)
	var def: Dictionary = Prop.KINDS.get(post.kind, {})
	var tex: Texture2D = load(Prop.ART % post.kind) if def.has("scale") else null
	if tex == null:
		return at + Vector3(0.0, 1.0, 0.0)
	var h := float(tex.get_height())
	var share: float = ATTACH.get(String(post.kind), ATTACH_DEFAULT)
	var metres := float(def["scale"]) / HeightMap.PX
	return at + Vector3(0.0, (h * (1.0 - share) - h * float(def.get("foot", 0.0))) * metres * STRETCH, 0.0)


## Les cordes de `region` dans `parent` (la zone 3D de la vue) : un maillage, et son ombre aplatie
## quand `shadows` (FlatShadows de la vue) en dessine.
static func build(parent: Node3D, region: Node, hm: HeightMap, shadows: FlatShadows) -> void:
	var spans: Array = []   # [début, fin, sol au début, sol à la fin]
	for pair: Variant in pairs(region):
		var ends := posts(region, pair)
		if ends.size() != 2 or ends[0] == null or ends[1] == null:
			continue
		var a := tie_point(hm, ends[0])
		var b := tie_point(hm, ends[1])
		if a.distance_to(b) > MAX_SPAN or a.distance_to(b) < 0.1:
			continue
		spans.append([a, b, hm.to_3d((ends[0] as Prop).position).y, hm.to_3d((ends[1] as Prop).position).y])
	if spans.is_empty():
		return
	var mesh := _mesh(spans)
	var rope := MeshInstance3D.new()
	rope.name = "Cordes"
	rope.mesh = mesh
	var mat := ShaderMaterial.new()
	mat.shader = ROPE_SHADER
	rope.material_override = mat
	rope.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rope.custom_aabb = mesh.get_aabb().grow(0.5)
	parent.add_child(rope)
	var shade := ShaderMaterial.new()
	shade.shader = load(SHADOW_SHADER)
	if not shadows.dress(shade, SHADOW_KIND):
		return
	var shadow := MeshInstance3D.new()
	shadow.name = "OmbreCordes"
	shadow.mesh = mesh
	shadow.material_override = shade
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# (Elle tombe à côté de la corde, jusqu'à 2 m par mètre de hauteur : FlatShadows.K_MAX.)
	shadow.custom_aabb = mesh.get_aabb().grow(3.0)
	parent.add_child(shadow)


## Le ruban de toutes les cordes : deux sommets par point de la ligne (de part et d'autre, UV.y = ±1),
## élargis vers la caméra dans le shader. UV.x : mètres depuis le début ; UV2 : (noué 0..1, sol sous ce
## point) ; CUSTOM0 : la direction de la corde.
static func _mesh(spans: Array) -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var dirs := PackedFloat32Array()
	var index := PackedInt32Array()
	for span: Array in spans:
		var a: Vector3 = span[0]
		var b: Vector3 = span[1]
		var length := a.distance_to(b)
		var sag := SAG * length
		var count := maxi(MIN_POINTS, ceili(length * POINTS_PER_M) + 1)
		var first := verts.size()
		for i in count:
			var t := float(i) / (count - 1)
			var p := a.lerp(b, t) + Vector3(0.0, -4.0 * sag * t * (1.0 - t), 0.0)
			var dir := ((b - a) + Vector3(0.0, -4.0 * sag * (1.0 - 2.0 * t), 0.0)).normalized()
			var from_end := minf(t, 1.0 - t) * length
			var tie := 1.0 - smoothstep(TIE_REACH, TIE_REACH + TIE_FADE, from_end)
			var ground := lerpf(float(span[2]), float(span[3]), t)
			for side: float in [-1.0, 1.0]:
				verts.append(p)
				uvs.append(Vector2(t * length, side))
				uv2s.append(Vector2(tie, ground))
				dirs.append_array([dir.x, dir.y, dir.z, 0.0])
			if i > 0:
				var k := first + (i - 1) * 2
				index.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_CUSTOM0] = dirs
	arrays[Mesh.ARRAY_INDEX] = index
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {},
		Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	return mesh
