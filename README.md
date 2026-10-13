# Infraestructura - Sistema Lost & Found

Repositorio de orquestación del sistema **Lost & Found**, una plataforma para gestionar objetos perdidos. Contiene la configuración de Docker y los scripts necesarios para clonar, construir, ejecutar y administrar los servicios del sistema.

## Requisitos previos

Antes de ejecutar el sistema, asegúrate de tener instalado y configurado lo siguiente:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y en ejecución.
- [Git](https://git-scm.com/) instalado.
- Acceso a los repositorios de los servicios, ya sea porque son públicos o porque tienes permisos como colaborador.

## Cómo levantar el sistema

### 1. Clonar el repositorio de infraestructura

Abre una terminal y ejecuta los siguientes comandos:

```bash
git clone <url-de-este-repo>
cd infraestructura
```

Reemplaza `<url-de-este-repo>` por la URL real del repositorio.

### 2. Ejecutar el script de arranque

En Windows, ejecuta:

```bat
start.bat
```

Este script se encarga de:

- Clonar los repositorios de los servicios que todavía no existan localmente.
- Crear el archivo `.env` a partir de `.env.example`, si es necesario.
- Construir las imágenes de Docker.
- Levantar los contenedores de los servicios.

### 3. Esperar a que los servicios estén disponibles

La primera ejecución puede tardar aproximadamente entre 2 y 3 minutos, dependiendo del equipo y de la conexión a Internet, debido a la descarga de dependencias y la compilación de los servicios.

### 4. Verificar el funcionamiento

Una vez iniciado el sistema, puedes comprobar los siguientes endpoints:

| Servicio | URL local |
|---|---|
| Eureka Server | http://localhost:8761 |
| API Gateway | http://localhost:8080 |
| Auth Service | http://localhost:8081 |
| Claim Service | http://localhost:8085 |

**Nota:** Que un endpoint responda no garantiza por sí solo que todas las funcionalidades estén operativas. Verifica también los registros de los contenedores si algún servicio presenta problemas.

## Servicios del sistema

| Servicio | Puerto | Repositorio |
|---|---:|---|
| `eureka-server` | 8761 | [Enlace al repositorio](<url-eureka-server>) |
| `api-gateway` | 8080 | [Enlace al repositorio](<url-api-gateway>) |
| `auth-service` | 8081 | [Enlace al repositorio](<url-auth-service>) |
| `claim-service` | 8085 | [Enlace al repositorio](<url-claim-service>) |

Reemplaza los enlaces de ejemplo por las URL reales de cada repositorio.

## Scripts disponibles

Los siguientes scripts permiten administrar el entorno de desarrollo:

| Script | Descripción |
|---|---|
| `start.bat` | Clona los repositorios faltantes, construye las imágenes y levanta los servicios. |
| `stop.bat` | Detiene los contenedores del sistema. |
| `update.bat` | Obtiene los cambios de los repositorios y reconstruye los servicios. |
| `reset.bat` | Reinicia el entorno desde cero y elimina los datos de las bases de datos, según la configuración del script. |

**Advertencia:** `reset.bat` puede provocar la pérdida irreversible de datos. Úsalo únicamente cuando quieras reiniciar el entorno y hayas respaldado la información necesaria.

## Cómo detener el sistema

Para detener los servicios mediante el script incluido, ejecuta:

```bat
stop.bat
```

También puedes detener los contenedores manualmente desde la carpeta que contiene el archivo `docker-compose.yml`:

```bash
docker compose down
```

Este comando detiene y elimina los contenedores creados por Compose, pero normalmente conserva los datos almacenados en volúmenes persistentes.

## Variables de entorno

El sistema utiliza variables de entorno para configurar la autenticación y la conexión a la base de datos.

El archivo `.env` se crea automáticamente a partir de `.env.example` durante el arranque, si el script está configurado para hacerlo.

Antes de iniciar los servicios, revisa que las variables requeridas estén definidas correctamente:

| Variable | Descripción |
|---|---|
| `JWT_SECRET` | Clave secreta utilizada para firmar y validar tokens JWT. Debe tener al menos 32 caracteres, de acuerdo con la configuración indicada. |
| `DB_USER` | Usuario de PostgreSQL. |
| `DB_PASSWORD` | Contraseña del usuario de PostgreSQL. |
| `DB_NAME` | Nombre de la base de datos. |

### Ejemplo de configuración

```dotenv
JWT_SECRET= reemplazar_por_una_clave_segura_de_al_menos_32_caracteres
DB_USER=tu_usuario
DB_PASSWORD=tu_contrasena
DB_NAME=lost_found
```

**Importante:**

- Sustituye los valores de ejemplo por los correspondientes a tu entorno.
- No compartas ni publiques el archivo `.env`.
- No subas credenciales reales al repositorio.
- Utiliza una clave JWT segura y suficientemente larga para el algoritmo de firma configurado.

## Solución de problemas

### Docker no está en ejecución

Abre Docker Desktop y espera hasta que el motor de Docker esté listo. Después, vuelve a ejecutar `start.bat`.

### Un servicio no inicia correctamente

Consulta los registros de los contenedores:

```bash
docker compose logs
```

Para consultar los registros de un servicio específico:

```bash
docker compose logs -f auth-service
```

Sustituye `auth-service` por el nombre del servicio que quieras revisar.

### Los cambios del código no se reflejan

Ejecuta `update.bat` para actualizar los repositorios y reconstruir los servicios, siempre que el script implemente esas operaciones correctamente.

Si el problema persiste, revisa los registros y verifica que los contenedores estén utilizando las imágenes actualizadas.

## Consideraciones adicionales

- Ejecuta los scripts desde la carpeta raíz del repositorio de infraestructura.
- Comprueba que los puertos requeridos estén disponibles antes de iniciar el sistema.
- Mantén Docker Desktop y Git actualizados.
- Conserva las credenciales y las claves secretas fuera del control de versiones.
- Antes de ejecutar operaciones de reinicio o limpieza, verifica si afectan los volúmenes persistentes y los datos almacenados.

