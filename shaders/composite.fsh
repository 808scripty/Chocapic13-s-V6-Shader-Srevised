#version 400 compatibility

/*






!! DO NOT REMOVE !! !! DO NOT REMOVE !!

This code is from Chocapic13' shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !! !! DO NOT REMOVE !!


Sharing and modification rules

Sharing a modified version of my shaders:
-You are not allowed to claim any of the code included in "Chocapic13' shaders" as your own
-You can share a modified version of my shaders if you respect the following title scheme : " -Name of the shaderpack- (Chocapic13' Shaders edit) "
-You cannot use any monetizing links
-The rules of modification and sharing have to be same as the one here (copy paste all these rules in your post), you cannot make your own rules
-I have to be clearly credited
-You cannot use any version older than "Chocapic13' Shaders V4" as a base, however you can modify older versions for personal use
-Common sense : if you want a feature from another shaderpack or want to use a piece of code found on the web, make sure the code is open source. In doubt ask the creator.
-Common sense #2 : share your modification only if you think it adds something really useful to the shaderpack(not only 2-3 constants changed)


Special level of permission; with written permission from Chocapic13, if you think your shaderpack is an huge modification from the original (code wise, the look/performance is not taken in account):
-Allows to use monetizing links
-Allows to create your own sharing rules
-Shaderpack name can be chosen
-Listed on Chocapic13' shaders official thread
-Chocapic13 still have to be clearly credited


Using this shaderpack in a video or a picture:
-You are allowed to use this shaderpack for screenshots and videos if you give the shaderpack name in the description/message
-You are allowed to use this shaderpack in monetized videos if you respect the rule above.


Minecraft website:
-The download link must redirect to the link given in the shaderpack's official thread
-You are not allowed to add any monetizing link to the shaderpack download

If you are not sure about what you are allowed to do or not, PM Chocapic13 on http://www.minecraftforum.net/
Not respecting these rules can and will result in a request of thread/download shutdown to the host/administrator, with or without warning. Intellectual property stealing is punished by law.











*/

varying vec2 texcoord;
varying vec3 lightColor;
varying vec3 avgAmbient;
varying vec3 lightVector;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;
varying vec3 avgAmbient2;
varying vec3 sky1;
varying vec3 sky2;
varying vec3 cloudColor;


varying vec2 lightPos;
varying float tr;

varying vec3 sunlight;
varying vec3 nsunlight;

varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D gdepthtex;
uniform sampler2D gcolor;
uniform sampler2D gdepth;

uniform vec3 skyColor;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferPreviousModelView;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform int fogMode;

const vec3 moonlight = vec3(0.5, 0.9, 1.4) * 0.005;
const vec3 moonlightS = vec3(0.5, 0.9, 1.4) * 0.001;
float comp = 1.0-near/far/far;			//distance above that are considered as sky
float invRain06 = 1.0-rainStrength*0.6;


/*
vec3 calcFog(vec3 fposition, vec3 color, vec3 fogclr) {
	float density = 1.0/mix(600.0,120,rainStrength);

	float d = length(fposition);


	float fog =  pow(1.0-exp(-d*density),2.2-rainStrength*1.2);

return color*(1.0-fog*(vec3(1.0,0.3,0.1)+rainStrength*vec3(0.0,0.7,0.9))) + fog*length(avgAmbient)*normalize(fogclr)*(1.0-rainStrength*0.85);	
}
*/
float getAirDensity (float h) {
return (max((h),60.0)-40.0)/2;
}
float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

vec3 calcFog(vec3 fposition, vec3 color, vec3 fogclr,float yPosition,float d) {
	float tmult = mix(min(abs(worldTime-6000.0)/6000.0,1.0),1.0,rainStrength);
	float density = (8000.-tmult*tmult*2000.)*0.75;

	vec3 worldpos = (gbufferModelViewInverse*vec4(fposition,1.0)).rgb+cameraPosition;
	float height = mix(getAirDensity (worldpos.y),0.1,rainStrength*0.8);

	float fog =   clamp(14.0*exp(-getAirDensity (yPosition)/density) * (1.0-exp( -d*height/density ))/height-0.24+rainStrength*0.24,0.0,1.);
	vec3 fogC = fogclr*(0.7+0.3*tmult)*(2.0-rainStrength*1.0);
return mix(color,fogC*(1.0-isEyeInWater),fog);	
}

float cdist(vec2 coord) {
	vec2 vec = abs(coord*2.0-1.0);
	float d = max(vec.x,vec.y);
	return 1.0 - d*d;
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}
/*--------------------------------*/
vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float getnoise(vec2 pos) {
	return fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f);
}
float invRain07 = 1.0-rainStrength*0.6;


vec3 getSkyColor(vec3 fposition) {
/*--------------------------------*/
vec3 sVector = normalize(fposition);
/*--------------------------------*/

float cosT = dot(sVector,upVec); 
float mCosT = max(cosT,0.0)+0.03;
float absCosT = 1.0-max(cosT*0.82+0.18,0.08);
float cosS = SdotU;			
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);	
/*--------------------------------*/
const float a = -1.;
const float b = -0.25;
float c = 1.0;
const float d = -3.;
const float e = 0.45;
/*--------------------------------*/
//luminance
float L =  (1.0+a*exp(b/(mCosT)));
float A = 1.0+e*cosY*cosY;

//gradient
vec3 grad1 = mix(sky1,sky2,absCosT*absCosT);
float sunscat = max(cosY,0.0);
vec3 grad3 = mix(grad1,nsunlight,sunscat*(1.0-sqrt(mCosT))*(1.0-rainStrength*0.5) +0.01);

float Y2 = 3.14159265359-Y;	
float L2 = L * (8.0*exp(d*Y2)+A);

const vec3 moonlight2 = pow(normalize(moonlight),vec3(3.0))*length(moonlight);
const vec3 moonlightRain = normalize(vec3(0.25,0.3,0.4))*length(moonlight);
vec3 gradN = mix(moonlight,moonlight2,1.-L2/2.0);
gradN = mix(gradN,moonlightRain,rainStrength);

return (1.4*grad3*pow(L*(c*exp(d*Y)+A),invRain07)*sunVisibility*vec3(0.85,0.88,1.0) *length(avgAmbient2)+ 0.05*gradN*pow(L2*1.2+1.5,invRain07)*moonVisibility);
}



float A = 0.22;		
float B = 0.3;		
float C = 0.10;			
	float D = 0.2;		
	float E = 0.03;
	float F = 0.4;
vec3 Uncharted2Tonemap(vec3 x) {

	/*--------------------------------*/
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}
float waterH(vec3 posxz,float time) {

float wave = 0.0;



const float amplitude = 0.2;

vec4 waveXYZW = vec4(posxz.xz,posxz.xz)/vec4(250.,50.,-250.,-150.)+vec4(50.,250.,50.,-250.);
vec2 fpxy = abs(fract(waveXYZW.xy*20.0)-0.5)*2.0;

float d = amplitude*length(fpxy);

wave = cos(waveXYZW.x*waveXYZW.y+time) + 0.5 * cos(2.0*waveXYZW.x*waveXYZW.y+time) + 0.25 * cos(4.0*waveXYZW.x*waveXYZW.y+time);

return d*wave + d*(cos(waveXYZW.z*waveXYZW.w+time) + 0.5 * cos(2.0*waveXYZW.z*waveXYZW.w+time) + 0.25 * cos(4.0*waveXYZW.z*waveXYZW.w+time));

}

float subSurfaceScattering(vec3 vec,vec3 pos, float N) {

return pow(max(dot(vec,normalize(pos)),0.0),N)*(N+1)/6.28;

}
float subSurfaceScattering2(vec3 vec,vec3 pos, float N) {

return pow(max(dot(vec,normalize(pos))*0.5+0.5,0.0),N)*(N+1)/6.28;

}

	float distratio(vec2 pos, vec2 pos2) {
	
		return distance(pos*vec2(aspectRatio,1.0),pos2*vec2(aspectRatio,1.0));
	}
float smStep (float edge0,float edge1,float x) {
float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
return t * t * (3.0 - 2.0 * t); }

