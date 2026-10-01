shader_type spatial;
render_mode cull_disabled, blend_mix;
uniform float flow_time=0.0;
varying vec3 world_pos;
varying float water_depth;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 water_depth=COLOR.r*5.0;
 float fade=smoothstep(0.0,.7,water_depth);
 VERTEX.y+=fade*(sin(world_pos.x*1.1+world_pos.z*.6-flow_time*2.1)*.035+sin(world_pos.z*1.8-flow_time*2.8)*.018);
}
void fragment(){
 float center=420.0+sin(world_pos.z*.009)*44.0+sin(world_pos.z*.021)*12.0;
 if(world_pos.x<180.0)center=-42.0+sin(world_pos.z*.065)*2.6;
 float across=world_pos.x-center;
 float river=1.0-smoothstep(19.0,24.0,abs(across));
 float along=world_pos.z-flow_time*mix(.4,1.8,river);
 float streams=noise(vec2(across*1.8,along*.5));
 float secondary=noise(vec2(world_pos.x*2.7+flow_time*.3,(world_pos.z-flow_time*1.3)*.9));
 float crests=smoothstep(.68,.85,streams)*smoothstep(.48,.75,secondary);
 float shore=(1.0-smoothstep(.1,.55,water_depth))*smoothstep(.02,.15,water_depth);
 float foam=crests*.38+shore*(.25+.25*sin(flow_time*2.0+world_pos.z*2.0));
 ALBEDO=mix(vec3(.12,.57,.68),vec3(.025,.28,.49),smoothstep(0.0,4.0,water_depth))+foam*vec3(.35,.45,.44);
 NORMAL=normalize(NORMAL+vec3(sin(world_pos.x*2.1+along*1.3)*.10,0.0,cos(along*2.4+world_pos.x)*.10));
 ROUGHNESS=.24;SPECULAR=.65;
 ALPHA=mix(.36,.79,smoothstep(0.0,3.8,water_depth))+foam*.18;
}
