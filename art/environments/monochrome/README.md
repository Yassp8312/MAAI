# Tres arenas de tinta

18 de octubre de 2026. La selección de personajes permite elegir arena. La pausa recorre las tres arenas y el laboratorio sin alterar la simulación.

- **Patio de tinta:** reutiliza el dibujo anterior del patio mediante un shader de escala de grises y reducción del contraste central. El original permanece intacto.
- **Santuario del bambú:** nuevo paisaje de tinta con vegetación en los bordes, santuario distante y un centro luminoso.
- **Orilla del silencio:** nuevo paisaje de lago y montañas, agua clara, pino lateral y pequeñas ondas animadas.

Los dos nuevos dibujos se generaron con la herramienta integrada de OpenAI `image_gen`; se conservan en `bamboo.png` y `shore.png`. No se usaron imágenes descargadas de terceros. El tratamiento gráfico se aplica únicamente al escenario. Los personajes, menús y señales mantienen su identidad; el terreno y elementos ambientales se dibujan en gris neutro.

Todas las arenas mantienen el mismo suelo, anchura, límites y colisiones. El fondo no introduce obstáculos ni ventajas de lado. Las sombras leen la altura física del personaje y permanecen ancladas al suelo. Animación ambiental y viento se detienen durante pausa y ajustes.

La legibilidad se obtiene con figuras oscuras sobre un centro claro, detalle periférico y sombras de apoyo. Queda pendiente valorar todos los enfrentamientos y los extremos de la arena jugando; los dibujos no garantizan por sí solos legibilidad competitiva.

Las capturas nativas se reproducen con `tools/preview_mvp.gd`. Los originales generados tienen proporción 16:9 y la línea de suelo coincide aproximadamente con el 79 % vertical del área lógica 1600 × 900.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
