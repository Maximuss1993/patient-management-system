#!/bin/bash

# Fail script if any command fails
set -e

echo "🛠️  Building Docker images with Jib..."

SERVICES=("patient-service" "billing-service")

for SERVICE in "${SERVICES[@]}"; do
  echo "🔧 Building $SERVICE..."
  if [ -f "$SERVICE/mvnw" ]; then
    (cd $SERVICE && ./mvnw compile jib:dockerBuild)
  else
    (cd $SERVICE && mvn compile jib:dockerBuild)
  fi
done

echo "🚀 Starting Docker Compose..."
docker compose down
docker compose up --build
