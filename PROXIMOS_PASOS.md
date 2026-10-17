# MAAI · Hoja de ruta hacia un MVP competitivo

Actualizada el 17 de octubre de 2026. Sustituye la lista anterior. Este documento ordena trabajo pendiente; las reglas propuestas no se consideran implementadas ni aprobadas por aparecer aquí.

## Objetivo y estado real

Jorge quiere revisar animaciones, incorporar bloqueo y parry con choques de armas propios, añadir música al juego, llevar el entorno al blanco y negro, disponer de entrenamiento y jugar por LAN. La aspiración es que el juego sea divertido y pueda sostener competición además de destacar por su arte.

Disponible: cinco personajes con primera animación y alcances propios, esquiva con cambio de zona vulnerable, muerte aérea con aterrizaje, duelo local, prólogo con voz y música elegida, presentación, selección, resultados, pausa y opciones coherentes, efectos por personaje y patio provisional. La práctica actual no tiene rival automático. La simulación funciona a 60 ticks por segundo y está separada del dibujo.

Falta: defensa con bloqueo/parry, poses y contactos de defensa, técnicas realmente diferenciadas, música fuera del prólogo, escenario monocromo, entrenamiento con órdenes, LAN, validación humana de diversión/equilibrio y distribución probada en otras computadoras. La separación del dibujo no demuestra determinismo entre equipos ni una arquitectura de red terminada.

## Orden recomendado

| Etapa | Trabajo | Criterio para avanzar |
| --- | --- | --- |
| 1 | Defensa experimental, poses legibles y rival que repita un ataque | Comparar bloquear, desviar, esquivar y contraatacar en una situación repetible |
| 2 | Prueba monocroma y animaciones que expliquen ese intercambio | Distinguir cuerpo, arma, defensa y contacto durante el movimiento |
| 3 | Extender defensa al elenco y diferenciar técnicas | Cada arma ofrece decisiones, compromisos y respuestas claras |
| 4 | Entrenamiento completo y pruebas con personas | Identificar confusión, estrategias dominantes y oportunidades de aprendizaje |
| 5 | Música por pantallas/estados y mezcla | Una partida completa mantiene identidad y claridad sonora |
| 6 | LAN en dos equipos | Resultado consistente y respuesta aceptable bajo distintas condiciones de red |
| 7 | Exportación, mandos físicos y rendimiento | Instalar, aprender y jugar fuera del editor sin ayuda constante |

La prueba monocroma puede avanzar junto a la defensa. Preparar registro de entradas y estados para red comienza pronto, aunque la interfaz LAN llegue después. Las pruebas de diversión empiezan en la primera etapa y continúan siempre.

## 1. Bloqueo y parry

- [ ] Añadir defensa reasignable para ambos jugadores, teclado y mando. Actualizar HUD, captura de controles e instrucciones; migrar preferencias sin borrar asignaciones existentes.
- [ ] Probar esta hipótesis: mantener el control para bloquear; pulsarlo cerca del contacto para desviar. No es una regla definitiva; separar acciones sigue siendo una alternativa.
- [ ] Definir dirección de guardia, cobertura alta/baja, ataques aéreos y defensa en el aire. Las excepciones deben ser visibles y enseñables.
- [ ] Decidir el coste de defender: movilidad, recuperación, espacio o resistencia de guardia. No introducir automáticamente una barra de postura si una solución más simple funciona.
- [ ] Probar ventana de parry, recuperación al fallar y respuesta al uso repetido. El botón no debería poder machacarse sin riesgo.
- [ ] Probar como recompensa una ventaja breve o un desvío que permita responder, sin convertir automáticamente cada parry en una ejecución en un juego de un solo golpe.
- [ ] Resolver ataque contra parry, dos ataques simultáneos, golpe por detrás, defensa tardía y aterrizajes. Un choque entre dos ataques no es automáticamente un parry.
- [ ] Empezar con dos armas contrastadas para evaluar la regla; extenderla después al elenco. Los cinco personajes actuales permanecen disponibles.

Aceptación: bloquear no resuelve todo, cada defensa tiene contrajuego y ambos jugadores pueden explicar por qué se desvió o entró un golpe. Los tiempos y costes finales se deciden jugando.

## 2. Animaciones y contacto

- [ ] Entrada/salida de guardia, bloqueo recibido, desvío exitoso, arma rechazada y recuperación del fallo.
- [ ] Revisar preparación, recorrido del arma, contacto y recuperación junto a las zonas de colisión.
- [ ] Corregir pies que deslizan, cambios de tamaño, continuidad de manos/armas y transiciones de sprint, salto y caída según la revisión de Jorge.
- [ ] Completar retrocesos propios de Tsukiyo y Sayo.
- [ ] Precisar cajas donde la trayectoria lo necesite; no imponer colisión por píxel. Buscar reglas estables y acordes con el dibujo.
- [ ] Mostrar cuándo una acción sigue comprometida y cuándo se puede actuar de nuevo.

