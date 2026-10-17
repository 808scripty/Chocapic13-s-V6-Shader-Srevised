#version 400 compatibility

/*
const int gcolorFormat = RGBA16;        //backward optifine compatibility
const int gcolorFormat = R11F_G11F_B10F;
const int gdepthFormat = RGBA8;
const int gnormalFormat = RGBA16;
*/

    const int shadowMapResolution = 1024;       //shadowmap resolution
    const float shadowDistance = 120.0;     //draw distance of shadows
    const bool  shadowHardwareFiltering0 = true;
    const float sunPathRotation = -40.0f;

    #define UNDERWATERFIX //fixes shadows and other stuff underwater

#define VIGNETTE
#define VIGNETTE_STRENGTH 1. 
#define VIGNETTE_START 0.1  //distance from the center of the screen where the vignette effect start (0-1)
#define VIGNETTE_END 1.25       //distance from the center of the screen where the vignette effect end (0-1), bigger than VIGNETTE_START
    //#define GODRAYS           //varying this step previous godrays result is blurred
        const float exposure = 1.05;            //godrays intensity
        const float density = 1.0;          
        const float grnoise = 0.0;      //amount of noise 


//////////////////////////////END OF ADJUSTABLE VARIABLES
const bool gdepthMipmapEnabled = true;
const int maxf = 4;             //number of refinements
const float stp = 2.0;          //size of one step for raytracing algorithm
const float ref = 0.02;         //refinement multiplier
const float inc = 2.2;          //increasement factor at each step
/*--------------------------------*/
varying vec2 texcoord;

varying vec3 avgAmbient;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;
varying vec3 lightColor;

varying vec3 sky1;
varying vec3 sky2;
varying float skyMult;
varying vec3 nsunlight;

varying float fading;

varying vec2 lightPos;

varying vec3 sunlight;
const vec3 moonlight = vec3(0.5, 0.9, 1.4) * 0.005;
const vec3 moonlightS =vec3(0.575, 1.05, 1.4) * 0.01;
varying vec3 ambient_c;
varying float tr;

varying vec3 rawAvg;

varying float handItemLight;
varying float eyeAdapt;
varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;
varying vec3 avgAmbient2;
varying vec3 cloudColor;
varying vec2 rainPos1;
varying vec2 rainPos2;
varying vec2 rainPos3;
varying vec2 rainPos4;
varying vec4 weights;
varying vec3 cloudc;

uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D composite;
uniform sampler2D gcolor;
uniform sampler2D depthtex0;

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

    float comp = 1.0-near/far/far;          //distances above that are considered as sky

float invRain07 = 1.0-rainStrength*0.4;
vec3 getSkyColor(vec3 fposition) {
vec3 sVector = normalize(fposition);

float cosT = dot(sVector,upVec);
float mCosT = max(cosT,0.0);
float absCosT = 1.0-max(cosT*0.82+0.26,0.2);
float cosS = SdotU;
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);

const float a = -1.;
const float b = -0.22;
const float c = 8.0;
const float d = -3.5;
const float e = 0.3;

//luminance
float L =  (1.0+a*exp(b/(mCosT)));
float A = 1.0+e*cosY*cosY;

//gradient
vec3 grad1 = mix(sky1,sky2,absCosT*absCosT);
float sunscat = max(cosY,0.0);
vec3 grad3 = mix(grad1,nsunlight,sunscat*sunscat*(1.0-mCosT)*(0.9-rainStrength*0.5*0.9)*(clamp(-(cosS)*4.0+3.0,0.0,1.0)*0.65+0.35)+0.1);

float Y2 = 3.14159265359-Y;
float L2 = L * (8.0*exp(d*Y2)+A);

const vec3 moonlight2 = pow(normalize(moonlightS),vec3(3.0))*length(moonlightS);
const vec3 moonlightRain = normalize(vec3(0.25,0.3,0.4))*length(moonlightS);

