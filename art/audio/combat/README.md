# MAAI · Sonidos de combate, primera integración

17 de octubre de 2026. 105 efectos mono, PCM16/48 kHz, editados a partir de grabaciones CC0. Siete familias con tres variantes por personaje: pasos, aterrizaje, arma en movimiento, impacto, esquiva, caída del cuerpo y parry. Los originales utilizados están en `sources/`; las fuentes por archivo, hashes, niveles y duraciones están en `manifest.json` y `parry-manifest.json`.

El parry es un contacto metálico propio por personaje, preparado con `tools/build_parry_sfx.py`. Solo suena al confirmar un desvío; no al pulsar en vacío ni durante cada tick del golpe. No dispara el impacto corporal. Su volumen sigue el canal SFX y abre espacio brevemente en la música. Ver `COMBATE_DEFENSA.md` en la raíz para las reglas.

## Identidad por personaje

| Personaje | Pasos y ropa | Arma |
| --- | --- | --- |
| Tsukiyo | Apoyo ligero sobre piedra, tela suave | Aire breve y definido, filo metálico discreto |
| Ren | Pisada firme, cuero y roce áspero | Barrido más ancho y grave, más cuerpo de hoja |
| Daichi | Apoyo pesado, golpe sordo y correaje | Barrido largo y grave con madera del asta |
| Nao | Apoyo amortiguado, corto y seco | Corte corto y rápido, capa de cuchillo |
| Sayo | Pisada fina, tela y roce ligero | Abanico construido con papel, fibras, aire y un pequeño clic metálico |

El abanico es una composición de efectos, no una grabación de un tessen real. Las diferencias se construyen con fuentes y capas diferentes; no son solamente el mismo archivo con otra altura tonal. Se comparten algunos materiales del suelo porque todos pisan el mismo patio. Cada técnica tiene una variación de tono adicional y cada jugador rota sus propias tres muestras sin alterar el azar de la simulación.

## Sincronización y mezcla

- Pasos ligados a los cambios de poses de avance/retroceso y al desplazamiento efectivo. Sin bucle de pasos estando quieto, en el aire o contra un límite.
- Sprint con impulso, ropa y apoyo final; conserva el deslizamiento de la animación actual. Si se interrumpe con un ataque, suena el apoyo al plantar los pies y el arma espera hasta el tramo activo del golpe.
- El barrido del arma empieza en el primer tick activo de la técnica. Un fallo de alcance no produce impacto.
- El impacto usa el banco del atacante y la posición de la víctima. Un doble KO conserva ambos ataques e impactos.
- La esquiva reproduce un roce al iniciarse; los contactos evitados repetidos no producen golpes falsos.
- Salto y aterrizaje separados. Una derrota aérea suena al tocar el suelo; la derrota en tierra acompaña el comienzo de la pose de caída. No se duplica después del aterrizaje.
- Canal **SFX**, controlado por «Efectos» y el silencio general. Panorama estéreo suave según la posición. Margen adicional de 3 dB en cada voz; sin normalización automática al importar.
- La pausa corta los efectos breves, incluyendo los que estaban pendientes de reproducción. Al volver no se repiten. Salir a menús detiene las voces del combate.
- El laboratorio comparte por ahora el material sonoro del patio. Un futuro escenario con otro suelo necesitará una capa de superficie distinta.

Verificación: 232 comprobaciones de audio, 74 de interfaz y 3208 de geometría pasaron, además de la carga de la escena hasta un duelo jugable. Los 90 WAV tienen contenido y hashes distintos. La captura de Godot contiene 68 eventos reales y no satura (pico de la mezcla: −17,6 dBFS con los volúmenes predeterminados). La valoración perceptiva del timbre y la mezcla queda para escuchar la muestra y jugar con altavoces/auriculares.

[Muestra dentro del juego: 45 segundos](../../reviews/combat-audio/MAAI-sonidos-personajes.mp4). Orden: Tsukiyo (0–9 s), Ren (9–18 s), Daichi (18–27 s), Nao (27–36 s) y Sayo (36–45 s). La caída final de cada segmento corresponde al rival que recibe el golpe. Música y ambiente están silenciados solo en esta grabación.

## Fuentes y licencia

Todos los archivos utilizados se publicaron como **Creative Commons Zero (CC0 1.0)** en estas fuentes; pueden editarse y usarse comercialmente. Se conservan los avisos incluidos por sus autores en `licenses/`, junto con las direcciones y hashes de las descargas. Los paquetes de StarNinjas y artisticdude declaran CC0 en sus páginas de distribución; no incluían un aviso de licencia independiente en el ZIP usado.

| Autor | Paquete y página de distribución |
| --- | --- |
| Kenney | [Impact Sounds](https://kenney.nl/assets/impact-sounds) |
| Kenney | [RPG Audio](https://kenney.nl/assets/rpg-audio) |
| StarNinjas | [20 Sword Sound Effects — Attacks and Clashes](https://opengameart.org/content/20-sword-sound-effects-attacks-and-clashes), archivo de ataques |
| Vehicle / Jan Schupke | [Fantasy Weapons and Apparel SFX Library](https://opengameart.org/content/fantasy-weapons-and-apparel-sfx-library) |
| artisticdude | [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack) |

[Texto de CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). Esta licencia se refiere a estos efectos y sus fuentes; no cambia la licencia del juego, las ilustraciones, la voz o la música.

## Reproducir la preparación y las pruebas

Desde la raíz del proyecto, con Python, NumPy, SciPy y FFmpeg:

```text
python tools/download_combat_sfx.py
python tools/build_combat_sfx.py --ffmpeg RUTA_A_FFMPEG
godot --headless --path . --editor
godot --headless --path . --script tests/test_combat_audio.gd
```

Cerrar el editor cuando termine la importación. `sources/` y `licenses/` tienen `.gdignore` para que los originales no se importen al juego. Solo se reproducen los WAV editados.

La muestra de comparación se graba desde Godot, sin música ni ambiente para apreciar los efectos:

```text
godot --path . --script tools/preview_combat_audio.gd --write-movie tmp/combat-audio.avi --fixed-fps 30
```

[Un café para Jorge](https://jorge-coffee.onrender.com/)
