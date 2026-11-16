shader_type canvas_item;
render_mode unshaded;
uniform float clock=0.0;
uniform float strength=1.0;
float box(vec2 p,vec4 r){
 vec2 a=smoothstep(r.xy,r.xy+vec2(.003),p);
 vec2 b=1.0-smoothstep(r.xy+r.zw-vec2(.003),r.xy+r.zw,p);
 return a.x*a.y*b.x*b.y;
}
vec3 fall_uv(vec2 p,vec4 r,vec3 original){
 float m=box(p,r)*smoothstep(.28,.65,min(original.g,original.b))*strength;
 vec2 q=p;
 if(m>.001){q.y=r.y+fract((p.y-r.y)/r.w-clock*.22)*r.w;}
 return vec3(q,m);
}
void fragment(){
 vec2 p=UV;vec4 source=texture(TEXTURE,p);vec3 color=source.rgb;
 vec3 f=fall_uv(p,vec4(.394,.221,.017,.085),source.rgb);
 if(f.z>.001){color=mix(color,texture(TEXTURE,f.xy).rgb,f.z*.5);}
 f=fall_uv(p,vec4(.430,.250,.018,.092),source.rgb);
 if(f.z>.001){color=mix(color,texture(TEXTURE,f.xy).rgb,f.z*.5);}
 f=fall_uv(p,vec4(.503,.304,.021,.122),source.rgb);
 if(f.z>.001){color=mix(color,texture(TEXTURE,f.xy).rgb,f.z*.5);}
 float paper=(box(p,vec4(.380,.438,.027,.105))+box(p,vec4(.318,.468,.022,.066)))*smoothstep(.12,.4,source.r-source.b*.6)*strength;
 if(paper>.001){vec2 q=p;q.x+=sin(clock*1.7+p.y*30.)*.0012*paper;color=mix(color,texture(TEXTURE,q).rgb,paper*.65);}
 float river=box(p,vec4(.425,.785,.175,.105))*strength;
 if(river>.001){vec2 q=p;q.x+=sin(p.y*190.+clock*1.1)*.0012*river;color=mix(color,texture(TEXTURE,q).rgb,river*.6);}
 float cloud=box(p,vec4(.57,.08,.27,.21))*smoothstep(.25,.65,min(source.g,source.b))*strength;
 if(cloud>.001){vec2 q=p;q.x+=sin(clock*.12)*.002*cloud;color=mix(color,texture(TEXTURE,q).rgb,cloud*.5);}
 float moon=1.-smoothstep(.085,.11,length((p-vec2(.345,.09))*vec2(1.,.5625)));
 color*=1.+moon*sin(clock*.24)*.004*strength;
 COLOR=vec4(color,source.a);
}
