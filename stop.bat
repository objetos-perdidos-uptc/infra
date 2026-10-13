@echo off
echo ============================================
echo   Deteniendo sistema...
echo ============================================
echo.
docker-compose down
echo.
echo Sistema detenido. Los datos de las bases de datos se conservan.
pause