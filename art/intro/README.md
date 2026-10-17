# Prólogo ilustrado de MAAI

Secuencia de apertura del juego, antes de la presentación interactiva. Dura aproximadamente 47,2 segundos: 0,8 s de entrada, la narración completa de Jorge (43 s) y 3,4 s para sostener el título. No se reproduce al iniciar cada combate ni al regresar al menú. «Volver a ver el prólogo» permite repetirla.

## Materiales y montaje

- `prologo-es.mp3`: copia sin modificar del audio entregado por Jorge.
- `war-road-v01.png`: paisaje creado para este prólogo; caminos, estandartes y montañas en tinta.
- `tsukiyo-poster.png`: referencia conservada de la primera versión. La versión actual no muestra recortes rectangulares del póster.
- Los cinco maestros de personajes se reutilizan desde `art/characters/`. El movimiento de cámara y los fundidos son propios de esta secuencia ilustrada; no reemplazan las animaciones de combate.
- `captions-es.json`: subtítulos revisados contra la transcripción local de la grabación. Sus tiempos son relativos al audio; el código añade la entrada de 0,8 s.

El reloj de reproducción del audio gobierna el montaje para evitar desfases por caídas de FPS. La revisión v02 mantiene un paisaje continuo con movimientos de cámara, fundidos de 1,15 s y veladuras de tinta que integran los contornos de los personajes. No muestra números, encabezados, nombres, cartelas ni recortes de fichas. Solo los subtítulos y el título final acompañan a las imágenes.

La aparición de los personajes sigue la narración y la Biblia Narrativa v0.2:

- Ren aparece con los caminos sin hogar y vuelve en la frase sobre el honor.
- La promesa se cuenta sobre el castillo distante, sin asociar al señor con ningún luchador.
- Nao aparece con la búsqueda de justicia.
- Daichi y Sayo comparten el deseo de evitar otra guerra: él protege su valle y ella trata de impedir que el Edicto legitime otra campaña.
- Tsukiyo aparece con el reconocimiento de la marca y el recuerdo de aquella noche.
- En la revisión v03, por petición de Jorge, los cinco personajes vuelven a reunirse antes del título, sobre el paisaje y sin nombres, números ni cartelas. El título llega al terminar la última frase.

## Controles y sonido

- Espacio / A / Start: pausa o continuación.
- Esc / B: saltar hacia la presentación.
- S / Y: mostrar u ocultar subtítulos.
- Los botones también admiten ratón, Tab y Enter.
- Al perder el foco, la secuencia se pausa y espera que el jugador la reanude.
- Opciones → Sonido → Narración controla el bus `IntroVO`. Música conserva su propio volumen. El volumen general y el silencio global afectan a ambos.

La música elegida por Jorge el 17 de octubre de 2026 es **Ink Resolve A** (original `MAAI/Ink Resolve.mp3`). `prologue-music.ogg` es una copia exacta de `art/reviews/ink-resolve/music-A.ogg`: el fragmento procesado de 47,2 segundos, sin narración. Se reproduce desde el segundo cero, sin bucle, a ganancia unitaria antes del bus Música. Ya contiene la reducción durante las frases, la subida del título y el fundido final; el código no vuelve a atenuarlo. La voz permanece en su pista y bus independientes. Ambos audios se pausan, reanudan y detienen juntos.

## Revisión

`tests/test_prologue.gd` comprueba inicio, duración, subtítulos, pausa, pérdida de foco, salto, repetición, final natural y salida hacia combate. Las pruebas no equivalen a una sesión con mando físico.

`tools/preview_prologue.gd` captura los nueve encuadres; con `-- --record` genera fotogramas a 1600 × 900 y 30 FPS en `tmp/prologue-v03-record/`. `art/reviews/prologo-v03.mp4` es la vista previa actual con la narración, sin música ni botones de reproducción dibujados en el vídeo. En el juego se conservan los controles. Las versiones anteriores quedan como referencia.

Las dos pruebas con **Ink Resolve** están en `art/reviews/ink-resolve/`, con mezclas de comparación y música procesada separada de la voz. Ver su README para las medidas y la ecualización que se activa con la narración. La versión A ya está incorporada como música predeterminada; su vídeo es la referencia de mezcla con los buses al 100 %.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
