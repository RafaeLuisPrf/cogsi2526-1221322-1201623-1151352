#!/bin/bash

DB_HOST="192.168.250.11"     # IP of your H2 VM
DB_PORT=9092                # H2 server port

echo "Waiting for H2 database at $DB_HOST:$DB_PORT..."

# Loop until the port is open
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 1
  echo "Still waiting for H2..."
done

echo "H2 is up! Starting Spring Boot app..."
./gradlew run
