// L'ombre aplatie des cordes des ponts (Ropes) : le même maillage que les cordes, chaque point de la
// corde couché au sol à l'opposé du soleil (flat_sun : comme les ombres des images, FlatShadows), de
// tant que sa hauteur au-dessus du tablier ; un trait fin et doux. Là où elle tomberait hors du
// tablier (dans le vide, sur les nuages bien plus bas), elle s'efface (flat_alpha « above »).
// Sommets (Ropes._mesh) : VERTEX sur la ligne de la corde, UV = (mètres le long, côté ±1),
// UV2 = (noué, sol sous ce point), CUSTOM0.xyz = la direction de la corde.
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

#include "res://world/view3d/ombre_aplatie.gdshaderinc"

// Demi-largeur du trait (m) : la corde, un peu adoucie.
uniform float half_width = 0.035;
// La plus haute corde (m au-dessus du tablier) : la longueur de l'ombre est plafonnée pour elle.
uniform float top_m = 1.2;

varying float v_side;

void vertex() {
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 t = normalize((MODEL_MATRIX * vec4(CUSTOM0.xyz, 0.0)).xyz);
	float ground = UV2.y;
	float h = max(p.y - ground, 0.0);
	vec2 sv = flat_length(top_m);
	vec2 g = p.xz + sv * h;
	// En travers du trait d'ombre (la corde couchée au sol), à plat.
	vec2 line = t.xz + sv * t.y;
	vec2 across = length(line) > 0.0001 ? normalize(vec2(-line.y, line.x)) : vec2(1.0, 0.0);
	v_along = clamp(h / top_m, 0.0, 1.0);
	v_blur = flat_blur(v_along, 0.0);
	g += across * UV.y * (half_width + v_blur * 0.5);
	// Toujours posée sur le relief (le bord du tablier descend déjà vers le vide : là, elle s'efface).
	vec3 foot = vec3(p.x, ground, p.z);
	float follow = has_ground ? 1.0 : 0.0;
	float y = flat_plane(foot, g, follow);
	v_fade = 1.0;
	v_ground_xz = g;
	v_plane = y;
	v_follow = follow;
	v_side = UV.y;
	VERTEX = flat_view(VIEW_MATRIX, vec3(g.x, y, g.y), flat_pull(FLAT_PULL, g));
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}

void fragment() {
	float silhouette = 1.0 - smoothstep(0.3, 1.0, abs(v_side));
	float above = v_follow > 0.5 ? v_plane - FLAT_BIAS - flat_floor(v_ground_xz) : 0.0;
	float a = flat_alpha(silhouette, v_along, v_fade, above) * flat_far(VERTEX);
	if (a < 0.003) {
		discard;
	}
	ALBEDO = flat_darken(a);
	ALPHA = a;
}
