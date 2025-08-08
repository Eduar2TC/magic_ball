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

    float ring;
    if (u_edge > 0.0) {
        ring = smoothstep(u_inner, u_inner + u_edge, r) - smoothstep(u_outer, u_outer + u_edge, r);
    } else {
        ring = step(u_inner, r) - step(u_outer, r);
    }

    float halo = exp(-85.0 * (r - u_outer));
    halo *= step(r, 0.95);

    float angle = atan(uv.y, uv.x);
    float anim = 0.5 + 0.5 * sin(u_time + angle * 4.0);
    vec3 baseColor = mix(u_color1, u_color2, anim);
    float baseAlpha = mix(u_color1Alpha, u_color2Alpha, anim);

    // Antialiasing para el borde interno
    float aa = 0.003; // Puedes ajustar este valor
    float innerFade = smoothstep(u_inner - aa, u_inner + aa, r);

    vec3 color = baseColor * baseAlpha * (ring + halo * 2.5) * innerFade;
    float ringAlpha = ring * baseAlpha * innerFade;
    float haloAlpha = halo * baseAlpha * 2.5 * innerFade;
    float alpha = clamp(ringAlpha + haloAlpha, 0.0, 1.0);

    // Si quieres un color de fondo en el centro, puedes mezclarlo así:
    if (u_innerAlpha > 0.0) {
        color = mix(u_innerColor, color, innerFade);
        alpha = mix(u_innerAlpha, alpha, innerFade);
    }

    fragColor = vec4(color, alpha);
}
