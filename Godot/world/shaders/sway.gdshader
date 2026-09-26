// Plants sway in the wind and lean away when Chloé walks through them.
// Only the top of the sprite moves (the base stays planted).
shader_type canvas_item;

global uniform vec2 player_position;
uniform float strength = 2.5;        // world px of sway at the top
uniform float speed = 1.3;
uniform float push_radius = 42.0;    // world px
uniform float push_strength = 9.0;   // world px at the top
uniform float stiffness = 2.0;       // higher = only the very top bends

void vertex() {
	vec2 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	float scale = max(length(MODEL_MATRIX[0].xy), 0.0001);
	float top = pow(1.0 - UV.y, stiffness);
	float sway = sin(TIME * speed + origin.x * 0.013 + origin.y * 0.007) * strength
		+ sin(TIME * speed * 2.7 + origin.x * 0.05) * strength * 0.25;
	vec2 d = origin - player_position;
	float near = 1.0 - smoothstep(0.0, push_radius, length(d));
	float push = (d.x >= 0.0 ? 1.0 : -1.0) * near * push_strength;
	VERTEX.x += (sway + push) * top / scale;
}
