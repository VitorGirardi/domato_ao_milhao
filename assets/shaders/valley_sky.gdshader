shader_type sky;
uniform vec4 zenith:source_color=vec4(.10,.43,.78,1);
uniform vec4 horizon:source_color=vec4(.64,.82,.94,1);
uniform vec3 sun_direction=vec3(.6,.7,0);
uniform vec3 moon_direction=vec3(-.6,-.7,0);
uniform float daylight=1.0;
uniform float cloud_time=0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void sky(){
 vec3 ray=normalize(EYEDIR);
 float up=max(ray.y,0.0);
 vec3 col=mix(horizon.rgb,zenith.rgb,pow(up,.48));
 float sun_dot=dot(ray,normalize(sun_direction));
 float moon_dot=dot(ray,normalize(moon_direction));
 col+=vec3(1.0,.69,.25)*pow(max(sun_dot,0.0),100.0)*.20*daylight;
 col=mix(col,vec3(1.0,.94,.72),smoothstep(.99948,.99966,sun_dot)*daylight);
 float moon=smoothstep(.99955,.99972,moon_dot)*(1.0-daylight);
 col=mix(col,vec3(.82,.89,1.0),moon);
 vec2 star_uv=vec2(atan(ray.z,ray.x),asin(ray.y))*vec2(340.0,240.0);
 float stars=step(.996,hash(floor(star_uv)))*(1.0-smoothstep(.08,.19,length(fract(star_uv)-.5)));
 col+=vec3(.76,.84,1.0)*stars*(1.0-daylight)*smoothstep(0.0,.2,ray.y);
 if(ray.y>.015){
  vec2 p=ray.xz/(ray.y+.24)*2.4+vec2(cloud_time*.0018,cloud_time*.0007);
  float n=noise(p)*.58+noise(p*2.1)*.27+noise(p*4.3)*.15;
  float clouds=smoothstep(.52,.70,n)*smoothstep(.015,.16,ray.y);
  vec3 cloud_color=mix(vec3(.10,.15,.24),mix(vec3(.76,.85,.93),vec3(1.0,.98,.93),smoothstep(.53,.74,n)),daylight);
  col=mix(col,cloud_color,clouds*.95);
 }
 COLOR=col;
}
