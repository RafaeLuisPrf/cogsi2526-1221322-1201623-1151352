#!/bin/bash
set -e


CLONE_REPO="${CLONE_REPO:-false}"
BUILD_APP_SPRING="${BUILD_APP_SPRING:-false}"
EXEC_APP_SPRING="${EXEC_APP_SPRING:-false}"
REPO_URL="${REPO_URL:-https://SantiagoAzevedo@github.com/RafaeLuisPrf/cogsi2526-1221322-1201623-1151352.git}"
REPO_DIR="$HOME/cogsi2526-1221322-1201623-1151352"
DB_HOST="${DB_HOST:-10.55.184.225}"
DB_PORT="${DB_PORT:-9092}"

echo "Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y git openjdk-17-jdk maven curl unzip zip netcat-openbsd

echo "Installing SDKMAN and Gradle..."
if [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
fi
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install gradle 8.5 || true

echo "Configuring Java..."
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
if ! grep -q "JAVA_HOME" ~/.bashrc; then
  echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> ~/.bashrc
  echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
fi


if ! grep -q "sdkman-init.sh" ~/.bashrc; then
  echo 'export SDKMAN_DIR="$HOME/.sdkman"' >> ~/.bashrc
  echo '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' >> ~/.bashrc
fi

if [ "$CLONE_REPO" = "true" ]; then
  echo "Cloning repository..."
  cd ~
  rm -rf "$REPO_DIR"
  git clone "$REPO_URL"
  echo "Repository successfully cloned!"
else
  echo "Repository clone skipped (CLONE_REPO=$CLONE_REPO)"
fi

if [ "$BUILD_APP_SPRING" = "true" ] || [ "$EXEC_APP_SPRING" = "true" ]; then
  echo "Configuring Spring Boot application for remote H2 database..."
  
  APP_PROPERTIES="$REPO_DIR/PLS/CA2/Part2/src/main/resources/application.properties"
  
  mkdir -p "$(dirname "$APP_PROPERTIES")"
  
  if [ -f "$APP_PROPERTIES" ] && [ ! -f "$APP_PROPERTIES.backup" ]; then
    cp "$APP_PROPERTIES" "$APP_PROPERTIES.backup"
    echo "Backup created: $APP_PROPERTIES.backup"
  fi
  
  echo "Creating application.properties for remote H2 at ${DB_HOST}:${DB_PORT}..."
  cat > "$APP_PROPERTIES" << EOF
    spring.datasource.url=jdbc:h2:tcp://${DB_HOST}:${DB_PORT}//home/ubuntu/h2/data/testdb;DB_CLOSE_ON_EXIT=FALSE;AUTO_RECONNECT=TRUE
    spring.datasource.driverClassName=org.h2.Driver
    spring.datasource.username=sa
    spring.datasource.password=
    spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
    spring.jpa.hibernate.ddl-auto=update
    spring.jpa.show-sql=true
    spring.h2.console.enabled=true
    spring.h2.console.path=/h2-console
    spring.h2.console.settings.web-allow-others=true
    server.port=8080
    logging.level.org.springframework=INFO
    logging.level.com.zaxxer.hikari=DEBUG
EOF
  
  echo "Application properties configured successfully!"
fi


if [ "$BUILD_APP_SPRING" = "true" ]; then
  echo "Building Spring Boot App..."
  cd "$REPO_DIR/PLS/CA2/Part2"
  
  gradle wrapper --gradle-version 8.5
  chmod +x gradlew
  ./gradlew clean build
  
  echo "Running Spring Boot App..."

  if [ -f "$HOME/start-app.sh" ]; then
    echo "Using start-app.sh with database health check..."
    "$HOME/start-app.sh"
  else
    echo "Warning: start-app.sh not found, running directly without health check..."
    ./gradlew bootRun
  fi
elif [ "$EXEC_APP_SPRING" = "true" ]; then
  echo "Running Spring Boot App (without build)..."
  cd "$REPO_DIR/PLS/CA2/Part2"
  
  if [ -f "$HOME/start-app.sh" ]; then
    echo "Using start-app.sh with database health check..."
    "$HOME/start-app.sh"
  else
    echo "Warning: start-app.sh not found, running directly without health check..."
    ./gradlew bootRun
  fi
else
  echo "Spring Boot App skipped"
fi
