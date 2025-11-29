shader_type canvas_item;
render_mode unshaded;

uniform float time_mult = 5.0;

void fragment(){
	vec4 color = texture(TEXTURE, UV);
	vec4 alpha_color = vec4(1.0, 0.0, 1.0, 1.0);

	if ((cos(TIME * time_mult) + UV.x) < 10.0) {
		//color.g = cos(TIME * time_mult) + UV.x;
		color.r = cos(TIME * time_mult);
		color.b = sin(TIME*time_mult) + UV.x + .1;
	}


	if (color == alpha_color) {
		COLOR.a = 0.0;
	}
	COLOR = color;
}
