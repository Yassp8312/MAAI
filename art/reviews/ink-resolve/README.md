# Ink Resolve · pruebas con narración y montaje v03

Se recupera el plano de los cinco personajes antes de MAAI. Se mantiene el paisaje continuo, los fundidos y la ausencia de números, nombres y cartelas. El cambio visual también está aplicado dentro del juego.

| Vídeo | Original | Duración original | Fragmento usado |
|---|---|---|---|
| `prologo-Ink-Resolve-A.mp4` | `MAAI/Ink Resolve.mp3` | 2:43 | 0:00–0:47,2 |
| `prologo-Ink-Resolve-B.mp4` | `MAAI/Ink Resolve (1).mp3` | 2:54 | 0:00–0:47,2 |

No se acelera la música ni se corta la narración. Se usa la apertura natural de cada tema y se hace un fundido al final. Es un cierre provisional por nivel, no una cadencia elegida mediante escucha musical. Los originales se conservan intactos.

## Mezcla

Se analiza la distribución espectral por bandas mediante Welch y se iguala el nivel de referencia de ambas músicas antes del tratamiento. La voz conserva su señal original con el ajuste de −1 dB que ya tenía la intro, duplicada en estéreo sin la atenuación automática de una conversión mono-estéreo.

La energía de la voz se concentra por debajo de 300 Hz. En la música predominan graves y medios: A tiene más energía por debajo de 300 Hz; B concentra más entre 300 y 1800 Hz. El nivel por sí solo no garantiza inteligibilidad, por lo que se prepara una reducción dinámica sobre la música:

- Se atenúa suavemente por debajo de 32 Hz.
- La envolvente de la narración se mide cada 10 ms, con anticipación de 10 ms, ataque de 35 ms y recuperación de 420 ms.
- Mientras habla, se reduce hasta 2 dB la banda de 80–300 Hz y hasta 5 dB la de 900–4500 Hz. Los filtros tienen pendientes suaves; los límites no son cortes abruptos.
- Se añade hasta 1,5 dB de reducción general. En las pausas, las bandas y el volumen se recuperan gradualmente.
- La música entra en 1 s, sube hasta 3 dB al terminar la voz y se desvanece durante los últimos 2,5 s.

Durante los pasajes hablados, la voz queda aproximadamente 9,7–9,8 dB por encima del RMS de la música. La reducción medida en la zona de presencia es de unos 5,5–5,6 dB. La música tiene más nivel medio que las pruebas anteriores. El informe completo está en `mix-analysis.json`.

Jorge eligió **A — Ink Resolve** el 17 de octubre de 2026. Su música procesada ya está incorporada al juego; B se conserva como alternativa de revisión.

## Material reutilizable

`music-A.ogg` y `music-B.ogg` son las pistas procesadas sin voz. A se copia a `art/intro/prologue-music.ogg` y se reproduce desde el segundo cero a ganancia unitaria antes del bus Música. Se retiraron la atenuación provisional de −17 dB y el fundido adicional de `prologue.gd` para no aplicar el tratamiento dos veces. La voz continúa en su bus independiente.

`tools/mix_intro_candidates.py` reproduce el análisis y las mezclas desde los originales. Requiere Python con numpy/scipy y `--ffmpeg RUTA`. Los WAV intermedios se guardan en `tmp/ink-resolve/`.

Se comprueba duración, valores finitos, conservación exacta de la voz antes de la codificación, ausencia de clipping y llegada del fundido a silencio. Las pruebas del prólogo siguen pasando: 20 comprobaciones.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
