#!/bin/bash

# Fail script if any command fails
set -e

echo "🛠️  Building Docker images with Jib..."

SERVICES=("patient-service" "billing-service" "analytics-service")

for SERVICE in "${SERVICES[@]}"; do
  echo "🔧 Building $SERVICE..."
  if [ -f "$SERVICE/mvnw" ]; then
    (cd "$SERVICE" && ./mvnw clean compile jib:dockerBuild)
  else
    (cd "$SERVICE" && mvn clean compile jib:dockerBuild)
  fi
done

echo ""
echo "🧹 Stopping and cleaning up previous Docker Compose services..."
docker compose down

echo ""
echo "🚀 Starting Docker Compose stack in detached mode..."
docker compose up -d --build

echo "✅ Docker Compose stack started."

echo ""
echo "💓 Healthcheck status (if defined):"
# Filtriramo samo pokrenute kontejnere koji imaju healthcheck definisan
docker ps --format '{{.Names}}' | while read -r CONTAINER_NAME; do
  HEALTH_STATUS=$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "N/A")
  if [ "$HEALTH_STATUS" != "<no value>" ] && [ "$HEALTH_STATUS" != "N/A" ]; then
    echo "$CONTAINER_NAME: $HEALTH_STATUS"
  fi
done

echo ""
echo "👀 Streaming logs from all services (Ctrl+C to stop)..."
# Dodajemo ovu liniju da pratimo logove svih servisa
docker compose logs -f