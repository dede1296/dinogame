// A soft dark patch on the ground under what stands there (trees, rocks, Chloé, dinos):
// the ambient light is blocked near the foot, whatever the sun does. Flat, never lit.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float strength = 0.38;

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	ALBEDO = vec3(0.05, 0.04, 0.03);
	ALPHA = strength * (1.0 - smoothstep(0.15, 1.0, r));
}
