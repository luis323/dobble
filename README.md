# Símbolos Relámpago 3D

Juego de reflejos original tipo Dobble para Android, hecho con Godot 4.4.1. No incluye imágenes ni marcas del juego comercial.

## Qué incluye

- 1 jugador contra 1, 2 o 3 CPU (2–4 participantes en total).
- Tres velocidades de CPU: Tranquila, Normal y Relámpago.
- Mesa, cartas, luces, fichas y símbolos en 3D real.
- 31 cartas de 6 símbolos. Cualquier par comparte exactamente uno.
- Control táctil, vibración, sonido, animaciones y modo horizontal inmersivo.
- APK universal para Android ARM de 32 y 64 bits.
- GitHub Actions listo para compilar sin instalar Godot en el teléfono.

## Regla

Mira la carta del centro y tu carta de abajo. Toca en tu carta el único símbolo repetido. El primer participante en llegar a 8 puntos gana.

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

3. Cuando termine la acción, entra en el repositorio de GitHub → **Actions** → ejecución más reciente → **Artifacts** → `SimbolosRelampago3D-Android`.

También puedes pulsar **Run workflow** dentro de Actions para volver a compilar cuando quieras.

## Abrir en Godot

Importa `project.godot` usando Godot 4.4.1. La escena inicial es `main.tscn`. El render usa **GL Compatibility** para funcionar mejor en teléfonos y tablets.

## Prueba matemática del mazo

En PC o Termux con Python:

```bash
python tests/verificar_mazo.py
```

