shader_type canvas_item;
render_mode unshaded;
uniform vec2 extent = vec2(1.0);
uniform vec4 top_color : source_color;
uniform vec4 base_color : source_color;
uniform vec4 bottom_color : source_color;
uniform vec4 lip_color : source_color;
uniform float radius_ratio;
uniform float gap_ratio;
uniform float lip_ratio;
uniform float highlight_width;
uniform float highlight_alpha;
uniform float press_offset;
uniform float pressed_lip;
uniform bool pressed = false;
uniform bool glossy = false;

float rounded_box(vec2 p, vec2 half_size, float radius) {
    vec2 q = abs(p) - half_size + radius;
    return length(max(q,0.0)) + min(max(q.x,q.y),0.0) - radius;
}

void fragment() {
    vec4 tint = COLOR;
    vec2 p = UV * extent;
    vec2 gap = extent * gap_ratio;
    vec2 full_size = extent-gap;
    float radius = min(full_size.x,full_size.y)*radius_ratio;
    float depth = pressed ? pressed_lip : full_size.y*lip_ratio;
    float offset = pressed ? press_offset : 0.0;
    vec2 center = extent*0.5;
    float body_d = rounded_box(p-center-vec2(0.0,(offset-depth)*0.5),vec2(full_size.x,full_size.y-depth-offset)*0.5,radius);
    float lip_d = rounded_box(p-center,full_size*0.5,radius);
    float aa = max(fwidth(body_d),0.5);
    float body = 1.0-smoothstep(-aa,aa,body_d);
    float lip = 1.0-smoothstep(-aa,aa,lip_d);
    // The center is exactly the supplied base, not an inferred midpoint.
    vec3 face = UV.y<0.5 ? mix(top_color.rgb,base_color.rgb,UV.y*2.0) : mix(base_color.rgb,bottom_color.rgb,(UV.y-0.5)*2.0);
    float highlight = (1.0-smoothstep(highlight_width,highlight_width+aa,abs(body_d+highlight_width)))*clamp(1.0-UV.y*2.0,0.0,1.0);
    face = mix(face,vec3(1.0),highlight*highlight_alpha);
    if (glossy) {
        face = mix(face,vec3(1.0),pow(max(0.0,1.0-UV.y*2.0),3.0)*highlight_alpha);
    }
    COLOR = vec4(mix(lip_color.rgb,face,body),max(lip,body))*tint;
}
