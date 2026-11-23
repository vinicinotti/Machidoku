shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene : hint_screen_texture,repeat_disable,filter_linear_mipmap;
uniform float progress;
uniform float dim;
uniform float saturation;
uniform float navy_tint;
uniform float blur_lod;
uniform vec4 navy : source_color;
void fragment() {
    vec3 sharp = textureLod(scene,SCREEN_UV,0.0).rgb;
    vec3 blurred = textureLod(scene,SCREEN_UV,blur_lod).rgb;
    float gray = dot(blurred,vec3(0.2126,0.7152,0.0722));
    vec3 muted = mix(vec3(gray),blurred,saturation);
    vec3 processed = mix(muted,navy.rgb,navy_tint)*(1.0-dim);
    COLOR = vec4(mix(sharp,processed,progress),1.0);
}
