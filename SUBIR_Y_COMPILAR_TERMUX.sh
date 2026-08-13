#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=========================================="
echo " SÍMBOLOS RELÁMPAGO 3D - TERMUX + GITHUB"
echo "=========================================="
echo

pkg update -y
pkg install git gh -y

if ! gh auth status >/dev/null 2>&1; then
  echo "Se abrirá el inicio de sesión seguro de GitHub."
  gh auth login
fi

if [ ! -d .git ]; then
  git init
fi

git config user.name >/dev/null 2>&1 || git config user.name "Leonardo"
git config user.email >/dev/null 2>&1 || git config user.email "android-build@users.noreply.github.com"

git add .
if ! git diff --cached --quiet; then
  git commit -m "Juego Símbolos Relámpago 3D"
else
  echo "No hay cambios nuevos para guardar."
fi

git branch -M main

if ! git remote get-url origin >/dev/null 2>&1; then
  echo
  read -r -p "Nombre del repositorio nuevo (ej: simbolos-3d): " REPO_NAME
  gh repo create "$REPO_NAME" --public --source=. --remote=origin
fi

git push -u origin main

echo
echo "Compilación iniciada. Abriendo GitHub Actions..."
sleep 3
RUN_ID="$(gh run list --workflow android.yml --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)"
if [ -n "$RUN_ID" ]; then
  gh run watch "$RUN_ID" --exit-status || true
fi
echo
echo "Cuando termine: GitHub > Actions > última ejecución > Artifacts."
