# Sayo · Primera animación jugable

16 de octubre de 2026. Derivada de `Sayo Monochrome Sprite.png` y `Sayo Poster.png`, entregados por Jorge. Copias sin modificar: `reference.png` y `poster.png`.

Porte formal, peinado recogido con adornos y traje de capas. El maestro muestra un tessen principal abierto y otro cerrado junto a la cintura. El ataque frontal cierra el principal; los cortes lo abren. Se conservan ambos abanicos como referencia visual.

## Probar

Selecciona **Sayo** para cualquiera de los dos jugadores. **Galería de movimientos** recorre guardia, avance, retroceso, seis ataques, sprint, esquiva y derrota. Admite duelos mixtos y espejo. `combate-preview.mp4` contiene 22 segundos del render real de Godot a 30 FPS; la simulación funciona a 60 Hz.

## Archivos y generación

Cinco hojas transparentes, ocho dibujos por hoja: **40 poses y 14 secuencias**.

- `01-guard-walk.png`: guardia y pasos medidos.
- `02-thrust.png`: cerrar el abanico, extender el golpe frontal y recuperar.
- `03-cuts.png`: cortes ascendente y bajo con el abanico abierto.
- `04-air.png`: salto, descenso y tres ataques aéreos.
- `05-motion-defeat.png`: sprint, esquiva y caída propia.

Generadas con la herramienta integrada `image_gen`, usando el maestro y póster como referencias. Los cinco prompts exactos están en `prompts.json`. Los PNG conservan su alfa original. `registration.json` registra puntos interiores, pivotes y escalas; `atlas.json` contiene los contornos triangulables que utiliza el juego.

Regenerar el atlas: Godot `--headless --path . --script tools/build_character_atlas.gd -- sayo`. Antes de ejecutar el juego, dejar que el editor importe los PNG. Capturar la demostración: `--path . --script tools/preview_characters.gd -- sayo`; codificar sus 660 PNG a 30 FPS.

## Alcance y revisión

Esta es una primera pasada de arte jugable. Guardia, pasos y ataques tienen poses propias; el retroceso todavía reutiliza los pasos invertidos. El sprint combina guardia, impulso y recuperación sin bucle. El golpe frontal usa preparación 0–2, extensión 3–5 y recuperación 5–7, para evitar mostrar la extensión durante la anticipación.

Los tiempos y las trayectorias verticales conservan la base del laboratorio. El alcance horizontal y la altura al esquivar ya usan un perfil propio de Sayo. El alcance del tessen aún no está ajustado al dibujo. Queda pulir continuidad de manos y varillas, pliegues, apoyos e intermedios; esta entrega no define su kit ni su arte final.

Se verificaron las secuencias de los cinco personajes mediante pruebas automáticas y capturas de Godot, incluyendo Sayo en ambos lados y en duelo espejo. Los resultados globales se registran en `../../README.md`.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
