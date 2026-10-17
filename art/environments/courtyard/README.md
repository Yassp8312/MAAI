# Patio al atardecer · v01

Primer entorno jugable de MAAI. El nombre describe esta arena visual; no fija aún una localización canónica de la narrativa.

El fondo `courtyard-v01.png` se generó con ImageGen para este proyecto: patio de piedra, dojo lateral, montañas y vegetación en tinta y acuarela contenida. Se integra completo, sin modificar los maestros de personajes. El área central clara sirve de contraste a armas y siluetas. El dibujo del fondo es una sola capa; la profundidad viene de su composición, no de una cámara con parallax.

`scripts/courtyard.gd` añade hojas, tallos animados en los extremos, sombras de contacto y piedras que señalan los límites. Lee `floor_y`, `arena_left` y `arena_right` de la simulación. No añade colisionadores ni cambia las distancias, velocidades o alcances. Las sombras se proyectan al suelo durante saltos y muertes aéreas y se atenúan con la altura. La sangre de este entorno aparece al llegar al suelo.

`scripts/courtyard_wind.gd` sintetiza viento suave provisional, en un bucle de 12 segundos con extremos atenuados. Usa el bus **Ambience** y pasa por **Master**. Al pausar, abrir opciones, volver al menú o elegir el laboratorio se desvanece en medio segundo. No es la banda sonora definitiva ni una grabación de campo. La animación ambiental se detiene al pausar.

El patio es el entorno por defecto de duelo, práctica y galería. En **Esc / Start → Escenario**, se alterna con el laboratorio negro sin reiniciar la ronda ni cambiar el marcador. La elección dura la sesión; no se añade una preferencia persistente.

El HUD del patio adapta nombres, puntos y controles a la claridad del fondo. F1 conserva las cajas de colisión y datos de alcance. La pausa conserva selección, opciones y vuelta al menú.

## Verificación

- `tests/test_courtyard.gd`: suelo y sombras, aislamiento respecto al combate, pausa, cambio de entorno y ciclo de sonido.
- `tools/preview_courtyard.gd`: cinco duelos espejo, salto, KO aéreo, extremos, pausa y laboratorio a 960 × 540. `-- --record` añade 240 fotogramas a 30 fps de movimiento real de la simulación; la vista previa no incluye audio.
- La integración también se comprueba con las pruebas de interfaz y geometría del combate.

Pendiente: ajustar el entorno con pruebas de juego, sonido ambiental final y comprobar el resultado en otras pantallas. El pulido de impactos y el rival de práctica son los siguientes bloques.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
