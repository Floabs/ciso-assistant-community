#! /bin/bash
set -euo pipefail

ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
  # export variables defined in .env so docker compose and this script share them
  set -a
  . "$ENV_FILE"
  set +a
fi

COMPOSE_FILE_PATH=${COMPOSE_FILE:-docker-compose.yml}
COMPOSE_DIR=$(dirname "$COMPOSE_FILE_PATH")
DB_PATH="$COMPOSE_DIR/db"

if [ -d "$DB_PATH" ]; then
  echo "The database seems already created at $DB_PATH. You should launch 'docker compose up -d' instead."
  echo "For a clean start, you can remove the db folder, and then run 'docker compose rm -fs' and start over"
  exit 1
fi

echo "Starting CISO Assistant services..."
echo "Using compose file: $COMPOSE_FILE_PATH"
docker compose -f "$COMPOSE_FILE_PATH" pull
echo "Initializing the database. This can take up to 2 minutes, please wait.."
docker compose -f "$COMPOSE_FILE_PATH" up -d

echo "Waiting for CISO Assistant backend to be ready..."
until docker compose -f "$COMPOSE_FILE_PATH" exec -T backend curl -f http://localhost:8000/api/health/ >/dev/null 2>&1; do
  echo "Backend is not ready - waiting 10s..."
  sleep 10
done

echo -e "Backend is ready!"
echo "Creating superuser..."
docker compose -f "$COMPOSE_FILE_PATH" exec backend poetry run python manage.py createsuperuser

echo -e "Initialization complete!"
echo "You can now access CISO Assistant at ${CISO_ASSISTANT_URL:-https://localhost:8443} (or the host:port you've specified)"