vec3 gradN = mix(moonlightS,moonlight2,1.-L2/2.0);
gradN = mix(gradN,moonlightRain,rainStrength);
return pow(L*(c*exp(d*Y)+A),invRain07)*sunVisibility *length(rawAvg) * (0.85+rainStrength*0.425)*grad3+ 0.2*pow(L2*1.2+1.2,invRain07)*moonVisibility*gradN;
}

float getAirDensity (float h) {
return max(h/10.,6.0);
}

float FogF(vec3 fposition) {
	float tmult = mix(min(abs(worldTime-6000.0)/6000.0,1.0),1.0,rainStrength);
	float density = 600./1.6*(1.0-rainStrength*0.5);

	vec3 worldpos = (gbufferModelViewInverse*vec4(fposition,1.0)).rgb+cameraPosition;
	float height = mix(getAirDensity (worldpos.y),6.,rainStrength);
	float d = length(fposition);

	// Original atmospheric height fog
	float baseFog = pow(clamp((2.625+rainStrength*3.4)/exp(-60/10./density)*exp(-getAirDensity (cameraPosition.y)/density) * (1.0-exp( -pow(d,2.712)*height/density/(6000.-tmult*tmult*2000.)/13))/height,0.0,1.),1.0-rainStrength*0.63)*clamp((eyeBrightnessSmooth.y/255.-2/16.)*4.,0.0,1.0);

	// SEAMLESS HORIZON FADE:
	// Smoothly ramps fog to 1.0 between 70% and 98% of the render distance 'far'
	float distFade = smoothstep(far * 0.70, far * 0.98, d);

	return clamp(max(baseFog, distFade), 0.0, 1.0);
}

    float distratio(vec2 pos, vec2 pos2) {
        return distance(pos*vec2(aspectRatio,1.0),pos2*vec2(aspectRatio,1.0));
    }
                                    
    float yDistAxis (in float degrees) {
        vec4 dVector = vec4(lightPos,texcoord);
        float ydistAxis = dot(dVector,vec4(-degrees,1.0,degrees,-1.0));
        return abs(ydistAxis);
    }
    
    float smoothCircleDist (in float lensDist) {
    vec2 lP = (lightPos*lensDist)-0.5*lensDist+0.5;
    return distratio(lP, texcoord);
    }
    
    float cirlceDist (float lensDist, float size) {
    vec2 lP = (lightPos*lensDist)-(0.5*lensDist-0.5);
        return pow(min(distratio(lP, texcoord),size)/size,10.);
    }
    
