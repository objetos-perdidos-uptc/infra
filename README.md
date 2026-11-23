# Infraestructura - Lost & Found

Orquestación de todo el sistema (microservicios + bases de datos + broker). Un solo script
clona los repos, valida la configuración y levanta los contenedores.

## Requisitos

- Docker Desktop corriendo
- Git (en Windows se usa **Git Bash**, que ya viene con Git)
- Acceso a los repos de `objetos-perdidos-uptc`

## Inicio rápido

```bash
git clone https://github.com/objetos-perdidos-uptc/infra.git infra
cd infra
./lost.sh start
```

La primera vez tarda varios minutos (descarga imágenes y compila). `start` crea el `.env`
desde `.env.example` y genera un `JWT_SECRET` aleatorio.

## Comandos

| Comando | Qué hace |
|---|---|
| `./lost.sh start` | Clona repos faltantes, valida `.env`, construye y levanta |
| `./lost.sh stop` | Detiene contenedores (conserva datos) |
| `./lost.sh restart [servicio]` | Reinicia todo o un servicio |
| `./lost.sh update` | `git pull` en cada servicio y reconstruye |
| `./lost.sh reset` | Borra contenedores **y datos** (pide confirmación) |
| `./lost.sh status` | Estado de los contenedores |
| `./lost.sh health` | Prueba endpoints y lista servicios registrados en Eureka |
| `./lost.sh logs [servicio]` | Sigue los logs |

Primera vez en Linux/macOS o si pierde permisos: `chmod +x lost.sh`.

## Servicios

| Servicio | Puerto | Repo |
|---|---:|---|
| eureka | 8761 | [eureka](https://github.com/objetos-perdidos-uptc/eureka) |
| api-gateway | 8080 | [api-gateway](https://github.com/objetos-perdidos-uptc/api-gateway) |
| auth-service | 8081 | [auth-service](https://github.com/objetos-perdidos-uptc/auth-service) |
| claim-service | 8085 | [claim-service-legacy](https://github.com/objetos-perdidos-uptc/claim-service-legacy) |
| report-service | 8082 (`/docs`) | [report-service](https://github.com/objetos-perdidos-uptc/report-service) |
| matching-service | 8000 (`/docs`) | [matching-service](https://github.com/objetos-perdidos-uptc/matching-service) |
| notification-service | — (worker) | [notification-service](https://github.com/objetos-perdidos-uptc/notification-service) |

Infraestructura: PostgreSQL (5432), MongoDB (27017), Redis (6379), RabbitMQ (5672, panel 15672).

Rutas por el gateway (`http://localhost:8080`): `/auth/**`, `/claims/**`, `/reports/**`, `/matches/**`.

## Variables de entorno (`.env`)

| Variable | Descripción |
|---|---|
| `JWT_SECRET` | Clave de firma JWT, mínimo 32 caracteres (la comparten gateway y auth) |
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` / `DB_PORT` | PostgreSQL |
| `MONGO_PORT` / `REDIS_PORT` | Puertos publicados en el host |
| `RABBITMQ_*` | Usuario, contraseña y puertos de RabbitMQ |
| `BREVO_API_KEY` / `TEST_EMAIL_DESTINATION` | Envío de correos (opcional) |

## Problemas frecuentes

- **Docker no está corriendo**: abre Docker Desktop y reintenta.
- **Un servicio falla**: `./lost.sh logs <servicio>`.
- **Cambié `.env` y no se aplica**: `docker compose up -d --force-recreate <servicio>`.
- **Puerto ocupado**: cambia el puerto en `.env`.
- **`update` no actualiza un repo**: tiene cambios locales; haz commit o stash en esa carpeta.
- **Windows y el script falla con `\r`**: el repo ya fuerza LF en `*.sh` vía `.gitattributes`; reclona si lo editaste con CRLF.