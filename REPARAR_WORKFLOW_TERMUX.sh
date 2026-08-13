#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${1:-$HOME/dobble}"

echo "=============================================="
echo " REPARAR GITHUB ACTIONS - GODOT 4.4.1"
echo "=============================================="
echo

if [ ! -d "$REPO_DIR/.git" ]; then
	echo "ERROR: no encontré el repositorio en: $REPO_DIR"
	echo "Uso: bash REPARAR_WORKFLOW_TERMUX.sh /ruta/del/repositorio"
	exit 1
fi

if [ ! -f "$SCRIPT_DIR/GITHUB_ANDROID.yml" ]; then
	echo "ERROR: falta GITHUB_ANDROID.yml junto a este reparador."
	exit 1
fi

mkdir -p "$REPO_DIR/.github/workflows"

# Los workflows antiguos con firebelley quedan desactivados y recuperables.
while IFS= read -r old_workflow; do
	[ -z "$old_workflow" ] && continue
	mv "$old_workflow" "$old_workflow.disabled"
	echo "Desactivado: $old_workflow"
done < <(
	find "$REPO_DIR/.github/workflows" -maxdepth 1 -type f \
		\( -name '*.yml' -o -name '*.yaml' \) \
		-exec grep -l "firebelley/godot-export" {} + 2>/dev/null || true
)

cp "$SCRIPT_DIR/GITHUB_ANDROID.yml" "$REPO_DIR/.github/workflows/android.yml"

if find "$REPO_DIR/.github/workflows" -maxdepth 1 -type f \
	\( -name '*.yml' -o -name '*.yaml' \) \
	-exec grep -l "firebelley/godot-export" {} + | grep -q .; then
	echo "ERROR: todavía existe un workflow activo con firebelley."
	exit 1
fi

cd "$REPO_DIR"
git config user.name >/dev/null 2>&1 || git config user.name "Leonardo"
git config user.email >/dev/null 2>&1 || git config user.email "android-build@users.noreply.github.com"
git add .github/workflows

if git diff --cached --quiet; then
	echo "El workflow nuevo ya estaba instalado."
	if command -v gh >/dev/null 2>&1; then
		gh workflow run android.yml --ref main
		echo "Se inició manualmente una ejecución nueva."
	fi
else
	git commit -m "Instalar workflow Android NUEVO sin firebelley"
	git push origin main
	echo "Cambio subido: GitHub inició una ejecución nueva."
fi

echo
echo "CORRECTO: el workflow activo se llama 'Compilar APK Android NUEVO'."
echo "Abre GitHub > Actions y entra en la ejecución más reciente."
