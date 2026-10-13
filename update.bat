@echo off
echo ============================================
echo   Actualizando codigo desde los repos...
echo ============================================
echo.

for %%R in (eureka-server api-gateway-lostobjects auth-service-lostobjects claim-service report-service) do (
    if exist "%%R" (
        echo Actualizando %%R...
        pushd "%%R"
        git pull
        popd
    )
)

echo.
echo Reconstruyendo servicios...
docker-compose up --build -d

echo.
echo Listo.
pause