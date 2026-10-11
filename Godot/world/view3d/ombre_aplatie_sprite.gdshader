// Ombres aplaties des images que la vue recopie du monde 2D (Chloé, les dinos, les PNJ, les objets
// d'une scène) : posé en « material_overlay » sur leur Sprite3D, il reçoit le même quad (l'image
// COURANTE de l'animation, retournée, décalée) et le couche sur le sol, sous les pieds (`pivot`),
// même quand l'image est en l'air (le Vol : l'ombre reste au sol, très en dessous). La taille, le
// saut de pas et la respiration (SpriteMotion) suivent : ils sont dans la transformation du nœud.
// Le gabarit (stencil) : là où une ombre de personnage est déjà posée, une autre ne la fonce pas
// (Chloé sur sa monture : une seule ombre) ; la monture passe d'abord (render_priority).
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;
stencil_mode read, write, compare_not_equal, 2;

#include "res://world/view3d/ombre_aplatie.gdshaderinc"

uniform sampler2D tex : filter_linear_mipmap, repeat_disable;
// Par image (FlatShadows.sync) : `ground` ses pieds au sol (xyz) et le haut de l'image au-dessus du
// sol (w, m) ; `uv_rect` l'image courante dans sa planche ; `look` ses pieds dessinés par rapport à
// l'origine du nœud (xy, m, retournement et taille compris), un pixel (z, m), sa hauteur en l'air
// (w, m ; négatif : pas d'ombre — elle nage, elle plonge, son ombre de contact est cachée).
instance uniform vec4 ground = vec4(0.0, 0.0, 0.0, 1.5);
instance uniform vec4 uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
instance uniform vec4 look = vec4(0.0, 0.0, 0.01, -1.0);
// En l'air, l'ombre pâlit et se floute avec la hauteur (m), comme Flight.SHADOW_DROP_M.
const vec2 LIFT_PALE = vec2(3.0, 9.0);

// Son bord le plus pâle (sous cette part de son opacité pleine) n'est pas dessiné : il marquerait
// le gabarit pour rien, et l'ombre d'à côté (Chloé sur sa monture) y serait coupée.
const float STENCIL_FROM = 0.08;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	vec3 pivot = ground.xyz;
	float top_m = ground.w;
	vec2 base_local = look.xy;
	float texel_m = look.z;
	float fade = look.w < 0.0 ? 0.0 : 1.0 - 0.6 * smoothstep(LIFT_PALE.x, LIFT_PALE.y, look.w);
	float extra_blur = max(look.w, 0.0) * 0.02;
	vec3 o = origin - pivot;          // l'image par rapport à ses pieds (en selle, en l'air, un saut…)
	vec2 cam_right = normalize(MAIN_CAM_INV_VIEW_MATRIX[0].xz);
	vec3 cam = MAIN_CAM_INV_VIEW_MATRIX[3].xyz;
	// L'ombre part de ses pieds dessinés, posés au sol (sans le saut, la selle ni le vol : ceux-là
	// décalent l'ombre, comme le soleil le veut) ; les hauteurs comptent depuis eux.
	vec3 stand = vec3(origin.x + cam_right.x * base_local.x, pivot.y + base_local.y, origin.z + cam_right.y * base_local.x);
	vec2 anchor = flat_anchor(stand, pivot.y, cam);
	float x = VERTEX.x * sx - base_local.x;
	float h = o.y + VERTEX.y * sy - base_local.y;
	float top = top_m - base_local.y;

	vec2 sv = flat_length(top);
	vec2 across = flat_across(cam_right, sv);
	vec2 g = anchor + across * x + sv * h;
	float follow = flat_on_ground(pivot);
	float y = flat_plane(pivot, g, follow);

	// (Pâle vers le haut de l'IMAGE, pas du ciel : en l'air, c'est `fade` qui la pâlit.)
	v_along = clamp((VERTEX.y * sy - base_local.y) / max(top - o.y, 0.01), 0.0, 1.0);
	v_blur = flat_blur(v_along, extra_blur);
	v_fade = fade * COLOR.a;
	v_ground_xz = g;
	v_plane = y;
	v_follow = follow;
	vec2 px = vec2(textureSize(tex, 0));
	v_uv_per_m = vec2(1.0) / (px * vec2(texel_m, texel_m * sy / max(sx, 0.0001)));
	VERTEX = flat_view(VIEW_MATRIX, vec3(g.x, y, g.y), flat_pull(FLAT_PULL_SPRITE, g));
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}

void fragment() {
	vec2 px = vec2(textureSize(tex, 0));
	// (Une planche de sprites : pas trop flou, l'image voisine y passerait.)
	float lod = flat_lod(v_blur, v_uv_per_m, px, 2.0);
	vec4 rect = uv_rect;
	if (rect.z < 0.0) {   // (retournée : le rectangle d'abord remis à l'endroit)
		rect = vec4(rect.x + rect.z, rect.y, -rect.z, rect.w);
	}
	float silhouette = flat_soft_alpha(tex, UV, v_blur * v_uv_per_m * 0.5, lod, rect);
	float above = v_follow > 0.5 ? v_plane - FLAT_BIAS - flat_floor(v_ground_xz) : 0.0;
	float a = flat_alpha(silhouette, v_along, v_fade, above) * flat_far(VERTEX);
	if (a < FLAT_FOOT_ALPHA * strength * flat_sun.z * v_fade * STENCIL_FROM || a < 0.003) {
		discard;
	}
	ALBEDO = flat_darken(a);
	ALPHA = a;
}
