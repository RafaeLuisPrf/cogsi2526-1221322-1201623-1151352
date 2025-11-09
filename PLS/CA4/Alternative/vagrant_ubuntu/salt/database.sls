include:
  - users

install_h2:
  pkg.installed:
    - pkgs:
      - openjdk-17-jdk
      - unzip
      - wget

h2_directory:
  file.directory:
    - name: /opt/h2
    - user: devuser
    - group: developers
    - mode: 750
    - makedirs: True
    - require:
      - user: devuser
      - group: developers

download_h2:
  cmd.run:
    - name: wget https://repo1.maven.org/maven2/com/h2database/h2/2.1.214/h2-2.1.214.jar -O /opt/h2/h2.jar
    - unless: test -f /opt/h2/h2.jar
    - require:
      - pkg: install_h2
      - file: h2_directory

create_h2_data:
  cmd.run:
    - name: |
        mkdir -p /opt/h2/data
        chown -R devuser:developers /opt/h2
    - require:
      - cmd: download_h2

h2_service:
  file.managed:
    - name: /etc/systemd/system/h2.service
    - contents: |
        [Unit]
        Description=H2 Database Server
        After=network.target

        [Service]
        Type=simple
        User=devuser
        ExecStart=/usr/bin/java -cp /opt/h2/h2.jar org.h2.tools.Server -tcp -web -baseDir /opt/h2/data -webAllowOthers -tcpAllowOthers
        Restart=always
        RestartSec=10

        [Install]
        WantedBy=multi-user.target
    - mode: 644
    - require:
      - cmd: create_h2_data

  service.running:
    - name: h2
    - enable: True
    - watch:
      - file: /etc/systemd/system/h2.service