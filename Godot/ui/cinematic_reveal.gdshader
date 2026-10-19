// A drawing that appears stroke by stroke over its blank page (docs/cinematiques.md: I-05 the map
// inked region after region, F-09 Chloé's pencil line): the layer shows where the sweep has passed,
// with a soft edge. ui/cinematic_plan.gd drives `progress` (0: nothing drawn, 1: all drawn).
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.2) = 0.0;
// 0: left to right (between span.x and span.y of the width); 1: from the rim inward to `origin` (the
// island's regions, to the volcano), starting on the side `start_angle` points to (radians, 0: right,
// PI/2: down) and going round both ways — no seam; 2: outward from `origin`.
uniform int mode = 0;
uniform vec2 span = vec2(0.0, 1.0);
uniform vec2 origin = vec2(0.5, 0.5);
uniform float start_angle = 2.4;
uniform float softness = 0.08;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float k;
	if (mode == 1 || mode == 2) {
		vec2 d = UV - origin;
		d.x *= 16.0 / 9.0;
		float r = clamp(length(d) / 0.62, 0.0, 1.0);
		float around = 0.5 - 0.5 * cos(atan(d.y, d.x) - start_angle);
		k = mode == 1 ? clamp((1.0 - r) * 0.6 + around * 0.4, 0.0, 1.0) : r;
	} else {
		k = clamp((UV.x - span.x) / max(span.y - span.x, 0.001), 0.0, 1.0);
	}
	float shown = 1.0 - smoothstep(progress - softness, progress, k);
	COLOR = vec4(c.rgb, c.a * shown);
}
