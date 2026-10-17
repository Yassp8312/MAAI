# Perfiles iniciales de combate

Los recursos de esta carpeta modifican la geometría del combate, no los píxeles del personaje. Cada selección se aplica tanto a la vista como a la simulación y se conserva entre rondas y revanchas. Los recursos de ataque compartidos no se modifican en ejecución.

| Personaje | Frontal | Ascendente | Bajo | Aéreo 1 | Aéreo 2 | Aéreo 3 | Altura al esquivar |
|---|---:|---:|---:|---:|---:|---:|---:|
| Tsukiyo | 245 | 160 | 240 | 190 | 150 | 160 | 130 |
| Ren | 260 | 170 | 235 | 210 | 170 | 175 | 145 |
| Daichi | 300 | 235 | 275 | 240 | 240 | 215 | 170 |
| Nao | 140 | 115 | 135 | 140 | 120 | 100 | 130 |
| Sayo | 160 | 125 | 140 | 135 | 125 | 125 | 165 |

Medidas en píxeles lógicos del mundo, no píxeles de ventana. Cada alcance es la máxima extensión horizontal del volumen de ataque desde el pivote del personaje durante su fase activa. No equivale a la separación máxima entre centros para golpear: también interviene el ancho del rival. El frontal de Nao falla a 215 unidades entre centros; los de espada conectan. A 315, el frontal de Daichi conecta y los demás fallan. Probado en ambos lados.

La trayectoria horizontal original se escala para alcanzar esos máximos; los tiempos y las alturas de las seis técnicas permanecen como base del laboratorio. Son envolventes iniciales diferenciadas, no un ajuste exacto a cada píxel ni técnicas marciales definitivas. Algunas poses, especialmente la extensión de Ren, todavía requieren reconciliar dibujo y volumen de ataque.

El cuerpo de pie conserva 64 × 250. Durante los ticks [3, 10) de la esquiva se reduce su altura según el perfil, con los pies anclados al suelo. La animación usa ese mismo intervalo para su pose baja. En esos ticks también permanece la invulnerabilidad; anticipación y recuperación vuelven a ser vulnerables. La caja que impide atravesar al rival conserva su ancho, independientemente de la postura.

La colisión continua usa la postura vigente en el tick; no arrastra una cabeza de pie al entrar en la postura baja. La caja de pie solo se consulta adicionalmente para registrar un golpe evitado, nunca para matar durante la esquiva.

Tras el KO se ignoran entradas y no se resuelven más impactos. La gravedad continúa para ambos luchadores; el muerto deja de ascender y cae. Su reloj de derrota en el suelo empieza al aterrizar. La ronda espera al menos 21 ticks de derrota en suelo y el aterrizaje de ambos, además del tiempo normal de cierre.

Pruebas: `tests/test_combat_geometry.gd` pasó 3208 comprobaciones de alcances de las seis técnicas, contactos reales a distintas distancias, perfiles independientes, postura y colisión continua, muertes aéreas ascendentes/descendentes, doble KO y cierre de ronda. El vencedor completa su acción y aterriza sin aceptar entradas ni órdenes pendientes. `tools/preview_combat_fixes.gd` produce capturas reales con F1 y una secuencia de KO aéreo en ambos lados. [Vídeo del juego a 60 FPS](../../art/reviews/caida-tras-ko.mp4).

[Un café para Jorge](https://jorge-coffee.onrender.com/)
