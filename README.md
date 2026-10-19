# MAAI

**La distancia entre la vida y la muerte.**

MAAI es un prototipo de combate 2D que desarrollo junto a Jesus Luis Perez Martinez bajo el nombre de **Yassper Design**. Soy Jorge Ricardo Cintra Rad, Game Designer del proyecto. Mi intención es crear duelos donde leer al rival, medir la distancia y elegir cuándo comprometer un ataque importe tanto como reaccionar a tiempo.

La estética parte de la tinta y los escenarios monocromos. Quiero que el arte y el combate se apoyen entre sí: que cada personaje tenga una identidad reconocible y que una derrota se pueda entender, aprender y responder en el siguiente duelo.

## Estado del proyecto

La versión actual es el **prototipo local 0.2.1 para Windows**, desarrollado con **Godot 4.2.1**, renderizador Compatibility. Es una base en evolución: las animaciones, los contactos y el equilibrio todavía necesitan pruebas y pulido. No lo presento como un juego terminado ni como una experiencia competitiva ya validada.

El prototipo reúne cinco personajes —**Tsukiyo, Ren, Daichi, Nao y Sayo**— con alcances, tiempos y movilidad propios; duelos locales para dos jugadores; entrenamiento; tres arenas monocromas; y un prólogo ilustrado con narración. La presentación, selección de personajes, resultados, pausa, opciones, créditos y música están integrados.

**LAN y juego por Internet todavía no están implementados.** El entrenamiento permite practicar contra conductas configurables; no incluye una IA competitiva.

## Cómo jugar

### Compilación para Windows

Cuando tengas el paquete `MAAI-MVP-Windows-v0.2.1.zip`, extráelo completo y abre `MAAI/MAAI.exe`. Mantén `MAAI.exe` y `MAAI.pck` en la misma carpeta. No necesitas instalar Godot.

Los ejecutables y paquetes de `build/` se conservan fuera de Git: **clonar este repositorio no descarga una compilación**. [Instrucciones de exportación y verificaciones](COMPILACION.md).

### Desde el código fuente

1. Clona este repositorio.
2. Abre Godot **4.2.1** e importa `project.godot`.
3. Espera a que termine la importación de recursos y pulsa **F5**.

`Jugar.bat`, `Abrir_en_Godot.bat` y `Ver_Tsukiyo.bat` son accesos para mi instalación local. Si estás en otro equipo, usa el editor o ajusta la ruta de Godot indicada en esos archivos.

Elige **Duelo local**, confirma un personaje por jugador y selecciona una arena. Puedes alternar partidas al mejor de tres o de cinco. Desde el resultado puedes pedir revancha, volver a elegir personajes o regresar al menú.

## Controles iniciales

Las teclas y los botones de acción se pueden reasignar en **Opciones → Controles**.

| Acción | Jugador 1 | Jugador 2 | Mando |
| --- | --- | --- | --- |
| Movimiento | A / D | Flechas izquierda / derecha | Stick izquierdo / cruceta |
| Salto | W | Flecha arriba | A |
| Sprint | S + dirección | Flecha abajo + dirección | RB + dirección |
| Esquiva | Q | K | LB |
| Ataques 1 / 2 / 3 | F / G / H | U / I / O | X / Y / B |
| Parry | E | J | R3 |
| Pausa y opciones | Esc | Esc | Start |

Las letras del mando corresponden a la disposición Xbox. Los mandos se asignan por orden de conexión. La prueba con dos mandos físicos y en otro equipo sigue pendiente; algunos teclados pueden limitar las pulsaciones simultáneas.

En la selección, J1 confirma con **F** y cancela con **Q**; J2 confirma con **U** y cancela con **K**. Estas acciones siguen las reasignaciones. También se puede usar el ratón o A/B en mando.

## Cómo funciona el combate

Un golpe válido decide la ronda. La distancia, la preparación del ataque y la recuperación dejan oportunidades para entrar, interceptar o castigar un fallo. Cada personaje tiene tres ataques terrestres y tres aéreos.

- Puedes atacar durante el sprint: se detiene el desplazamiento y empieza la preparación normal del golpe.
- El **parry es una defensa precisa**: debes pulsar cerca del impacto; mantener el botón no protege. Un acierto rechaza el arma del rival y abre una oportunidad de respuesta.
- La esquiva reduce la zona vulnerable y tiene una ventana breve de invulnerabilidad. Su inicio y recuperación pueden castigarse.
- El salto compromete la dirección inicial. Si un personaje muere en el aire, cae antes de quedar tendido y cerrar la ronda.

Las reglas y los tiempos actuales están documentados en [Defensa y parry](COMBATE_DEFENSA.md), [Técnicas de los personajes](TECNICAS_PERSONAJES.md) y [Perfiles de combate](data/characters/README.md). Son valores de trabajo, no equilibrio definitivo.

## Entrenamiento y opciones

