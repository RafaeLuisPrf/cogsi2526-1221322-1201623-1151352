# Use a base image that has Java installed
FROM eclipse-temurin:21-jdk-alpine

# Install necessary tools (like bash)
RUN apk update && apk add bash

# Set the working directory
WORKDIR /app

COPY db/h2/bin/*.jar /app/db.jar
COPY Web/build/libs/*.jar /app/backend.jar

COPY dockerStartupFile.sh /app/startupScript.sh
RUN chmod +x /app/startupScript.sh

EXPOSE 8081

CMD ["/app/startupScript.sh"]