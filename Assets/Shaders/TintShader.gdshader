shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0,0,0,1.0);
// How much of the tint to apply. 0.0 = original texture only, 1.0 = full tint.
uniform float tint_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    // Mix the original texture color with the tint color based on tint_strength.
    // Keep the texture's alpha but allow the tint's alpha to scale it when
    // tint_strength > 0 (so setting tint alpha can dim the sprite if desired).
    vec3 mixed_rgb = mix(tex.rgb, tint_color.rgb, tint_strength);
    float mixed_a = tex.a * mix(1.0, tint_color.a, tint_strength);
    COLOR = vec4(mixed_rgb, mixed_a);
}