float A = 0.25;     
float B = 0.29;     
float C = 0.10;         
float D = 0.2;      
float E = 0.03;
float F = 0.35;
vec3 Uncharted2Tonemap(vec3 x) {
    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float gen_circular_lens(vec2 center, float size) {
    float dist=distratio(center,texcoord.xy)/size;
    return exp(-dist*dist);
}
vec3 nvec3(vec4 pos) { return pos.xyz/pos.w; }
vec2 nvec2(vec4 pos) { return pos.xy/pos.w; }
float nvec1(vec4 pos) { return pos.z/pos.w; }
vec4 nvec4(vec3 pos) { return vec4(pos.xyz, 1.0); }

float cdist(vec2 coord) {
    return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}

vec3 drawSun(vec3 fposition,vec3 color,float vis) {
vec3 sVector = normalize(fposition);

float angle = (1.0-max(dot(sVector,sunVec),0.0))*300;
float sun = exp(-angle*angle*angle);
sun *= (1.0-rainStrength*0.9925)*sunVisibility;
vec3 sunlightB = mix(pow(sunlight,vec3(1.0))*2.2*20.,vec3(0.25,0.3,0.4),rainStrength*0.8)*(1.0+SdotU*2.0);

return mix(color,sunlightB,sun*vis);
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec4 raytrace(vec3 fragpos, vec3 normal,vec3 fogclr,vec3 rvector,float sky,float mulfov) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    float tmult = mix(min(abs(worldTime-6000.0)/6000.0,1.0),1.0,rainStrength);

    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
    float minZ = start.z;
    float maxZ = fragpos.z;
    int sr = 0;

    for(int i=0;i<25;i++){
        vec2 pos = nvec2(gbufferProjection * nvec4(fragpos)) * 0.5/mulfov + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || -minZ <  0 || min(-minZ,-maxZ) > far*1.412) break;
        vec3 spos = vec3(pos, texture2D(depthtex0, pos).r);
        spos.z = nvec1(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));

        if(spos.z < minZ + 10.  && spos.z > maxZ){
                sr++;
                if(sr >= maxf){
                    bool land = texture2D(depthtex0, pos.st).r < comp;
                    float border = clamp(1.0 - pow(cdist(pos.st), 20.0), 0.0, 1.0);
                    color = texture2D(gcolor, pos.st);
                    if (isEyeInWater == 0) color.rgb = land ? mix(color.rgb,fogclr*(0.7+0.3*tmult)*(1.33-rainStrength*0.8),FogF(spos.xyz)) : drawSun(rvector,fogclr,1.0);
                    else color.rgb = land? color.rgb = mix(color.rgb*0.4,vec3(0.25,0.5,0.72)*rawAvg*0.07,1.-exp(-length(spos.xyz)*0.5/40)) : vec3(0.25,0.5,0.72)*rawAvg*0.07*clamp((eyeBrightnessSmooth.y/255.-2/16.)*4.,0.0,1.0);
                    color.a = border;
                    break;
                }
                fragpos -=vector;
                vector *=ref;
        }

    minZ = fragpos.z;
    vector *= inc;
    fragpos += vector;
    maxZ = fragpos.z;

    }
    return color;
}

float smStep (float edge0,float edge1,float x) {
float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
return t * t * (3.0 - 2.0 * t); }

vec3 decode (vec2 enc)
{
    vec2 fenc = enc*4-2;
    float f = dot(fenc,fenc);
    float g = sqrt(1-f/4.0);
    vec3 n;
    n.xy = fenc*g;
    n.z = 1-f/2;
    return n;
}

void main() {
#ifdef UNDERWATERFIX
float mulfov = 1.0;
if (isEyeInWater>0.1){
float fov = atan(1./gbufferProjection[1][1]);
float fovUnderWater = fov*0.85;
mulfov = gbufferProjection[1][1]*tan(fovUnderWater); 
}
#endif
#ifndef UNDERWATERFIX
const float mulfov = 1.0;
#endif

float Depth = texture2D(depthtex0, texcoord).x;
bool land = Depth < comp;
vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord,Depth,1.0) * 2.0 - 1.0);
fragpos.xyz /= fragpos.w;
fragpos.xy *= mulfov;

vec4 albedo = texture2D(gcolor,texcoord);
vec3 color = albedo.xyz;

    vec3 normal = texture2D(gnormal,texcoord,0).xyz;
    bool reflective = dot(normal,normal) > 0.0;
    if (reflective) {
    float sky = normal.z;
    float sunVis = 1.0;

    bool iswater = sky < 0.2499;
    bool isice = sky > 0.2499 && sky < 0.4999;

    if (iswater) sky *= 4.0;
    if (isice) sky = (sky - 0.25)*4.0;

    if (!iswater && !isice) sky = (sky - 0.5)*4.0;

    sky = max(sky-2./16.0,0.0)*1.14285714286;
    sky *= sky;

    normal = decode(normal.xy);

        vec3 reflectedVector = reflect(normalize(fragpos.xyz), normal);
        vec3 hV= normalize(normalize(reflectedVector) + normalize(-fragpos.xyz));

        float normalDotEye = dot(hV, normalize(fragpos.xyz));

        float F0 = iswater? 0.2 : 0.1;

        float fresnel = pow(clamp(1.0 + normalDotEye,0.0,1.0), 4.0) ;
        fresnel = fresnel+F0*(1.0-fresnel);

        vec3 sky_c = getSkyColor(reflectedVector*620.)*1.7;

        vec4 reflection = raytrace(fragpos.xyz, normal,sky_c,reflectedVector,sky,mulfov);
        sky_c = (isEyeInWater == 0)? drawSun(reflectedVector,sky_c,sunVis)*sky : pow(vec3(0.25,0.5,0.72),vec3(2.2))*rawAvg*0.1;
        reflection.rgb = mix(sky_c, reflection.rgb, reflection.a);

        fresnel *= !iswater? 0.5 : 1.0;

        vec3 reflC = vec3(1.0);

        color = mix(color,reflection.rgb,fresnel);
    }

