# Use a base image with Java (JDK)
FROM eclipse-temurin:17-jdk-jammy

# Set working directory
WORKDIR /app

# Copy the project files into the container
COPY . .

# === THIS INSTALLS DEPENDENCIES AND BUILDS THE APP ===
# The 'gradlew' script downloads Gradle and all Java dependencies
RUN cd ./Web && chmod 700 ./gradlew && ./gradlew build
RUN chmod 700 ./Web/build/libs/Part2-0.0.1-SNAPSHOT.jar

CMD [ "java", "-jar", "/app/Web/build/libs/Part2-0.0.1-SNAPSHOT.jar" ]