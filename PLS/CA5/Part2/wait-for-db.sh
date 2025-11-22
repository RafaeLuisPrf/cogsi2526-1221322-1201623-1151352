#!/bin/bash

DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-9092}"
MAX_RETRIES=30
RETRY_INTERVAL=2

echo "Waiting for H2 database at $DB_HOST:$DB_PORT..."

for i in $(seq 1 $MAX_RETRIES); do
  if nc -z $DB_HOST $DB_PORT; then
    echo "H2 database is ready"
    echo "Starting Spring Boot application..."
    exec java -jar app.jar
    exit 0
  fi
  
  echo "Attempt $i/$MAX_RETRIES: H2 not ready yet, waiting ${RETRY_INTERVAL}s..."
  sleep $RETRY_INTERVAL
done

echo "ERROR: H2 database did not become ready in time"
echo "Check if the db container is running properly"
exit 1
