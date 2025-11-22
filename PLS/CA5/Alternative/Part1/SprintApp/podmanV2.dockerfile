# Use a base image with Java (JDK)
FROM eclipse-temurin:17-jdk-jammy

# Set working directory
WORKDIR /app

# Copy the pre-built JAR file into the container
COPY ./Web/build/libs/Part2-0.0.1-SNAPSHOT.jar .

CMD [ "java", "-jar", "/app/Part2-0.0.1-SNAPSHOT.jar" ]