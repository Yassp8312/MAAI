# MAAI · Interfaz de entrada al duelo

Primera versión funcional, 16 de octubre de 2026. Se implementan los dos primeros bloques de `PROXIMOS_PASOS.md`. El combate dispone del Patio al atardecer y del laboratorio, alternables desde la pausa.

## Recorrido

Presentación → menú principal → selección independiente → presentación del enfrentamiento → duelo → resultado con revancha, otra selección o menú.

El menú ofrece Duelo local, Práctica libre, Galería de movimientos, Opciones y Salir. Práctica aún requiere manejar los dos jugadores; el rival automático de entrenamiento es un trabajo posterior. La galería reproduce las animaciones del jugador 1 frente al personaje elegido como jugador 2.

Cada lado de la selección muestra retrato, nombre, arma, una frase de carácter y cinco miniaturas. Ambos pueden elegir el mismo personaje. Cada confirmación bloquea únicamente la elección de ese jugador; cancelarla vuelve a permitir cambios. Los dos «Listo» abren una transición de 1,8 segundos que puede cancelarse. Cambiar el formato de partida elimina las confirmaciones anteriores.

## Controles de interfaz

| Pantalla | Teclado | Mando | Ratón |
|---|---|---|---|
| Presentación | Cualquier tecla | Cualquier botón | Comenzar |
| Menú / resultado | Arriba/abajo o W/S; Enter; Esc para volver | Stick vertical o cruceta; A confirmar, B volver | Botones |
| Selección J1 | A/D elegir; F confirmar; Q cancelar | Mando asignado a J1: stick horizontal/cruceta; A/B | Miniaturas y confirmación del lado izquierdo |
| Selección J2 | Flechas izquierda/derecha; U confirmar; K cancelar | Mando asignado a J2: stick horizontal/cruceta; A/B | Miniaturas y confirmación del lado derecho |
| Formato de duelo | Tab alterna mejor de 3/5 | Y | Botón inferior derecho |
| Volver desde selección | Esc | B sin elección confirmada | Volver al menú |

Las teclas de selección se leen de las asignaciones actuales: movimiento izquierda/derecha, ataque 1 para confirmar y esquiva para cancelar. Sus indicaciones cambian al reasignar controles. Los mandos usan A/B para navegación de interfaz, independientemente de sus botones de combate.

Cada mando conserva su lado durante esa sesión; desconectarlo durante la selección cancela su confirmación y cualquier entrada pendiente al duelo. Durante el combate se abre la pausa. Los dispositivos disponibles se comparten con la captura de controles de Opciones. Si se pierde el foco durante la transición del enfrentamiento, vuelve a selección. Al entrar al combate se exige soltar las entradas de menú antes de actuar.

## Dirección visual y respuesta

Papel cálido con fibras y luz suave, texto de tinta, tipografía serif para nombres y títulos y rojo discreto para foco y confirmación. El círculo se dibuja con trazos irregulares de pincel y una respiración lenta. El retrato tiene un pequeño desplazamiento de profundidad al mover el ratón; motas de tinta y lavados suaves completan el fondo. El título aparece por etapas.

Los botones responden al ratón, teclado y mando con un barrido de tinta, un desplazamiento de texto y una flecha. Sus zonas de clic permanecen quietas. El menú incluye un indicador que acompaña el foco y una descripción de la opción elegida. En selección, el círculo responde al cambio de personaje; el estado listo mantiene la confirmación resaltada y muestra un sello con marca de verificación.

La presentación recorre Tsukiyo → Ren → Daichi → Nao → Sayo en bucle. Cada retrato permanece 3,6 segundos y da paso al siguiente con un fundido y desplazamiento suave de 0,9 segundos. Nombre y arma acompañan al dibujo, sin marcas de paginación inferiores. El carrusel se detiene al salir de la presentación y continúa al volver; se puede entrar al menú durante cualquier transición. El menú conserva el personaje que estaba apareciendo en la presentación.

Los sonidos de interfaz son tonos de cuerda sintetizados como prototipos; pasan por SFX y Master y respetan silencio y volumen. No son la banda sonora final. La grabación de revisión no contiene audio.

