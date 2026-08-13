# Símbolos Relámpago 3D

Juego de reflejos original tipo Dobble para Android, hecho con Godot 4.4.1. No incluye imágenes ni marcas del juego comercial.

## Qué incluye

- 1 jugador contra 1, 2 o 3 CPU, o partidas LAN/Wi‑Fi entre 2 y 4 teléfonos.
- Tres velocidades de CPU: Tranquila, Normal y Relámpago.
- Pantalla completa dividida en dos: carta central arriba y carta del jugador abajo.
- Figuras grandes, coloridas y reconocibles, con volumen 3D y zona táctil amplia.
- 31 diseños matemáticos de 6 símbolos. Cualquier par distinto comparte exactamente uno.
- Montones de 20, 30, 40, 50 o 70 cartas para cada jugador.
- Marcador de cartas restantes y final inmediato cuando alguien llega a cero.
- Control táctil invisible, sonido original, celebraciones 2D y modo vertical inmersivo.
- APK universal para Android ARM de 32 y 64 bits.
- GitHub Actions listo para compilar sin instalar Godot en el teléfono.
- Compilación directa con Godot oficial, Java 17, Android SDK 34 y keystore de depuración; no depende de `firebelley/godot-export`.

## Regla

Todos comienzan con la misma cantidad de cartas y hay una sola carta central. Cada jugador o CPU busca el único símbolo repetido entre su carta superior y la carta central. Quien acierta descarta su carta poniéndola como nueva carta central y muestra la siguiente de su montón. El primero que queda sin cartas gana.

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

## Versión 1.2.1 — penalización

- Un solo toque en un símbolo incorrecto bloquea la carta del jugador durante 5 segundos.
- Muestra una cuenta regresiva clara y vuelve a habilitar los símbolos automáticamente.
- Las CPU continúan compitiendo durante la penalización.
- La cuenta regresiva se cancela de forma segura si termina la ronda o se vuelve al menú.

## Versión 1.2.2 — señal de derrota

- Si una CPU gana una carta, aparece una X roja animada sobre la carta inferior del jugador.
- Reproduce un sonido descendente de derrota sin ejecutarlo directamente desde el toque.
- Si el jugador pierde la partida completa, muestra una X roja mayor y un sonido final distinto.
- Los empates no muestran la señal de derrota.

## Versión 1.3.0 — primero sin cartas

- Cambia la partida al modo de descarte: la carta acertada pasa al centro.
- Permite elegir 20, 30, 40, 50 o 70 cartas para cada jugador.
- Todos reciben exactamente la misma cantidad y la central es una carta extra.
- El ganador es inmediatamente el primer jugador o CPU que llega a cero cartas.
- Conserva la penalización de 5 segundos, celebraciones, X roja y sonidos.

## Versión 1.4.0 — LAN / Wi‑Fi

- Permite jugar entre 2, 3 o 4 teléfonos Android conectados a la misma red Wi‑Fi.
- Un jugador crea la sala y actúa como anfitrión; los demás pueden encontrarla automáticamente.
- Incluye conexión por dirección IP manual cuando el router no permite descubrir la sala.
- El anfitrión controla el mazo, las penalizaciones y quién tocó primero para que todos vean el mismo resultado.
- Cada teléfono muestra la carta privada de su jugador abajo y la misma carta central arriba.
- Mantiene el modo contra CPU, las cantidades de 20/30/40/50/70 cartas y la regla del primero sin cartas.
- Usa solamente la red local: puerto de juego `7359` y descubrimiento `7360`.

## Versión 1.4.1 — carta ganadora al frente

- Al acertar, tu carta inferior salta hacia la cámara y aumenta de tamaño.
- La figura correcta se ilumina mientras la carta queda un instante al frente.
- Después la carta viaja hacia arriba, reemplaza la central anterior y se convierte en la nueva carta compartida.
- La animación funciona tanto contra CPU como en partidas LAN/Wi‑Fi.

## Versión 1.4.2 — derrota con carta quieta

- La animación de avance se reproduce únicamente cuando tú aciertas.
- Cuando otro jugador o una CPU gana la ronda, tu carta inferior queda totalmente estática.
- En la derrota solamente aparecen la X roja y el sonido; la carta no gira, no aumenta de tamaño y no se desplaza.
- Aplica igualmente al modo contra CPU y a las partidas LAN/Wi‑Fi.

## Jugar por LAN o Wi‑Fi

1. Todos deben instalar la misma versión de la APK y conectarse a la misma red Wi‑Fi.
2. En un teléfono, elige la cantidad de cartas y pulsa **CREAR SALA LAN / WI‑FI**.
3. En los otros teléfonos, pulsa **BUSCAR Y UNIRSE A SALA** y elige la sala encontrada.
4. Si la sala no aparece, escribe en **IP manual** la dirección que muestra el teléfono anfitrión y pulsa **CONECTAR**.
5. Cuando haya entre 2 y 4 jugadores conectados, el anfitrión pulsa **INICIAR PARTIDA**.

No hace falta activar la depuración inalámbrica de Android ni usar ADB para jugar. Esa función solo se utilizó para obtener registros de errores durante las pruebas.

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