**Entrenamiento** permite configurar un rival quieto o repetidor, distancias, respuestas de parry, secuencias y ejercicios guiados. También admite grabación temporal de entradas de J2. **F3** abre sus ajustes y **R** reinicia. [Guía de entrenamiento](ENTRENAMIENTO.md).

**Galería de movimientos** permite revisar las animaciones sin controlar a ambos jugadores.

En **Opciones** puedes ajustar resolución, pantalla completa, VSync, controles y volumen de música, efectos, ambiente y narración. Los cambios de pantalla requieren confirmación y se revierten si no respondes. Los ajustes se guardan localmente en `user://settings.cfg`.

Durante el prólogo, **Espacio / A** pausa, **Esc / B** salta y **S / Y** activa o desactiva subtítulos. Puedes repetirlo desde el menú.

## Lo que viene después

Quiero dedicar la siguiente etapa a jugar, recoger feedback y mejorar la sensación del combate. Las prioridades son:

1. Probar el prototipo en otros equipos y con mandos físicos.
2. Pulir animaciones, contactos, desplazamientos y claridad de los ataques.
3. Ajustar las diferencias entre personajes a partir de partidas reales.
4. Consolidar la documentación de diseño, arte, narrativa y sonido.
5. Desarrollar LAN y comprobar la sincronización en dos equipos.

El icono de la barra de tareas sigue apareciendo genérico en mi equipo y queda pendiente de revisión. El tráiler también queda pendiente: los montajes de prueba no forman parte de esta entrega.

[Hoja de ruta detallada](PROXIMOS_PASOS.md).

## Desarrollo y comprobaciones

La simulación funciona a **60 ticks por segundo**, separada del dibujo y de la entrada. Esta separación permite revisar las reglas y sustituir animaciones, aunque cada cambio de arte necesita comprobar pivotes, tiempos y recorridos de las armas.

| Carpeta | Contenido |
| --- | --- |
| `scripts/` | Simulación, personajes, menús, ajustes y audio |
| `scenes/` | Escenas de Godot |
| `data/` | Configuración y perfiles de personajes |
| `art/` | Recursos visuales, música, efectos y documentación de procedencia |
| `tests/` | Pruebas automáticas del combate y la integración |
| `tools/` | Herramientas de preparación y revisión |

Para ejecutar las pruebas desde PowerShell, sustituye la ruta por la de tu ejecutable de consola de Godot 4.2.1:

```powershell
$maaiGodot = 'C:/ruta/a/Godot_v4.2.1-stable_win64_console.exe'
& $maaiGodot --headless --editor --path . --quit
Get-ChildItem tests/test_*.gd | Sort-Object Name | ForEach-Object {
    & $maaiGodot --headless --path . --script ('tests/' + $_.Name)
    if ($LASTEXITCODE -ne 0) { throw "Falló $($_.Name)" }
}
```

Las pruebas cubren combate, geometría, técnicas, personajes, defensa, escena principal, interfaces, ajustes, entrenamiento y audio. No sustituyen las partidas con personas ni demuestran equilibrio competitivo o sincronización de red.

Última revisión, **19 de octubre de 2026**, con Godot 4.2.1: **19 795 comprobaciones sin fallos**, más la carga de la escena principal hasta el combate jugable; 16 suites en total, ejecutadas sin ventana.

Herramientas de depuración durante el duelo: **F1** muestra colisiones, **Espacio** pausa, **F2** avanza un tick y **R** reinicia la ronda. El registro de impactos queda localmente en `user://duel_log.jsonl`; no se envía a un servidor.

Las compilaciones, cachés, archivos temporales y vídeos de revisión se excluyen de Git. Algunas referencias históricas de la documentación apuntan a material conservado solo en mi equipo.

## Equipo y recursos

**Jorge Ricardo Cintra Rad:** Game Designer, dirección creativa, programación, diseño de interfaces, narrativa, dirección de arte y concepto y dirección de la composición musical.

**Jesus Luis Perez Martinez:** programación, sistemas de juego, integración técnica, herramientas y revisión técnica; producción y desarrollo en colaboración.

También recibimos aportes de colaboradores que prefieren permanecer anónimos, entre ellos contribuciones a la ilustración. Los créditos completos están disponibles dentro del juego.

La música se generó con **Suno** y la narración con **ElevenLabs**. Los efectos parten de recursos CC0 de Kenney, StarNinjas, Vehicle / Jan Schupke y artisticdude. Conservamos sus fuentes y avisos en la [documentación de audio](art/audio/combat/README.md); esa licencia corresponde a esos efectos, no al conjunto del juego.

Más información: [música](art/music/README.md), [prólogo](art/intro/README.md), [personajes](art/characters/README.md), [arenas](art/environments/monochrome/README.md) e [interfaces](INTERFACES.md).

## Feedback

Puedes escribirme a **[jorgecintra2@gmail.com](mailto:jorgecintra2@gmail.com)**. Me ayuda saber qué personajes usaste, qué ocurrió y qué esperabas que ocurriera. Si puedes acompañarlo de un vídeo corto o pasos para repetirlo, mejor.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
