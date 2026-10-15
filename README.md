# MAAI · Laboratorio de combate 0.1

Primera base jugable local, creada el 15 de octubre de 2026 para probar distancia, compromiso y justicia antes de producir el arte. Dos figuras geométricas comparten seis técnicas experimentales. **No representan los personajes ni sus animaciones definitivas.**

## Jugar

En esta computadora, haz doble clic en **Jugar.bat**. Usa **Abrir_en_Godot.bat** para editar. También puedes importar `project.godot` en Godot 4.2.1 y pulsar F5. Los lanzadores usan la instalación existente en `D:\Trabajo\Programas\Para juegos\godot`; para otra computadora, importa el proyecto desde su propio Godot.

Selecciona mejor de 3 o de 5 y pulsa **Entrar al dojo**. Práctica libre permite repetir duelos sin acumular puntos. Necesitas dos personas para evaluar el combate: no hay IA.

| Acción | Jugador 1 | Jugador 2 | Mando de cada jugador |
|---|---|---|---|
| Mover / retroceder | A / D | Flechas izquierda / derecha | Stick izquierdo / cruceta |
| Saltar | W | Flecha arriba | A / botón inferior |
| Sprint | S + dirección | Flecha abajo + dirección | RB + dirección |
| Esquiva | Q | K | LB |
| Ataques 1 / 2 / 3 | F / G / H | U / I / O | X / Y / B |

Sprint sin dirección avanza hacia el rival. Los tres ataques tienen variantes aéreas. El sprint y el salto mantienen la dirección inicial. Los mandos se asignan por el orden de dispositivos conectados; las letras corresponden a disposición Xbox. El soporte está implementado, pendiente de comprobar con dos mandos físicos. Algunos teclados limitan pulsaciones simultáneas; para pruebas competitivas usaremos dos mandos.

| Herramienta de prueba | Tecla |
|---|---|
| Ver zonas de colisión, estado y ticks | F1 |
| Pausa / continuar | Espacio |
| Avanzar un paso de simulación | F2 |
| Repetir ronda; revancha al terminar partida | R |
| Volver al menú | Esc |

Al perder el foco se pausa: Espacio continúa. R durante una partida conserva el marcador. F2 procesa un tick y las entradas pulsadas en ese momento. El HUD normal no muestra vida ni cronómetro.

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
- Sprint de recorrido fijo, limitado por arena/rival; no cancela hacia ataque.
- Buffer breve: una pulsación reciente puede ejecutarse en el primer tick legal.
- Tres ataques terrestres y tres aéreos, con anticipación, tramo activo y finalización.
- Un contacto válido mata. Ambos impactos se evalúan antes de aplicar muertes: doble KO sin puntos.
- Esquiva con ventana invulnerable y registro de coincidencia precisa sin premio ofensivo.
- Detección continua entre volúmenes rectangulares activos para evitar atravesar al rival entre ticks.
- Rondas al mejor de 3/5, práctica, reinicio, pausa y depuración.
- Registro local de impactos en `user://duel_log.jsonl` (normalmente `%APPDATA%\Godot\app_userdata\MAAI`). No se envía a ningún servidor.
- Adaptador opcional de sprites con pivote y exposición de dibujos, separado de colisiones.

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
| Cierre de ronda | 120 ticks / 2 segundos |
| Cámara | Encuadre fijo de laboratorio; seguimiento discreto pendiente |
| Colisiones | Cuerpo rectangular simplificado y bandas rectangulares de arma |

Durante una acción comprometida no se cancela. Desde neutral se permite caminar, saltar, atacar, esquivar o hacer sprint. En aire se conserva el desplazamiento inicial y se permite iniciar un ataque. Tras acabar una acción se procesa una orden aún vigente. Las ventanas se cuentan desde edad 0; el inicio activo del primer ataque es edad 9.

Las armas del prototipo muestran volúmenes de prueba, no trayectorias marciales definitivas. Una hurtbox rectangular todavía abarca espacios vacíos entre extremidades: habrá que desglosarla en zonas anatómicas y ajustar la geometría junto al arte. Los seis movimientos son de laboratorio; **no** son el kit aprobado de Tsukiyo.

## Integrar el arte después

`combat_sim.gd` decide posiciones, estados e impactos. `fighter_view.gd` recibe esos datos y dibuja. `main.gd` coordina la partida, los menús y la entrada. Un cambio de dibujo no altera el alcance ni la velocidad.

En `scenes/fighter_view.tscn`, asigna un recurso `SpriteFrames` a `sprite_frames`. Usa PNG transparentes con lienzo constante y pivote de pies común. `foot_anchor` admite el punto exacto del anclaje en píxeles de origen; por defecto utiliza el centro inferior. `sprite_height` controla la altura del lienzo en el mundo, sin escalar las colisiones.

Nombres actuales: `idle`, `walk`, `jump`, `sprint`, `dodge`, `dead`, y `TEST_GROUND_A1/A2/A3`, `TEST_AIR_A1/A2/A3`. La ausencia de una secuencia usa `idle`. Las exposiciones relativas de SpriteFrames se respetan; las secuencias de ataque se ajustan al total de ticks de su acción. Para producción habrá que alinear expresamente anticipación, contacto y finalización con sus fases, añadir retroceso distinto de avance y asignar una vista/recurso por personaje. No basta con colocar cualquier animación sobre la simulación: deben coincidir poses, pivotes y recorridos de arma.

La separación evita reescribir el combate al cambiar dibujos; **la integración y revisión del arte siguen siendo necesarias**. No vamos a prometer que cualquier sprite funcione sin ajustes. El arte definitivo debe permitir distinguir a Ren, Daichi, Nao, Sayo y Tsukiyo por su locomoción.

## Siguiente iteración

Primero validar este duelo simétrico con dos personas. Después introducir dos armas realmente diferentes (propuesta: espada y yari), medir los enfrentamientos y consolidar P01–P04 del GDD. Luego ampliar los cinco kits, sustituir figuras por dibujos revisados e integrar sonido. Online/rollback necesita un estudio técnico y pruebas propias: este prototipo no lo implementa ni demuestra determinismo entre plataformas.

Pendientes: balance humano, controles reconfigurables, pruebas con mandos físicos, cámara final, hitboxes anatómicas y de espada, voces/sonido/música, escenarios y arte definitivos, selector del elenco, online y exportación distribuible. El enlace de café se encuentra discretamente en el menú.

## Verificación reproducible

Desde esta carpeta, con el ejecutable de consola de Godot:

```powershell
& 'D:/Trabajo/Programas/Para juegos/godot/Godot_v4.2.1-stable_win64_console.exe' --headless --path . --script tests/test_combat.gd
& 'D:/Trabajo/Programas/Para juegos/godot/Godot_v4.2.1-stable_win64_console.exe' --headless --path . --script tests/test_scene.gd
```

`test_combat.gd` cubre movimiento, límites, salto, sprint, buffer, fases, esquiva, simultaneidad, barridos, rondas y repetibilidad local. `test_scene.gd` carga la escena real y llega al duelo jugable. Los tests no sustituyen las sesiones de juego.

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
