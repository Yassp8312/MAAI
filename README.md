# MAAI · Laboratorio de combate 0.1

Base jugable local, creada el 15 de octubre de 2026 para probar distancia, compromiso y justicia. Incluye una primera animación de Tsukiyo, Ren, Daichi, Nao y Sayo, elegibles por separado para ambos jugadores. **Cada personaje tiene alcances, tiempos y movilidad propios: primera versión de sus técnicas, pendiente de equilibrio y pulido visual jugando.** La zona vulnerable baja al esquivar. La representación geométrica original sigue disponible desactivando `use_tsukiyo` en la escena de vista (nombre conservado por compatibilidad; controla todo el arte de personajes).

## Jugar

En esta computadora, haz doble clic en **Jugar.bat**. Usa **Abrir_en_Godot.bat** para editar. También puedes importar `project.godot` en Godot 4.2.1 y pulsar F5. Los lanzadores usan la instalación existente en `D:\Trabajo\Programas\Para juegos\godot`; para otra computadora, importa el proyecto desde su propio Godot.

El juego abre con una entrada breve y saltable de **Yassper Design**, seguida del **prólogo ilustrado con narración**, antes de la presentación. En el prólogo, **Espacio / A** pausa; **Esc / B** salta; **S / Y** alterna los subtítulos. Puedes repetirlo desde **Volver a ver el prólogo** en el menú y ajustar su voz en **Sonido → Narración**. [Montaje y música del prólogo](art/intro/README.md).

La presentación y los menús incorporan **Banda1 / Ink Duel**, aportada por Jorge, como primera prueba musical. Continúa entre menú, opciones y selección, repite con fundido y se desvanece al iniciar el duelo. Se controla desde **Sonido → Música**. [Preparación y comportamiento](art/music/README.md).

Los duelos alternan **Banda sonora2** y **Banda sonora 3** por partida o revancha. La pista continúa entre rondas, baja durante la pausa y deja espacio a armas e impactos. Entrenamiento utiliza **Ink Duel · Dojo**, una adaptación más pausada de Banda1, sin reinicios al repetir ejercicios. La galería mantiene ambiente y efectos. Todas las pistas respetan **Sonido → Música**.

Pulsa una tecla en la presentación y elige **Duelo local**. Cada jugador elige y confirma su personaje; al estar ambos listos se presenta el enfrentamiento y comienza el duelo. **Tab / Y** alterna mejor de 3 o de 5. La selección también permite elegir la arena.

**Entrenamiento** ofrece rival quieto o con acciones repetidas, respuesta de parry, secuencias, distancias configurables, grabación temporal de J2 y ejercicios guiados. **F3**, el botón visible o **Pausa → Ajustar entrenamiento** abre sus opciones; **R** reinicia. [Guía completa](ENTRENAMIENTO.md). No hay IA competitiva.

**Créditos** reúne el equipo, roles, colaboradores anónimos, fuentes de efectos, herramientas de IA y contacto para feedback. [Identidad de estudio e icono de aplicación](art/branding/README.md).

**Bloqueo preciso / parry:** pulsa cerca del impacto; mantener no protege. Incluye poses propias de defensa y arma rechazada para los cinco personajes, choque metálico y una oportunidad de respuesta al acertar. **E / J**, o **R3** en mando, reasignables. [Reglas, entrenamiento, animaciones y ajustes de ritmo](COMBATE_DEFENSA.md).

**Esc / Start → Técnicas de los personajes** muestra los seis ataques de cada luchador elegido y sus botones actuales. Nao entra con un paso de dagas, Ren avanza con sus cortes, Sayo cede espacio y Tsukiyo recupera pronto su estocada. Daichi conserva el alcance largo, con mayor recuperación al fallar. [Funciones, tiempos y prueba Nao–Daichi](TECNICAS_PERSONAJES.md). El parry mantiene sus reglas.

