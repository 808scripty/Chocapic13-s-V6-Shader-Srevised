#version 120

/*
!! DO NOT REMOVE !!
This code is from Chocapic13' shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/

	const int shadowMapResolution = 1024;		//shadowmap resolution


#define SHADOW_MAP_BIAS 0.8
varying vec4 color;

varying vec2 texcoord;
varying vec4 ambientNdotL;
varying vec4 sunlightMat;

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
uniform vec3 upPosition;
uniform int fogMode;
uniform int worldTime;
uniform float wetness;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;

uniform int heldBlockLightValue;
uniform vec4 entityColor;

vec3 sunlight = sunlightMat.rgb;
float diffuse = ambientNdotL.a;
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	vec4 albedo = texture2D(texture, texcoord.xy);
	
	if (albedo.a > 0.1){ 
	albedo *= color;
	
	vec3 sunlight = sunlightMat.rgb;
	float diffuse = ambientNdotL.a;
	
	float shading = 1.0;
	if (diffuse > 0.00001){
		vec4 fragposition = gbufferProjectionInverse*(vec4(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z,1.0)*2.0-1.0);
		vec4 worldposition = gbufferModelViewInverse * fragposition;
		

	worldposition = shadowModelView * worldposition;
	worldposition = shadowProjection * worldposition;
	worldposition /= worldposition.w;
	vec2 pos = abs(worldposition.xy * 1.25);
	float distb = pow(pow(pos.x, 12.) + pow(pos.y, 12.), 1.0 / 12.0);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;		
	worldposition.xy *=  1.0/distortFactor/0.85; 
	if (max(abs(worldposition.x),abs(worldposition.y)) < 1.0) {
			float diffthresh = distortFactor*distortFactor*(0.008*tan(acos(max(diffuse,0.0))) + 0.001)*0.225;
			const float halfres = (0.25/shadowMapResolution);
			float offset = halfres;
			
			worldposition = worldposition * vec4(0.5,0.5,0.2,0.5) + vec4(0.5,0.5,0.5-diffthresh,0.5);
			shading = dot(vec4(shadow2D(shadow,vec3(worldposition.st + vec2(offset,offset), worldposition.z)).x,shadow2D(shadow,vec3(worldposition.st + vec2(-offset,offset), worldposition.z)).x,shadow2D(shadow,vec3(worldposition.st + vec2(offset,-offset), worldposition.z)).x,shadow2D(shadow,vec3(worldposition.st + vec2(-offset,-offset), worldposition.z)).x),vec4(0.25));

	}
	}


	albedo.rgb = ((sunlight*shading)*(diffuse*2.15*0.63) + ambientNdotL.rgb*1.4*0.63)*pow(albedo.rgb,vec3(2.2));	//don't export to gamma 1/2.2 due to RGB11F format
}
	
/* DRAWBUFFERS:02 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(0.0,0.,0.,1.);
}