Las poses necesarias para entender una regla se trabajan con esa regla. Los intermedios se pulen después de probar su duración. Sustituir dibujos sigue requiriendo revisar pivotes y sincronización.

## 3. Escenario en blanco y negro

No basta con desaturar el patio actual. Primera prueba de composición:

- [ ] Papel y grises claros en el fondo, con trazos menos oscuros y densos que en los personajes.
- [ ] Negros más firmes y contornos definidos en los personajes, conservando las zonas blancas de sus ropas.
- [ ] Franja de combate despejada: evitar ramas, tejados o líneas fuertes detrás de caras, manos y filos.
- [ ] Separar planos con niebla, lavados grises y bordes suaves a distancia.
- [ ] Suelo y sombras de contacto legibles para distinguir apoyo, salto y caída.
- [ ] Probar todos los personajes, extremos, superposiciones y duelos espejo durante movimiento y efectos.
- [ ] Distinguir a los jugadores en espejos con indicadores o tratamientos discretos de tinta; no depender solo del color.
- [ ] Comprobar que las opciones gráficas no eliminen señales esenciales ni den ventajas de visibilidad sin evaluar.

Aceptación: reconocer pies, siluetas, armas y lado del jugador a 960 × 540 sin depuración. Primero una arena bien resuelta; más escenarios después.

## 4. Sonido de defensa y música

- [ ] Eventos distintos para ataque al aire, bloqueo, parry, impacto corporal y choque entre ataques o ruptura de guardia si se incorporan esas reglas.
- [ ] Materiales coherentes: hoja contra hoja, hoja contra tessen y metal/madera de la yari según la zona representada. No reutilizar el golpe corporal para desviar un arma.
- [ ] Parry breve, identificable y sincronizado con el contacto real, sin repetición por cada tick de colisión.
- [ ] Pose y señal visual equivalentes: la comprensión no debe depender únicamente del sonido.
- [ ] Música para presentación/menú, selección, entrenamiento y duelo; entradas/cierres breves cuando aporten algo al enfrentamiento y al resultado.
- [ ] Conservar la música elegida del prólogo y buscar identidad común con las demás piezas.
- [ ] Bucles sin cortes, transiciones suaves, variación contenida y comportamiento definido al pausar o repetir una partida.
- [ ] Mezcla que deje oír los efectos importantes; probar auriculares y altavoces. La música no debe revelar entradas ni estados ocultos del rival.
- [ ] Registrar procedencia y condiciones de uso de las pistas incorporadas.

## 5. Identidad jugable, diversión y equilibrio

Hoy los alcances cambian, pero los tiempos básicos de ataque y movimiento siguen siendo comunes: aún no son cinco kits terminados.

- [x] Permitir iniciar cualquiera de los tres ataques durante el sprint. Implementado: interrumpe el desplazamiento, mantiene la orientación hacia el rival y conserva la preparación/recuperación normal del ataque. Incluye apoyo sonoro al detenerse. Revisar su sensación en partidas.

- [ ] Distancia preferida, fortalezas, debilidades y formas de aproximación de cada personaje.
- [ ] Una función por ataque: alcance, velocidad, cobertura o castigo. Evitar técnicas redundantes o superiores en todo.
- [ ] Oportunidades reales de acercarse con armas cortas y compromisos castigables para las largas.
- [ ] Contrajuego de salto, sprint, esquiva, guardia y parry; reglas claras de cancelación y recuperación.
- [ ] Evaluar si hace falta una respuesta adicional al bloqueo —finta, ruptura u otra— tras observar el problema. No añadir agarres o medidores solo para acumular sistemas.
- [ ] Resolver estancamientos, empates y final de ronda si nadie ataca. Un temporizador es una opción por evaluar.
- [ ] Rondas y revanchas ágiles, con presentaciones largas saltables.
- [ ] Probar con principiantes y con personas que aprendan a explotar las reglas.
- [ ] Registrar duración, técnicas utilizadas, parries/bloqueos y resultados por enfrentamiento. Interpretar los datos junto con vídeos y comentarios, no solo porcentajes de victoria.

Preguntas de aceptación: ¿entiendo por qué perdí?, ¿tenía respuesta?, ¿tomo decisiones diferentes?, ¿puedo mejorar?, ¿quiero jugar otra partida? Las pruebas automáticas no prueban diversión.

## 6. Entrenamiento y aprendizaje

