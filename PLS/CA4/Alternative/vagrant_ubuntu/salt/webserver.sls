include:
  - users

install_required_packages:
  pkg.installed:
    - pkgs:
      - openjdk-17-jdk
      - unzip
      - netcat

app_directory:
  file.directory:
    - name: /opt/spring-app
    - user: devuser
    - group: developers
    - mode: 750
    - makedirs: True
    - require:
      - user: devuser
      - group: developers

copy_gradle_app:
  file.recurse:
    - name: /opt/spring-app
    - source: salt://host1/spring-rest
    - user: devuser
    - group: developers
    - require:
      - file: app_directory
      - pkg: install_required_packages

set_gradlew_permissions:
  file.managed:
    - name: /opt/spring-app/gradlew
    - mode: 755
    - replace: False
    - require:
      - file: copy_gradle_app

build_spring_app:
  cmd.run:
    - name: cd /opt/spring-app && ./gradlew clean build
    - runas: devuser
    - require:
      - file: set_gradlew_permissions

spring_app_service:
  file.managed:
    - name: /etc/systemd/system/spring-app.service
    - contents: |
        [Unit]
        Description=Spring REST Application
        After=network.target

        [Service]
        Type=simple
        User=devuser
        WorkingDirectory=/opt/spring-app
        ExecStart=/opt/spring-app/gradlew bootRun
        Restart=always
        RestartSec=10

        [Install]
        WantedBy=multi-user.target
    - mode: 644
    - require:
      - cmd: build_spring_app

  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: /etc/systemd/system/spring-app.service

  service.running:
    - name: spring-app
    - enable: True
    - require:
      - file: /etc/systemd/system/spring-app.service
      - cmd: build_spring_app
    - watch:
      - file: /etc/systemd/system/spring-app.service