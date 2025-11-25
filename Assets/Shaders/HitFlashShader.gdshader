shader_type canvas_item;

// Controls the intensity of the white flash (0.0 = no flash, 1.0 = full white)
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;

// Original tint color (optional, can be combined with flash)
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	// Apply tint
	vec3 tinted = tex.rgb * tint_color.rgb;
	
	// Blend white flash over the tinted color
	// Higher flash_intensity = whiter the result
	vec3 flashed = mix(tinted, vec3(1.0), flash_intensity);
	
	// Preserve alpha
	float out_a = tex.a * tint_color.a;
	
	COLOR = vec4(flashed, out_a);
}
