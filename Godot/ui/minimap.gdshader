shader_type canvas_item;
// The minimap's round window over its cached picture (Minimap: a SubViewport drawn now and then,
// larger than the window by a margin all round): the picture slides by Chloé's steps since it was
// drawn, and is cut to a disc with a soft edge.

uniform vec2 shift = vec2(0.0);   // in the picture's UV
uniform float inner = 1.0;        // the window's share of the picture's width
uniform float soft = 0.012;       // the disc's soft edge, in the window's UV

void fragment() {
	vec2 uv = vec2(0.5) + (UV - vec2(0.5)) * inner + shift;
	vec4 c = texture(TEXTURE, uv);
	float d = length(UV - vec2(0.5));
	c.a *= 1.0 - smoothstep(0.5 - soft, 0.5, d);
	COLOR = c;
}