if (land){
    float fog = FogF(fragpos.xyz);
    
    // FORCE 100% FOG AT CHUNK EDGE:
    // This smoothly ramps the fog to exactly 1.0 between 75% and 95% of your render distance.
    float edgeFog = smoothstep(far * 0.75, far * 0.95, length(fragpos.xyz));
    fog = clamp(max(fog, edgeFog), 0.0, 1.0);

    float tmult = mix(min(abs(worldTime-6000.0)/6000.0,1.0),1.0,rainStrength);
    vec3 skyDir = normalize(fragpos.xyz);
    vec3 fogC = getSkyColor(skyDir) * 1.7 * (0.7 + 0.3 * tmult) * (1.33 - rainStrength * 0.8);

    if (isEyeInWater < 0.9) {
        color = mix(color, fogC, fog);
    } else {
        color = mix(color * 0.4, vec3(0.25, 0.5, 0.72) * rawAvg * 0.07, 1.0 - exp(-length(fragpos.xyz) / 40.0));
    }
}
    if (rainStrength > 0.01){
    vec4 rain = texture2D(composite,texcoord);
        if (rain.r > 0.0001) {
    float rainRGB = 0.25;
    float rainA = rain.r;

    float torch_lightmap        = 6.4 - min(rain.g/rain.r * 6.16,5.6);
    torch_lightmap      = 0.1 / torch_lightmap / torch_lightmap - 0.002595;

    vec3 rainC = rainRGB*(pow(max(dot(normalize(fragpos.xyz),sunVec)*0.1+0.9,0.0),6.0)*(0.1+tr*0.9)*pow(sunlight,vec3(0.25))*sunVisibility+pow(max(dot(normalize(fragpos.xyz),-sunVec)*0.05+0.95,0.0),6.0)*48.0*moonlight*moonVisibility)*0.04 + 0.05*rainRGB*length(avgAmbient2);
    rainC += torch_lightmap*vec3(1.0,0.4,0.04)*2.05/2.4;
    color = color*(1.0-rainA*0.3)+rainC*1.5*rainA;

    }
}

    float gr = 0.0;
    
    float illuminationDecay = pow(abs(dot(normalize(fragpos.xyz),sunVec)),30.0)+pow(abs(dot(normalize(fragpos.xyz),sunVec)),16.0)*0.8+pow(abs(dot(normalize(fragpos.xyz),sunVec)),2.0)*0.125;
    illuminationDecay *= (dot(normalize(fragpos.xyz),sunVec)*sunPosition.z<0.0? 1.0 : 0.0);
    if (illuminationDecay > 0.001) {
    const float blurScale = 0.005;
    vec2 deltaTextCoord = (lightPos-texcoord)*blurScale;
    vec2 textCoord = texcoord/4.0;

            gr += texture2DLod(gdepth, textCoord + deltaTextCoord,1).a;
            gr += texture2DLod(gdepth, textCoord + 2.0 * deltaTextCoord,1).a;
            gr += texture2DLod(gdepth, textCoord + 3.0 * deltaTextCoord,1).a;
            gr += texture2DLod(gdepth, textCoord + 4.0 * deltaTextCoord,1).a;
            gr += texture2DLod(gdepth, textCoord + 5.0 * deltaTextCoord,1).a;
            gr += texture2DLod(gdepth, textCoord + 6.0 * deltaTextCoord,1).a;
            gr += texture2DLod(gdepth, textCoord + 7.0 * deltaTextCoord,1).a;
            
    vec3 grC = lightColor*exposure;
    color += grC*gr/7.*illuminationDecay;
}

    float distr = distance(texcoord*vec2(aspectRatio,1.0),lightPos*vec2(aspectRatio,1.0));
    float overglow = exp(-distr*42.)*200.;
    
    color += overglow*fading*pow(dot(textureGather(gdepth,vec2(1.0)/vec2(viewWidth,viewHeight),3),vec4(0.25)),2.)*lightColor;
    
    #ifdef VIGNETTE
    float len = distance(texcoord,vec2(.5));
    float len2 = distratio(texcoord,vec2(.5));

    float dc = mix(len,len2,0.1);
    float vignette = smStep(VIGNETTE_END, VIGNETTE_START,  dc);

    color = color*pow(vignette,1.6)*1.05;
    #endif  

    vec3 curr = Uncharted2Tonemap(color*pow(eyeAdapt,0.88)*4.8);

    color = pow(curr/Uncharted2Tonemap(vec3(15.)),vec3(1.0/2.2));
