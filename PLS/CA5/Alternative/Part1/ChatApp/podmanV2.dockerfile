# Use a base image with Java (JDK)
FROM eclipse-temurin:17-jdk-jammy

# Set working directory
WORKDIR /app

# Copy the pre-built JAR file into the container
COPY ./gradle_basic_demo/build/libs/basic_demo-0.1.0.jar .

CMD [ "java", "-jar", "/app/basic_demo-0.1.0.jar" ]