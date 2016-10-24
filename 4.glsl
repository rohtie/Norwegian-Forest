struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

Material defaultMaterial = Material(
    vec3(0.15, 1.51, 0.25),
    vec3(4.7, 0.5, 0.35),
    vec3(90.0)
);

mat2 rotate(float a) {
    return mat2(-sin(a), cos(a),
                 cos(a), sin(a));
}

vec3 getCameraPosition() {
    vec3 cameraPosition = vec3(0.0, 0.5, 5.0);

    float b = 1.25;
    cameraPosition.zy *= rotate(b);
    cameraPosition.xz *= rotate(b - 1.0 + sin(iGlobalTime * 0.25) * 0.1);

    cameraPosition.z -= iGlobalTime * 0.05;
    cameraPosition.x -= iGlobalTime * 0.05;
    cameraPosition.y -= 0.05;

    return cameraPosition;
}

vec3 getRayDirection(vec3 rayDirection) {
    float b = 1.25;
    rayDirection.zy *= rotate(b);
    rayDirection.xz *= rotate(b - 1.0 + sin(iGlobalTime * 0.25) * 0.1);

    return rayDirection;
}

#pragma include <project/horse.glsl>