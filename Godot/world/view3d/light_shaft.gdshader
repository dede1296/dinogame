// A shaft of light slanting down through the water (Underwater): a soft band, brightest near
// the top, fading at its sides and towards the floor, shimmering slowly. Light added on what is
// behind it; it always faces the camera around its own (leaning) axis. `fade` (per shaft):
// how much of it shows while it comes and goes; `phase`: its own shimmer.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(0.72, 0.94, 1.0, 1.0);
uniform float strength = 0.28;
// How much it leans (sideways, per metre down).
uniform float lean = 0.2;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
instance uniform float fade = 1.0;
instance uniform float phase = 0.0;

void vertex() {
	VERTEX.x += VERTEX.y * lean;
	// Face the camera around the vertical (as BILLBOARD_FIXED_Y), keeping the shaft's scale.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	// UV.y = 0 at the top (the surface), 1 at the foot (the floor).
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	float sides = smoothstep(0.0, 0.85, across);
	float along = smoothstep(0.0, 0.1, UV.y) * (1.0 - smoothstep(0.35, 1.0, UV.y));
	float n = texture(noise_tex, vec2(UV.x * 0.6 + phase, UV.y * 0.25 - TIME * 0.035 + phase * 0.7)).r;
	float shimmer = 0.6 + 0.4 * sin(TIME * 0.8 + phase * 6.2832 + n * 4.0);
	float a = sides * along * shimmer * (0.75 + 0.5 * n) * strength * fade;
	ALBEDO = colour.rgb;
	ALPHA = clamp(a, 0.0, 1.0);
}
