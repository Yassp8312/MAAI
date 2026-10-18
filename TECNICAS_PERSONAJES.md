# MAAI · Primera diferenciación del elenco

18 de octubre de 2026. Primera versión para probar decisiones distintas con los cinco personajes. El parry conserva ventana, recuperaciones, condiciones y controles. No es un equilibrio definitivo.

## Cómo probarlo

Entra en duelo o práctica y abre **Esc / Start → Técnicas de los personajes**. La guía muestra los seis movimientos de los dos personajes elegidos con las teclas y botones configurados. Cerrar la guía vuelve a la pausa, sin avanzar la pelea.

Por defecto, J1 ataca con **F/G/H** y J2 con **U/I/O**; mando **X/Y/B**. Los mismos botones en el aire eligen las tres variantes aéreas. Atacar durante el sprint sigue funcionando: detiene el sprint e inicia la preparación normal, incluido el paso propio de esa técnica.

| Personaje | Decisión principal | Riesgo |
|---|---|---|
| Tsukiyo | Medir a media distancia y responder con una estocada de recuperación breve | No gana terreno al atacar; el corte bajo exige anticipación |
| Ren | Ganar terreno con la estocada y el barrido | Acerca su cuerpo y tarda más en recoger el arma |
| Daichi | Interceptar entradas y controlar la distancia larga | Camina más lento y deja una recuperación larga al fallar |
| Nao | Provocar un fallo, entrar y castigar de cerca | El paso no es invulnerable; entrar contra una punta preparada pierde |
| Sayo | Alternar un toque rápido, arcos duraderos y retirada | Alcance corto; retirarse demasiado hace fallar el corte |

Cada personaje dispone de punta frontal, ataque que cubre hacia arriba y corte bajo, con variantes aéreas. Los nombres y la función concreta de los treinta ataques están en la guía y en `data/characters/*.tres`. La geometría vertical sigue siendo provisional; no se añaden defensas altas/bajas nuevas.

## Preparación / actividad / recuperación

Valores en ticks a 60 Hz. Por ejemplo, **15/4/30** significa que el ataque empieza a golpear a los 0,25 segundos, tiene cuatro ticks activos y después treinta de recuperación. Las recuperaciones se aplican al ataque normal; un parry confirmado interrumpe la técnica y usa las reglas de rechazo ya existentes. Un contacto letal termina el intercambio.

| Personaje | Suelo 1 | Suelo 2 | Suelo 3 | Aire 1 | Aire 2 | Aire 3 |
|---|---|---|---|---|---|---|
| Tsukiyo | 9/4/11 | 8/4/15 | 14/5/18 | 8/4/12 | 10/5/15 | 13/5/18 |
| Ren | 12/4/21 | 10/5/18 | 17/6/25 | 10/4/17 | 13/6/20 | 16/5/23 |
| Daichi | 15/4/30 | 12/5/24 | 20/7/32 | 13/4/24 | 16/6/28 | 18/5/30 |
| Nao | 10/3/18 | 7/4/13 | 6/3/12 | 7/3/10 | 8/4/12 | 10/4/15 |
| Sayo | 8/4/10 | 10/7/17 | 13/5/17 | 8/4/12 | 10/6/15 | 12/5/18 |

| Personaje | Caminar, px/tick | Sprint, px en 18 ticks | Paso propio del ataque |
|---|---:|---:|---|
| Tsukiyo | 5,0 | 260 | Sin paso |
| Ren | 4,8 | 249,6 | Suelo 1: +38; suelo 3: +20 |
| Daichi | 4,3 | 228,8 | Sin paso |
| Nao | 6,2 | 286 | Suelo 1: +84 |
| Sayo | 5,4 | 265,2 | Suelo 3: −24, retirada |

Son píxeles del mundo lógico. El paso se desarrolla durante la preparación, tras dos ticks de apoyo, y termina en el primer tick activo. No continúa en recuperación ni después de ser rechazado. Respeta cuerpos, límites y orientación inicial; no permite atravesar al rival. Las variantes aéreas conservan la trayectoria del salto. El alcance local del arma sigue separado del desplazamiento corporal.

## Nao contra Daichi

Dos situaciones repetibles, verificadas intercambiando lados:

1. Desde 335 unidades entre centros, la estocada de Daichi falla. Cuando acaba su actividad, Nao puede caminar 16 ticks hacia él y usar Entrada de dagas para alcanzar durante su recuperación.
2. Desde 285 unidades, si ambos lanzan su primer ataque a la vez, Daichi intercepta la entrada. Nao necesita preparar la aproximación; no obtiene inmunidad por atacar.

A corta distancia, Corte al apoyo de Nao sale en seis ticks y permite castigar antes que su entrada. La ventaja no equivale a una garantía contra cualquier respuesta: todavía cuentan el alcance, la anticipación, la esquiva y el parry.

## Animación, audio y verificación

Se reutilizan los dibujos existentes, distribuidos según las fases reales de cada técnica. Los sonidos de arma se disparan al comenzar su actividad y los pasos al caminar siguen la cadencia propia. No se generó arte nuevo: el pulido de pies, poses y correspondencia exacta del filo sigue pendiente.

`tests/test_character_kits.gd` verifica las treinta técnicas en ambos lados, compromiso, actividad, poses, desplazamiento, límites, parry sin cambios y guía durante la pausa. Las pruebas de combate, geometría, personajes, parry, sonido, opciones e interfaz comprueban regresiones. `tools/preview_character_kits.gd` graba intercambios reales y revisa sus resultados y la disposición de la guía en el renderizador nativo.

Para afinar jugando: observar si Nao logra entrar con suficiente frecuencia, si Daichi puede mantener distancia sin dominar ni sentirse torpe, si Ren justifica su compromiso y si Sayo aprovecha la retirada. Comparar también con Tsukiyo. Las pruebas automáticas no demuestran diversión ni equilibrio entre todos los enfrentamientos.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
