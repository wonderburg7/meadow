shader_type canvas_item;
// Sharp-bilinear sampling: pixels stay square at any zoom, with only a
// one-screen-pixel blend at each texel edge. Needs linear filtering.

varying vec4 node_modulate;

void vertex() {
	// Fragment COLOR already includes one texture sample, so carry the
	// node's modulate across from the vertex stage.
	node_modulate = COLOR;
}

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 px = UV * size;
	vec2 seam = floor(px + 0.5);
	px = seam + clamp((px - seam) / fwidth(px), -0.5, 0.5);
	COLOR = texture(TEXTURE, px / size) * node_modulate;
}
