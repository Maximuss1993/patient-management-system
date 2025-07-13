#!/bin/bash

# Exit immediately if any command fails
set -eo pipefail

REMOVE_VOLUMES=false

# Check if user passed --volumes flag
if [[ "$1" == "--volumes" ]]; then
  REMOVE_VOLUMES=true
fi

echo "🧹 Stopping Docker Compose stack..."
docker compose down

# Optional: show ports still listening (debugging)
echo ""
echo "🔎 Ports still in use (if any):"
sudo lsof -i -P -n | grep LISTEN || echo "✅ No open ports detected."

# Ask user interactively if volumes should be deleted (if not passed as flag)
if [ "$REMOVE_VOLUMES" = false ]; then
  echo ""
  read -p "🗑️  Do you also want to remove named volumes (e.g. database data)? [y/N]: " CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]] && REMOVE_VOLUMES=true
fi

# Remove named volumes if confirmed or flag used
if [ "$REMOVE_VOLUMES" = true ]; then
  echo "🔻 Removing Docker volumes..."
  docker volume rm $(docker volume ls -q --filter "dangling=false" --filter name=postgres-data) || true
else
  echo "ℹ️  Volumes not removed."
fi

echo ""
echo "✅ Docker Compose services stopped."
