shader_type canvas_item;

uniform sampler2D map_texture;
uniform vec2 submarine_pos_px = vec2(170.0, 134.0); // Положение субмарины в пикселях
uniform float current_time = 0.0;
uniform float ping_start_time = -9999.0;
uniform float ping_speed_px = .0;   // скорость расширения кольца в пикселях/сек
uniform float fade_duration = 3.0;
uniform vec4 glow_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float ring_thickness_px = 5.0; // толщина кольца в пикселях
uniform float map_size = 2000.0; // ширина и высота карты в пикселях

void fragment() {
    float t = current_time - ping_start_time;
    vec4 final_color = vec4(0.0);

    if (t >= 0.0) {
        float ping_radius = ping_speed_px * t;
        float fade = 1.0 - (t / fade_duration);
        if (fade < 0.0) fade = 0.0;

        // Переводим UV в пиксельные координаты
        vec2 pixel_pos = UV * map_size;

        // Расстояние от субмарины в пикселях
        vec2 diff = pixel_pos - submarine_pos_px;
        float dist = length(diff);

        float edge_lower = ping_radius - ring_thickness_px;
        float edge_upper = ping_radius + ring_thickness_px;

        bool in_ring = (dist > edge_lower) && (dist < edge_upper);

        if (in_ring && fade > 0.0) {
            // Выборка цвета карты по UV
            vec4 map_col = texture(map_texture, UV);
            float terrain = map_col.r;

            // Минимальная яркость, чтобы видеть кольцо даже над водой:
            float base_intensity = 0.2;
            float intensity = mix(base_intensity, 1.0, terrain) * fade;

            // Плавный градиент по толщине кольца
            float dist_from_center = abs(dist - ping_radius);
            float gradient = 1.0 - (dist_from_center / ring_thickness_px);
            if (gradient < 0.0) gradient = 0.0;
            intensity *= gradient;

            final_color = glow_color * intensity;
        }
    }

    COLOR = final_color;
}
