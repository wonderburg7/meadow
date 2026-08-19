shader_type canvas_item;

// Fog-of-war mask shader. AUDIT_PLAN.md Bundle F: replaces the old
// per-tile draw_rect run-merging in fog_of_war.gd with a single textured
// quad. fog_of_war.gd writes one byte per visible tile into mask_tex each
// dirty frame (0 = unexplored, ~half = explored/unlit, full = lit) and
// issues one draw_texture_rect call; this shader turns that single-channel
// mask back into the same two-colour, three-state fog picture the old
// draw_rect version drew, entirely on the GPU.

uniform sampler2D mask_tex : filter_nearest, repeat_disable;
uniform bool permanent_reveal = false;
// The old draw_rect version's UNEXPLORED_COLOR/EXPLORED_DIM_COLOR both used
// this same RGB (18, 11, 15) and only differed by alpha -- see the state
// bands below, which reproduce that.
uniform vec3 fog_rgb = vec3(0.0706, 0.0431, 0.0588);

void fragment() {
	float state = texture(mask_tex, UV).r;
	float a;
	if (state < 0.25) {
		a = 1.0; // unexplored -- fully opaque
	} else if (state < 0.75) {
		a = permanent_reveal ? 0.0 : (140.0 / 255.0); // explored, not lit
	} else {
		a = 0.0; // lit right now
	}
	COLOR = vec4(fog_rgb, a);
}
