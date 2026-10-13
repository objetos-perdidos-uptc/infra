@echo off
setlocal
echo ============================================
echo   Lost ^& Found - Sistema de Objetos Perdidos
echo ============================================
echo.

REM 1. Verificar Docker
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker no esta corriendo.
    echo Abre Docker Desktop y vuelve a intentar.
    pause
    exit /b 1
)

REM 2. Clonar repos si no existen
echo [1/3] Verificando repositorios...

if not exist "eureka-server" (
    echo   Clonando eureka-server...
    git clone https://github.com/objetos-perdidos-uptc/eureka-server.git
) else (echo   eureka-server OK)

if not exist "api-gateway" (
    echo   Clonando api-gateway...
    git clone https://github.com/objetos-perdidos-uptc/api-gateway.git
) else (echo   api-gateway OK)

if not exist "auth-service" (
    echo   Clonando auth-service...
    git clone https://github.com/objetos-perdidos-uptc/auth-service.git
) else (echo   auth-service OK)

if not exist "claim-service" (
    echo   Clonando claim-service...
    git clone https://github.com/objetos-perdidos-uptc/claim-service.git
) else (echo   claim-service OK)

if not exist "report-service" (
    echo   Clonando report-service...
    git clone https://github.com/objetos-perdidos-uptc/report-service.git
) else (echo   report-service OK)

if not exist "notification-service" (
    echo   Clonando notification-service...
    git clone https://github.com/objetos-perdidos-uptc/notification-service.git
) else (echo   notification-service OK)

if not exist "matching-service" (
    echo   Clonando matching-service...
    git clone https://github.com/objetos-perdidos-uptc/matching-service.git
) else (echo   matching-service OK)

REM 3. Verificar .env
echo.
echo [2/3] Verificando archivo .env...

if not exist ".env" (
    echo   No existe .env. Copiando desde .env.example...
    copy .env.example .env >nul
    echo   [IMPORTANTE] Edita .env si quieres cambiar el JWT_SECRET u otros valores.
)

REM 4. Levantar
echo.
echo [3/3] Construyendo imagenes y levantando servicios...
docker-compose up --build -d

echo.
echo Esperando 60 segundos a que arranquen los servicios...
timeout /t 60 /nobreak >nul

echo.
echo ============================================
echo   Sistema levantado
echo ============================================
echo.
echo   Eureka:              http://localhost:8761
echo   API Gateway:         http://localhost:8080
echo   Auth Service:        http://localhost:8081
echo   Report Service:      http://localhost:8082
echo   Matching Service:    http://localhost:8083
echo   Notification Service:http://localhost:8084
echo   Claim Service:       http://localhost:8085
echo.
echo   Ver logs:   docker-compose logs -f
echo   Detener:    stop.bat
echo   Actualizar: update.bat
echo   Reiniciar limpio: reset.bat
echo ============================================
pause