uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_offset;
uniform float u_inner;
uniform float u_outer;
uniform vec3 u_color1;
uniform float u_color1Alpha;
uniform vec3 u_color2;
uniform float u_color2Alpha;
uniform vec3 u_innerColor;
uniform float u_innerAlpha;
uniform float u_edge;

out vec4 fragColor;

void main() {
    vec2 localCoord = gl_FragCoord.xy - u_offset;
    vec2 uv = (localCoord - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y) * 2.0;
    float r = length(uv);

    float glow = 0.0;
    float edgeSoftness = 0.01; // Ajusta este valor para más/menos suavidad (0.01 es ~1% del radio)

    if (r >= u_inner && r <= u_outer) {
        float t = (r - u_inner) / (u_outer - u_inner);
        glow = pow(t, 1.0);

        // Suaviza el borde externo
        float outerFade = smoothstep(u_outer, u_outer - edgeSoftness, r);
        glow *= outerFade;
    }

    float angle = atan(uv.y, uv.x);
    float anim = 0.5 + 0.5 * sin(u_time + angle * 4.0);
    vec3 baseColor = mix(u_color1, u_color2, anim);
    float baseAlpha = mix(u_color1Alpha, u_color2Alpha, anim);

    float intensity = 2.4;

    vec3 color = baseColor * baseAlpha * glow * intensity;
    float alpha = baseAlpha * glow * intensity;

    // Nada dentro de u_inner
    if (r < u_inner) {
        alpha = 0.0;
        color = vec3(0.0);
    }

    // Si quieres un color de fondo en el centro, puedes mezclarlo así:
    if (u_innerAlpha > 0.0 && r < u_inner) {
        color = u_innerColor;
        alpha = u_innerAlpha;
    }

    fragColor = vec4(color, alpha);
}
