# MAAI · Entrenamiento funcional

Desde el menú, **Entrenamiento** permite elegir ambos personajes y la arena. J1 es quien practica y J2 puede ser un rival automático o un segundo jugador. Las reglas, colisiones y tiempos son los mismos que en el duelo; el parry no se ha cambiado.

## Preparar una situación

**F3**, el botón visible «Entrenamiento» o **Pausa → Ajustar entrenamiento** abre los ajustes y detiene el combate. Si F3 está asignada a una acción en tus controles, esa asignación tiene prioridad; usa la pausa o el ratón.

- **Conducta:** control libre de J2, quieto, repetir un ataque, responder con parry, repetir esquiva, repetir salto, secuencia de tres ataques o reproducir grabación.
- **Ataque:** cualquiera de los tres de suelo del personaje elegido.
- **Distancia:** 110, 220, 335 o 440 unidades entre centros. Son posiciones de práctica, no un indicador universal de alcance seguro: cada técnica puede avanzar.
- **Intervalo:** 60, 100 o 160 ticks entre intentos. Espera a estar libre para la siguiente acción.
- **Secuencia:** tres ataques seleccionables, en orden y con el intervalo elegido. Se repite.
- **Repetir después del KO:** activado por defecto. Espera a que ambos aterricen y completa el cierre de ronda antes de recolocar. Desactivado, conserva la derrota para observarla.
- **Información:** distancia actual, fase de ambos luchadores, golpes, desvíos, golpes recibidos y aciertos del ejercicio. F1 conserva las cajas de colisión opcionales.

**Aplicar y entrenar** recoloca inmediatamente. **R** repite desde las posiciones configuradas. Cerrar los ajustes sin aplicar vuelve a la pausa. Cambiar de arena conserva la pelea. Elegir personajes o iniciar otra sesión limpia los contadores y la grabación.

## Ejercicios

**Castigar el fallo:** selecciona explícitamente Nao contra Daichi, a 335 unidades. Daichi repite su punta. Espera a que falle, acércate y entra con las dagas durante su recuperación. El contador de ejercicio solo aumenta ante un golpe real de Nao durante esa recuperación; no por pulsar un botón.

**Practicar el parry:** conserva tus personajes y coloca al rival a una distancia alcanzable. Repite la punta y cuenta los desvíos confirmados de J1. Mantener el botón no protege.

**Rival que responde con parry:** es una conducta deliberadamente previsible de práctica que consulta la preparación del ataque de J1. Emite la misma pulsación que un jugador; no añade invulnerabilidad, no mantiene guardia y puede fallar por distancia o por estar ocupado. No representa una IA competitiva ni un tiempo de reacción humano.

## Grabación

«Grabar J2» reinicia y captura sus entradas de teclado/mando durante hasta cinco segundos de simulación. Puedes detenerla con F3; un KO también cierra la toma. Elige «Reproducir la grabación» para practicar como J1 contra esa secuencia. Conserva la distancia original de grabación y, al acabar, deja un segundo antes de repetir desde el inicio.

La grabación es temporal, vive en la sesión y corresponde al par de personajes con que se hizo. No se presenta como una repetición de partida completa ni sustituye el trabajo de red. Una secuencia puede producir otro resultado si J1 cambia su respuesta: se reproducen entradas, no se fuerzan posiciones o impactos.

## Música

Suena **Ink Duel · Dojo**, una adaptación de Banda1: tramo de 12 a 96 segundos, tempo un 6 % más lento sin cambiar la afinación, graves y agudos suavizados y un eco corto discreto. La versión dura unos 89,5 segundos y repite con un fundido cruzado de tres segundos. No se separaron instrumentos ni se modificó el MP3 original.

Respeta Música y General; baja al pausar y deja espacio a armas e impactos con una reducción breve de 2 dB. Recolocar, repetir un ejercicio o cambiar sus ajustes no reinicia la pieza. No consume la alternancia de música de duelo. La valoración artística de la adaptación y del empalme queda para la escucha de Jorge.

Referencia opcional para una futura pista de Suno; no es necesaria para esta entrega:

> Instrumental soundtrack for a monochrome Japanese sword-fighting training dojo. Calm focus, quiet determination, 78 BPM. Warm low strings, restrained shakuhachi phrases, sparse koto, soft wooden percussion and a subtle steady pulse. Full, expressive acoustic arrangement, never thin or ambient-only. No vocals, choir, epic drops, sudden crescendos or sharp percussion. Leave space for footsteps, blade swishes and metal clashes. Consistent dynamics, understated melody, seamless-loop-friendly beginning and ending, about 3 minutes.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
