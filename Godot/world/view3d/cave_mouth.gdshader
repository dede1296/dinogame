// The dark opening of a cave in a rock face: an arch (round top, straight sides), black
// inside with a faint cold depth, a soft ragged edge so it reads as a hole in the rock.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque, shadows_disabled;


void fragment() {
	// UV: x 0..1 across, y 0 (top) .. 1 (ground).
	vec2 q = vec2(UV.x * 2.0 - 1.0, UV.y);
	// Arch: a half-ellipse on top of a slightly narrowing rectangle.
	float arch_top = 0.45;
	float d;
	if (q.y < arch_top) {
		vec2 e = vec2(q.x, (q.y - arch_top) / arch_top);
		d = length(e);
	} else {
		d = abs(q.x) * mix(1.0, 1.08, (q.y - arch_top) / (1.0 - arch_top));
	}
	float ragged = 0.06 * sin(UV.y * 23.0 + UV.x * 7.0) + 0.04 * sin(UV.x * 31.0);
	float inside = 1.0 - smoothstep(0.86 + ragged, 1.0 + ragged, d);
	// Deeper = darker; a hint of cold blue near the top of the opening.
	vec3 col = mix(vec3(0.02, 0.025, 0.035), vec3(0.07, 0.09, 0.12), smoothstep(0.9, 0.2, d) * (1.0 - UV.y) * 0.6);
	col = mix(vec3(0.0), col, smoothstep(0.3, 1.0, d));
	ALBEDO = col;
	ALPHA = inside;
}