Para ver las animaciones sin manejar ambos jugadores, entra en **Galería de movimientos**, elige el personaje que quieres revisar en Jugador 1 y confirma ambos lados. **Ver_Tsukiyo.bat** sigue abriendo la demostración de Tsukiyo. El recorrido incluye guardia, pasos, seis ataques, sprint, esquiva y derrota; Esc abre la pausa. Ren, Daichi y Nao tienen 44 dibujos propios cada uno; Sayo tiene 40; Tsukiyo conserva su sprint delicado de seis poses. [Inventario, referencias y estado del elenco](art/characters/README.md). La sincronización temporal está implementada; el ajuste exacto de cada arma y las colisiones sigue pendiente.

| Acción | Jugador 1 | Jugador 2 | Mando de cada jugador |
|---|---|---|---|
| Mover / retroceder | A / D | Flechas izquierda / derecha | Stick izquierdo / cruceta |
| Saltar | W | Flecha arriba | A / botón inferior |
| Sprint | S + dirección | Flecha abajo + dirección | RB + dirección |
| Esquiva | Q | K | LB |
| Ataques 1 / 2 / 3 | F / G / H | U / I / O | X / Y / B |
| Bloqueo preciso / parry | E | J | R3 / pulsar stick derecho |

Sprint sin dirección avanza hacia el rival. Los tres ataques tienen variantes aéreas. El sprint y el salto mantienen la dirección inicial. Los mandos se asignan por el orden de dispositivos conectados; las letras corresponden a disposición Xbox. El soporte está implementado, pendiente de comprobar con dos mandos físicos. Algunos teclados limitan pulsaciones simultáneas; para pruebas competitivas usaremos dos mandos.

## Interfaz y selección

Presentación, menú, selección con retratos, transición al duelo y resultado con revancha ya están conectados. J1 elige con A/D, confirma con F y cancela con Q; J2 usa flechas izquierda/derecha, U y K. Las teclas siguen las reasignaciones de movimiento, ataque 1 y esquiva. En mando, stick/cruceta para elegir y A/B para confirmar/cancelar. También funciona el ratón.

La pausa permite volver a elegir personajes. La pantalla de resultado ofrece revancha, otra selección o menú. Los sonidos de interfaz respetan SFX y Master. [Diseño, controles y verificación de las interfaces](INTERFACES.md).

## Opciones

Hay tres arenas monocromas: **Patio de tinta**, **Santuario del bambú** y **Orilla del silencio**, además del laboratorio. Se eligen antes del encuentro o con **Esc / Start → Escenario** sin reiniciar la ronda. Comparten suelo y límites de combate; conservan sombras y animación ambiental. El viento respeta **Ambiente** y el silencio general. [Arte e integración](art/environments/monochrome/README.md).

Entra en **Opciones** desde el menú principal o pulsa **Esc / Start** durante el duelo para abrir la pausa. Volver de las opciones conserva la ronda y el marcador; pulsa **Continuar** para reanudar.

- **Pantalla:** resolución de ventana entre 960 × 540 y 3840 × 2160, pantalla completa y VSync. La ventana se limita al espacio disponible del monitor; pantalla completa usa su resolución nativa. El encuadre conserva la proporción 16:9. Al guardar un cambio de pantalla hay 12 segundos para confirmarlo; Esc, Revertir o agotar el tiempo recuperan la pantalla anterior.
- **Sonido:** volumen general, música, efectos, ambiente y narración, además de silenciar todo. Cada canal tiene un tono de prueba. Los niveles se preescuchan y Cancelar recupera los anteriores. El prólogo incluye la voz y **Ink Resolve A**, con volumen independiente para cada pista. El combate incluye pasos, ropa, armas, impactos y caídas propios de los cinco personajes, con variantes y control desde **Efectos**. [Perfiles sonoros y créditos CC0](art/audio/combat/README.md).
- **Controles:** selecciona jugador y pulsa la casilla que quieras cambiar. Admite teclas físicas y los siete botones de acción de cada mando; stick y cruceta mantienen el movimiento. Rechaza teclas duplicadas entre jugadores y botones duplicados dentro del mismo mando. Esc cancela una asignación. Esc, Espacio, R, F1, F2, Tab, Enter y las teclas modificadoras están reservadas. Start queda reservado para pausa. Las indicaciones del HUD se actualizan con el teclado elegido.

**Guardar y volver** conserva todas las secciones entre ejecuciones; **Cancelar** descarta lo pendiente. **Restaurar esta sección** devuelve sus valores iniciales (en Controles, los de ambos jugadores) y requiere guardar. Al volver al duelo, suelta los controles antes de actuar para evitar trasladar pulsaciones del menú a la partida.

