#!/bin/bash

# Exit immediately if a command fails, including in pipelines
set -eo pipefail

# Check for Docker
if ! command -v docker &> /dev/null; then
  echo "❌ Docker is not installed. Please install Docker before running this script."
  exit 1
fi

echo "🛠️  Building Docker images with Jib..."

# List of services that are local Maven projects (Java-based)
SERVICES=("patient-service" "billing-service" "analytics-service" "api-gateway" "auth-service")

for SERVICE in "${SERVICES[@]}"; do
  if [ ! -d "$SERVICE" ]; then
    echo "⚠️  Skipping $SERVICE (directory not found)"
    continue
  fi

  echo "🔧 Building $SERVICE..."
  if [ -f "$SERVICE/mvnw" ]; then
    (cd "$SERVICE" && ./mvnw clean compile jib:dockerBuild)
  else
    (cd "$SERVICE" && mvn clean compile jib:dockerBuild)
  fi
done

echo ""
echo "🧹 Stopping and removing previous Docker Compose services..."
docker compose down

echo ""
echo "📥 Pulling only public images (Kafka & Postgres)..."
docker pull bitnami/kafka:latest
docker pull postgres:latest

echo ""
echo "🚀 Starting Docker Compose stack in detached mode..."
docker compose up -d --build

echo ""
echo "⏳ Waiting for services with healthchecks to become healthy..."

MAX_WAIT=120  # Maximum wait time in seconds
WAIT_INTERVAL=5
ELAPSED=0

while true; do
  UNHEALTHY=0
  HEALTHY=0
  CHECKED=0

  for CONTAINER in $(docker ps --format '{{.Names}}'); do
    STATUS=$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo "none")
    if [ "$STATUS" == "starting" ]; then
      ((CHECKED++))
    elif [ "$STATUS" == "healthy" ]; then
      ((HEALTHY++))
      ((CHECKED++))
    elif [ "$STATUS" == "unhealthy" ]; then
      echo "❌ $CONTAINER is unhealthy."
      exit 1
    fi
  done

  if [ "$CHECKED" -gt 0 ] && [ "$HEALTHY" -eq "$CHECKED" ]; then
    echo "✅ All $HEALTHY containers with healthchecks are healthy."
    break
  fi

  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "⏰ Timeout reached after $MAX_WAIT seconds. Some services are still not healthy."
    docker compose ps
    exit 1
  fi

  sleep $WAIT_INTERVAL
  ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

echo ""
echo "💓 Healthcheck status of all containers (if defined):"
docker ps --format '{{.Names}}' | while read -r CONTAINER_NAME; do
  HEALTH_STATUS=$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "N/A")
  if [ "$HEALTH_STATUS" != "<no value>" ] && [ "$HEALTH_STATUS" != "N/A" ]; then
    STATUS_ICON="✅"
    [[ "$HEALTH_STATUS" == "unhealthy" ]] && STATUS_ICON="❌"
    echo "$STATUS_ICON $CONTAINER_NAME: $HEALTH_STATUS"
  fi
done

echo ""
echo "👀 Streaming logs from all services (Press Ctrl+C to stop)..."
docker compose logs -f