// --- DYNAMIC TIME-BASED COLOR TEMPERATURE ---
    float tempIntensity = 1.1; // 0.0 = Off, 0.5 = Subtle, 1.0 = Default, 1.5 = Strong

    vec3 noonTint   = vec3(1.00, 1.00, 1.00); 
    vec3 sunsetTint = vec3(1.15, 0.95, 0.80); 
    vec3 nightTint  = vec3(0.85, 0.95, 1.15); 

    float dayWeight = clamp(1.0 - abs(float(worldTime) - 6000.0) / 6000.0, 0.0, 1.0);
    float nightWeight = clamp(1.0 - abs(float(worldTime) - 18000.0) / 6000.0, 0.0, 1.0);
    float sunsetWeight = clamp(1.0 - (dayWeight + nightWeight), 0.0, 1.0);

    vec3 dynamicTint = (noonTint * dayWeight) + 
                       (nightTint * nightWeight) + 
                       (sunsetTint * sunsetWeight);

    // Blend between neutral vec3(1.0) and dynamicTint based on intensity
    vec3 finalTint = mix(vec3(1.0), dynamicTint, tempIntensity);

    color = clamp(color * finalTint, 0.0, 1.0);

    // --- CINEMATIC COLOR GRADING PASS ---
    const float cineContrast   = 1.10;                  // S-curve contrast boost (>1.0 = punchier)
    const float cineSaturation = 1.09;                  // Vibrance (>1.0 = more vibrant)
    const float filmBlackLift  = 0.015;                 // Faded film toe (lifts pure blacks slightly)
    vec3 shadowSplitTint       = vec3(0.94, 0.97, 1.05); // Cool teal/blue shadow tint
    vec3 highlightSplitTint    = vec3(1.05, 1.01, 0.95); // Warm gold/amber highlight tint

    // 1. S-Curve Contrast around midtones (0.5)
    color = clamp((color - 0.5) * cineContrast + 0.5, 0.0, 1.0);

    // 2. Luminance & Vibrance/Saturation Adjustment
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(luma), color, cineSaturation);

    // 3. Filmic Split Toning (Cool shadows, warm highlights based on luminance)
    color = mix(color * shadowSplitTint, color * highlightSplitTint, clamp(luma, 0.0, 1.0));

    // 4. Filmic Black Lift (gives rich, cinematic crushed blacks)
    color = color * (1.0 - filmBlackLift) + vec3(filmBlackLift);

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}