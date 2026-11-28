shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 dot_color : source_color = vec4(0.24, 0.36, 0.90, 1.0);
uniform vec4 ring_color : source_color = vec4(1.0);
uniform float dot_size : hint_range(0.0, 1.0) = 0.75; // the rest is the ring

void fragment() {
	// 0 at the center, 1 at the edge of the circle
	float d = length(UV - vec2(0.5)) * 2.0;
	float aa = fwidth(d); // smooth edges

	float ring = smoothstep(dot_size - aa, dot_size + aa, d);
	ALBEDO = mix(dot_color.rgb, ring_color.rgb, ring);

	// Hide the quad's corners
	ALPHA = 1.0 - smoothstep(1.0 - aa, 1.0, d);
}