Material dirtMaterial = Material(
    vec3(2.45, 0.71, 0.15),
    vec3(4.7, 4.0, 0.95),
    vec3(1.0)
);

float smin(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec3 triPlanar(sampler2D tex, vec3 normal, vec3 p) {
    vec3 cX = texture(tex, p.yz).rgb;
    vec3 cY = texture(tex, p.xz).rgb;
    vec3 cZ = texture(tex, p.xy).rgb;

    vec3 blend = abs(normal);
    blend /= blend.x + blend.y + blend.z + 0.001;

    return blend.x * cX + blend.y * cY + blend.z * cZ;
}

float hash(float n) {
    return fract(sin(n)*43758.5453);
}

vec3 hash3(float n) {
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(43758.5453123,22578.1459123,19642.3490423));
}

float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;

    return mix(mix(mix( hash(n+0.0), hash(n+1.0),f.x),
                   mix( hash(n+57.0), hash(n+58.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

float capsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float line(vec3 p, vec3 a, vec3 b) {
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );

    return length( pa - ba*h );
}

vec3 repeat(vec3 p, vec3 c) {
    return mod(p,c)-0.5*c;
}

float ground(vec3 p) {
    p.xz -= iGlobalTime * 0.5;

    float ground = p.y + noise(vec3(p.x, 0.0, p.z) * 1.5) * 0.5;

    return ground;
}

float hyphaeExtensions(vec3 p) {
    p = repeat(p, vec3(0.0006));
    return length(p) - 0.000001;
}

float extensions(vec3 p, float scale) {
    p = repeat(p, vec3(0.15 * scale));
    return length(p) - 0.01 * scale;
}

float map(vec3 p) {
    p.y -= 1.75;



    float d =  p.y * (1.0 - texture2D(iChannel1, p.xz / 5.0).r);

    // Maybe sound ...
    // d = smin(d, length(p - vec3(-2.25, -0.5, 0.0)) - texture2D(iChannel0, vec2(0.0)).r * 0.5, 1.5);

    d =  smin(d, p.y, 0.08);

    // This is super scary for some reason...
    float f = max(hyphaeExtensions(p), d) + 0.0005;
    d = f;

    // d = smin(d, max(extensions(p, 0.004), d - 0.01), -0.005);


    return d;
}

bool isSameDistance(float distanceA, float distanceB, float eps) {
    return distanceA > distanceB - eps && distanceA < distanceB + eps;
}

bool isSameDistance(float distanceA, float distanceB) {
    return isSameDistance(distanceA, distanceB, 0.0001);
}

Material getMaterial(vec3 p) {
    return defaultMaterial;
    // float distance = map(p);
    // if (isSameDistance(distance, dirt(p), 0.25)) {
    //     return dirtMaterial;
    // }
}

vec3 getNormal(vec3 p) {
    vec2 extraPolate = vec2(0.002, 0.0);

    return normalize(vec3(
        map(p + extraPolate.xyy),
        map(p + extraPolate.yxy),
        map(p + extraPolate.yyx)
    ) - map(p));
}

float intersect (vec3 rayOrigin, vec3 rayDirection) {
    const float maxDistance = 15.0;
    const float distanceTreshold = 0.0001;
    const int maxIterations = 100;

    float distance = 0.0;

    float currentDistance = 1.0;

    for (int i = 0; i < maxIterations; i++) {
        if (currentDistance < distanceTreshold || distance > maxDistance) {
            break;
        }

        vec3 p = rayOrigin + rayDirection * distance;

        currentDistance = map(p);

        distance += currentDistance;
    }

    if (distance > maxDistance) {
        return -1.0;
    }

    return distance;
}

vec3 light = normalize(vec3(10.0, 20.0, 2.0));

void mainImage (out vec4 color, in vec2 p) {
    p /= iResolution.xy;
    p = 2.0 * p - 1.0;
    p.x *= iResolution.x / iResolution.y;

    vec3 cameraPosition = getCameraPosition();
    vec3 rayDirection = normalize(vec3(p, -1.0));
    rayDirection = getRayDirection(rayDirection);

    float distance = intersect(cameraPosition, rayDirection);

    vec3 col = vec3(0.05, 0.05, 0.15);
    col += (1.0 - length(p)) * 0.1;

    if (distance > 0.0) {
        col = vec3(0.0);

        vec3 p = cameraPosition + rayDirection * distance;
        vec3 normal = getNormal(p);
        Material material = getMaterial(p);

        col += material.ambient;

        col += material.diffuse * max(dot(normal, light), 0.0);

        vec3 halfVector = normalize(light + normal);
        col += material.specular * pow(max(dot(normal, halfVector), 0.0), 1024.0);

        float attDistance = 11.0;
        float att = clamp(1.0 - length(light - p) / attDistance, 0.0, 1.0); att *= att;
        col *= att;

        col *= vec3(smoothstep(0.25, 0.75, map(p + light))) + 0.5;
    }

    color.rgb = col;

    if (p.x > 1.0 && p.y < -0.5) {
        color.rgb = texture2D(iChannel1, p).rgb;
    }

}
