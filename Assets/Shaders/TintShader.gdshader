shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec3 out_rgb;
    out_rgb = tex.rgb * tint_color.rgb;
    float out_a = tex.a * tint_color.a;
    COLOR = vec4(out_rgb, out_a);
}
