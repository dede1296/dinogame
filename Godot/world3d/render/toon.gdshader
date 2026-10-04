// Ambrelune's cartoon shading for the 3D models (docs/migration-3d.md, phase 4), whatever their
// source (Quaternius, low-poly...): set up by world3d/render/toon_style.gd from the imported
// materials, not by hand.
// - The base colour and texture of the model are kept (and its vertex colours if it used them).
// - The sun lights it in three soft steps (lit, half-lit, shade) instead of a smooth gradient,
//   like the painted shading of the 2.5D's pictures; its cast shadows fall into the shade step.
// - The shade stays warm: a little of the sun's colour fills it (a bounce), over the sky's ambient.
// - A thin rim of light on the edges turned to the sun.
// - No shine, no reflections (nor the grey sheen of a metallic material).
// Variants (#define added by toon_style.gd just after shader_type): TOON_ALPHA_SCISSOR (cut-out leaves),
// TOON_ALPHA_BLEND (see-through), TOON_CULL_DISABLED (two-sided), TOON_CULL_FRONT.
// Fading out (Chloé near the camera: GeometryInstance3D.transparency): the Mobile renderer ignores
// `transparency`, so toon_style.gd passes it as `toon_fade` and, with `dither_fade`, the model is
// dithered away (a 4×4 pattern, as the 2.5D's see-through trees), in the camera's view only (its
// shadow stays whole). Under Forward+ the engine fades it itself: it never writes ALPHA when opaque,
// and the engine starts ALPHA at 1 - transparency.
shader_type spatial;

#if defined(TOON_CULL_DISABLED)
render_mode cull_disabled, specular_disabled;
#elif defined(TOON_CULL_FRONT)
render_mode cull_front, specular_disabled;
#else
render_mode cull_back, specular_disabled;
#endif

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_vertex_color = false;
uniform bool vertex_color_is_srgb = false;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.5;

// 1: the full cartoon steps; 0: plain smooth (Lambert) lighting.
uniform float toon_strength : hint_range(0.0, 1.0) = 1.0;
// Where the steps fall, on dot(normal, sun): shade below `shade_edge`, lit above `lit_edge`
// (the sun ~48° high: tops and the sides turned to it lit, the sides at an angle half-lit).
uniform float shade_edge : hint_range(-1.0, 1.0) = 0.05;
uniform float lit_edge : hint_range(-1.0, 1.0) = 0.55;
// How bright the half-lit and lit steps are (the shade is 0, before the ambient and the bounce).
uniform float mid_level : hint_range(0.0, 1.0) = 0.58;
uniform float lit_level : hint_range(0.0, 1.5) = 0.9;
// Width of the blend between two steps (soft, painted; 0 would be a hard cel edge).
uniform float softness : hint_range(0.0, 0.3) = 0.08;
// The 2.5D's pictures are bright and saturated: a touch more colour than the imported one.
uniform float saturation : hint_range(0.0, 2.0) = 1.12;
// The warm bounce in the shade: its colour and how much of the sun it takes.
uniform vec4 shade_tint : source_color = vec4(1.0, 0.72, 0.52, 1.0);
uniform float shade_fill : hint_range(0.0, 1.0) = 0.16;
// The rim of light: strength and width (share of the edge, seen from the camera).
uniform float rim_strength : hint_range(0.0, 2.0) = 0.35;
uniform float rim_width : hint_range(0.0, 1.0) = 0.28;
uniform bool dither_fade = true;
instance uniform float toon_fade = 0.0;

varying flat float v_dither;

// 4×4 ordered dither threshold, 0..1 (the same as outline.gdshader's)
float bayer2(vec2 a) {
	a = floor(a);
	return fract(a.x * 0.5 + a.y * a.y * 0.75);
}

float bayer4(vec2 a) {
	return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	if (use_vertex_color && vertex_color_is_srgb) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	// dithered only as the camera sees it, not in a light's shadow pass
	bool camera_view = distance(INV_VIEW_MATRIX[3].xyz, MAIN_CAM_INV_VIEW_MATRIX[3].xyz) < 0.01;
	v_dither = dither_fade && camera_view ? toon_fade : 0.0;
}

void fragment() {
	if (v_dither > 0.0 && bayer4(FRAGCOORD.xy) < v_dither) {
		discard;
	}
	vec4 base = albedo * texture(albedo_texture, UV);
	if (use_vertex_color) {
		base *= COLOR;
	}
	float luma = dot(base.rgb, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = clamp(mix(vec3(luma), base.rgb, saturation), 0.0, 1.0);
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
#if defined(TOON_ALPHA_SCISSOR)
	ALPHA *= base.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
#elif defined(TOON_ALPHA_BLEND)
	ALPHA *= base.a;
#endif
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// three steps: 0 (shade), mid_level, 1 (lit), with soft edges
	float to_mid = smoothstep(shade_edge - softness, shade_edge + softness, ndl);
	float to_lit = smoothstep(lit_edge - softness, lit_edge + softness, ndl);
	float steps = to_mid * mid_level + to_lit * (lit_level - mid_level);
	float lit = mix(clamp(ndl, 0.0, 1.0), steps, toon_strength);
	// the sun's cast shadows: a crisper edge, into the shade step (point lights keep their falloff)
	float shadow = ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		shadow = mix(ATTENUATION, smoothstep(0.2, 0.8, ATTENUATION), toon_strength);
	}
	lit *= shadow;
	vec3 colour = LIGHT_COLOR / PI;
	// a thin rim of light on the edges turned to the light, out of the shadows
	float edge = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = smoothstep(1.0 - rim_width, 1.0 - rim_width + 0.1, edge) * smoothstep(-0.1, 0.35, ndl) * shadow;
	float unlit = 1.0 - clamp(lit / max(lit_level, 1e-3), 0.0, 1.0);
	DIFFUSE_LIGHT += colour * (lit + rim * rim_strength + unlit * shade_fill * shade_tint.rgb);
}