- [ ] Primero: rival quieto o repitiendo un ataque para desarrollar la defensa.
- [ ] Después: órdenes de bloquear, desviar, esquivar, saltar y responder a una situación.
- [ ] Reinicio instantáneo y selección de posiciones/distancia con ambos personajes elegibles.
- [ ] Grabar/reproducir una secuencia corta del rival cuando la repetición simple se quede corta.
- [ ] Información opcional de entradas, distancia, preparación/actividad/recuperación y cajas de contacto.
- [ ] Explicación de defensa temprana, tardía o incorrecta por dirección, diferenciada de un ataque que nunca alcanzó. Basarla en datos reales.
- [ ] Tutorial breve y saltable con ejercicios de alcance, movimiento, esquiva, guardia y parry.
- [ ] Lista de movimientos accesible desde práctica/pausa.

No requiere una IA competitiva completa; esa IA se considera después según su utilidad.

## 7. LAN y preparación de red

Preparar pronto registro de entradas por tick, captura/restauración del estado, reproducción de partidas y detección de diferencias entre simulaciones. Verificar resultados en equipos distintos: funcionar a 60 Hz no garantiza determinismo entre plataformas.

- [ ] Comparar mediante una prueba pequeña retardo de entradas y predicción/corrección; evaluar rollback con medidas de respuesta y complejidad, sin prometer que la LAN resolverá Internet.
- [ ] Crear/unirse a sala, inicialmente por dirección de red; descubrimiento automático opcional después.
- [ ] Versiones compatibles, asignación de lados, selección, confirmación, inicio común, resultado y revancha.
- [ ] Política de pausa/pérdida de foco compartida: un equipo no puede continuar mientras el otro cree que está pausado.
- [ ] Salida y desconexión con mensajes y recuperación claros.
- [ ] Medir latencia y probar retardo variable, pérdida de paquetes y diferencias de rendimiento; evaluar la ventaja del anfitrión.
- [ ] Si se reejecutan ticks para corregir la red, no duplicar sonidos, efectos ni puntuación.
- [ ] Validar en dos computadoras reales, no solo en dos ventanas de una misma máquina.

Internet, cuentas, emparejamiento y clasificación quedan para una etapa posterior.

## 8. Base competitiva y aspiración de deporte electrónico

La primera meta es un juego local/LAN justo, legible y profundo. Una escena competitiva también necesita jugadores que quieran practicar, competir y organizar encuentros.

- [ ] Baja latencia de entrada y tiempos estables medidos durante combates en equipos objetivo.
- [ ] Reglas explícitas y reproducibles de defensa, empate, doble KO y final de ronda.
- [ ] Probar los 15 enfrentamientos sin distinguir lados entre cinco personajes, incluidos cinco espejos; intercambiar quién ocupa cada lado.
- [ ] Revisar ventajas de lado/control, cancelaciones no previstas, bloqueo permanente y estrategias sin respuesta.
- [ ] Repeticiones asociadas a versión para analizar problemas; indicar incompatibilidad tras cambios que impidan reproducirlas.
- [ ] Registro de cambios y reglas estables durante una competición.
- [ ] Después del MVP: modo torneo con nombres, sets, cambio de jugadores, pausa regulada y depuración restringida.
- [ ] Más adelante: espectador, información para retransmisión, torneos y comunidad. Integridad/clasificación para Internet se diseñan con su arquitectura de red.

La profundidad puede venir de distancia, compromiso, lectura y adaptación; no exige muchos botones o personajes.

## 9. Entrega, accesibilidad y calidad

- [ ] Versión independiente del editor probada en otra computadora.
- [ ] Dos mandos físicos y teclado compartido, incluidos límites de teclas simultáneas.
- [ ] Reconexión, pérdida de foco y conservación de preferencias.
- [ ] Reasignación completa y señales visuales equivalentes a las sonoras.
- [ ] Reducción de sacudidas/destellos si se incorporan; texto legible y escalado correcto.
- [ ] Rendimiento, memoria, carga y estabilidad en sesiones largas.
- [ ] Créditos/procedencia de recursos y enlace discreto de apoyo a Jorge.

## Dos entregas comprobables

**MVP local:** cinco personajes con ataques comprensibles y opciones viables, guardia/parry y esquiva coherentes, arena monocroma legible, música/efectos integrados, entrenamiento básico, explicación de reglas, mandos y opciones funcionales, versión exportada y pruebas con personas. Puede mantener animación provisional donde no perjudique la lectura.

**MVP con LAN:** lo anterior más sala, sincronización comprobada en dos equipos, resultados consistentes, revancha y manejo de desconexión/pausa. Por el interés de Jorge, LAN forma parte del objetivo; se separa en una entrega para verificarla por sí misma.

Siguiente trabajo recomendado: especificar y prototipar defensa con un ataque repetible. Esta lista propone el comportamiento inicial; no fija ventanas, costes ni recompensas definitivas.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
