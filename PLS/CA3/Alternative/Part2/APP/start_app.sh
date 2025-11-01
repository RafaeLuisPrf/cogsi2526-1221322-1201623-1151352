#!/bin/bash
set -e

DB_HOST="${DB_HOST:-10.55.184.225}"
DB_PORT="${DB_PORT:-9092}"
REPO_DIR="$HOME/cogsi2526-1221322-1201623-1151352"
APP_DIR="$REPO_DIR/PLS/CA2/Part2"
MAX_RETRIES=60
RETRY_INTERVAL=5

check_db() {
    nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null
    return $?
}

echo "Checking H2 database availability at ${DB_HOST}:${DB_PORT}..."
counter=0
until check_db; do
    counter=$((counter + 1))
    if [ $counter -eq $MAX_RETRIES ]; then
        echo "ERROR: Database not available after $MAX_RETRIES attempts"
        exit 1
    fi
    echo "Attempt $counter/$MAX_RETRIES: Database not ready. Waiting ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
done

echo "Database is ready!"
echo ""

if [ ! -d "$APP_DIR" ]; then
    echo "ERROR: Application directory not found at $APP_DIR"
    exit 1
fi

cd "$APP_DIR"

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

echo "Application directory: $APP_DIR"
echo "Database: ${DB_HOST}:${DB_PORT}"
echo ""

./gradlew bootRun