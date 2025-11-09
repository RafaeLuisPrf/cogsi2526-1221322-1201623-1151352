include:
  - host1

spring_app_config:
  file.managed:
    - name: /opt/spring-app/src/main/resources/application.properties
    - contents: |
        spring.datasource.url=jdbc:h2:tcp://192.168.250.11:9092/~/test
        spring.datasource.driverClassName=org.h2.Driver
        spring.datasource.username=sa
        spring.datasource.password=
        spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
        spring.jpa.hibernate.ddl-auto=update
        server.port=8080
    - user: devuser
    - group: developers
    - mode: 660
    - makedirs: True
    - require:
      - file: copy_gradle_app

extend:
  spring_app_service:
    service.running:
      - watch:
        - file: spring_app_config

systemd_reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: spring_app_service

wait_for_database:
  cmd.run:
    - name: |
        echo "Waiting for H2 database at 192.168.250.11:9092..."
        timeout=60
        elapsed=0
        while ! nc -z 192.168.250.11 9092; do
          sleep 2
          elapsed=$((elapsed + 2))
          if [ $elapsed -ge $timeout ]; then
            echo "Timeout waiting for database"
            exit 0
          fi
        done
        echo "Database is ready!"
    - require:
      - pkg: install_required_packages
    - require_in:
      - service: spring_app_running

spring_app_running:
  service.running:
    - name: spring-app
    - enable: True
    - reload: True
    - init_delay: 10
    - require:
      - file: spring_app_service
      - cmd: systemd_reload
      - cmd: wait_for_database
    - watch:
      - file: spring_app_service
      - file: spring_app_config