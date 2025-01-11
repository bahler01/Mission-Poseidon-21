shader_type canvas_item;

uniform float hole_radius : hint_range(0.0, 1.0) = 0.3;
uniform vec2 hole_center = vec2(0.5, 0.5);
uniform vec4 panel_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform float smoothness : hint_range(0.0, 0.1) = 0.01;

// Параметры для обводки
uniform vec4 edge_color : source_color = vec4(0.0, 1.0, 0.0, 1.0); // Зеленый цвет
uniform int edge_thickness = 1; // Толщина обводки в пикселях

void fragment() {
    vec2 uv = UV;
    float dist = distance(uv, hole_center);

    // Размер одного пикселя в UV-пространстве
    vec2 pixel_size = SCREEN_PIXEL_SIZE;
    float outline_width = float(edge_thickness) * pixel_size.x; // Предполагаем квадратные пиксели

    // Основной круг отверстия с плавным краем
    float hole = smoothstep(hole_radius - smoothness, hole_radius + smoothness, dist);
    vec4 base_color = panel_color * hole;

    // Параметры обводки
    float outer_radius = hole_radius + outline_width;
    float inner_radius = hole_radius;

    // Создаем сглаженную обводку
    float edge = smoothstep(outer_radius - smoothness, outer_radius + smoothness, dist) -
                 smoothstep(inner_radius - smoothness, inner_radius + smoothness, dist);

    // Комбинируем основной цвет с обводкой
    COLOR = mix(base_color, edge_color, edge);
}
