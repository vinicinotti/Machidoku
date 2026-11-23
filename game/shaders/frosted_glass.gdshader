shader_type canvas_item;
render_mode unshaded;
uniform sampler2D backdrop : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec2 panel_size = vec2(250.0, 514.0);
uniform float radius = 38.0;
uniform float tint_strength : hint_range(0.0, 1.0) = 0.54;
uniform float blur_lod : hint_range(0.0, 5.0) = 2.6;

void fragment() {
    vec2 half_size = panel_size * 0.5;
    float corner = min(radius, min(half_size.x, half_size.y));
    vec2 q = abs((UV - 0.5) * panel_size) - (half_size - vec2(corner));
    float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner;
    float aa = max(fwidth(distance_to_edge), 0.6);
    float mask = 1.0 - smoothstep(-aa, aa, distance_to_edge);
    vec3 blurred = textureLod(backdrop, SCREEN_UV, blur_lod).rgb;
    vec3 cream = mix(vec3(1.0, 0.99, 0.98), vec3(1.0, 0.945, 0.895), UV.y);
    vec3 face = mix(blurred, cream, tint_strength);
    float edge = 1.0 - smoothstep(1.0, 2.8, abs(distance_to_edge + 1.4));
    face = mix(face, vec3(1.0, 0.99, 0.96), edge * mix(0.82, 0.32, UV.y));
    float rim_light = (1.0-smoothstep(1.0,8.0,abs(distance_to_edge+3.0)))*0.10;
    face = mix(face,vec3(1.0,0.99,0.96),rim_light);
    face += vec3(0.03) * pow(1.0 - UV.y, 5.0);
    COLOR = vec4(face, mask*0.97);
}
