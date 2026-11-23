#!/usr/bin/env bash
# Lost & Found - orquestador (Git Bash en Windows, Linux y macOS)
# Uso: ./lost.sh {start|stop|restart|update|reset|status|health|logs|help}
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

ORG_URL="https://github.com/objetos-perdidos-uptc"
SERVICES=(eureka api-gateway auth-service claim-service-legacy report-service matching-service notification-service)
REQUIRED_VARS=(JWT_SECRET DB_NAME DB_USER DB_PASSWORD DB_PORT MONGO_PORT REDIS_PORT RABBITMQ_PORT RABBITMQ_MGMT_PORT RABBITMQ_USER RABBITMQ_PASSWORD)
WAIT_SECONDS=180

# --- utilidades -------------------------------------------------------------
info() { printf '\033[36m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m%s\033[0m\n' "$*"; }
warn() { printf '  \033[33m[AVISO]\033[0m %s\n' "$*"; }
fail() { printf '\033[31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

compose() {
  if docker compose version >/dev/null 2>&1; then docker compose "$@"; else docker-compose "$@"; fi
}

get_var() { # valor de una variable del .env (sin comillas ni CR)
  grep -E "^$1=" .env 2>/dev/null | tail -n 1 | cut -d= -f2- | tr -d '\r"' || true
}

check_tools() {
  command -v git >/dev/null 2>&1    || fail "Git no esta instalado."
  command -v docker >/dev/null 2>&1 || fail "Docker no esta instalado."
  docker info >/dev/null 2>&1       || fail "Docker no esta corriendo. Abre Docker Desktop y reintenta."
  command -v curl >/dev/null 2>&1   || warn "curl no encontrado: se omiten las verificaciones de salud."
}

clone_repos() {
  info "[1/3] Verificando repositorios..."
  for s in "${SERVICES[@]}"; do
    if [[ -d "$s/.git" ]]; then
      ok "$s OK"
    elif [[ -e "$s" ]]; then
      fail "'$s' existe pero no es un repo git. Borralo o muevelo y reintenta."
    else
      echo "  Clonando $s..."
      git clone --quiet "$ORG_URL/$s.git" "$s" || fail "No se pudo clonar $s (permisos o red)."
    fi
  done
}

ensure_env() {
  info "[2/3] Verificando .env..."
  if [[ ! -f .env ]]; then
    cp .env.example .env
    echo "  Se creo .env desde .env.example."
  fi

  # JWT_SECRET: si sigue el placeholder, generar uno aleatorio
  if [[ "$(get_var JWT_SECRET)" == "CAMBIAME" ]]; then
    local secret tmp
    secret="$(head -c 64 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | cut -c1-48)"
    tmp="$(mktemp)"
    sed "s|^JWT_SECRET=.*|JWT_SECRET=${secret}|" .env > "$tmp" && cat "$tmp" > .env && rm -f "$tmp"
    ok "JWT_SECRET generado automaticamente."
  fi

  local missing=()
  for v in "${REQUIRED_VARS[@]}"; do
    [[ -n "$(get_var "$v")" ]] || missing+=("$v")
  done
  (( ${#missing[@]} == 0 )) || fail "Faltan variables en .env: ${missing[*]}"

  local jwt; jwt="$(get_var JWT_SECRET)"
  (( ${#jwt} >= 32 )) || fail "JWT_SECRET debe tener al menos 32 caracteres (tiene ${#jwt})."

  [[ -n "$(get_var BREVO_API_KEY)" ]] || warn "BREVO_API_KEY vacia: notification-service arrancara pero no enviara correos."
  ok ".env OK"
}

wait_ready() {
  command -v curl >/dev/null 2>&1 || return 0
  info "Esperando a Eureka y al Gateway (max ${WAIT_SECONDS}s)..."
  local waited=0
  until curl -fs -o /dev/null http://localhost:8761/eureka/apps && curl -s -o /dev/null http://localhost:8080/; do
    sleep 3; waited=$((waited + 3))
    if (( waited >= WAIT_SECONDS )); then
      warn "Aun no responden. Revisa: ./lost.sh logs"
      return 0
    fi
  done
  ok "Eureka y Gateway respondiendo."
}

print_urls() {
  cat <<EOF

============================================
  Sistema levantado
============================================
  Eureka:            http://localhost:8761
  API Gateway:       http://localhost:8080
  Auth Service:      http://localhost:8081
  Report Service:    http://localhost:8082/docs
  Matching Service:  http://localhost:8000/docs
  Claim Service:     http://localhost:8085
  RabbitMQ (panel):  http://localhost:15672

  ./lost.sh health | status | logs | update | stop | reset
============================================
EOF
}

# --- comandos ---------------------------------------------------------------
cmd_start() {
  check_tools; clone_repos; ensure_env
  info "[3/3] Construyendo imagenes y levantando servicios (la primera vez tarda varios minutos)..."
  compose up --build -d
  wait_ready
  print_urls
}

cmd_stop() {
  check_tools
  info "Deteniendo sistema..."
  compose down
  echo "Sistema detenido. Los datos de las bases de datos se conservan."
}

cmd_restart() {
  check_tools
  if (( $# > 0 )); then compose restart "$@"; else compose restart; fi
}

cmd_update() {
  check_tools; ensure_env
  info "Actualizando codigo desde los repos..."
  for s in "${SERVICES[@]}"; do
    if [[ -d "$s/.git" ]]; then
      echo "  $s..."
      git -C "$s" pull --ff-only --quiet || warn "No se pudo actualizar $s (cambios locales o ramas divergentes)."
    else
      warn "$s no esta clonado. Ejecuta ./lost.sh start primero."
    fi
  done
  info "Reconstruyendo y reiniciando servicios..."
  compose up --build -d
  wait_ready
}

cmd_reset() {
  check_tools
  cat <<'EOF'
============================================
  ADVERTENCIA
============================================
Esto ELIMINARA los contenedores Y todos los datos:
Postgres, Mongo, RabbitMQ y fotos de reportes.
Usuarios, reportes y reclamos se perderan.
EOF
  read -r -p "Escribe 'si' para continuar: " answer
  [[ "$answer" == "si" ]] || { echo "Cancelado."; exit 0; }
  ensure_env
  compose down -v
  compose up --build -d
  wait_ready
  echo "Sistema reiniciado con bases de datos vacias."
}

cmd_status() { check_tools; compose ps; }

cmd_health() {
  check_tools
  command -v curl >/dev/null 2>&1 || fail "Se necesita curl."
  info "Endpoints:"
  local checks=(
    "Eureka|http://localhost:8761/eureka/apps"
    "API Gateway|http://localhost:8080/"
    "Auth Service|http://localhost:8081/"
    "Claim Service|http://localhost:8085/"
    "Report Service|http://localhost:8082/health"
    "Matching Service|http://localhost:8000/health"
    "RabbitMQ panel|http://localhost:15672/"
  )
  for c in "${checks[@]}"; do
    local name="${c%%|*}" url="${c#*|}" code
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$url" || true)"
    if [[ "$code" =~ ^[0-9]+$ && "$code" != "000" ]]; then
      printf '  \033[32m%-18s UP (%s)\033[0m\n' "$name" "$code"
    else
      printf '  \033[31m%-18s DOWN\033[0m\n' "$name"
    fi
  done
  info "Registrados en Eureka:"
  curl -s --max-time 3 -H 'Accept: application/json' http://localhost:8761/eureka/apps \
    | grep -o '"app":"[A-Z-]*"' | sort -u | sed 's/"app":"\(.*\)"/  \1/' || echo "  (Eureka no responde)"
}

cmd_logs() { check_tools; compose logs -f --tail 100 "$@"; }

usage() {
  cat <<'EOF'
Uso: ./lost.sh <comando>

  start            Clona repos faltantes, valida .env, construye y levanta todo
  stop             Detiene los contenedores (conserva los datos)
  restart [svc]    Reinicia todo o un servicio (nombre del compose, ej: auth-service)
  update           git pull en cada servicio y reconstruye
  reset            Borra contenedores y volumenes (pide confirmacion)
  status           Estado de los contenedores
  health           Prueba los endpoints y lista lo registrado en Eureka
  logs [svc]       Sigue los logs (todos o de un servicio)
EOF
}

case "${1:-help}" in
  start)   cmd_start ;;
  stop)    cmd_stop ;;
  restart) shift; cmd_restart "$@" ;;
  update)  cmd_update ;;
  reset)   cmd_reset ;;
  status)  cmd_status ;;
  health)  cmd_health ;;
  logs)    shift; cmd_logs "$@" ;;
  help|-h|--help) usage ;;
  *)       usage; exit 1 ;;
esac
