shader_type canvas_item;

uniform vec2 SONAR_CENTER; // Центр пинга (позиция субмарины)
uniform float SONAR_TIME; // Текущее время
uniform float SONAR_WAVE_SPEED = 300.0; // Скорость расширения волны
uniform float SONAR_WAVE_INTERVAL = 1.0; // Интервал между пингами
uniform sampler2D MAP_TEXTURE; // Текстура рельефа
uniform sampler2D NOISE_TEXTURE; // Текстура шума
uniform vec4 HIGHLIGHT_COLOR : hint_color = vec4(0.0, 1.0, 0.0, 1.0); // Цвет подсветки
uniform float MAP_THRESHOLD = 0.5; // Порог для определения рельефа
uniform vec2 WORLD_SIZE = vec2(2000.0, 2000.0); // Размер игрового мира

void fragment() {
    vec2 world_pos = UV * WORLD_SIZE;
    float dist = distance(world_pos, SONAR_CENTER);

    // Расчёт текущего радиуса волны
    float phase = mod(SONAR_TIME, SONAR_WAVE_INTERVAL) / SONAR_WAVE_INTERVAL;
    float radius = phase * SONAR_WAVE_SPEED * SONAR_WAVE_INTERVAL;

    // Проверка рельефа
    vec4 map_color = texture(MAP_TEXTURE, UV);
    float is_relief = step(MAP_THRESHOLD, map_color.r);

    // Подсветка хлопьями (шум)
    vec4 noise_color = texture(NOISE_TEXTURE, UV * 10.0); // Масштаб шума
    float noise_value = noise_color.r;

    float band_width = 20.0; // Толщина волны
    float diff = abs(dist - radius);
    float wave_intensity = max(0.0, 1.0 - diff / band_width);
    float highlight_intensity = wave_intensity * noise_value * is_relief;

    vec4 base_color = vec4(0.0, 0.0, 0.0, 0.0);
    vec4 final_color = mix(base_color, HIGHLIGHT_COLOR, highlight_intensity);

    COLOR = final_color;
}