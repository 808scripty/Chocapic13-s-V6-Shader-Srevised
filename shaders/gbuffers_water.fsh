#version 400 compatibility
/*
!! DO NOT REMOVE !!
This code is from Chocapic13' shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/

	const float shadowMapResolution = 1024;		//shadowmap resolution
	
	

#define SHADOW_MAP_BIAS 0.8
in vec4 color;
in vec2 texcoord;
in vec2 lmcoord;
in vec4 ambientNdotL;
in vec4 sunlightMat;

in vec3 binormal;
in vec3 normal;
in vec3 tangent;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;


uniform sampler2D texture;
uniform sampler2DShadow shadow;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 cameraPosition;
uniform vec3 upPosition;
uniform int fogMode;
uniform int worldTime;
uniform float wetness;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform int heldBlockLightValue;


vec3 sunlight = sunlightMat.rgb;
float mat = sunlightMat.a;


float waterH(vec3 worldPos,float time) {

	float waveSpeed = 0.6;

float wave = 0.0;



const float amplitude = 0.2;

vec4 waveXYZW = vec4(worldPos.xz,worldPos.xz)/vec4(250.,50.,-250.,-150.)+vec4(50.,250.,50.,-250.);
vec2 fpxy = abs(fract(waveXYZW.xy*20.0)-0.5)*2.0;

float d = amplitude*length(fpxy);

wave = cos(waveXYZW.x*waveXYZW.y+time) + 0.5 * cos(2.0*waveXYZW.x*waveXYZW.y+time) + 0.25 * cos(4.0*waveXYZW.x*waveXYZW.y+time);

	return (d*wave + d*(cos(waveXYZW.z*waveXYZW.w+time) + 0.5 * cos(2.0*waveXYZW.z*waveXYZW.w+time) + 0.25 * cos(4.0*waveXYZW.z*waveXYZW.w+time)));

}
/*
float waterH(vec3 posxz,float time) {

float wave = 0.0;



const float amplitude = 0.2;

vec4 waveXYZW = vec4(posxz.xz,posxz.xz)/vec4(250.,50.,-250.,-150.)+vec4(50.,250.,50.,-250.);
vec2 fpxy = abs(fract(waveXYZW.xy*20.0)-0.5)*2.0;

float d = amplitude*length(fpxy);

wave = cos(waveXYZW.x*waveXYZW.y+time) + 0.5 * cos(2.0*waveXYZW.x*waveXYZW.y+time) + 0.25 * cos(4.0*waveXYZW.x*waveXYZW.y+time);

return d*wave + d*(cos(waveXYZW.z*waveXYZW.w+time) + 0.5 * cos(2.0*waveXYZW.z*waveXYZW.w+time) + 0.25 * cos(4.0*waveXYZW.z*waveXYZW.w+time));

}
*/

vec4 encode (vec3 n,float dif)
{
    float p = sqrt(n.z*8+8);
	
	float vis = lmcoord.t;
	if (ambientNdotL.a > 0.9) vis = vis / 4.0;
	if (ambientNdotL.a > 0.4 && ambientNdotL.a < 0.6) vis = vis/4.0+0.25;
	if (ambientNdotL.a < 0.1) vis = vis/4.0+0.5;
		
	
    return vec4(n.xy/p + 0.5,vis,1.0);
}


//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {

	float iswater = ambientNdotL.a;
	float diffuse = dot(normalize(sunPosition),normal);
	diffuse = (worldTime > 12700 && worldTime < 23250)? -diffuse : diffuse;
		



	
	vec4 albedo = texture2D(texture, texcoord.xy)*color;
	albedo.rgb = pow(albedo.rgb,vec3(2.2));
	if (iswater > 0.9) albedo.rgb = mix(albedo.rgb,vec3(0.35,0.67,0.72),0.8);
	vec3 colorrgb = albedo.rgb;
	
	vec4 fragposition = gbufferProjectionInverse*(vec4(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z,1.0)*2.0-1.0);
	fragposition /= fragposition.w;
	

	
	vec4 worldposition = gbufferModelViewInverse * fragposition;
	vec3 wpos = worldposition.xyz;


	worldposition = shadowModelView * worldposition;
	worldposition = shadowProjection * worldposition;
	worldposition /= worldposition.w;
	vec2 pos = abs(worldposition.xy * 1.25);
	float distb = pow(pow(pos.x, 12.) + pow(pos.y, 12.), 1.0 / 12.0);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
	worldposition.xy /= distortFactor*0.85; 


	
	float shading = 1.0;
	if (max(abs(worldposition.x),abs(worldposition.y)) < 0.99) {
			float diffthresh = mix(0.0004,distortFactor*distortFactor*(0.008*tan(acos(max(diffuse,0.0))) + 0.001)*0.24,mix(albedo.a,0.35,max(iswater*2.0-1.0,0.0)));
			diffuse = max(diffuse,0.0);
			
			const float halfres = (0.25/shadowMapResolution);
			float offset = halfres;
			
			worldposition = worldposition * vec4(0.5,0.5,0.2,0.5) + vec4(0.5,0.5,0.5-diffthresh,0.5);
			shading = dot(vec4(shadow2D(shadow,vec3(worldposition.st + vec2(offset,offset), worldposition.z)).x,shadow2D(shadow,vec3(worldposition.st + vec2(-offset,offset), worldposition.z)).x,shadow2D(shadow,vec3(worldposition.st + vec2(offset,-offset), worldposition.z)).x,shadow2D(shadow,vec3(worldposition.st + vec2(-offset,-offset), worldposition.z)).x),vec4(0.25));

			diffuse = shading*diffuse;
	}
	


	vec3 sunlight = (1.0-iswater)*sunlight*diffuse;
	
	vec4 frag2 = vec4((normal), 1.0f);
	
	if (iswater > 0.45) {

			vec3 posxz = wpos+cameraPosition;
			float ft = iswater > 0.9? frameTimeCounter*4.0:0.0;
			
			posxz.x += sin(posxz.z+ft)*0.25;
			posxz.z += cos(posxz.x+ft*0.5)*0.25;
			posxz.xz += sin(-posxz.y);
			
			const float deltaPos = 0.4;
			float h0 = waterH(posxz,ft);
			float h1 = waterH(posxz - vec3(deltaPos,0.0,0.0),ft);
			float h2 = waterH(posxz - vec3(0.0,0.0,deltaPos),ft);
			
			vec2 dXY = h0-vec2(h1,h2);
			
			
			vec3 bump = normalize(vec3(dXY/deltaPos,1.0));
			
		
		float bumpmult = 0.06*clamp(iswater*2.0-1.0,0.0,1.0);	
		
		bump = bump * bumpmult + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);
		
		frag2 = vec4(bump * tbnMatrix, 1.0);
}

		

	vec3 fColor = colorrgb*(sunlight*2.15+ambientNdotL.rgb*1.4)*0.63;

	
	
	float alpha = mix(albedo.a,0.11,max(iswater*2.0-1.0,0.0));

/* DRAWBUFFERS:02 */
	gl_FragData[0] = vec4(fColor,alpha);
	gl_FragData[1] = encode(frag2.rgb,diffuse);

}