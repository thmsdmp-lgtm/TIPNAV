shader_type spatial;
// unshaded: flat color, ignores lights and shadows
// cull_disabled: visible from both sides
render_mode unshaded, cull_disabled;

uniform vec4 edge_color : source_color = vec4(0.52, 0.61, 0.96, 1.0);
uniform vec4 core_color : source_color = vec4(0.24, 0.36, 0.90, 1.0);
uniform float core_size : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	// UV.x goes 0..1 across the path. Turn it into distance from the center:
	// 0 in the middle, 1 at either edge
	float d = abs(UV.x - 0.5) * 2.0;

	// About one pixel of blending, so the stripe isn't jagged
	float aa = fwidth(d);

	// 0 = core color, 1 = edge color
	float blend = smoothstep(core_size - aa, core_size + aa, d);

	ALBEDO = mix(core_color.rgb, edge_color.rgb, blend);
}