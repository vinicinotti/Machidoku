shader_type canvas_item;
uniform vec4 ink : source_color = vec4(0.1, 0.25, 0.35, 1.0);
uniform bool revealed = false;
void fragment() {
    vec4 portrait = texture(TEXTURE, UV);
    float lighting = 0.75 + dot(portrait.rgb, vec3(0.299,0.587,0.114)) * 0.35;
    COLOR = revealed ? portrait : vec4(ink.rgb * lighting, portrait.a * 0.80);
}
