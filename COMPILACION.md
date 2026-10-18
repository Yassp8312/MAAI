# MAAI · Compilación Windows

Entrega local del 18 de octubre de 2026, versión 0.2.1. Windows x86-64, renderizador Compatibility, Godot 4.2.1. Esta revisión refuerza la asignación del icono de ventana; la versión 0.2.0 permanece archivada en su ZIP.

## Abrir y compartir

- Ejecutable: `build/windows/MAAI.exe`, junto a `MAAI.pck`.
- Paquete portátil: `build/MAAI-MVP-Windows-v0.2.1.zip`. Extraer completo y abrir `MAAI/MAAI.exe`; no requiere instalar el editor.
- Incluye instrucciones y créditos en `LEEME.txt`, y licencia del motor y sus dependencias en `LICENCIA-GODOT.txt`.
- Los artefactos de compilación se conservan localmente y están excluidos del repositorio.

## Herramientas

Se usaron las [plantillas oficiales de Godot 4.2.1](https://godotengine.org/download/archive/4.2.1-stable/), comprobando el SHA512 de todo el archivo contra `SHA512-SUMS.txt` de la misma publicación. Se instalaron las dos plantillas Windows x86-64 en `%APPDATA%/Godot/export_templates/4.2.1.stable/`.

[rcedit 2.0.0](https://github.com/electron/rcedit/releases/tag/v2.0.0), instalado en `%APPDATA%/Godot/export_tools/`, incorpora icono y metadatos. Su ruta está configurada en las preferencias del editor de Godot 4.2. Se conservó una copia previa de esas preferencias en `tmp/export-tools/`. No se cambiaron las preferencias de Godot 4.5.

Con los recursos importados, desde la raíz del proyecto:

```powershell
& 'D:/Trabajo/Programas/Para juegos/godot/Godot_v4.2.1-stable_win64_console.exe' --headless --path . --export-release 'Windows Desktop' build/windows/MAAI.exe
```

El perfil excluye herramientas, pruebas, capturas y experimentos. No se firma el ejecutable. Los metadatos son MAAI / Yassper Design / 0.2.1.0. El icono del ejecutable y el de su ventana se verifican por separado.

## Verificación realizada

En 0.2.1: 35 comprobaciones de ajustes y 155 de integración del MVP sin fallos, exportación con código 0, arranque nativo y lectura de los iconos pequeño/grande de Windows (todos asignados y con el logo). Archivos `art/reviews/export/window-icon-v0.2.1*`. El recorrido completo siguiente corresponde a 0.2.0, cuya lógica de combate y música no cambia en esta revisión.

- 15 suites con 19 795 comprobaciones sin fallos, más carga de la escena hasta combate jugable. Incluyen música, entrenamiento, interfaz, opciones, personajes, defensa, geometría y audio.
- Captura nativa de entrenamiento con seis castigos confirmados y audio real, incluyendo pausa y reanudación. Pico de mezcla −18,9 dBFS, sin saturación. La valoración musical y el empalme entre frases requieren escucha de Jorge.
- `tools/verify_export.gd`, ejecutado externamente por **MAAI.exe**, comprobó 21 condiciones sin fallos: entrada automática al prólogo, reproducción musical real, cinco personajes, tres arenas y pantallas de combate, pausa, opciones y créditos. No se distribuye este script.
- Informe y capturas: `art/reviews/export/verification.json` y PNG adyacentes. El informe identifica el ejecutable utilizado.
- Arranque normal del ejecutable, sin script de prueba ni cierre automático: ventana MAAI activa y respondiendo, cerrada con su solicitud normal de cierre. Informe en `art/reviews/export/normal-startup.json`. El argumento de diagnóstico `--quit-after` de esta versión devolvía 1 al forzar el fin; se descartó como señal de fallo tras comprobar el arranque y cierre normales.
- Inspección del PCK: 404 entradas, sin herramientas, pruebas ni capturas y sin las referencias retiradas de los textos y scripts del juego.
- Los avisos de recursos pendientes al cerrar el proceso de exportación pertenecen al editor headless; la exportación terminó con código 0. Se revisó aparte el ejecutable generado. No se presenta como una exportación sin avisos.
- El MP3 Banda1 original conserva su SHA256; solo la copia de entrenamiento fue procesada.

La prueba en otra computadora y con dos mandos físicos sigue pendiente. Esta compilación no incluye LAN.

Jorge confirmó que el icono de la barra de tareas sigue apareciendo genérico en su equipo con 0.2.1. Queda pendiente y fuera del trabajo actual por su indicación; las comprobaciones locales de los iconos de ventana no demuestran que ese problema esté resuelto.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
