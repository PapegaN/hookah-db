#!/bin/sh
set -eu

export PGPASSWORD="${POSTGRES_PASSWORD:-}"

apply_sql_dir() {
  target_dir="$1"

  if [ ! -d "$target_dir" ]; then
    return 0
  fi

  for file in "$target_dir"/*.sql; do
    if [ ! -e "$file" ]; then
      continue
    fi

    echo "Applying $file"
    psql \
      -v ON_ERROR_STOP=1 \
      -h "${POSTGRES_HOST:-db}" \
      -U "$POSTGRES_USER" \
      -d "$POSTGRES_DB" \
      -f "$file"
  done
}

apply_sql_dir /opt/hookah-db/migrations
apply_sql_dir /opt/hookah-db/seeds