Preferencias locales en `user://settings.cfg`, normalmente `%APPDATA%\Godot\app_userdata\MAAI\settings.cfg`. Una configuración inexistente o inválida recupera valores utilizables. Si no se puede escribir el archivo, se muestra el error y el panel permanece abierto.

Para incorporar audio, asigna cada `AudioStreamPlayer` al bus **Music**, **SFX** o **Ambience**, definidos en `default_bus_layout.tres`; todos pasan por **Master**. Así los futuros recursos respetarán los controles de volumen desde su integración. `scripts/game_settings.gd` gestiona preferencias y dispositivos; `scripts/settings_menu.gd` contiene la interfaz, sin modificar la simulación de combate.

| Herramienta de prueba | Tecla |
|---|---|
| Ver zonas de colisión, estado y ticks | F1 |
| Pausa / continuar | Espacio |
| Avanzar un paso de simulación | F2 |
| Repetir ronda; revancha al terminar partida | R |
| Abrir / cerrar menú de pausa y opciones | Esc / Start del mando |

Al perder el foco se abre la pausa: **Continuar**, Esc o Start reanudan. Espacio sigue disponible para la pausa rápida de depuración. R durante una partida conserva el marcador. F2 procesa un tick y las entradas pulsadas en ese momento. El HUD normal no muestra vida ni cronómetro.

## Qué probar primero

1. Jugar 10 rondas con estocada (ataque 1), caminata y sprint. Cada jugador explica por qué conectó el golpe.
2. Añadir salto y comprobar si se puede anticipar el aterrizaje. La dirección aérea no cambia.
3. Añadir ataques 2/3 y esquiva. Comprobar que cada técnica ofrece una decisión útil.
4. Activar F1 cuando un impacto resulte confuso. Anotar distancia, técnica y estado; repetir pausando con Espacio y avanzando con F2.
5. Intercambiar lados y controles. Si una ventaja cambia de jugador con el lado, investigar controles o lógica antes de tocar el equilibrio.

El primer criterio de aceptación es que ambos jugadores puedan explicar las muertes y castigar un fallo. Pasar pruebas automáticas no demuestra que el combate sea divertido ni esté equilibrado.

## Implementado

- Simulación a 60 Hz, independiente del dibujo y de los dispositivos de entrada.
- Caminar mirando al rival; salto con velocidad horizontal fijada al despegar.
- Sprint de recorrido fijo, limitado por arena/rival; cualquiera de los tres ataques puede interrumpirlo inmediatamente. El personaje planta los pies e inicia la preparación normal del golpe mirando al rival, incluso tras un sprint de retirada.
- Buffer breve: una pulsación reciente puede ejecutarse en el primer tick legal.
- Tres ataques terrestres y tres aéreos, con anticipación, tramo activo y finalización.
- Un contacto válido mata. Ambos impactos se evalúan antes de aplicar muertes: doble KO sin puntos.
- Esquiva con reducción de la zona vulnerable durante la pose baja, ventana invulnerable y registro de coincidencia precisa sin premio ofensivo.
- Alcances distintos por personaje para los seis ataques; perfiles independientes conservados entre rondas y revanchas.
- Gravedad después del KO: muerte aérea con aterrizaje antes de la pose tendida y del cambio de ronda.
- Detección continua entre volúmenes rectangulares activos para evitar atravesar al rival entre ticks.
- Rondas al mejor de 3/5, práctica, reinicio, pausa y depuración.
- Presentación y menú con retratos, selección independiente, confirmación/cancelación, transición al duelo y resultado con revancha.
- Opciones persistentes de pantalla, sonido y controles para ambos jugadores, accesibles desde inicio y pausa.
- Registro local de impactos en `user://duel_log.jsonl` (normalmente `%APPDATA%\Godot\app_userdata\MAAI`). No se envía a ningún servidor.
- Adaptador opcional de sprites con pivote y exposición de dibujos, separado de colisiones.
- Primeras animaciones de Tsukiyo, Ren, Daichi, Nao y Sayo conectadas a los estados del duelo, con selector independiente y demostración automática.

