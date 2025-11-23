# cogsi2526-1221322-1201623-1151352

## Self-evaluation

# TODO

Santiago-
Rafael -
Joao -

## Part 1

### 1 - Analysis / Requirements

### 2 - Design of the solution

### 3 - Implementation

## Part 2

### 1 - Analysis / Requirements

"The goal of Part 2 is to use Docker to create a containerized environment for running the Gradle version of the “Building REST Services with Spring” application"

The tasks to be performed are as follows:
- Use Docker Compose to create two containers
- Verify network connectivity between the web and db services
- Use a Docker volume in the db container to persist the database file
- Use Docker Compose environment variables to configure services
- Publish the images (db and web) to Docker Hub

### 2 - Design of the solution

The structure needed to meet all requirements will need a Docker compose for defining and orchestrating the services (web and database), networks, volumes, environment variables and healthchecks, an .env to declare environment variables that will be used to configure the containers, and a Dockerfile inside each folder that represents the content of each container, i.e., one for the database and another for the web. These Dockerfile files are used to build reproducible images that install dependencies, copy the application artifact, configure the runtime environment, and define the startup command (e.g., expose ports, set environment variables, and entrypoint):

    Part2
    ├───db
    │   |───h2
    |   |___Dockerfile.db
    │   |___...   
    |  
    |───Web
    |   |___Dockerfile.web
    |   |___...
    |
    |___Docker-compose.yml
    |___.env
        

### 3 - Implementation

#### Use Docker Compose (and Dockerfiles) to create two containers

**db**

In docker-compose:

```yaml
db:
    image: santiagoazevedo/h2-db:ca5-p2
    build:
      context: ./db
      dockerfile: Dockerfile.db
    container_name: db
    environment:
      - H2_OPTIONS=${H2_OPTIONS}
    ports:
      - "${DB_PORT}:9092"
      - "8082:8082"
    volumes:
      - h2-data:/h2
    networks:
      ca5-network:
        ipv4_address: 192.168.250.11
    healthcheck:
      test: ["CMD", "nc", "-z", "127.0.0.1", "9092"]
      interval: 15s
      timeout: 3s
      retries: 5
      start_period: 30s
```
In compose, the database service needs to be configured as follows:
- image
- build containing the path and dockerfile
- environment variables
- container ports
- volumes to persist data
- the network on which the container will be hosted
- healthcheck to verify that the service is operational

In addition, it is also necessary to configure Dockerfile.db:

```Dockerfile
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y openjdk-17-jre-headless wget netcat iputils-ping && \
    wget https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar -O /h2.jar && \
    apt-get clean

RUN mkdir -p /h2

ENV H2_OPTIONS="-ifNotExists -tcp -tcpAllowOthers -tcpPort 9092"

EXPOSE 9092

HEALTHCHECK --interval=10s --timeout=3s --start-period=30s --retries=3 \
    CMD nc -z localhost 9092 || exit 1

CMD java -cp /h2.jar org.h2.tools.Server \
    -baseDir /h2 \
    $H2_OPTIONS

```
This file performs the following tasks:

- defines the base image (Ubuntu 22.04 in this case)
- updates the package list and installs dependencies
- creates the /h2 directory where the database files will be stored
- defines an environment variable with default options to start the H2 server (will be used in CMD)
- documents that the image exposes port 9092
- defines a health check
- performs the container startup command, i.e., starts the H2 server

**web**

The web service has a configuration very similar to the db service, so the explanation will only identify the differences.

In docker-compose:

```yaml
web:
    image: santiagoazevedo/spring-web:ca5-p2
    build:
      context: ./web
      dockerfile: Dockerfile.web
    container_name: web
    environment:
      - SPRING_DATASOURCE_URL=${SPRING_DATASOURCE_URL}
      - SPRING_DATASOURCE_USERNAME=${DB_USERNAME}
      - SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
      - SPRING_DATASOURCE_DRIVERCLASSNAME=${SPRING_DATASOURCE_DRIVER}
      - SPRING_JPA_DATABASE_PLATFORM=${SPRING_JPA_DATABASE_PLATFORM}
      - SPRING_JPA_HIBERNATE_DDL_AUTO=${SPRING_JPA_HIBERNATE_DDL_AUTO}
      - SPRING_JPA_SHOW_SQL=${SPRING_JPA_SHOW_SQL}
    ports:
      - "${WEB_PORT}:8080"
    depends_on:
      db:
        condition: service_healthy
    networks:
      ca5-network:
        ipv4_address: 192.168.250.10
```
The only differences are the variables that are necessary to connect to the database and the depends_on, which is used to check the status of the db service (which will be explained later)

In Dockerfile.web:

