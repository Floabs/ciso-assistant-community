#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <email>"
  exit 1
fi

# Load .env if present to pick up COMPOSE_FILE and other settings
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

COMPOSE_FILE_PATH=${COMPOSE_FILE:-config/docker-compose-barebone.yml}

echo "Using compose file: $COMPOSE_FILE_PATH"
EMAIL="$1"
docker compose -f "$COMPOSE_FILE_PATH" exec backend bash -c "cd /code && poetry run python manage.py shell -c \"from django.contrib.auth import get_user_model; import secrets,string; User=get_user_model(); pwd=''.join(secrets.choice(string.ascii_letters+string.digits) for _ in range(16)); email='${EMAIL}'; u=User.objects.filter(email=email).first() or User.objects.create_superuser(email=email, password=pwd); u.set_password(pwd); u.keep_local_login=True; u.save(); print('user:', u.email); print('password:', pwd)\""
