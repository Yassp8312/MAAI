# Tsukiyo · Primera animación jugable

16 de octubre de 2026. Primera pasada de animación por dibujos a partir de `reference.png`, copia de «Samurái de tinta en guardia lunar.png». El original se conserva fuera del proyecto.

## Ver y jugar

Abre `Ver_Tsukiyo.bat` en la raíz del proyecto, o elige Tsukiyo en Jugador 1 y selecciona **Galería de movimientos** en el menú. La demostración recorre once etapas y se repite. Esc abre la pausa; desde allí puedes volver al menú y entrar en un duelo normal o práctica. Ahora se puede elegir un personaje diferente para cada lado; el lanzador conserva el ensayo espejo de Tsukiyo.

`combate-preview.mp4` es una grabación de 22 segundos del render real de Godot, muestreada a 10 FPS para revisión. El juego sigue ejecutando su simulación a 60 Hz.

`sprint-v02-preview.mp4` muestra el sprint revisado en ambos lados: primero a velocidad real y después a un cuarto de velocidad, con captura a 60 FPS. Para regenerar sus fotogramas: Godot `--path . --script tools/preview_tsukiyo_sprint.gd`; quedan en `tmp/tsukiyo-sprint-record/`.

## Dibujos y reproducción

Seis PNG transparentes, **46 dibujos conservados y 44 usados**: las cinco primeras hojas tienen ocho dibujos; la revisión de sprint añade seis y sustituye las dos poses antiguas de carrera.

| Hoja | Contenido |
|---|---|
| 01-guard-walk.png | Dos guardias y seis pasos |
| 02-thrust.png | Ocho fases de la estocada |
| 03-cuts.png | Ascendente y corte bajo |
| 04-air.png | Ascenso, descenso y preparación/contacto de tres ataques aéreos |
| 05-motion-defeat.png | Sprint antiguo (conservado, sin uso), esquiva y caída hasta quedar tendida |
| 06-sprint-v02.png | Seis fases de impulso, deslizamiento y vuelta a guardia |

El controlador ofrece 14 secuencias: guardia, avance, retroceso, sprint, esquiva, ascenso, descenso, derrota y los seis ataques experimentales del prototipo. Se reutilizan dibujos al recuperar la guardia. El retroceso reproduce los pasos en orden inverso; aún no tiene dibujos exclusivos.

La revisión de sprint busca el carácter delicado de Tsukiyo: torso más erguido, espada estable y desplazamiento contenido. Sus seis dibujos se reproducen una sola vez, tres ticks por dibujo, durante los mismos 18 ticks y 260 píxeles del combate. Ya no alterna las dos poses antiguas de carrera. No cambia ataques, esquiva, derrota ni reglas de simulación.

`scripts/tsukiyo_animation.gd` escoge el dibujo según el estado de combate. Los ataques separan explícitamente anticipación, tramo activo y recuperación; la postura baja de esquiva coincide con su ventana invulnerable. La derrota tiene dibujos propios, sin girar una ilustración de pie. La simulación, sus valores y sus reglas no se han cambiado.

Las hojas generadas no forman una cuadrícula perfectamente regular. `tools/build_tsukiyo_atlas.gd` obtiene contornos a partir del alfa y construye geometría de recorte y pivotes en `atlas.json`; **no reescribe los PNG**. Esto evita mostrar bordes, marcas sueltas o fragmentos de celdas vecinas. Dos poses contiguas de la estocada requieren una separación explícita registrada en ese script. Las mallas se triangulan una sola vez y se comparten entre ambos jugadores. `ink.gdshader` mantiene la paleta monocromática en pantalla, incluidos los píxeles de borde.

Para regenerar el manifiesto, ejecuta Godot con `--headless --path . --script tools/build_tsukiyo_atlas.gd`. Los pivotes y escalas están declarados allí. Si se crea una exportación distribuible, incluir `art/characters/tsukiyo/v01/atlas.json` en el filtro de archivos adicionales del preset de exportación.

## Límites de esta pasada

- Es animación limitada por poses: varios ataques aéreos solo tienen preparación y contacto propios. Necesitan más intermedios para mejorar la fluidez.
- Se conserva la identidad general, pero hay variaciones de volumen, manos, pliegues y longitud aparente del arma entre dibujos que requieren revisión artística.
- Los pies tienen anclajes revisados, aunque la caminata todavía necesita ajuste para reducir deslizamiento.
- La sincronización temporal está conectada al combate. La coincidencia geométrica exacta entre filo, cuerpo y colisiones **todavía no está resuelta**. F1 permite comparar las zonas de laboratorio con el dibujo.
- No constituye aprobación del diseño definitivo ni del repertorio final de Tsukiyo.

## Procedencia y comprobaciones

Dibujos creados con la herramienta integrada `image_gen`, usando la habilidad `imagegen`. Prompts completos y revisiones iniciales en `prompts.json`; prompt de la nueva hoja en `sprint-v02-prompt.txt`. La primera hoja de estocada con espada recortada y la hoja de cortes con bordes fueron descartadas; sus revisiones son las incluidas aquí.

Verificación de la revisión: 174 comprobaciones sin renderizado (175 al recorrer también la demostración), incluyendo secuencia completa de sprint en ambos lados, distancia, duración y vuelta a guardia; 38 comprobaciones de combate. Revisión de capturas del render real del nuevo sprint: entrada, deslizamiento, final y orientación izquierda. Las 31 comprobaciones de opciones habían pasado en la versión anterior; no se modifican opciones en esta revisión.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