```Dockerfile
FROM gradle:8.5-jdk17 AS builder

WORKDIR /app

COPY --chown=gradle:gradle gradlew gradlew
COPY --chown=gradle:gradle gradle gradle
COPY --chown=gradle:gradle build.gradle settings.gradle gradle.properties ./
RUN chmod +x ./gradlew

COPY --chown=gradle:gradle . /app
RUN ./gradlew clean build -x test --no-daemon

FROM ubuntu:22.04

WORKDIR /app

RUN apt-get update && apt-get install -y openjdk-17-jre-headless netcat iputils-ping bash && apt-get clean
COPY --from=builder /app/build/libs/*.jar app.jar

ENV SPRING_DATASOURCE_URL=jdbc:h2:tcp://db:9092/./jpadb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
ENV SPRING_DATASOURCE_USERNAME=sa
ENV SPRING_DATASOURCE_PASSWORD=
ENV SPRING_DATASOURCE_DRIVERCLASSNAME=org.h2.Driver
ENV SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.H2Dialect

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

The dockerfile is not very different from dockerfile.db. The only differences are in the execution of gradle, to start the application, and the variables that are customized for this service.

#### Verify network connectivity between the web and db services

To test connectivity between containers from the hostname, it is possible to use the following command:

```powershell
PS C:\Users\Admin\Documents\GitHub\cogsi2526-1221322-1201623-1151352\PLS\CA5\Part2> docker exec -it web ping -c 3 db            
    PING db (192.168.250.11) 56(84) bytes of data.
    64 bytes from db.part2_ca5-network (192.168.250.11): icmp_seq=1 ttl=64 time=0.164 ms
    64 bytes from db.part2_ca5-network (192.168.250.11): icmp_seq=2 ttl=64 time=0.070 ms
    64 bytes from db.part2_ca5-network (192.168.250.11): icmp_seq=3 ttl=64 time=0.052 ms

    --- db ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2071ms
    rtt min/avg/max/mdev = 0.052/0.095/0.164/0.049 ms
```

(To test the reverse connection, simply change the order of the containers in the command)

**Healthcheck**

A health check is created so that the web application only starts when the database is active:

```yaml
healthcheck:
      test: ["CMD", "nc", "-z", "127.0.0.1", "9092"]
      interval: 15s
      timeout: 3s
      retries: 5
      start_period: 30s
```

For the check to be performed on the web service, it is necessary to configure the following piece of code that defines that the web service depends on the “health of the database service”:

```yaml
depends_on:
    db:
        condition: service_healthy
```

#### Use a Docker volume in the db container to persist the database file

To persist the data even if the container is restarted, it is necessary to create a volume and add its path to the database service:

**On db service:**
```yaml
volumes:
      - h2-data:/h2
```
**General:**
```yaml
volumes:
  h2-data:
    driver: local
```
Now, when an entry is added, it will persist even after restarting the containers in the specified location.

#### Use Docker Compose environment variables to configure services

The .env file is created, which contains all the project variables, namely the ports for the services, the database information (credentials, path), among others:

**.env file**
```properties
DB_USERNAME=sa
DB_PASSWORD=password123
DB_NAME=jpadb
DB_PORT=9092
H2_OPTIONS=-ifNotExists -tcp -tcpAllowOthers -tcpPort 9092 -web -webAllowOthers -webPort 8082
WEB_PORT=8080
SPRING_DATASOURCE_URL=jdbc:h2:tcp://db:9092/./jpadb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
SPRING_DATASOURCE_DRIVER=org.h2.Driver
SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.H2Dialect
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_JPA_SHOW_SQL=true
```

These variables are called in the application properties and have priority, meaning they will be used even over the variables in Dockerfile.web:

**application properties**
```properties
spring.datasource.url=jdbc:h2:tcp://${DB_HOST:db}:${DB_PORT:9092}/${DB_NAME:~/mydb}
spring.datasource.username=${DB_USER:sa}
spring.datasource.password=${DB_PASSWORD:}
```
**Dockerfile web**
```properties
ENV SPRING_DATASOURCE_URL=jdbc:h2:tcp://db:9092/./jpadb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
ENV SPRING_DATASOURCE_USERNAME=sa
ENV SPRING_DATASOURCE_PASSWORD=
ENV SPRING_DATASOURCE_DRIVERCLASSNAME=org.h2.Driver
ENV SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.H2Dialect
```

#### Publish the images (db and web) to Docker Hub

Finally, to publish the images to Docker Hub, it is necessary to define the names of the images (in this case, santiagoazevedo/h2-db and /spring-web), log in with a Docker account, and then build and use the docker compose push command:

![Docker hub](Images/Part2/docker_hub.png)

## Alternative solution

### 1 - Analysis / Requirements

### 2 - Design of the solution

### 3 - Implementation
