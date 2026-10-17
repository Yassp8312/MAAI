shader_type canvas_item;

// Keep the generated edge pixels within MAAI's monochrome ink palette.
void fragment() {
	float ink = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = vec3(ink);
}
