shader_type spatial;
render_mode cull_disabled, diffuse_burley, depth_prepass_alpha;
uniform int surface_kind = 0; // curtain, plunge foam, mist
uniform vec4 water_color : source_color = vec4(0.16,0.57,0.72,1.0);
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex() {
 if(surface_kind==0) VERTEX.z += sin(UV.x*31.0+TIME*2.5)*sin(UV.y*20.0-TIME*6.0)*0.075;
}
void fragment() {
 if(surface_kind==0) {
  vec2 flow=vec2(UV.x*27.0,UV.y*9.0-TIME*2.7);
  float streak=noise(flow)+0.4*noise(flow*2.3);
  float foam=smoothstep(0.57,1.13,streak);
  ALBEDO=mix(water_color.rgb,vec3(0.87,0.97,0.98),foam);
  ROUGHNESS=0.29; SPECULAR=0.5;
  ALPHA=smoothstep(0.0,0.055,UV.x)*smoothstep(1.0,0.945,UV.x)*0.95;
 } else {
  vec2 p=(UV-0.5)*2.0;float r=length(p);
  float fleck=noise(p*7.0+vec2(TIME*.4,-TIME*.7));
  float ring=pow(max(0.0,sin(r*25.0-TIME*4.2+fleck*2.0)),8.0);
  float edge=1.0-smoothstep(.60,1.0,r);
  ALBEDO=vec3(.78,.94,.96);ROUGHNESS=.6;
  ALPHA=surface_kind==1 ? edge*(.09+ring*.20+fleck*.34) : edge*fleck*.19;
 }
}
