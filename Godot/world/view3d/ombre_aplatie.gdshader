// Ombres aplaties des décors posés en images (arbres, buissons, rochers, clôtures, herbes, barques…),
// une instance par paquet de décors : le MÊME MultiMesh que leurs images (WorldView._add_multimesh),
// donc les mêmes places, retournés, tailles, secousses (un arbre fouillé) et soulevés (une pierre
// retournée) ; le même vent que billboard.gdshader, et le même écart quand Chloé passe.
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

#include "res://world/view3d/ombre_aplatie.gdshaderinc"

uniform sampler2D tex : filter_linear_mipmap, repeat_disable;
// Comme l'image (billboard.gdshader) :
uniform float stretch = 1.15;
uniform float sway = 0.0;
uniform float push = 0.0;
uniform float push_radius = 0.9;
uniform float stiffness = 2.0;
// Le haut de l'image au-dessus de son pied, et un pixel de l'image (m, à la taille 1).
uniform float top_m = 1.0;
uniform float texel_m = 0.01;
// Sa base dessinée : x à côté du point au sol (0 : au droit de lui), y sa dernière ligne opaque
// au-dessus de lui (FlatShadows.picture_bottom ; m, à la taille 1, négatif : en dessous).
uniform vec2 base = vec2(0.0);
global uniform vec3 player_world;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	if (INSTANCE_CUSTOM.x > 0.5) {
		UV.x = 1.0 - UV.x;
	}
	float size = INSTANCE_CUSTOM.y;
	vec2 v = VERTEX.xy * size;
	v.y *= stretch;
	// Le vent et Chloé qui passe, comme l'image : le haut de l'ombre bouge avec le haut de l'image.
	// (L'image n'a que 4 sommets : entre le bas, fixe, et le haut, elle penche en ligne droite.
	// L'ombre a ses rangées : elle suit cette même ligne, pas la courbe de `stiffness`.)
	float top = clamp(1.0 - UV.y, 0.0, 1.0);
	float s = sin(TIME * 1.3 + origin.x * 0.62 + origin.z * 0.34) * sway
		+ sin(TIME * 3.5 + origin.x * 2.4) * sway * 0.25;
	vec2 d = origin.xz - player_world.xz;
	float near = 1.0 - smoothstep(0.0, push_radius, length(d));
	v.x += (s + (d.x >= 0.0 ? 1.0 : -1.0) * near * push) * top;
	v.x += INSTANCE_CUSTOM.z * sin(TIME * 42.0) * 0.16 * (0.3 + top);
	v.y += INSTANCE_CUSTOM.w;
	// Hauteurs comptées depuis sa base dessinée (b), qui touche le sol là où on la voit (anchor).
	vec2 b = vec2(base.x * size * (INSTANCE_CUSTOM.x > 0.5 ? -1.0 : 1.0), base.y * size * stretch);
	float height = top_m * size * stretch + INSTANCE_CUSTOM.w - b.y;
	vec2 cam_right = normalize(MAIN_CAM_INV_VIEW_MATRIX[0].xz);
	vec3 cam = MAIN_CAM_INV_VIEW_MATRIX[3].xyz;
	vec2 anchor = flat_anchor(origin + vec3(cam_right.x * b.x, b.y, cam_right.y * b.x), origin.y, cam);

	// Couchée au sol : la largeur le long de `across`, la hauteur le long de `sv`.
	vec2 sv = flat_length(height);
	vec2 across = flat_across(cam_right, sv);
	vec2 g = anchor + across * (v.x - b.x) + sv * (v.y - b.y);
	float follow = flat_on_ground(origin);
	float y = flat_plane(origin, g, follow);

	v_along = clamp((v.y - b.y) / max(height, 0.01), 0.0, 1.0);
	v_blur = flat_blur(v_along, 0.0);
	v_fade = 1.0;
	v_ground_xz = g;
	v_plane = y;
	v_follow = follow;
	vec2 px = vec2(textureSize(tex, 0));
	v_uv_per_m = vec2(1.0) / (px * texel_m * size * vec2(1.0, stretch));
	VERTEX = flat_view(VIEW_MATRIX, vec3(g.x, y, g.y), flat_pull(FLAT_PULL, g));
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}

void fragment() {
	vec2 px = vec2(textureSize(tex, 0));
	float lod = flat_lod(v_blur, v_uv_per_m, px, 5.0);
	float silhouette = flat_soft_alpha(tex, UV, v_blur * v_uv_per_m * 0.5, lod, vec4(0.0, 0.0, 1.0, 1.0));
	float above = v_follow > 0.5 ? v_plane - FLAT_BIAS - flat_floor(v_ground_xz) : 0.0;
	float a = flat_alpha(silhouette, v_along, v_fade, above) * flat_far(VERTEX);
	if (a < 0.003) {
		discard;
	}
	ALBEDO = flat_darken(a);
	ALPHA = a;
}