void LensFlare(inout vec3 color)
{

vec3 tempColor2 = vec3(0.0);
vec2 ntc2 = texcoord*2.0-1.0;

      vec2 lPos = lightPos;
      vec2 checkcoord = lPos;


         float sunstep = -4.5;
         float masksize = 0.004f;




            float sunmask = 1.0;
            sunmask *= (1.0 - rainStrength);

         if (sunmask > 0.02)
         {
         //Detect if sun is on edge of screen

            float edgemaskx = clamp(distance(lPos.x, 0.5f)*9.0f - 3.0f, 0.0f, 1.0f)*2.0;

			
			vec3 lenslc = normalize(sqrt(lightColor))*length(lightColor)*sunVisibility;
         //Adjust global flare settings
            float flaremultR = 0.8*lenslc.r;
            float flaremultG = 1.0*lenslc.g;
            float flaremultB = 1.5*lenslc.b;
            const float flarescale = 1.0;
            const float flarescaleconst = 1.0;


         //Flare gets bigger at center of screen

            //flarescale *= (1.0 - centermask);



                 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW

 //lens
 //Lens



        const float flarescale2 = 1.1;

        const float flarescale3 = 2.0;

        const float flarescale4 = 1.5;

		vec3 tempColor = vec3(0.0);

        vec3 tempColor3 = vec3(0.0);

        vec3 tempColor4 = vec3(0.0);

        vec2 resolution = vec2(viewWidth, viewHeight);

        float PI = 3.141592;

        vec2 uv = ntc2;


        float c = 0.0;
        vec2 dxy = uv - 0.5;
        c = atan(dxy.x, dxy.y) / PI;
        c = tan(c * 720.0);


        vec4 tempColor2 = vec4(c, c, c, 1.0 );

		tempColor2.r = clamp(tempColor2.r,0.7,0.9);





//(1-x)*(0.8)+0.1 = 0.8-0.8x-0.1 = 0.9-0.8x

//-------------------Red--------------------------------------------------------------------------------------

                        vec2 flare_Red_scale = vec2(aspectRatio,1.0)*vec2(0.9*flarescale2);
                        const float flare_Red_pow = 4.25;
                        const float flare_Red_fill = 10.0;
                        vec2 flare_Red_pos = flare_Red_scale - lPos*flare_Red_scale;


                        float flare_Red_ = distance(flare_Red_pos, ntc2*flare_Red_scale);
                                  flare_Red_ = 0.5 - flare_Red_;
                                  flare_Red_ = clamp(flare_Red_*flare_Red_fill, 0.0, 1.0)  ;
                                  flare_Red_ = sin(flare_Red_*1.57075);

                                  flare_Red_ = pow(flare_Red_, 1.1);

                                  flare_Red_ *= flare_Red_pow;


                                  //subtract
                                  vec2 flare_RedD_scale = vec2(aspectRatio,1.0)*vec2(0.58*flarescale2);
                                const float flare_RedD_pow = 8.0;
                                const float flare_RedD_fill = 1.4;
                                
                                vec2 flare_RedD_pos = 0.9*flare_RedD_scale - lPos*0.8*flare_RedD_scale;


                                float flare_RedD_ = distance(flare_RedD_pos, ntc2*flare_RedD_scale);
                                        flare_RedD_ = 0.5 - flare_RedD_;
                                        flare_RedD_ = clamp(flare_RedD_*flare_RedD_fill, 0.0, 1.0)  ;
                                        flare_RedD_ = sin(flare_RedD_*1.57075);
                                        flare_RedD_ = pow(flare_RedD_, 0.9);

                                        flare_RedD_ *= flare_RedD_pow;

                                flare_Red_ = clamp(flare_Red_ - flare_RedD_, 0.0, 10.0);
                                flare_Red_ *= sunmask;

                                        tempColor.r += flare_Red_*0.55*flaremultR * tempColor2.r;


//--------------------------------------------------------------------------------------

//-------------------Orange--------------------------------------------------------------------------------------

                        vec2 flare_Orange_scale = vec2(aspectRatio,1.0)*vec2(0.86*flarescale2);
                          float flare_Orange_pow = 4.25f;
                          float flare_Orange_fill = 10.0;
                        vec2 flare_Orange_pos = flare_Orange_scale - lPos*flare_Orange_scale;


                        float flare_Orange_ = distance(flare_Orange_pos, ntc2*flare_Orange_scale);
                                  flare_Orange_ = 0.5 - flare_Orange_;
                                  flare_Orange_ = clamp(flare_Orange_*flare_Orange_fill, 0.0, 1.0)  ;
                                  flare_Orange_ = sin(flare_Orange_*1.57075);

                                  flare_Orange_ = pow(flare_Orange_, 1.1);

                                  flare_Orange_ *= flare_Orange_pow;


                                  //subtract
                                  vec2 flare_OrangeD_scale = vec2(aspectRatio,1.0)*vec2(0.5446f*flarescale2);
                                const float flare_OrangeD_pow = 8.0;
                                const float flare_OrangeD_fill = 1.4;
                                vec2 flare_OrangeD_pos = 0.9*flare_OrangeD_scale - lPos*0.8*flare_OrangeD_scale;


                                float flare_OrangeD_ = distance(flare_OrangeD_pos, ntc2*flare_OrangeD_scale);
                                        flare_OrangeD_ = 0.5 - flare_OrangeD_;
                                        flare_OrangeD_ = clamp(flare_OrangeD_*flare_OrangeD_fill, 0.0, 1.0);
                                        flare_OrangeD_ = sin(flare_OrangeD_*1.57075);
                                        flare_OrangeD_ = pow(flare_OrangeD_, 0.9);

                                        flare_OrangeD_ *= flare_OrangeD_pow;

                                flare_Orange_ = clamp(flare_Orange_ - flare_OrangeD_, 0.0, 10.0);
                                flare_Orange_ *= sunmask;

                                        tempColor.rg += flare_Orange_*0.55*flaremultR * tempColor2.r;


//--------------------------------------------------------------------------------------

//-------------------Green--------------------------------------------------------------------------------------

            vec2 flare_Green_scale = vec2(0.82f*flarescale2, 0.82f*flarescale2);
                          float flare_Green_pow = 4.25f;
                          float flare_Green_fill = 10.0;
                          float flare_Green_offset = -0.0;
                        vec2 flare_Green_pos = vec2(  ((1.0 - lPos.x)*(flare_Green_offset + 1.0) - (flare_Green_offset*0.5))  *aspectRatio*flare_Green_scale.x,  ((1.0 - lPos.y)*(flare_Green_offset + 1.0) - (flare_Green_offset*0.5))  *flare_Green_scale.y);


                        float flare_Green_ = distance(flare_Green_pos, vec2(ntc2.s*aspectRatio*flare_Green_scale.x, ntc2.t*flare_Green_scale.y));
                                  flare_Green_ = 0.5 - flare_Green_;
                                  flare_Green_ = clamp(flare_Green_*flare_Green_fill, 0.0, 1.0)  ;
                                  flare_Green_ = sin(flare_Green_*1.57075);

                                  flare_Green_ = pow(flare_Green_, 1.1);

                                  flare_Green_ *= flare_Green_pow;


                                  //subtract
                                  vec2 flare_GreenD_scale = vec2(0.5193f*flarescale2, 0.5193f*flarescale2);
                                  float flare_GreenD_pow = 8.0;
                                  float flare_GreenD_fill = 1.4;
                                  float flare_GreenD_offset = -0.2;
                                vec2 flare_GreenD_pos = vec2(  ((1.0 - lPos.x)*(flare_GreenD_offset + 1.0) - (flare_GreenD_offset*0.5))  *aspectRatio*flare_GreenD_scale.x,  ((1.0 - lPos.y)*(flare_GreenD_offset + 1.0) - (flare_GreenD_offset*0.5))  *flare_GreenD_scale.y);


                                float flare_GreenD_ = distance(flare_GreenD_pos, vec2(ntc2.s*aspectRatio*flare_GreenD_scale.x, ntc2.t*flare_GreenD_scale.y));
                                        flare_GreenD_ = 0.5 - flare_GreenD_;
                                        flare_GreenD_ = clamp(flare_GreenD_*flare_GreenD_fill, 0.0, 1.0)  ;
                                        flare_GreenD_ = sin(flare_GreenD_*1.57075);
                                        flare_GreenD_ = pow(flare_GreenD_, 0.9);

                                        flare_GreenD_ *= flare_GreenD_pow;

                                flare_Green_ = clamp(flare_Green_ - flare_GreenD_, 0.0, 10.0);
                                flare_Green_ *= sunmask;

                                        tempColor.g += flare_Green_*0.55f*flaremultG * tempColor2.r;

//--------------------------------------------------------------------------------------

//-------------------Blue--------------------------------------------------------------------------------------

        vec2 flare_Blue_scale = vec2(0.78f*flarescale2, 0.78f*flarescale2);
                          float flare_Blue_pow = 4.25f;
                          float flare_Blue_fill = 10.0;
                          float flare_Blue_offset = -0.0;
                        vec2 flare_Blue_pos = vec2(  ((1.0 - lPos.x)*(flare_Blue_offset + 1.0) - (flare_Blue_offset*0.5))  *aspectRatio*flare_Blue_scale.x,  ((1.0 - lPos.y)*(flare_Blue_offset + 1.0) - (flare_Blue_offset*0.5))  *flare_Blue_scale.y);


                        float flare_Blue_ = distance(flare_Blue_pos, vec2(ntc2.s*aspectRatio*flare_Blue_scale.x, ntc2.t*flare_Blue_scale.y));
                                  flare_Blue_ = 0.5 - flare_Blue_;
                                  flare_Blue_ = clamp(flare_Blue_*flare_Blue_fill, 0.0, 1.0)  ;
                                  flare_Blue_ = sin(flare_Blue_*1.57075);

                                  flare_Blue_ = pow(flare_Blue_, 1.1);

                                  flare_Blue_ *= flare_Blue_pow;


                                  //subtract
                                  vec2 flare_BlueD_scale = vec2(0.494f*flarescale2, 0.494f*flarescale2);
                                  float flare_BlueD_pow = 8.0;
                                  float flare_BlueD_fill = 1.4;
                                  float flare_BlueD_offset = -0.2;
                                vec2 flare_BlueD_pos = vec2(  ((1.0 - lPos.x)*(flare_BlueD_offset + 1.0) - (flare_BlueD_offset*0.5))  *aspectRatio*flare_BlueD_scale.x,  ((1.0 - lPos.y)*(flare_BlueD_offset + 1.0) - (flare_BlueD_offset*0.5))  *flare_BlueD_scale.y);


                                float flare_BlueD_ = distance(flare_BlueD_pos, vec2(ntc2.s*aspectRatio*flare_BlueD_scale.x, ntc2.t*flare_BlueD_scale.y));
                                        flare_BlueD_ = 0.5 - flare_BlueD_;
                                        flare_BlueD_ = clamp(flare_BlueD_*flare_BlueD_fill, 0.0, 1.0)  ;
                                        flare_BlueD_ = sin(flare_BlueD_*1.57075);
                                        flare_BlueD_ = pow(flare_BlueD_, 0.9);

                                        flare_BlueD_ *= flare_BlueD_pow;

                                flare_Blue_ = clamp(flare_Blue_ - flare_BlueD_, 0.0, 10.0);
                                flare_Blue_ *= sunmask;

                                        tempColor.b += flare_Blue_*0.45f*flaremultB * tempColor2.r;

//--------------------------------------------------------------------------------------

//RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_


//-------------------Red2--------------------------------------------------------------------------------------

                        vec2 flare_Red2_scale = vec2(0.9*flarescale3, 0.9*flarescale3);
                          float flare_Red2_pow = 4.25f;
                          float flare_Red2_fill = 10.0;
                          float flare_Red2_offset = -0.0;
                        vec2 flare_Red2_pos = vec2(  ((1.0 - lPos.x)*(flare_Red2_offset + 1.0) - (flare_Red2_offset*0.5))  *aspectRatio*flare_Red2_scale.x,  ((1.0 - lPos.y)*(flare_Red2_offset + 1.0) - (flare_Red2_offset*0.5))  *flare_Red2_scale.y);


                        float flare_Red2_ = distance(flare_Red2_pos, vec2(ntc2.s*aspectRatio*flare_Red2_scale.x, ntc2.t*flare_Red2_scale.y));
                                  flare_Red2_ = 0.5 - flare_Red2_;
                                  flare_Red2_ = clamp(flare_Red2_*flare_Red2_fill, 0.0, 1.0)  ;
                                  flare_Red2_ = sin(flare_Red2_*1.57075);

                                  flare_Red2_ = pow(flare_Red2_, 1.1);

                                  flare_Red2_ *= flare_Red2_pow;


                                  //subtract
                                  vec2 flare_Red2D_scale = vec2(0.58*flarescale3, 0.58*flarescale3);
                                  float flare_Red2D_pow = 8.0;
                                  float flare_Red2D_fill = 1.4;
                                  float flare_Red2D_offset = -0.2;
                                vec2 flare_Red2D_pos = vec2(  ((1.0 - lPos.x)*(flare_Red2D_offset + 1.0) - (flare_Red2D_offset*0.5))  *aspectRatio*flare_Red2D_scale.x,  ((1.0 - lPos.y)*(flare_Red2D_offset + 1.0) - (flare_Red2D_offset*0.5))  *flare_Red2D_scale.y);


                                float flare_Red2D_ = distance(flare_Red2D_pos, vec2(ntc2.s*aspectRatio*flare_Red2D_scale.x, ntc2.t*flare_Red2D_scale.y));
                                        flare_Red2D_ = 0.5 - flare_Red2D_;
                                        flare_Red2D_ = clamp(flare_Red2D_*flare_Red2D_fill, 0.0, 1.0)  ;
                                        flare_Red2D_ = sin(flare_Red2D_*1.57075);
                                        flare_Red2D_ = pow(flare_Red2D_, 0.9);

                                        flare_Red2D_ *= flare_Red2D_pow;

                                flare_Red2_ = clamp(flare_Red2_ - flare_Red2D_, 0.0, 10.0);
                                flare_Red2_ *= sunmask;

                                        tempColor3.r += flare_Red2_*10.0*flaremultR * (tempColor2.r / 16);

//--------------------------------------------------------------------------------------

//-------------------Orange2--------------------------------------------------------------------------------------

                        vec2 flare_Orange2_scale = vec2(0.86f*flarescale3, 0.86f*flarescale3);
                          float flare_Orange2_pow = 4.25f;
                          float flare_Orange2_fill = 10.0;
                          float flare_Orange2_offset = -0.0;
                        vec2 flare_Orange2_pos = vec2(  ((1.0 - lPos.x)*(flare_Orange2_offset + 1.0) - (flare_Orange2_offset*0.5))  *aspectRatio*flare_Orange2_scale.x,  ((1.0 - lPos.y)*(flare_Orange2_offset + 1.0) - (flare_Orange2_offset*0.5))  *flare_Orange2_scale.y);


                        float flare_Orange2_ = distance(flare_Orange2_pos, vec2(ntc2.s*aspectRatio*flare_Orange2_scale.x, ntc2.t*flare_Orange2_scale.y));
                                  flare_Orange2_ = 0.5 - flare_Orange2_;
                                  flare_Orange2_ = clamp(flare_Orange2_*flare_Orange2_fill, 0.0, 1.0)  ;
                                  flare_Orange2_ = sin(flare_Orange2_*1.57075);

                                  flare_Orange2_ = pow(flare_Orange2_, 1.1);

                                  flare_Orange2_ *= flare_Orange2_pow;


                                  //subtract
                                  vec2 flare_Orange2D_scale = vec2(0.5446f*flarescale3, 0.5446f*flarescale3);
                                  float flare_Orange2D_pow = 8.0;
                                  float flare_Orange2D_fill = 1.4;
                                  float flare_Orange2D_offset = -0.2;
                                vec2 flare_Orange2D_pos = vec2(  ((1.0 - lPos.x)*(flare_Orange2D_offset + 1.0) - (flare_Orange2D_offset*0.5))  *aspectRatio*flare_Orange2D_scale.x,  ((1.0 - lPos.y)*(flare_Orange2D_offset + 1.0) - (flare_Orange2D_offset*0.5))  *flare_Orange2D_scale.y);


                                float flare_Orange2D_ = distance(flare_Orange2D_pos, vec2(ntc2.s*aspectRatio*flare_Orange2D_scale.x, ntc2.t*flare_Orange2D_scale.y));
                                        flare_Orange2D_ = 0.5 - flare_Orange2D_;
                                        flare_Orange2D_ = clamp(flare_Orange2D_*flare_Orange2D_fill, 0.0, 1.0)  ;
                                        flare_Orange2D_ = sin(flare_Orange2D_*1.57075);
                                        flare_Orange2D_ = pow(flare_Orange2D_, 0.9);

                                        flare_Orange2D_ *= flare_Orange2D_pow;

                                flare_Orange2_ = clamp(flare_Orange2_ - flare_Orange2D_, 0.0, 10.0);
                                flare_Orange2_ *= sunmask;

                                        tempColor3.r += flare_Orange2_*10.0*flaremultR/ 16 * tempColor2.r ;
                                        tempColor3.g += flare_Orange2_*5.0*flaremultG / 16* tempColor2.r ;


//--------------------------------------------------------------------------------------

//-------------------Green2--------------------------------------------------------------------------------------

            vec2 flare_Green2_scale = vec2(0.82f*flarescale3, 0.82f*flarescale3);
                          float flare_Green2_pow = 4.25f;
                          float flare_Green2_fill = 10.0;
                          float flare_Green2_offset = -0.0;
                        vec2 flare_Green2_pos = vec2(  ((1.0 - lPos.x)*(flare_Green2_offset + 1.0) - (flare_Green2_offset*0.5))  *aspectRatio*flare_Green2_scale.x,  ((1.0 - lPos.y)*(flare_Green2_offset + 1.0) - (flare_Green2_offset*0.5))  *flare_Green2_scale.y);


                        float flare_Green2_ = distance(flare_Green2_pos, vec2(ntc2.s*aspectRatio*flare_Green2_scale.x, ntc2.t*flare_Green2_scale.y));
                                  flare_Green2_ = 0.5 - flare_Green2_;
                                  flare_Green2_ = clamp(flare_Green2_*flare_Green2_fill, 0.0, 1.0)  ;
                                  flare_Green2_ = sin(flare_Green2_*1.57075);

                                  flare_Green2_ = pow(flare_Green2_, 1.1);

                                  flare_Green2_ *= flare_Green2_pow;


                                  //subtract
                                  vec2 flare_Green2D_scale = vec2(0.5193f*flarescale3, 0.5193f*flarescale3);
                                  float flare_Green2D_pow = 8.0;
                                  float flare_Green2D_fill = 1.4;
                                  float flare_Green2D_offset = -0.2;
                                vec2 flare_Green2D_pos = vec2(  ((1.0 - lPos.x)*(flare_Green2D_offset + 1.0) - (flare_Green2D_offset*0.5))  *aspectRatio*flare_Green2D_scale.x,  ((1.0 - lPos.y)*(flare_Green2D_offset + 1.0) - (flare_Green2D_offset*0.5))  *flare_Green2D_scale.y);


                                float flare_Green2D_ = distance(flare_Green2D_pos, vec2(ntc2.s*aspectRatio*flare_Green2D_scale.x, ntc2.t*flare_Green2D_scale.y));
                                        flare_Green2D_ = 0.5 - flare_Green2D_;
                                        flare_Green2D_ = clamp(flare_Green2D_*flare_Green2D_fill, 0.0, 1.0)  ;
                                        flare_Green2D_ = sin(flare_Green2D_*1.57075);
                                        flare_Green2D_ = pow(flare_Green2D_, 0.9);

                                        flare_Green2D_ *= flare_Green2D_pow;

                                flare_Green2_ = clamp(flare_Green2_ - flare_Green2D_, 0.0, 10.0);
                                flare_Green2_ *= sunmask;

   
                                        tempColor3.g += flare_Green2_*0.5*flaremultG * tempColor2.r;


//--------------------------------------------------------------------------------------

//-------------------Blue2--------------------------------------------------------------------------------------

        vec2 flare_Blue2_scale = vec2(0.78f*flarescale3, 0.78f*flarescale3);
                          float flare_Blue2_pow = 4.25f;
                          float flare_Blue2_fill = 10.0;
                          float flare_Blue2_offset = -0.0;
                        vec2 flare_Blue2_pos = vec2(  ((1.0 - lPos.x)*(flare_Blue2_offset + 1.0) - (flare_Blue2_offset*0.5))  *aspectRatio*flare_Blue2_scale.x,  ((1.0 - lPos.y)*(flare_Blue2_offset + 1.0) - (flare_Blue2_offset*0.5))  *flare_Blue2_scale.y);


                        float flare_Blue2_ = distance(flare_Blue2_pos, vec2(ntc2.s*aspectRatio*flare_Blue2_scale.x, ntc2.t*flare_Blue2_scale.y));
                                  flare_Blue2_ = 0.5 - flare_Blue2_;
                                  flare_Blue2_ = clamp(flare_Blue2_*flare_Blue2_fill, 0.0, 1.0)  ;
                                  flare_Blue2_ = sin(flare_Blue2_*1.57075);

                                  flare_Blue2_ = pow(flare_Blue2_, 1.1);

                                  flare_Blue2_ *= flare_Blue2_pow;


                                  //subtract
                                  vec2 flare_Blue2D_scale = vec2(0.494f*flarescale3, 0.494f*flarescale3);
                                  float flare_Blue2D_pow = 8.0;
                                  float flare_Blue2D_fill = 1.4;
                                  float flare_Blue2D_offset = -0.2;
                                vec2 flare_Blue2D_pos = vec2(  ((1.0 - lPos.x)*(flare_Blue2D_offset + 1.0) - (flare_Blue2D_offset*0.5))  *aspectRatio*flare_Blue2D_scale.x,  ((1.0 - lPos.y)*(flare_Blue2D_offset + 1.0) - (flare_Blue2D_offset*0.5))  *flare_Blue2D_scale.y);


                                float flare_Blue2D_ = distance(flare_Blue2D_pos, vec2(ntc2.s*aspectRatio*flare_Blue2D_scale.x, ntc2.t*flare_Blue2D_scale.y));
                                        flare_Blue2D_ = 0.5 - flare_Blue2D_;
                                        flare_Blue2D_ = clamp(flare_Blue2D_*flare_Blue2D_fill, 0.0, 1.0)  ;
                                        flare_Blue2D_ = sin(flare_Blue2D_*1.57075);
                                        flare_Blue2D_ = pow(flare_Blue2D_, 0.9);

                                        flare_Blue2D_ *= flare_Blue2D_pow;

                                flare_Blue2_ = clamp(flare_Blue2_ - flare_Blue2D_, 0.0, 10.0);
                                flare_Blue2_ *= sunmask;

                                        tempColor3.b += flare_Blue2_*0.5*flaremultB * tempColor2.r;

//--------------------------------------------------------------------------------------




        color += tempColor3 / 4.0;
        color += tempColor4;
    color += tempColor;



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




         //Center white flare
         vec2 flare1scale = vec2(1.7*flarescale, 1.7*flarescale);
         float flare1pow = 12.0;
         vec2 flare1pos = vec2(lPos.x*aspectRatio*flare1scale.x, lPos.y*flare1scale.y);


         float flare1 = distance(flare1pos, vec2(ntc2.s*aspectRatio*flare1scale.x, ntc2.t*flare1scale.y));
              flare1 = 0.5 - flare1;
              flare1 = clamp(flare1, 0.0, 10.0)  ;
              flare1 *= sunmask;
              flare1 = pow(flare1, 1.8);

              flare1 *= flare1pow;

                 color.r += flare1*0.7*flaremultR;
               color.g += flare1*0.4*flaremultG;
               color.b += flare1*0.2*flaremultB;



         //Center white flare
           vec2 flare1Bscale = vec2(0.5*flarescale, 0.5*flarescale);
           float flare1Bpow = 6.0;
         vec2 flare1Bpos = vec2(lPos.x*aspectRatio*flare1Bscale.x, lPos.y*flare1Bscale.y);


         float flare1B = distance(flare1Bpos, vec2(ntc2.s*aspectRatio*flare1Bscale.x, ntc2.t*flare1Bscale.y));
              flare1B = 0.5 - flare1B;
              flare1B = clamp(flare1B, 0.0, 10.0)  ;
              flare1B *= sunmask;
              flare1B = pow(flare1B, 1.8);

              flare1B *= flare1Bpow;

                 color.r += flare1B*0.7*flaremultR;
               color.g += flare1B*0.2*flaremultG;





         //Far blue flare MAIN
           vec2 flare3scale = vec2(2.0*flarescale, 2.0*flarescale);
           float flare3pow = 0.7;
           float flare3fill = 10.0;
           float flare3offset = -0.5;
         vec2 flare3pos = vec2(  ((1.0 - lPos.x)*(flare3offset + 1.0) - (flare3offset*0.5))  *aspectRatio*flare3scale.x,  ((1.0 - lPos.y)*(flare3offset + 1.0) - (flare3offset*0.5))  *flare3scale.y);


         float flare3 = distance(flare3pos, vec2(ntc2.s*aspectRatio*flare3scale.x, ntc2.t*flare3scale.y));
              flare3 = 0.5 - flare3;
              flare3 = clamp(flare3*flare3fill, 0.0, 1.0)  ;
              flare3 = sin(flare3*1.57075);
              flare3 *= sunmask;
              flare3 = pow(flare3, 1.1);

              flare3 *= flare3pow;


              //subtract from blue flare
              vec2 flare3Bscale = vec2(1.4*flarescale, 1.4*flarescale);
              float flare3Bpow = 1.0;
              float flare3Bfill = 2.0;
              float flare3Boffset = -0.65f;
            vec2 flare3Bpos = vec2(  ((1.0 - lPos.x)*(flare3Boffset + 1.0) - (flare3Boffset*0.5))  *aspectRatio*flare3Bscale.x,  ((1.0 - lPos.y)*(flare3Boffset + 1.0) - (flare3Boffset*0.5))  *flare3Bscale.y);


            float flare3B = distance(flare3Bpos, vec2(ntc2.s*aspectRatio*flare3Bscale.x, ntc2.t*flare3Bscale.y));
               flare3B = 0.5 - flare3B;
               flare3B = clamp(flare3B*flare3Bfill, 0.0, 1.0)  ;
               flare3B = sin(flare3B*1.57075);
               flare3B *= sunmask;
               flare3B = pow(flare3B, 0.9);

               flare3B *= flare3Bpow;

            flare3 = clamp(flare3 - flare3B, 0.0, 10.0);


                 color.r += flare3*0.5*flaremultR;
               color.g += flare3*0.3*flaremultG;




         //Far blue flare MAIN 2
           vec2 flare3Cscale = vec2(3.2*flarescale, 3.2*flarescale);
           float flare3Cpow = 1.4;
           float flare3Cfill = 10.0;
           float flare3Coffset = -0.0;
         vec2 flare3Cpos = vec2(  ((1.0 - lPos.x)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *aspectRatio*flare3Cscale.x,  ((1.0 - lPos.y)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *flare3Cscale.y);


         float flare3C = distance(flare3Cpos, vec2(ntc2.s*aspectRatio*flare3Cscale.x, ntc2.t*flare3Cscale.y));
              flare3C = 0.5 - flare3C;
              flare3C = clamp(flare3C*flare3Cfill, 0.0, 1.0)  ;
              flare3C = sin(flare3C*1.57075);

              flare3C = pow(flare3C, 1.1);

              flare3C *= flare3Cpow;


              //subtract from blue flare
              vec2 flare3Dscale = vec2(2.1*flarescale, 2.1*flarescale);
              float flare3Dpow = 2.7;
              float flare3Dfill = 1.4;
              float flare3Doffset = -0.05f;
            vec2 flare3Dpos = vec2(  ((1.0 - lPos.x)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *aspectRatio*flare3Dscale.x,  ((1.0 - lPos.y)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *flare3Dscale.y);


            float flare3D = distance(flare3Dpos, vec2(ntc2.s*aspectRatio*flare3Dscale.x, ntc2.t*flare3Dscale.y));
               flare3D = 0.5 - flare3D;
               flare3D = clamp(flare3D*flare3Dfill, 0.0, 1.0)  ;
               flare3D = sin(flare3D*1.57075);
               flare3D = pow(flare3D, 0.9);

               flare3D *= flare3Dpow;

            flare3C = clamp(flare3C - flare3D, 0.0, 10.0);
            flare3C *= sunmask;

                 color.r += flare3C*0.5*flaremultR;
               color.g += flare3C*0.3*flaremultG;



         //far small pink flare
           vec2 flare4scale = vec2(4.5*flarescale, 4.5*flarescale);
           float flare4pow = 0.3;
           float flare4fill = 3.0;
           float flare4offset = -0.1;
         vec2 flare4pos = vec2(  ((1.0 - lPos.x)*(flare4offset + 1.0) - (flare4offset*0.5))  *aspectRatio*flare4scale.x,  ((1.0 - lPos.y)*(flare4offset + 1.0) - (flare4offset*0.5))  *flare4scale.y);


         float flare4 = distance(flare4pos, vec2(ntc2.s*aspectRatio*flare4scale.x, ntc2.t*flare4scale.y));
              flare4 = 0.5 - flare4;
              flare4 = clamp(flare4*flare4fill, 0.0, 1.0)  ;
              flare4 = sin(flare4*1.57075);
              flare4 *= sunmask;
              flare4 = pow(flare4, 1.1);

              flare4 *= flare4pow;

                 color.r += flare4*0.6*flaremultR;
               color.b += flare4*0.8*flaremultB;



         //far small pink flare2
           vec2 flare4Bscale = vec2(7.5*flarescale, 7.5*flarescale);
           float flare4Bpow = 0.4;
           float flare4Bfill = 2.0;
           float flare4Boffset = 0.0;
         vec2 flare4Bpos = vec2(  ((1.0 - lPos.x)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *aspectRatio*flare4Bscale.x,  ((1.0 - lPos.y)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *flare4Bscale.y);


         float flare4B = distance(flare4Bpos, vec2(ntc2.s*aspectRatio*flare4Bscale.x, ntc2.t*flare4Bscale.y));
              flare4B = 0.5 - flare4B;
              flare4B = clamp(flare4B*flare4Bfill, 0.0, 1.0)  ;
              flare4B = sin(flare4B*1.57075);
              flare4B *= sunmask;
              flare4B = pow(flare4B, 1.1);

              flare4B *= flare4Bpow;

                 color.r += flare4B*0.4*flaremultR;
               color.b += flare4B*0.8*flaremultB;



         //far small pink flare3
           vec2 flare4Cscale = vec2(37.5*flarescale, 37.5*flarescale);
           float flare4Cpow = 2.0;
           float flare4Cfill = 2.0;
           float flare4Coffset = -0.3;
         vec2 flare4Cpos = vec2(  ((1.0 - lPos.x)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *aspectRatio*flare4Cscale.x,  ((1.0 - lPos.y)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *flare4Cscale.y);


         float flare4C = distance(flare4Cpos, vec2(ntc2.s*aspectRatio*flare4Cscale.x, ntc2.t*flare4Cscale.y));
              flare4C = 0.5 - flare4C;
              flare4C = clamp(flare4C*flare4Cfill, 0.0, 1.0)  ;
              flare4C = sin(flare4C*1.57075);
              flare4C *= sunmask;
              flare4C = pow(flare4C, 1.1);

              flare4C *= flare4Cpow;

                 color.r += flare4C*0.6*flaremultR;
               color.g += flare4C*0.3*flaremultG;
               color.b += flare4C*0.1*flaremultB;



         //far small pink flare4
           vec2 flare4Dscale = vec2(67.5*flarescale, 67.5*flarescale);
           float flare4Dpow = 1.0;
           float flare4Dfill = 2.0;
           float flare4Doffset = -0.35f;
         vec2 flare4Dpos = vec2(  ((1.0 - lPos.x)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *aspectRatio*flare4Dscale.x,  ((1.0 - lPos.y)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *flare4Dscale.y);


         float flare4D = distance(flare4Dpos, vec2(ntc2.s*aspectRatio*flare4Dscale.x, ntc2.t*flare4Dscale.y));
              flare4D = 0.5 - flare4D;
              flare4D = clamp(flare4D*flare4Dfill, 0.0, 1.0)  ;
              flare4D = sin(flare4D*1.57075);
              flare4D *= sunmask;
              flare4D = pow(flare4D, 1.1);

              flare4D *= flare4Dpow;

                 color.r += flare4D*0.2*flaremultR;
               color.g += flare4D*0.2*flaremultG;
               color.b += flare4D*0.2*flaremultB;



         //far small pink flare5
           vec2 flare4Escale = vec2(60.5*flarescale, 60.5*flarescale);
           float flare4Epow = 1.0;
           float flare4Efill = 3.0;
           float flare4Eoffset = -0.3393f;
         vec2 flare4Epos = vec2(  ((1.0 - lPos.x)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *aspectRatio*flare4Escale.x,  ((1.0 - lPos.y)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *flare4Escale.y);


         float flare4E = distance(flare4Epos, vec2(ntc2.s*aspectRatio*flare4Escale.x, ntc2.t*flare4Escale.y));
              flare4E = 0.5 - flare4E;
              flare4E = clamp(flare4E*flare4Efill, 0.0, 1.0)  ;
              flare4E = sin(flare4E*1.57075);
              flare4E *= sunmask;
              flare4E = pow(flare4E, 1.1);

              flare4E *= flare4Epow;

                 color.r += flare4E*0.2*flaremultR;
               color.g += flare4E*0.2*flaremultG;





           vec2 flare5scale = vec2(3.2*flarescale , 3.2*flarescale );
           float flare5pow = 13.4;
           float flare5fill = 1.0;
           float flare5offset = -2.0;
         vec2 flare5pos = vec2(  ((1.0 - lPos.x)*(flare5offset + 1.0) - (flare5offset*0.5))  *aspectRatio*flare5scale.x,  ((1.0 - lPos.y)*(flare5offset + 1.0) - (flare5offset*0.5))  *flare5scale.y);


         float flare5 = distance(flare5pos, vec2(ntc2.s*aspectRatio*flare5scale.x, ntc2.t*flare5scale.y));
              flare5 = 0.5 - flare5;
              flare5 = clamp(flare5*flare5fill, 0.0, 1.0)  ;
              flare5 *= sunmask;
              flare5 = pow(flare5, 1.9);

              flare5 *= flare5pow;

                 color.r += flare5*0.9*flaremultR;
               color.g += flare5*0.4*flaremultG;
               color.b += flare5*0.1*flaremultB;







         //close ring flare green
           vec2 flare6Bscale = vec2(1.1*flarescale, 1.1*flarescale);
           float flare6Bpow = 0.2;
           float flare6Bfill = 5.0;
           float flare6Boffset = -1.9;
         vec2 flare6Bpos = vec2(  ((1.0 - lPos.x)*(flare6Boffset + 1.0) - (flare6Boffset*0.5))  *aspectRatio*flare6Bscale.x,  ((1.0 - lPos.y)*(flare6Boffset + 1.0) - (flare6Boffset*0.5))  *flare6Bscale.y);


         float flare6B = distance(flare6Bpos, vec2(ntc2.s*aspectRatio*flare6Bscale.x, ntc2.t*flare6Bscale.y));
              flare6B = 0.5 - flare6B;
              flare6B = clamp(flare6B*flare6Bfill, 0.0, 1.0)  ;
              flare6B = pow(flare6B, 1.6);
              flare6B = sin(flare6B*3.1415);
              flare6B *= sunmask;


              flare6B *= flare6Bpow;

                 color.r += flare6B*1.0*flaremultR * (tempColor2.r);
               color.g += flare6B*0.4*flaremultG * (tempColor2.r);



         //close ring flare blue
           vec2 flare6Cscale = vec2(0.9*flarescale, 0.9*flarescale);
           float flare6Cpow = 0.3;
           float flare6Cfill = 5.0;
           float flare6Coffset = -1.9;
         vec2 flare6Cpos = vec2(  ((1.0 - lPos.x)*(flare6Coffset + 1.0) - (flare6Coffset*0.5))  *aspectRatio*flare6Cscale.x,  ((1.0 - lPos.y)*(flare6Coffset + 1.0) - (flare6Coffset*0.5))  *flare6Cscale.y);


         float flare6C = distance(flare6Cpos, vec2(ntc2.s*aspectRatio*flare6Cscale.x, ntc2.t*flare6Cscale.y));
              flare6C = 0.5 - flare6C;
              flare6C = clamp(flare6C*flare6Cfill, 0.0, 1.0)  ;
              flare6C = pow(flare6C, 1.8);
              flare6C = sin(flare6C*3.1415);
              flare6C *= sunmask;


              flare6C *= flare6Cpow;

                 color.r += flare6C*0.5*flaremultR * (tempColor2.r);
               color.g += flare6C*0.3*flaremultG * (tempColor2.r);



      ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


                           //Edge blue strip 1
           vec2 flareEscale = vec2(0.2*flarescale, 5.0*flarescale);
           float flareEpow = 1.0;
           float flareEfill = 2.0;
           vec2 flareEoffset = vec2(0.0);
         vec2 flareEpos = vec2(lPos.x*aspectRatio*flareEscale.x, lPos.y*flareEscale.y);


         float flareE = distance(flareEpos, vec2(ntc2.s*aspectRatio*flareEscale.x, ntc2.t*flareEscale.y));
              flareE = 0.5 - flareE;
              flareE = clamp(flareE*flareEfill, 0.0, 1.0)  ;
              flareE *= sunmask;
              flareE = pow(flareE, 1.4);

              flareE *= flareEpow;


               color.r += flareE*1.0*flaremultR;
               color.g += flareE*0.6*flaremultG;



            //Center orange strip 1
           vec2 flare_strip1_scale = vec2(0.5*flarescale, 40.0*flarescale);
           float flare_strip1_pow = 0.25f;
           float flare_strip1_fill = 2.0;
           float flare_strip1_offset = 0.0;
         vec2 flare_strip1_pos = vec2(lPos.x*aspectRatio*flare_strip1_scale.x, lPos.y*flare_strip1_scale.y);


         float flare_strip1_ = distance(flare_strip1_pos, vec2(ntc2.s*aspectRatio*flare_strip1_scale.x, ntc2.t*flare_strip1_scale.y));
              flare_strip1_ = 0.5 - flare_strip1_;
              flare_strip1_ = clamp(flare_strip1_*flare_strip1_fill, 0.0, 1.0)  ;
              flare_strip1_ *= sunmask;
              flare_strip1_ = pow(flare_strip1_, 1.4);

              flare_strip1_ *= flare_strip1_pow;


                 color.r += flare_strip1_*0.05f*flaremultR;
               color.g += flare_strip1_*0.03f*flaremultG;




            //Center orange strip 3
           vec2 flare_strip3_scale = vec2(0.4*flarescale, 35.0*flarescale);
           float flare_strip3_pow = 0.5;
           float flare_strip3_fill = 10.0;
           float flare_strip3_offset = 0.0;
         vec2 flare_strip3_pos = vec2(lPos.x*aspectRatio*flare_strip3_scale.x, lPos.y*flare_strip3_scale.y);


         float flare_strip3_ = distance(flare_strip3_pos, vec2(ntc2.s*aspectRatio*flare_strip3_scale.x, ntc2.t*flare_strip3_scale.y));
              flare_strip3_ = 0.5 - flare_strip3_;
              flare_strip3_ = clamp(flare_strip3_*flare_strip3_fill, 0.0, 1.0)  ;
              flare_strip3_ *= sunmask;
              flare_strip3_ = pow(flare_strip3_, 1.4);

              flare_strip3_ *= flare_strip3_pow;


                 color.r += flare_strip3_*0.05f*flaremultR;
               color.g += flare_strip3_*0.03f*flaremultG;


               //mid orange sweep
           vec2 flare_extra3scale = vec2(32.0*flarescale, 32.0*flarescale);
           float flare_extra3pow = 2.5;
           float flare_extra3fill = 1.1;
           float flare_extra3offset = -1.3;
         vec2 flare_extra3pos = vec2(  ((1.0 - lPos.x)*(flare_extra3offset + 1.0) - (flare_extra3offset*0.5))  *aspectRatio*flare_extra3scale.x,  ((1.0 - lPos.y)*(flare_extra3offset + 1.0) - (flare_extra3offset*0.5))  *flare_extra3scale.y);


         float flare_extra3 = distance(flare_extra3pos, vec2(ntc2.s*aspectRatio*flare_extra3scale.x, ntc2.t*flare_extra3scale.y));
              flare_extra3 = 0.5 - flare_extra3;
              flare_extra3 = clamp(flare_extra3*flare_extra3fill, 0.0, 1.0)  ;
              flare_extra3 = sin(flare_extra3*1.57075);
              flare_extra3 *= sunmask;
              flare_extra3 = pow(flare_extra3, 1.1);

              flare_extra3 *= flare_extra3pow;


              //subtract
              vec2 flare_extra3Bscale = vec2(5.1*flarescale, 5.1*flarescale);
              float flare_extra3Bpow = 1.5;
              float flare_extra3Bfill = 1.0;
              float flare_extra3Boffset = -0.77f;
            vec2 flare_extra3Bpos = vec2(  ((1.0 - lPos.x)*(flare_extra3Boffset + 1.0) - (flare_extra3Boffset*0.5))  *aspectRatio*flare_extra3Bscale.x,  ((1.0 - lPos.y)*(flare_extra3Boffset + 1.0) - (flare_extra3Boffset*0.5))  *flare_extra3Bscale.y);


            float flare_extra3B = distance(flare_extra3Bpos, vec2(ntc2.s*aspectRatio*flare_extra3Bscale.x, ntc2.t*flare_extra3Bscale.y));
               flare_extra3B = 0.5 - flare_extra3B;
               flare_extra3B = clamp(flare_extra3B*flare_extra3Bfill, 0.0, 1.0)  ;
               flare_extra3B = sin(flare_extra3B*1.57075);
               flare_extra3B *= sunmask;
               flare_extra3B = pow(flare_extra3B, 0.9);

               flare_extra3B *= flare_extra3Bpow;

            flare_extra3 = clamp(flare_extra3 - flare_extra3B, 0.0, 10.0);


                 color.r += flare_extra3*0.5*flaremultR;
               color.g += flare_extra3*0.4*flaremultG;
               color.b += flare_extra3*0.1*flaremultB;



                  //mid orange sweep
           vec2 flare_extra4scale = vec2(35.0*flarescale, 35.0*flarescale);
           float flare_extra4pow = 1.0;
           float flare_extra4fill = 1.1;
           float flare_extra4offset = -1.2;
         vec2 flare_extra4pos = vec2(  ((1.0 - lPos.x)*(flare_extra4offset + 1.0) - (flare_extra4offset*0.5))  *aspectRatio*flare_extra4scale.x,  ((1.0 - lPos.y)*(flare_extra4offset + 1.0) - (flare_extra4offset*0.5))  *flare_extra4scale.y);


         float flare_extra4 = distance(flare_extra4pos, vec2(ntc2.s*aspectRatio*flare_extra4scale.x, ntc2.t*flare_extra4scale.y));
              flare_extra4 = 0.5 - flare_extra4;
              flare_extra4 = clamp(flare_extra4*flare_extra4fill, 0.0, 1.0)  ;
              flare_extra4 = sin(flare_extra4*1.57075);
              flare_extra4 *= sunmask;
              flare_extra4 = pow(flare_extra4, 1.1);

              flare_extra4 *= flare_extra4pow;


              //subtract
              vec2 flare_extra4Bscale = vec2(5.1*flarescale, 5.1*flarescale);
              float flare_extra4Bpow = 1.5;
              float flare_extra4Bfill = 1.0;
              float flare_extra4Boffset = -0.77f;
            vec2 flare_extra4Bpos = vec2(  ((1.0 - lPos.x)*(flare_extra4Boffset + 1.0) - (flare_extra4Boffset*0.5))  *aspectRatio*flare_extra4Bscale.x,  ((1.0 - lPos.y)*(flare_extra4Boffset + 1.0) - (flare_extra4Boffset*0.5))  *flare_extra4Bscale.y);


            float flare_extra4B = distance(flare_extra4Bpos, vec2(ntc2.s*aspectRatio*flare_extra4Bscale.x, ntc2.t*flare_extra4Bscale.y));
               flare_extra4B = 0.5 - flare_extra4B;
               flare_extra4B = clamp(flare_extra4B*flare_extra4Bfill, 0.0, 1.0)  ;
               flare_extra4B = sin(flare_extra4B*1.57075);
               flare_extra4B *= sunmask;
               flare_extra4B = pow(flare_extra4B, 0.9);

               flare_extra4B *= flare_extra4Bpow;

            flare_extra4 = clamp(flare_extra4 - flare_extra4B, 0.0, 10.0);


                 color.r += flare_extra4*0.6*flaremultR;
               color.g += flare_extra4*0.4*flaremultG;
               color.b += flare_extra4*0.1f*flaremultB;



               //mid orange sweep
           vec2 flare_extra5scale = vec2(25.0*flarescale, 25.0*flarescale);
           float flare_extra5pow = 4.0;
           float flare_extra5fill = 1.1;
           float flare_extra5offset = -0.9;
         vec2 flare_extra5pos = vec2(  ((1.0 - lPos.x)*(flare_extra5offset + 1.0) - (flare_extra5offset*0.5))  *aspectRatio*flare_extra5scale.x,  ((1.0 - lPos.y)*(flare_extra5offset + 1.0) - (flare_extra5offset*0.5))  *flare_extra5scale.y);


         float flare_extra5 = distance(flare_extra5pos, vec2(ntc2.s*aspectRatio*flare_extra5scale.x, ntc2.t*flare_extra5scale.y));
              flare_extra5 = 0.5 - flare_extra5;
              flare_extra5 = clamp(flare_extra5*flare_extra5fill, 0.0, 1.0)  ;
              flare_extra5 = sin(flare_extra5*1.57075);
              flare_extra5 *= sunmask;
              flare_extra5 = pow(flare_extra5, 1.1);

              flare_extra5 *= flare_extra5pow;


              //subtract
              vec2 flare_extra5Bscale = vec2(5.1*flarescale, 5.1*flarescale);
              float flare_extra5Bpow = 1.5;
              float flare_extra5Bfill = 1.0;
              float flare_extra5Boffset = -0.77f;
            vec2 flare_extra5Bpos = vec2(  ((1.0 - lPos.x)*(flare_extra5Boffset + 1.0) - (flare_extra5Boffset*0.5))  *aspectRatio*flare_extra5Bscale.x,  ((1.0 - lPos.y)*(flare_extra5Boffset + 1.0) - (flare_extra5Boffset*0.5))  *flare_extra5Bscale.y);


            float flare_extra5B = distance(flare_extra5Bpos, vec2(ntc2.s*aspectRatio*flare_extra5Bscale.x, ntc2.t*flare_extra5Bscale.y));
               flare_extra5B = 0.5 - flare_extra5B;
               flare_extra5B = clamp(flare_extra5B*flare_extra5Bfill, 0.0, 1.0)  ;
               flare_extra5B = sin(flare_extra5B*1.57075);
               flare_extra5B *= sunmask;
               flare_extra5B = pow(flare_extra5B, 0.9);

               flare_extra5B *= flare_extra5Bpow;

            flare_extra5 = clamp(flare_extra5 - flare_extra5B, 0.0, 10.0);


                 color.r += flare_extra5*0.5*flaremultR;
               color.g += flare_extra5*0.3*flaremultG;


//////////////////////////////////////////////////////////////////////////////


         //far red glow

           vec2 flare7Bscale = vec2(0.2*flarescale, 0.2*flarescale);
           float flare7Bpow = 0.1;
           float flare7Bfill = 2.0;
           float flare7Boffset = 2.9;
         vec2 flare7Bpos = vec2(  ((1.0 - lPos.x)*(flare7Boffset + 1.0) - (flare7Boffset*0.5))  *aspectRatio*flare7Bscale.x,  ((1.0 - lPos.y)*(flare7Boffset + 1.0) - (flare7Boffset*0.5))  *flare7Bscale.y);


         float flare7B = distance(flare7Bpos, vec2(ntc2.s*aspectRatio*flare7Bscale.x, ntc2.t*flare7Bscale.y));
              flare7B = 0.5 - flare7B;
              flare7B = clamp(flare7B*flare7Bfill, 0.0, 1.0)  ;
              flare7B = pow(flare7B, 1.9);
              flare7B = sin(flare7B*3.1415*0.5);
              flare7B *= sunmask;


              flare7B *= flare7Bpow;

                 color.r += flare7B*1.0*flaremultR;



         //Edge blue strip 1
           vec2 flare8scale = vec2(0.3*flarescale, 40.5*flarescale);
           float flare8pow = 0.5;
           float flare8fill = 12.0;
           float flare8offset = 1.0;
         vec2 flare8pos = vec2(  ((1.0 - lPos.x)*(flare8offset + 1.0) - (flare8offset*0.5))  *aspectRatio*flare8scale.x,  ((lPos.y)*(flare8offset + 1.0) - (flare8offset*0.5))  *flare8scale.y);


         float flare8 = distance(flare8pos, vec2(ntc2.s*aspectRatio*flare8scale.x, ntc2.t*flare8scale.y));
              flare8 = 0.5 - flare8;
              flare8 = clamp(flare8*flare8fill, 0.0, 1.0)  ;
              flare8 *= sunmask;
              flare8 = pow(flare8, 1.4);

              flare8 *= flare8pow;
              flare8 *= edgemaskx;
               color.g += flare8*0.3*flaremultG;
               color.b += flare8*0.8*flaremultB;



         //Edge blue strip 1
           vec2 flare9scale = vec2(0.2*flarescale, 5.5*flarescale);
           float flare9pow = 1.9;
           float flare9fill = 2.0;
           vec2 flare9offset = vec2(1.0, 0.0);
         vec2 flare9pos = vec2(  ((1.0 - lPos.x)*(flare9offset.x + 1.0) - (flare9offset.x*0.5))  *aspectRatio*flare9scale.x,  ((1.0 - lPos.y)*(flare9offset.y + 1.0) - (flare9offset.y*0.5))  *flare9scale.y);


         float flare9 = distance(flare9pos, vec2(ntc2.s*aspectRatio*flare9scale.x, ntc2.t*flare9scale.y));
              flare9 = 0.5 - flare9;
              flare9 = clamp(flare9*flare9fill, 0.0, 1.0)  ;
              flare9 *= sunmask;
              flare9 = pow(flare9, 1.4);

              flare9 *= flare9pow;
              flare9 *= edgemaskx;
                 color.r += flare9*0.2*flaremultR;
               color.g += flare9*0.4*flaremultG;
               color.b += flare9*0.9*flaremultB;



      //SMALL SWEEPS      ///////////////////////////////


         //mid orange sweep
           vec2 flare10scale = vec2(6.0*flarescale, 6.0*flarescale);
           float flare10pow = 1.9;
           float flare10fill = 1.1;
           float flare10offset = -0.7;
         vec2 flare10pos = vec2(  ((1.0 - lPos.x)*(flare10offset + 1.0) - (flare10offset*0.5))  *aspectRatio*flare10scale.x,  ((1.0 - lPos.y)*(flare10offset + 1.0) - (flare10offset*0.5))  *flare10scale.y);


         float flare10 = distance(flare10pos, vec2(ntc2.s*aspectRatio*flare10scale.x, ntc2.t*flare10scale.y));
              flare10 = 0.5 - flare10;
              flare10 = clamp(flare10*flare10fill, 0.0, 1.0)  ;
              flare10 = sin(flare10*1.57075);
              flare10 *= sunmask;
              flare10 = pow(flare10, 1.1);

              flare10 *= flare10pow;


              //subtract
              vec2 flare10Bscale = vec2(5.1*flarescale, 5.1*flarescale);
              float flare10Bpow = 1.5;
              float flare10Bfill = 1.0;
              float flare10Boffset = -0.77f;
            vec2 flare10Bpos = vec2(  ((1.0 - lPos.x)*(flare10Boffset + 1.0) - (flare10Boffset*0.5))  *aspectRatio*flare10Bscale.x,  ((1.0 - lPos.y)*(flare10Boffset + 1.0) - (flare10Boffset*0.5))  *flare10Bscale.y);


            float flare10B = distance(flare10Bpos, vec2(ntc2.s*aspectRatio*flare10Bscale.x, ntc2.t*flare10Bscale.y));
               flare10B = 0.5 - flare10B;
               flare10B = clamp(flare10B*flare10Bfill, 0.0, 1.0)  ;
               flare10B = sin(flare10B*1.57075);
               flare10B *= sunmask;
               flare10B = pow(flare10B, 0.9);

               flare10B *= flare10Bpow;

            flare10 = clamp(flare10 - flare10B, 0.0, 10.0);


                 color.r += flare10*0.5*flaremultR;
               color.g += flare10*0.3*flaremultG;



         //mid blue sweep
           vec2 flare10Cscale = vec2(6.0*flarescale, 6.0*flarescale);
           float flare10Cpow = 1.9;
           float flare10Cfill = 1.1;
           float flare10Coffset = -0.6;
         vec2 flare10Cpos = vec2(  ((1.0 - lPos.x)*(flare10Coffset + 1.0) - (flare10Coffset*0.5))  *aspectRatio*flare10Cscale.x,  ((1.0 - lPos.y)*(flare10Coffset + 1.0) - (flare10Coffset*0.5))  *flare10Cscale.y);


         float flare10C = distance(flare10Cpos, vec2(ntc2.s*aspectRatio*flare10Cscale.x, ntc2.t*flare10Cscale.y));
              flare10C = 0.5 - flare10C;
              flare10C = clamp(flare10C*flare10Cfill, 0.0, 1.0)  ;
              flare10C = sin(flare10C*1.57075);
              flare10C *= sunmask;
              flare10C = pow(flare10C, 1.1);

              flare10C *= flare10Cpow;


              //subtract
              vec2 flare10Dscale = vec2(5.1*flarescale, 5.1*flarescale);
              float flare10Dpow = 1.5;
              float flare10Dfill = 1.0;
              float flare10Doffset = -0.67f;
            vec2 flare10Dpos = vec2(  ((1.0 - lPos.x)*(flare10Doffset + 1.0) - (flare10Doffset*0.5))  *aspectRatio*flare10Dscale.x,  ((1.0 - lPos.y)*(flare10Doffset + 1.0) - (flare10Doffset*0.5))  *flare10Dscale.y);


            float flare10D = distance(flare10Dpos, vec2(ntc2.s*aspectRatio*flare10Dscale.x, ntc2.t*flare10Dscale.y));
               flare10D = 0.5 - flare10D;
               flare10D = clamp(flare10D*flare10Dfill, 0.0, 1.0)  ;
               flare10D = sin(flare10D*1.57075);
               flare10D *= sunmask;
               flare10D = pow(flare10D, 0.9);

               flare10D *= flare10Dpow;

            flare10C = clamp(flare10C - flare10D, 0.0, 10.0);


                 color.r += flare10C*0.5*flaremultR;
               color.g += flare10C*0.3*flaremultG;
      //////////////////////////////////////////////////////////





      //Pointy fuzzy glow dots////////////////////////////////////////////////
         //RedGlow1

           vec2 flare11scale = vec2(1.5*flarescale, 1.5*flarescale);
           float flare11pow = 1.1;
           float flare11fill = 2.0;
           float flare11offset = -0.523f;
         vec2 flare11pos = vec2(  ((1.0 - lPos.x)*(flare11offset + 1.0) - (flare11offset*0.5))  *aspectRatio*flare11scale.x,  ((1.0 - lPos.y)*(flare11offset + 1.0) - (flare11offset*0.5))  *flare11scale.y);


         float flare11 = distance(flare11pos, vec2(ntc2.s*aspectRatio*flare11scale.x, ntc2.t*flare11scale.y));
              flare11 = 0.5 - flare11;
              flare11 = clamp(flare11*flare11fill, 0.0, 1.0)  ;
              flare11 = pow(flare11, 2.9);
              flare11 *= sunmask;


              flare11 *= flare11pow;

                 color.r += flare11*1.0*flaremultR;
               color.g += flare11*0.2*flaremultG;



         //PurpleGlow2

           vec2 flare12scale = vec2(2.5*flarescale, 2.5*flarescale);
           float flare12pow = 0.5;
           float flare12fill = 2.0;
           float flare12offset = -0.323f;
         vec2 flare12pos = vec2(  ((1.0 - lPos.x)*(flare12offset + 1.0) - (flare12offset*0.5))  *aspectRatio*flare12scale.x,  ((1.0 - lPos.y)*(flare12offset + 1.0) - (flare12offset*0.5))  *flare12scale.y);


         float flare12 = distance(flare12pos, vec2(ntc2.s*aspectRatio*flare12scale.x, ntc2.t*flare12scale.y));
              flare12 = 0.5 - flare12;
              flare12 = clamp(flare12*flare12fill, 0.0, 1.0)  ;
              flare12 = pow(flare12, 2.9);
              flare12 *= sunmask*flare12pow;


                 color.r += flare12*0.7*flaremultR;
               color.g += flare12*0.3*flaremultG;



         //BlueGlow3

           const vec2 flare13scale = vec2(1.0*flarescale, 1.0*flarescale);
           float flare13pow = 1.5;
           const float flare13fill = 2.0;
           const float flare13offset = +0.138f;
         vec2 flare13pos = vec2(  ((1.0*(flare13offset + 1.0f) - lPos.x*(flare13offset + 1.0f)) - (flare13offset*0.5))  *aspectRatio*flare13scale.x,  ((1.0 - lPos.y)*(flare13offset + 1.0f) - (flare13offset*0.5))  *flare13scale.y);


         float flare13 = distance(flare13pos, vec2(ntc2.s*aspectRatio*flare13scale.x, ntc2.t*flare13scale.y));
              flare13 = 0.5*flare13fill - flare13*flare13fill;
              flare13 = clamp(flare13, 0.0, 1.0) ;
              flare13 = pow(flare13, 2.9);
              flare13 *= sunmask*flare13pow;

                 color.r += flare13*0.5*flaremultR;
               color.g += flare13*0.3*flaremultG;

			   
	float distr = distance(ntc2*vec2(aspectRatio,1.0),lPos*vec2(aspectRatio,1.0));
	float overglow = exp(-distr*42.)*300.;
	color += overglow*lightColor;
         
   }
}
//((48*(0.5*48+0.25*0.1)+0.006)/(48*(0.5*48+0.25)+0.3*0.3))-0.02/0.3
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
void main() {

vec2 ntc2 = texcoord*4.0;

float gr = 0.0;

if (ntc2.x < 1.0 && ntc2.y < 1.0 && ntc2.x > 0.0 && ntc2.y > 0.0){
			vec2 deltatexcoord = vec2(lightPos - ntc2);
			deltatexcoord *= 0.72/13.0;
		
			vec2 noisetc = ntc2 + deltatexcoord*getnoise(ntc2) + deltatexcoord;
			
			vec4 Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex,noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;

			Samplee = textureGather(gdepthtex, noisetc);
			gr += dot(step(vec4(comp),Samplee),vec4(0.25))*cdist(noisetc);
			noisetc += deltatexcoord;
			
			
			

gr /= 13.0;

if (texcoord.x < 2./viewWidth && texcoord.y < 2.0/viewHeight) {

gr = 0.0;
	for (int i = -6; i < 7;i++) {
		for (int j = -6; j < 7 ;j++) {
		vec2 ij = vec2(i,j);
		vec4 temp = textureGather(gdepthtex,texcoord*2.0+lightPos + sign(ij)*sqrt(abs(ij))*vec2(0.006));
		gr += dot(step(vec4(comp),temp),vec4(0.25));
		}
	}
	gr /= 169.0;

}




gl_FragData[0] = vec4(gr);
}
/* DRAWBUFFERS:1 */
}