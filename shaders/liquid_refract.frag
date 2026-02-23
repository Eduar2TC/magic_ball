uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_offset;
uniform float u_radius; // Por ejemplo: 0.4
uniform float u_refract; // Por ejemplo: 0.15
uniform sampler2D u_texture;

out vec4 fragColor;

void main() {
    vec2 localCoord = gl_FragCoord.xy - u_offset;
    vec2 uv = localCoord / u_resolution;
    vec2 center = vec2(0.5, 0.5); // Centro de la lupa (ajusta si quieres moverla)
    float dist = distance(uv, center);

    vec2 dir = normalize(uv - center);
    float strength = (u_radius - dist) / u_radius * u_refract;
    float wave = 0.03 * sin(u_time * 2.0 + dist * 20.0); // Aumenta el wave para más efecto

    vec2 refractUV = uv;
    if (dist < u_radius) {
        refractUV = uv + dir * strength + wave * dir;
    }

    refractUV = clamp(refractUV, vec2(0.0), vec2(1.0));

    fragColor = texture(u_texture, refractUV);
}
