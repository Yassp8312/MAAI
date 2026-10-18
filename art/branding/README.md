# MAAI · Identidad de aplicación

Marca vectorial propia: nombre MAAI dentro de un círculo abierto, fondo oscuro y acento de tinta roja. Conserva la identidad tipográfica y circular de la interfaz. No se usó generación de imágenes para esta marca; sus trazos son SVG editable.

- `maai-icon.svg`: original vectorial del icono del proyecto.
- `maai-icon.png`: render a 512 px.
- `maai.ico`: siete resoluciones, 16/24/32/48/64/128/256 px.
- `tools/render_app_icon.gd` renderiza cada tamaño directamente desde el SVG.
- `tools/pack_app_icon.py` empaqueta esos PNG sin modificar sus píxeles.

`project.godot` configura el PNG como icono de ventana. Además, `game_settings.gd` lo asigna explícitamente con `DisplayServer.set_icon` después de aplicar modo y resolución. `export_presets.cfg` conserva el ICO para el archivo ejecutable. Desde 0.2.1 se verifican ambos iconos de la ventana mediante `WM_GETICON`, además del recurso embebido del EXE; capturas e informe en `art/reviews/export/window-icon-v0.2.1*`. En 0.2.0 la ventana también devolvía el logo al inspeccionarla localmente; no se pudo reproducir el icono genérico de la barra de Jorge, por lo que la caché o agrupación de Windows sigue siendo una posible causa, no una causa demostrada.

Exportación Windows realizada con las plantillas oficiales de Godot 4.2.1 y rcedit; ejecutable en `build/windows/MAAI.exe`. [Procedimiento oficial del icono](https://docs.godotengine.org/en/4.2/tutorials/export/changing_application_icon_for_windows.html).

La entrada de **Yassper Design** dura 4,6 segundos, es saltable y precede al prólogo existente. Usa una firma tipográfica con aparición gradual y textura oscura discreta. Se retiró el círculo con trazo central por petición de Jorge, y se desactivó la imagen de arranque predeterminada del motor. La entrada no añade otra narración ni música encima del prólogo.

Créditos agrupados por persona, seguidos de recursos y herramientas. Correo publicado con autorización: `jorgecintra2@gmail.com`. Los enlaces abren sus destinos cuando el jugador los activa; el juego no envía correos automáticamente.

[Un café para Jorge](https://jorge-coffee.onrender.com/)
