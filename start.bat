@echo off
echo ============================================
echo   Lost ^& Found - Sistema de Objetos Perdidos
echo ============================================
echo.

REM Verificar que Docker este corriendo
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker no esta corriendo. Abre Docker Desktop y vuelve a intentar.
    pause
    exit /b 1
)

REM Clonar repos si no existen
echo [1/3] Verificando repositorios...

if not exist "eureka-server" (
    echo Clonando eureka-server...
    git clone https://github.com/tu-usuario/eureka-server.git
) else (
    echo eureka-server ya existe, saltando.
)

if not exist "api-gateway-lostobjects" (
    echo Clonando api-gateway-lostobjects...
    git clone https://github.com/tu-usuario/api-gateway-lostobjects.git
) else (
    echo api-gateway-lostobjects ya existe, saltando.
)

if not exist "auth-service-lostobjects" (
    echo Clonando auth-service-lostobjects...
    git clone https://github.com/tu-usuario/auth-service-lostobjects.git
) else (
    echo auth-service-lostobjects ya existe, saltando.
)

if not exist "claim-service" (
    echo Clonando claim-service...
    git clone https://github.com/tu-companero/claim-service.git
) else (
    echo claim-service ya existe, saltando.
)

echo.
echo [2/3] Verificando archivo .env...

if not exist ".env" (
    echo No existe .env, copiando desde .env.example...
    copy .env.example .env
)

echo.
echo [3/3] Construyendo imagenes y levantando servicios...
docker-compose up --build -d

echo.
echo Esperando a que los servicios arranquen (60s)...
timeout /t 60 /nobreak >nul

echo.
echo ============================================
echo   Servicios disponibles:
echo ============================================
echo   - Eureka:        http://localhost:8761
echo   - API Gateway:   http://localhost:8080
echo   - Auth Service:  http://localhost:8081
echo   - Claim Service: http://localhost:8085
echo.
echo   Para ver logs:  docker-compose logs -f
echo   Para detener:   stop.bat
echo ============================================
pause