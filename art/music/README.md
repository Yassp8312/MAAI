# Música de presentación y menú · Banda1 / Ink Duel

Pista aportada por Jorge el 17 de octubre de 2026: `D:/Proyectos/Juegos/MAAI/Banda1.mp3`. El archivo original se conserva sin modificar en esa ubicación. Título incorporado en sus metadatos: **Ink Duel**; procedencia indicada: Suno. No se presupone licencia CC0 ni se extienden a esta música las licencias de los efectos de combate.

SHA-256 del MP3 original: `B92BCD6E101BB5AB17F87E73ED2D6BC7671951E38E7F75A9F51138972F67BA6D`.

Duración decodificada: 239,9335 segundos. Medición del original: pico −1,9 dBFS y nivel RMS aproximado −16,2 dBFS (no es una medición LUFS). Se conserva la pista completa, convertida a Ogg Vorbis estéreo de 48 kHz, sin portada ni metadatos del prompt. No se ha aplicado compresión adicional de dinámica ni ecualización.

## Integración inicial para valorar

- Presentación, menú, selección, enfrentamiento y resultado comparten reproducción continua. Abrir Opciones desde el menú no reinicia la música.
- Nivel propio de −7 dB, además de los ajustes Music/Master del usuario.
- Entrada de 1,4 segundos; salida de 0,8 segundos al iniciar la partida, durante la cuenta atrás.
- Dos reproductores realizan una superposición lineal de tres segundos al llegar al final. Evita un corte de reproducción; la continuidad musical entre frases queda pendiente de valoración auditiva por Jorge.
- El prólogo conserva Ink Resolve A. Al reproducirlo se detiene inmediatamente esta pista para evitar superposiciones.
- Las opciones y la pausa de un combate no arrancan música de menú. El combate utiliza las dos pistas descritas a continuación.
- Pruebas de continuidad, vuelta al menú, buses, fundidos y relevo entre las dos voces en `tests/test_menu_music.gd`.

La valoración realizada es técnica. La elección artística y el volumen final se revisan escuchando la prueba dentro del juego.

Conversión reproducible:

```text
ffmpeg -i Banda1.mp3 -map 0:a:0 -map_metadata -1 -vn -c:a libvorbis -q:a 5 -ar 48000 art/music/menu-ink-duel.ogg
```

## Combates · Banda sonora2 y Banda sonora 3

Ambas aportadas por Jorge y adaptadas sin modificar sus MP3 originales. Conservan la pieza completa, aproximadamente 2:57 y 2:50, respectivamente. Los archivos del juego son `battle-2.ogg` y `battle-3.ogg`, estéreo a 48 kHz. Procedencia y hashes en `battle-preparation.json`; no se presupone una licencia CC0 para estas pistas.

Preparación con `tools/prepare_battle_music.py`: filtro suave por debajo de 35 Hz y reducción amplia de 2 dB alrededor de 2,5 kHz para reservar espacio a los efectos. Se mide la sonoridad y se aplica una ganancia fija de −7,67 y −7,93 dB, respectivamente, para aproximar ambas a −21 LUFS. Se preserva la dinámica: el filtro loudnorm del análisis no se aplica a los archivos finales. El informe conserva su salida de medición completa; sus campos `output_*` corresponden a esa pasada descartada, no al audio exportado.

Funcionamiento:

- Primer duelo: Banda sonora2. Siguiente partida o revancha: Banda sonora 3. Después se alternan, sin repetir consecutivamente dentro de la sesión. Reiniciar la aplicación reinicia el orden.
- Una partida al mejor de 3/5 mantiene su pista entre rondas, sin reiniciarla. Si llega al final, repite con el fundido cruzado de tres segundos.
- Nivel adicional de −3 dB en el reproductor, además de los volúmenes Music/Master. Entrada de 1,1 segundos y salida de 0,8 segundos al pasar al resultado/menú.
- Pausa y opciones durante el duelo reducen la música 12 dB de forma suave. La reproducción continúa y recupera su nivel al reanudar.
- Barridos de arma e impactos solicitan una reducción breve de hasta 3 dB, con recuperación gradual. La señal procede de los contactos/acciones reales del sistema de sonido.
- Práctica y galería no activan música de combate ni consumen un turno de alternancia. Práctica tiene la adaptación Dojo descrita abajo; la galería mantiene ambiente y efectos.
- El prólogo detiene ambos sistemas de música de inmediato y conserva su mezcla propia.

Pruebas: `tests/test_battle_music.gd` cubre alternancia, rondas, pausa, opciones, resultado, revancha, práctica/galería, fundidos y reducción ante efectos. `tools/preview_battle_music.gd` graba dos combates de muestra con sonido real y pausa. La valoración del timbre y de los empalmes musicales se realiza escuchando la muestra; las comprobaciones automáticas verifican comportamiento y niveles.

Verificado: 21 comprobaciones de música de combate, 15 de menú, 35 de opciones y 74 del recorrido de interfaz. En modo headless se verifica el estado de reproducción sin abrir decodificadores; la captura de Godot usa audio real. [Muestra local de 40 segundos](../reviews/battle-music/MAAI-dos-temas-combate.mp4): primera pista en los primeros 20 segundos, segunda en los siguientes 20. Pico de la mezcla capturada: −18,2 dBFS, sin saturación. El vídeo de revisión se excluye del repositorio como las demás capturas de vídeo.

## Entrenamiento · Ink Duel — Dojo

Adaptación de `Banda1.mp3`, aportada por Jorge y generada con Suno, sin descargas nuevas. El original queda intacto. Se utiliza el tramo 12–96 s, con tempo 0,94 conservando afinación, filtro de graves, reducciones suaves de graves/medios/agudos y un eco corto. No hay separación de instrumentos. Duración: aproximadamente 89,5 segundos.

`tools/prepare_training_music.py` conserva receta, hashes y mediciones en `training-preparation.json`. Ganancia fija de −4,86 dB; archivo codificado a −22,06 LUFS y pico real de −8,70 dBTP. Solo los campos `input_*` del análisis describen el audio medido; la normalización de loudnorm se descarta.

El reproductor añade −4 dB, respeta Música/General, cruza tres segundos entre repeticiones y no reinicia al repetir ejercicios. Pausar reduce 12 dB; armas, impactos y parry reducen brevemente 2 dB. La galería y el prólogo no activan esta pista. Pruebas en `tests/test_training_music.gd`; escucha y empalme disponibles en `art/reviews/training-music/`. Las comprobaciones técnicas no sustituyen la valoración auditiva de Jorge.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