## Decisiones experimentales, no aprobaciones del diseño

Los valores están en `data/combat.tres`; los valores iniciales de movimiento se declaran en `scripts/combat_config.gd` y se pueden sobrescribir desde el Inspector del recurso.

| Parámetro | Hipótesis inicial |
|---|---|
| Caminata | 5 píxeles lógicos/tick (300/s) |
| Sprint | 260 píxeles en 18 ticks; se acorta al chocar |
| Salto | Velocidad vertical inicial -18; gravedad 0,65 por tick |
| Esquiva | 25 ticks; invulnerabilidad [3, 10); precisión [3, 5) |
| Buffer | 5 ticks contando el de pulsación; última orden sustituye anterior |
| Ataques aéreos | Máximo uno por salto; aterrizar conserva la acción en curso |
| Cruce del rival | No se permite, tampoco por encima en este primer bloque |
| Sprint / esquiva aéreos | No se permiten |
| Entradas simultáneas | Ataque 1 > 2 > 3 > esquiva > sprint > salto |
| Cierre de ronda | Mínimo 120 ticks; espera aterrizajes y al menos 21 ticks de derrota en suelo |
| Cámara | Encuadre fijo de laboratorio; seguimiento discreto pendiente |
| Colisiones | Cuerpo rectangular que baja al esquivar y bandas de arma con alcance por personaje |

Los ataques pueden cancelar el sprint desde su siguiente tick: al pulsar ataque se detiene el desplazamiento y comienza la preparación normal, sin esperar al final del sprint. Salto y esquiva conservan el buffer hasta que termine; no se han añadido cancelaciones de la recuperación de ataques. Desde neutral se permite caminar, saltar, atacar, esquivar o hacer sprint. En aire se conserva el desplazamiento inicial y se permite iniciar un ataque. Tras acabar una acción se procesa una orden aún vigente. Las ventanas se cuentan desde edad 0; el inicio activo del primer ataque es edad 9.

Las armas del prototipo muestran volúmenes de prueba, no trayectorias marciales definitivas. Una hurtbox rectangular todavía abarca espacios vacíos entre extremidades: habrá que desglosarla en zonas anatómicas y ajustar la geometría junto al arte. Los seis movimientos son de laboratorio; **no** son el kit aprobado de Tsukiyo.

## Alcance, esquiva y caída

Los recursos de [data/characters](data/characters/README.md) definen seis alcances y una altura de esquiva para cada personaje. El frontal alcanza como máximo 140 unidades con Nao, 160 con Sayo, 245 con Tsukiyo, 260 con Ren y 300 con Daichi, medidos desde su pivote. Son valores iniciales que aún requieren ajuste junto al arte, no balance final.

Pulsa F1: la caja del cuerpo baja durante los ticks [3, 10) de esquiva y vuelve a su tamaño al recuperarse. Los mismos ticks conservan invulnerabilidad; el inicio y la recuperación pueden ser castigados. El panel muestra altura del cuerpo y alcance máximo durante el ataque.

Un KO aéreo ya no congela al personaje: cae y comienza la secuencia tendida al aterrizar. El cierre de ronda espera también al otro combatiente si sigue en el aire. El resultado solo concede puntos una vez.

## Integrar el arte después

`combat_sim.gd` decide posiciones, estados e impactos. `fighter_view.gd` recibe esos datos y dibuja. `main.gd` coordina la partida, los menús y la entrada. Un cambio de dibujo no altera el alcance ni la velocidad.

`scripts/tsukiyo_animation.gd` ahora acepta un identificador de personaje (por defecto `tsukiyo`) y carga `art/characters/<id>/v01/atlas.json`, con caché independiente por personaje, pivotes por dibujo, escalas opcionales por pose y fases explícitas. El nombre del archivo se conserva por compatibilidad. `character_catalog.gd` ofrece únicamente personajes con un atlas integrado: los cinco personajes tienen su primera animación integrada. Para utilizar el adaptador genérico anterior, desactiva `use_tsukiyo` en `scenes/fighter_view.tscn` y asigna un recurso `SpriteFrames` a `sprite_frames`. Usa PNG transparentes con lienzo constante y pivote de pies común. `foot_anchor` admite el punto exacto del anclaje en píxeles de origen; por defecto utiliza el centro inferior. `sprite_height` controla la altura del lienzo en el mundo, sin escalar las colisiones.

