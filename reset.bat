@echo off
echo Reiniciando sistema desde cero...
docker-compose down -v
docker-compose up --build -d
timeout /t 60 /nobreak >nul
echo Listo.
pause