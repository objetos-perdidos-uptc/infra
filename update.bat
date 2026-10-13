@echo off
setlocal
echo ============================================
echo   Actualizando codigo desde los repos...
echo ============================================
echo.

for %%R in (eureka-server api-gateway auth-service claim-service report-service notification-service matching-service) do (
    if exist "%%R" (
        echo Actualizando %%R...
        pushd "%%R"
        git pull
        popd
        echo.
    )
)

echo.
echo ============================================
echo   Reconstruyendo y reiniciando servicios...
echo ============================================
docker-compose up --build -d

echo.
echo Esperando 60 segundos...
timeout /t 60 /nobreak >nul
echo.
echo Listo.
pause