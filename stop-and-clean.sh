#!/bin/bash

# Exit immediately if any command fails
set -eo pipefail

echo "🧹 Stopping Docker Compose stack..."
docker compose down

echo ""
read -p "🗑️  Do you also want to remove named volumes (e.g. database data)? [y/N]: " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "🔻 Removing Docker volumes..."
  docker volume rm $(docker volume ls -q --filter "dangling=false" --filter name=postgres-data) || true
else
  echo "ℹ️  Volumes not removed."
fi

echo ""
echo "✅ Docker Compose services stopped."
