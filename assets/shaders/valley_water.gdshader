shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform float flow_time=0.0;
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float center=-42.0+sin(world_pos.z*.065)*2.6;
 float across=world_pos.x-center;
 // Both layers advect downstream, following the curved centerline.
 float along=world_pos.z-flow_time*1.55;
 float streams=noise(vec2(across*2.2,along*.48));
 float secondary=noise(vec2(across*3.7+.7,(world_pos.z-flow_time*1.9)*.8));
 float edge=smoothstep(2.1,3.3,abs(across));
 float filaments=smoothstep(.62,.78,streams)*smoothstep(.38,.67,secondary);
 float foam=smoothstep(.74,.84,streams)*(.25+.75*edge);
 vec3 water=mix(vec3(.065,.24,.23),vec3(.15,.36,.31),streams*.45+edge*.35);
 ALBEDO=water+filaments*vec3(.12,.19,.16)+foam*vec3(.21,.25,.20);
 ROUGHNESS=.4;
}
