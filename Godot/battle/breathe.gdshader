// Battle fighters breathe: drawn with few pictures, they would stand frozen between two
// frames. The picture swells and settles around its feet (the sprite's origin), at the same
// rhythm as in the exploration (world/view3d/sprite_motion.gd). In the vertex stage, so it
// adds to every tween of the battle (lunges, shakes, the collar drawing it in).
shader_type canvas_item;

uniform float amount = 0.012;   // share of the height
uniform float period = 2.6;     // one breath (s)
uniform float phase = 0.0;      // the two fighters do not breathe together

void vertex() {
	float b = sin(TAU * TIME / period + phase) * amount;
	VERTEX.y *= 1.0 + b;
	VERTEX.x *= 1.0 - b * 0.4;
}
