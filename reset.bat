@echo off
echo ============================================
echo   ADVERTENCIA
echo ============================================
echo.
echo Esto ELIMINARA todos los contenedores Y los datos
echo de las bases de datos (Postgres, Mongo, Redis).
echo.
echo Usuarios, reportes y reclamos se perderan.
echo.
pause

echo.
echo Reiniciando desde cero...
docker-compose down -v
docker-compose up --build -d

echo.
echo Esperando 60 segundos...
timeout /t 60 /nobreak >nul
echo.
echo Sistema reiniciado con bases de datos vacias.
pause