Nombres actuales: `idle`, `walk`, `jump`, `sprint`, `dodge`, `dead`, y `TEST_GROUND_A1/A2/A3`, `TEST_AIR_A1/A2/A3`. La ausencia de una secuencia usa `idle`. Las exposiciones relativas de SpriteFrames se respetan; las secuencias de ataque se ajustan al total de ticks de su acción. Para producción habrá que alinear expresamente anticipación, contacto y finalización con sus fases, completar el retroceso propio de Tsukiyo y Sayo y asignar una vista/recurso por personaje. No basta con colocar cualquier animación sobre la simulación: deben coincidir poses, pivotes y recorridos de arma.

La separación evita reescribir el combate al cambiar dibujos; **la integración y revisión del arte siguen siendo necesarias**. No vamos a prometer que cualquier sprite funcione sin ajustes. El arte definitivo debe permitir distinguir a Ren, Daichi, Nao, Sayo y Tsukiyo por su locomoción.

## Siguiente iteración

[Hoja de ruta actualizada y criterios de revisión](PROXIMOS_PASOS.md): MVP local con entrenamiento, arenas monocromas, créditos, identidad y música integrada. Compilación Windows en `build/windows/MAAI.exe`, junto a `MAAI.pck`; se abre sin el editor. [Preparación y verificación](COMPILACION.md). Pendientes: revisión de Jorge y prueba con mandos en otro equipo. Después: documentación profesional, pruebas de combate, pulido de animaciones/diversión y LAN. El parry se conserva por petición de Jorge. Online/rollback necesita estudio técnico y pruebas propias: este prototipo no lo implementa ni demuestra determinismo entre plataformas.

Pendientes: pulir continuidad e intermedios del elenco, retroceso propio de Tsukiyo y Sayo, kits propios y ajuste preciso de trayectorias, balance humano, pruebas con mandos físicos, cámara final, hitboxes anatómicas y de armas, voces/sonido/música, escenarios y arte definitivos, online y exportación distribuible. El enlace de café se encuentra discretamente en el menú.

## Verificación reproducible

El repositorio conserva el código, los recursos utilizados por el juego, las fuentes/licencias de efectos y las capturas de documentación. Los vídeos de revisión, mezclas comparativas y experimentos externos se conservan solo localmente y están excluidos del commit; sus enlaces históricos requieren esos archivos locales. Las herramientas de `tools/` permiten regenerar las revisiones. La voz y la música utilizadas por el prólogo sí forman parte del proyecto versionado.

Desde esta carpeta, con el ejecutable de consola de Godot:

```powershell
& 'D:/Trabajo/Programas/Para juegos/godot/Godot_v4.2.1-stable_win64_console.exe' --headless --path . --script tests/test_combat.gd
& 'D:/Trabajo/Programas/Para juegos/godot/Godot_v4.2.1-stable_win64_console.exe' --headless --path . --script tests/test_scene.gd
& 'D:/Trabajo/Programas/Para juegos/godot/Godot_v4.2.1-stable_win64_console.exe' --headless --path . --script tests/test_settings.gd
& 'D:/Trabajo/Programas/Para juegos/godot/Godot_v4.2.1-stable_win64_console.exe' --headless --path . --script tests/test_tsukiyo.gd
& 'D:/Trabajo/Programas/Para juegos/godot/Godot_v4.2.1-stable_win64_console.exe' --headless --path . --script tests/test_characters.gd
& 'D:/Trabajo/Programas/Para juegos/godot/Godot_v4.2.1-stable_win64_console.exe' --headless --path . --script tests/test_combat_geometry.gd
& 'D:/Trabajo/Programas/Para juegos/godot/Godot_v4.2.1-stable_win64_console.exe' --headless --path . --script tests/test_front_end.gd
```

`test_combat.gd` cubre movimiento, límites, salto, sprint, buffer, fases, esquiva, simultaneidad, barridos, rondas y repetibilidad local. `test_scene.gd` carga la escena real y llega al duelo jugable. Los tests no sustituyen las sesiones de juego.

