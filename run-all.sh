#!/bin/bash

# Fail script if any command fails
set -e

echo "🛠️  Building Docker images with Jib..."

SERVICES=("patient-service" "billing-service")

for SERVICE in "${SERVICES[@]}"; do
  echo "🔧 Building $SERVICE..."
  if [ -f "$SERVICE/mvnw" ]; then
    (cd $SERVICE && ./mvnw clean compile jib:dockerBuild)
  else
    (cd $SERVICE && mvn clean compile jib:dockerBuild)
  fi
done

echo ""
echo "🧹 Stopping and cleaning up previous Docker Compose services..."
docker compose down

echo ""
echo "🚀 Starting Docker Compose stack in detached mode..."
docker compose up -d --build

echo "✅ Docker Compose stack started. Logs saved to docker-up.log"

echo ""
echo "💓 Healthcheck status (if defined):"
docker inspect --format '{{.Name}}: {{.State.Health.Status}}' $(docker ps -q)
