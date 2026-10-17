# Daichi · Primera animación jugable
16 de octubre de 2026. Primera pasada derivada del maestro y póster que Jorge dejó en la carpeta de MAAI. Los originales permanecen intactos; copias locales: `reference.png` y `poster.png`.

Postura firme, armadura con peso y yari de asta recta a dos manos.

## Probar
Selecciona **Daichi** en cualquiera de los dos lados de la selección de personajes. **Galería de movimientos** recorre guardia, avance, retroceso, seis ataques, sprint, esquiva y derrota. También se pueden jugar duelos mixtos o espejo.
`combate-preview.mp4` muestra 22 segundos del render real de Godot a 30 FPS. La simulación sigue a 60 Hz.

## Archivos
Cinco hojas de ocho dibujos y una hoja adicional de retroceso de cuatro: **44 poses y 14 secuencias**.
- `01-guard-walk.png`: guardia y pasos.
- `02-thrust.png`: preparación, extensión y recuperación de estocada.
- `03-cuts.png`: corte ascendente y corte bajo.
- `04-air.png`: salto, descenso y tres ataques aéreos.
- `05-motion-defeat.png`: sprint, esquiva y derrota.
- `06-backstep-v02.png`: cuatro apoyos propios de retirada mirando al rival.

Dibujos creados con la herramienta integrada `image_gen`. Prompt completo por hoja y revisiones en `prompts.json`. `registration.json` conserva puntos interiores, anclajes de suelo y escalas, con ajustes por pose cuando hacen falta. `atlas.json` contiene los contornos triangulables. No se modifican los píxeles originales de los PNG para extraer poses.

Regenerar con Godot: `--headless --path . --script tools/build_character_atlas.gd -- daichi`.
Capturar vídeo: `--path . --script tools/preview_characters.gd -- daichi`; genera 660 PNG en `tmp/characters-daichi`, para codificar a 30 FPS.

## Alcance de esta versión
Se integra el arte en las acciones existentes. Los tiempos y las trayectorias verticales siguen como base del laboratorio; el alcance horizontal y la altura al esquivar ya usan un perfil propio: **todavía no representa su kit propio ni una coincidencia exacta entre arma dibujada e impacto**. F1 muestra las colisiones.
La animación es limitada por poses. Hay variaciones de pliegues, empuñaduras y perspectiva que quedan sujetas a revisión artística. El retroceso usa sus cuatro poses propias a 8 FPS, conservando la velocidad y orientación de la simulación; sprint combina guardia, impulso y recuperación sin bucle.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
