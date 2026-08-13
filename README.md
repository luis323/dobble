# Símbolos Relámpago 3D

Juego de reflejos original tipo Dobble para Android, hecho con Godot 4.4.1. No incluye imágenes ni marcas del juego comercial.

## Qué incluye

- 1 jugador contra 1, 2 o 3 CPU (2–4 participantes en total).
- Tres velocidades de CPU: Tranquila, Normal y Relámpago.
- Pantalla completa dividida en dos: carta central arriba y carta del jugador abajo.
- Figuras grandes, coloridas y reconocibles, con volumen 3D y zona táctil amplia.
- 31 cartas de 6 símbolos. Cualquier par comparte exactamente uno.
- Cada participante conserva su propia carta durante toda la partida.
- Marcador de cartas ganadas, cartas restantes y resultado con posibilidad de empate.
- Control táctil invisible, sonido original, celebraciones 2D y modo vertical inmersivo.
- APK universal para Android ARM de 32 y 64 bits.
- GitHub Actions listo para compilar sin instalar Godot en el teléfono.
- Compilación directa con Godot oficial, Java 17, Android SDK 34 y keystore de depuración; no depende de `firebelley/godot-export`.

## Regla

Todos miran la carta central de arriba. Cada jugador o CPU busca en su propia carta el único símbolo repetido. Si tú lo encuentras primero, toca esa figura en tu carta de abajo y ganas la carta central. Después aparece otra carta central. La partida termina cuando se agota el mazo y gana quien haya acumulado más cartas; puede haber empate.

## Versión 1.1.1

- Corrige el cierre de la aplicación al tocar una figura en Android.
- Filtra el toque y el clic duplicados enviados por algunos dispositivos.
- Procesa la puntuación fuera del evento físico y valida las cartas antes de animarlas.
- Mantiene la respuesta visual y la vibración; el sonido procedural queda desactivado en Android por estabilidad.

## Versión 1.1.2

- Sustituye por completo los eventos táctiles 3D por seis botones 2D transparentes.
- Las áreas físicas de las figuras ya no reciben toques ni raycasts en Android.
- Conserva las figuras, animaciones, puntuación y zonas táctiles grandes.

## Versión 1.1.3 — toque seguro

- Elimina vibración, audio procedural y tweens 3D durante la selección.
- Mantiene los botones 2D y realiza el cambio de carta de forma sencilla.
- Muestra la versión dentro del menú para comprobar que la APK instalada es la nueva.

## Versión 1.2.0 — edición celebración

- Elimina las cajas oscuras de las seis zonas táctiles en todos sus estados.
- Renueva el menú con estilo luminoso, controles grandes y selector de sonido.
- Añade melodías originales generadas dentro del juego, sin archivos externos.
- Celebra cada carta del jugador con confeti y muestra una súper celebración al ganar la partida.
- Mantiene el toque seguro: audio y efectos 2D se ejecutan después del evento táctil.
- Verifica partidas con 2, 3 y 4 participantes y puntuación independiente para cada CPU.

## Compilar desde Termux

1. Descomprime el proyecto y entra a su carpeta:

   ```bash
   cd /sdcard/Download/simbolos-3d
   ```

2. Da permiso al ayudante y ejecútalo:

   ```bash
   chmod +x SUBIR_Y_COMPILAR_TERMUX.sh
   ./SUBIR_Y_COMPILAR_TERMUX.sh
   ```

Si GitHub todavía muestra `firebelley/godot-export`, ejecuta el reparador visible
desde la carpeta descomprimida (el repositorio local se supone en `~/dobble`):

```bash
chmod +x REPARAR_WORKFLOW_TERMUX.sh
./REPARAR_WORKFLOW_TERMUX.sh ~/dobble
```

3. Cuando termine la acción, entra en el repositorio de GitHub → **Actions** → ejecución más reciente → **Artifacts** → `SimbolosRelampago3D-Android`.

También puedes pulsar **Run workflow** dentro de Actions para volver a compilar cuando quieras.

## Abrir en Godot

Importa `project.godot` usando Godot 4.4.1. La escena inicial es `main.tscn`. El render usa **GL Compatibility** para funcionar mejor en teléfonos y tablets.

## Prueba matemática del mazo

En PC o Termux con Python:

```bash
python tests/verificar_mazo.py
```