`test_characters.gd` recorre cada personaje disponible, ambos lados, todos los ticks de ataque, los otros estados, aislamiento y reutilización de caché, señales reales de los selectores, duelo mixto, espejo y demostración completa. `tools/preview_characters.gd -- <id>` captura el render del personaje a 30 FPS y un ataque mirando a la izquierda.

`test_settings.gd` usa un archivo temporal independiente para comprobar persistencia, datos inválidos, reasignación real de teclas, conflictos, audio, cancelación, confirmación de pantalla, errores de escritura y continuidad del duelo. Para revisar también ventana y pantalla completa, ejecútalo sin `--headless` y añade `-- --visual`; guarda capturas de los paneles en `tmp/`. Verificado el 16 de octubre de 2026: 31 comprobaciones de opciones sin renderizado y 34 con ventana real, sin fallos. La revisión visual incluye 1280 × 720 y 960 × 540. Pendiente validación con mandos físicos y otros monitores.

`test_tsukiyo.gd` comprueba los 46 dibujos conservados (44 en uso), las fases de los seis ataques y la independencia de la simulación. Incluye el sprint revisado de seis poses, sin repetición, en ambos lados: conserva los 260 píxeles y 18 ticks. Sin `--headless`, `-- --visual` recorre también la demostración y guarda capturas; `-- --visual --record` guarda 220 fotogramas de revisión en `tmp/tsukiyo-record` (10 FPS). La ejecución visual pasa 175 comprobaciones. `art/characters/tsukiyo/v01/sprint-v02-preview.mp4` permite revisar el sprint a velocidad real y en cámara lenta.

Verificado el 15 de octubre de 2026 con Godot 4.2.1: **38 comprobaciones de combate sin fallos**, carga de la escena hasta el duelo y revisión visual de menú, ataque activo y doble KO en el renderizador Compatibility. No se ha realizado todavía una sesión humana de balance ni una prueba con mandos físicos.

## Contexto consultado

Se revisaron los cinco PDF y se recorrió el chat **«Script Blender futurista»**, ID `6ad060fc-b450-83ea-9a38-42ef4dabcda0`, hasta el planteamiento inicial de MAAI. Algunos mensajes antiguos del asistente aparecen como referencias de contenido sin cuerpo recuperable; no se presume haber inspeccionado el código del prototipo eliminado. Los mensajes accesibles del usuario confirman Godot, salto comprometido, sprint, cinco personajes y la prioridad actual de desarrollar antes del arte.

- [GDD v0.1](../Documentacion%20P/MAAI_GDD_v0.1.pdf): reglas y etapas M1–M7; parámetros todavía sujetos a prueba.
- [Arte, volumen I](../Documentacion%20P/MAAI_Biblia_de_Arte_Volumen_I_v0.1.pdf): simulación separada del dibujo, tinta monocroma, rojo solo para sangre.
- [Narrativa v0.2](../Documentacion%20P/MAAI_Biblia_Narrativa_v0.2.pdf): cinco identidades; la escena de conversación Ren/Sayo requiere revisión silenciosa según decisión posterior.
- [Visión v0.1](../Documentacion%20P/MAAI_One_Vision_Statement_v0.1.pdf): permanece la referencia antigua a cuatro luchadores; prevalecen los cinco del GDD y biblias posteriores.
- [Sonido v0.2](../Documentacion%20P/MAAI_Guia_de_Sonido_y_Banda_Sonora_v0.2.pdf): silencio musical, ambiente y shakuhachi. El chat añade tratamiento mixto y el tema «Entre dos respiraciones»; la maqueta fue pedida de mejorar, no aceptada como definitiva.

También se confirmó en el chat la guardia «La luna inmóvil», silueta alta y esbelta de Tsukiyo y el rechazo a animar desplazando una ilustración completa como papel. Este bloque geométrico no sustituye ese trabajo artístico.

Referencias técnicas verificadas: [procesamiento físico de Godot 4.2](https://docs.godotengine.org/en/4.2/tutorials/scripting/idle_and_physics_processing.html) y [recursos editables](https://docs.godotengine.org/en/4.2/tutorials/scripting/resources.html).

[Un café para Jorge](https://jorge-coffee.onrender.com/)
