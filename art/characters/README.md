# Personajes de MAAI · Estado de producción
Actualizado el 16 de octubre de 2026.

## Elenco integrado
| Personaje | Referencia principal en la carpeta MAAI | Estado | Dibujos |
|---|---|---|---|
| Tsukiyo | Samurái de tinta en guardia lunar.png | Jugable; sprint delicado conservado | 46 conservados, 44 usados |
| Ren | Ren Monochrome Sprite.png + Ren Poster.png | Jugable; retroceso propio; 14 secuencias | 44 |
| Daichi | Daichi Monochrome Sprite.png + Daichi, Guardián del Valle-3.png | Jugable; retroceso propio; 14 secuencias | 44 |
| Nao | Nao Asesina errante con dos dagas.png + Nao Poster.png | Jugable; retroceso propio; 14 secuencias | 44 |
| Sayo | Sayo Monochrome Sprite.png + Sayo Poster.png | Jugable; 14 secuencias | 40 |

Los cinco personajes parten de los maestros entregados por Jorge. Sayo se integró al recibir su maestro y póster en la carpeta padre. Los archivos con nombre genérico «Monochrome Samurai Warrior Sprite» y las variantes de guardia lunar corresponden a Tsukiyo, no a personajes nuevos.

Se consultó el chat **Script Blender futurista** (`6ad060fc-b450-83ea-9a38-42ef4dabcda0`), cuyos últimos mensajes accesibles confirmaban la sobrecapa asimétrica de Nao y el trabajo de su maestro. La identidad visual se toma de los PNG inspeccionados; los textos dentro de los pósteres son referencias artísticas, no órdenes de ejecución.

## Probar y revisar
En el menú, elegir personaje para **Jugador 1** y **Jugador 2**. Se permiten duelos mixtos y espejo. **Galería de movimientos** recorre once etapas y mantiene al segundo personaje en guardia. El selector muestra solo personajes con atlas integrado.

| Personaje | Archivos, prompts y notas | Vídeo real del dojo |
|---|---|---|
| Tsukiyo | [Carpeta y documentación](tsukiyo/v01/README.md) | [Sprint revisado](tsukiyo/v01/sprint-v02-preview.mp4) |
| Ren | [Carpeta y documentación](ren/v01/README.md) | [22 segundos, 30 FPS](ren/v01/combate-preview.mp4) |
| Daichi | [Carpeta y documentación](daichi/v01/README.md) | [22 segundos, 30 FPS](daichi/v01/combate-preview.mp4) |
| Nao | [Carpeta y documentación](nao/v01/README.md) | [22 segundos, 30 FPS](nao/v01/combate-preview.mp4) |
| Sayo | [Carpeta y documentación](sayo/v01/README.md) | [22 segundos, 30 FPS](sayo/v01/combate-preview.mp4) |

Ren, Daichi, Nao y Sayo suman 23 hojas y 172 dibujos: cinco hojas de ocho poses por personaje, más cuatro poses propias de retroceso para Ren, Daichi y Nao. Se generaron con la herramienta integrada `image_gen`. Cada carpeta `v01` contiene las referencias, los PNG finales y `prompts.json` con los prompts exactos y revisiones. Los originales externos no se modifican. Se revisaron los cortes de Ren para separar celdas y su nuevo retroceso para corregir un cruce de pies. El total del elenco es 218 dibujos conservados, 216 usados.

## Integración y límites
Los nuevos personajes tienen dibujos propios de guardia, avance, sprint, esquiva, salto, descenso, derrota, tres ataques terrestres y tres aéreos. Ren, Daichi y Nao añaden dibujos específicos de retroceso. Las fases se sincronizan con la simulación. El sprint se reproduce una vez y vuelve a guardia; Tsukiyo conserva sus seis dibujos delicados aprobados.

El controlador comparte mallas únicamente entre instancias del mismo personaje. `registration.json` declara anclajes y escalas; `atlas.json` almacena los contornos generados. El recorte usa alfa y no reescribe las imágenes. Para exportar, incluir los `atlas.json` en archivos adicionales.

Esta entrega amplía el **arte jugable**. Los tiempos y las trayectorias verticales conservan la base del laboratorio; los alcances horizontales ya son distintos por personaje y el cuerpo baja al esquivar. Véase [perfiles de combate](../../data/characters/README.md). La yari, las dagas y el tessen aún no tienen alcances definitivos ni colisiones ajustadas al dibujo. No se presenta esta pasada como balance del elenco o kit final. Quedan por pulir intermedios, apoyo de pies, manos, longitud aparente de armas y variaciones de volumen. Ren, Daichi y Nao usan retrocesos de cuatro poses propias a 8 FPS; Tsukiyo y Sayo todavía reutilizan sus pasos invertidos.

## Comprobaciones
- 5277 comprobaciones del catálogo de cinco personajes, referencias de clips, caché por personaje, avance/retroceso real en ambos lados, conservación de orientación y distancia, estados, ataques completos, independencia de la simulación, selectores reales, duelos mixtos/espejo y demostraciones; cero fallos.
- 3208 comprobaciones nuevas de alcance, postura y muerte aérea; 174 específicas de Tsukiyo; 38 de combate; 31 de opciones. Cero fallos.
- Revisión de capturas reales de Godot de las animaciones y menú a 960 × 540; vídeos propios por personaje. Los vídeos de animación anteriores a la revisión de colisiones conservan el texto de alcance compartido; el juego actual ya muestra alcances propios. La simulación sigue ejecutándose a 60 Hz.
- No se ha probado el balance humano ni se han creado kits diferentes en esta entrega.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
