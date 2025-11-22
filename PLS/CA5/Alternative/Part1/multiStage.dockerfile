FROM eclipse-temurin:17-jdk-jammy as builder

WORKDIR /app

# Copy the project files into the container
COPY . .

# === THIS INSTALLS DEPENDENCIES AND BUILDS THE APP ===
# The 'gradlew' script downloads Gradle and all Java dependencies
RUN cd ./SprintApp/Web && chmod 700 ./gradlew && ./gradlew build
RUN chmod 700 ./SprintApp/Web/build/libs/Part2-0.0.1-SNAPSHOT.jar

# Stage 2

FROM gcr.io/distroless/java17

WORKDIR /app

COPY --from=builder /app/SprintApp/Web/build/libs/Part2-0.0.1-SNAPSHOT.jar /app/Part2.jar

CMD [ "java", "-jar", "/app/Part2.jar" ]