# Use a base image with Java (JDK)
FROM eclipse-temurin:17-jdk-jammy

# Set working directory
WORKDIR /app

# Copy the project files into the container
COPY . .

# === THIS INSTALLS DEPENDENCIES AND BUILDS THE APP ===
# The 'gradlew' script downloads Gradle and all Java dependencies
RUN cd ./gradle_basic_demo && chmod 700 ./gradlew && ./gradlew build
RUN chmod 700 ./gradle_basic_demo/build/libs/basic_demo-0.1.0.jar

CMD [ "java", "-jar", "/app/gradle_basic_demo/build/libs/basic_demo-0.1.0.jar" ]