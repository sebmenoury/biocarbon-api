@echo off
cd /d "C:\Users\7311576R\Documents\streamlit_test\carbone_web"

echo 🔄 Détection des modifications...
git status

echo ✅ Ajout de tous les fichiers modifiés...
git add .

set /p msg="💬 Message de commit : "
if "%msg%"=="" (
  echo ❌ Aucun message saisi, commit annulé.
  exit /b
)
git commit -m "%msg%"

echo 🚀 Envoi vers GitHub...
git push

pause