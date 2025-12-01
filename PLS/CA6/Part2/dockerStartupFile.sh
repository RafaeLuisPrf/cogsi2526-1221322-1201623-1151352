#!/bin/bash

DB_HOST="0.0.0.0"     # IP of your H2 VM
DB_PORT=9092          # H2 server port


java -cp /app/db.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -ifNotExists -baseDir /app &

echo "Waiting for H2 database at $DB_HOST:$DB_PORT..."

# Loop until the port is open
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 1
  echo "Still waiting for H2..."
done

echo "H2 is up! Starting Spring Boot app..."
java -Dspring.datasource.url="jdbc:h2:tcp://127.0.0.1:9092/file:/app/mydb" \
     -Dspring.jpa.hibernate.ddl-auto=none \
     -Dspring.sql.init.enabled=true \
     -Dspring.sql.init.mode=always \
     -jar /app/backend.jar --server.port=8081
