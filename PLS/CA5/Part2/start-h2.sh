#!/bin/bash

echo "Starting H2 Database Server..."

java -cp /h2/bin/h2*.jar org.h2.tools.Server \
  -tcp \
  -tcpAllowOthers \
  -tcpPort 9092 \
  -ifNotExists \
  -baseDir /h2data
