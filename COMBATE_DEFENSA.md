# MAAI · Bloqueo preciso, reacción y ritmo

Primera versión jugable, 17 de octubre de 2026. Jorge pidió que el bloqueo funcione solo al recibir el ataque: **mantener el botón no protege**. Bloqueo preciso y parry son una sola acción.

## Controles y práctica

- Jugador 1: **E**. Jugador 2: **J**. Mando: **R3**, pulsar stick derecho. Reasignables en Opciones → Controles.
- Las preferencias antiguas mantienen sus ocho teclas/seis botones. La migración busca una asignación libre para la nueva acción si E, J o R3 ya estaban usados.
- En Entrenamiento, el botón visible, **F3** o **Pausa → Ajustar entrenamiento** abre conductas, distancias y ejercicios. «Practicar el parry» conserva los personajes y configura una punta repetida. **R** recoloca y reinicia. Si F3 ya está asignada a una acción, se respeta esa asignación; usar la pausa o el botón visible.
- El rival espera antes de repetir y se detiene durante la pausa. No persigue ni adapta su estrategia. Grabación, secuencias y otras conductas están descritas en [Entrenamiento](ENTRENAMIENTO.md). La música de práctica es Ink Duel · Dojo, adaptada de Banda1.

## Reglas actuales

- Pulsación nueva; activa desde ese mismo tick durante **9 ticks (0,15 segundos)** a 60 Hz. La versión inicial de 6 ticks se amplió tras la observación de Jorge sobre dificultad.
- En tierra, protege del frente ante los tres ataques de suelo y ataques aéreos que realmente alcancen. No es invulnerabilidad general, no cubre detrás y no puede iniciarse en el aire.
- Se puede plantar un sprint en parry. No cancela ataques ni esquivas, no se guarda para activarse al acabar una acción o aterrizar. Parry tiene prioridad si se pulsan defensa y ataque a la vez.
- Fallar deja **20 ticks totales** de compromiso; los últimos 11 ya no protegen. Mantener no repite. Pulsar otra vez durante ese compromiso tampoco lo reinicia.
- Acierto: termina el ataque rival, evita el KO, genera un único contacto y cambia ambos estados. El defensor se libera a los **6 ticks** del contacto y el atacante a los **18**. Esa oportunidad puede castigarse si el contraataque alcanza; distancia y elección siguen contando.
- En práctica se indica cuando un golpe entró porque ya había expirado la ventana. No se diagnostica «tarde» sin evidencia de una pulsación.
- Ventana, recuperación de fallo, recuperación de éxito y rechazo están en `scripts/combat_config.gd`. Son parámetros de prueba, no equilibrio definitivo.

## Animaciones y sonido

Cada personaje tiene una hoja `art/characters/<id>/v01/07-defence.png`, con entrada/desvío y reacción propia al arma rechazada. Las poses de reacción solo se activan ante un parry confirmado por la simulación. El movimiento aéreo conserva gravedad. El desvío añade un destello breve en el punto de contacto y un aviso visual; no depende solo del audio.

PNG generados con la herramienta integrada **image_gen**, usando los maestros existentes como referencias. Prompts completos en `art/characters/defence-prompts.json`. Se conserva transparencia; `defence.json` registra contornos, pies y escala sin alterar píxeles. No se usan los dibujos ambiguos: en Nao se descarta el cel de hoja extra y se selecciona la pose limpia de dos dagas. Los dibujos anteriores permanecen intactos.

Quince efectos de parry, tres por personaje, preparados con las fuentes CC0 ya conservadas en el proyecto. Metal predominante, variaciones por arma y capas de asta/abanico donde corresponde; no usan impactos corporales. Recetas, fuentes y hashes en `art/audio/combat/parry-manifest.json`. Se reproducen por SFX y atenúan brevemente la música como los impactos importantes.

## Ritmo

El cierre de ronda pasa de 120 a **72 ticks** y la cuenta previa de 90 a **54 ticks**. La simulación sigue esperando a que los derrotados aterricen y completen el mínimo de caída.

La primera revisión redujo la recuperación compartida de ataques en tierra a **11/14/16 ticks** y en aire a **12/15/16**. Esa base ahora se sustituye por los tiempos propios de cada personaje, descritos en [Técnicas de los personajes](TECNICAS_PERSONAJES.md). La diferenciación conserva las reglas y los tiempos del parry descritos arriba, así como la condición de un golpe decisivo. La posibilidad de contraatacar tras desviar depende también de la técnica elegida y la distancia.

La prueba humana debe comprobar claridad del contacto, respuesta al control, facilidad de aprender el parry y oportunidades tras acertar/fallar. Las pruebas automáticas verifican reglas y regresiones, no que sea divertido ni equilibrado.

## Reproducir y verificar

```text
python tools/build_parry_sfx.py --ffmpeg RUTA_A_FFMPEG
godot --headless --path . --script tools/build_defence_atlas.gd
godot --headless --path . --editor
godot --headless --path . --script tests/test_parry.gd
godot --path . --script tools/preview_parry.gd --write-movie tmp/parry.avi --fixed-fps 30
```

[Un café para Jorge](https://jorge-coffee.onrender.com/)