Se reutilizan los maestros existentes. Tsukiyo utiliza ahora `art/characters/tsukiyo/ui-master.png`, una copia sin modificaciones del archivo de Jorge `Monochrome Samurai Warrior Sprite.png`. Sustituye en la interfaz la celda de animación de 444 × 444; el combate conserva sus animaciones. No se han regenerado los personajes. La tipografía se resuelve con fuentes del sistema y alternativas; su aspecto puede variar entre computadoras.

## Archivos y revisión

### Pausa y opciones · 17 de octubre de 2026

La pausa del duelo y las opciones comparten ahora el papel, la tinta, la tipografía serif y los acentos rojos del menú de entrada. La pausa se superpone al escenario oscurecido, muestra los personajes y el marcador actual y conserva sus cinco acciones. Una entrada breve y los botones de tinta animada dan respuesta sin desplazar las zonas de clic.

Opciones sustituye las pestañas nativas por navegación lateral de Pantalla, Sonido y Controles. Los selectores, interruptores, deslizadores, asignaciones y acciones inferiores usan la misma paleta. La sección activa permanece marcada, y el foco de teclado/ratón responde con el barrido de tinta. La confirmación de pantalla también se renovó y sigue aislando los controles de fondo durante los 12 segundos de prueba.

Se conservan la preescucha de audio, Guardar/Cancelar, restaurar una sección, la captura de teclas y botones y el regreso a la misma partida pausada. Se verificaron 35 comprobaciones de opciones y 74 del recorrido de interfaz; las capturas de pausa y las tres secciones se revisaron a 960 × 540. No se modificaron los efectos de combate.

[Pausa](art/reviews/interface-options/pausa.png) · [Pantalla](art/reviews/interface-options/pantalla.png) · [Sonido](art/reviews/interface-options/sonido.png) · [Controles](art/reviews/interface-options/controles.png) · [Confirmación](art/reviews/interface-options/confirmacion.png).

- `scripts/interface_style.gd`: materiales, tipografía y controles compartidos de los paneles.
- `scripts/pause_menu.gd`: composición y contexto de la pausa.
- `scripts/settings_menu.gd`: navegación lateral y opciones funcionales.
- `tools/preview_pause_settings.gd`: capturas reproducibles de ambas interfaces y la confirmación.

- `scripts/front_end.gd`: pantallas, navegación, selección, confirmación y transición.
- `scripts/ui_portrait.gd`: presentación de los dibujos existentes.
- `scripts/ui_sound.gd`: sonidos de navegación por el canal SFX.
- `scripts/ink_button.gd`: respuesta visual común de botones y tarjetas.
- `art/ui/paper.gdshader`: papel, fibras y luz del fondo.
- `scripts/main.gd`: integración con pausa, opciones, simulación y resultado.
- `tests/test_front_end.gd`: 74 comprobaciones del recorrido, carrusel completo, entrada real de teclado/clic de ratón, señal de hover simulada, mandos simulados, reasignaciones, desconexión, pérdida de foco, revancha y límites de los controles.
- `tools/preview_front_end.gd`: capturas de siete pantallas reales a 960 × 540; `-- --record` añade fotogramas para la vista previa.
- `tools/preview_title.gd`: captura un ciclo completo de la presentación rotativa a 960 × 540.
- `tools/preview_interface_v03.gd`: grabación de la presentación, navegación por las opciones y confirmación de personajes con eventos de teclado.

También pasan las pruebas de opciones (35), selección y personajes (5277), y carga hasta el duelo jugable. La navegación de mando se verifica con eventos simulados; falta la prueba física con dos mandos.

[Presentación](art/reviews/interfaz-presentacion.png) · [Selección](art/reviews/interfaz-seleccion.png) · [Recorrido en vídeo](art/reviews/interfaz-recorrido.mp4)

[Presentación con los cinco personajes](art/reviews/interfaz-presentacion-v02.mp4)

Revisión actual: [Presentación](art/reviews/interfaz-presentacion-v03.png) · [Menú](art/reviews/interfaz-menu-v03.png) · [Selección](art/reviews/interfaz-seleccion-v03.png) · [Navegación en vídeo](art/reviews/interfaz-v03.mp4).

El primer entorno ya está integrado; el siguiente bloque son las señales de impacto, esquiva y aterrizaje. El pulido completo de animaciones se mantiene para después.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
