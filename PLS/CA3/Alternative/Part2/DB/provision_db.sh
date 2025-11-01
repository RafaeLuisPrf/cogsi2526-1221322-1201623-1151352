#!/bin/bash
set -e

APP_HOST="${APP_HOST:-10.55.184.185}"

echo "Updating system and installing dependencies..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y openjdk-17-jdk ufw unzip

echo "Creating H2 directory..."
mkdir -p /home/ubuntu/h2
cd /home/ubuntu/h2

echo "Downloading H2 Database..."
wget https://github.com/h2database/h2database/releases/download/version-2.2.224/h2-2023-09-17.zip
unzip h2-2023-09-17.zip
rm h2-2023-09-17.zip

echo "Creating H2 startup script..."
cat > /home/ubuntu/h2/start-h2.sh << 'EOF'
#!/bin/bash
cd /home/ubuntu/h2/h2/bin
java -cp h2*.jar org.h2.tools.Server -tcp -tcpAllowOthers -ifNotExists -tcpPort 9092 -baseDir /home/ubuntu/h2/data
EOF

chmod +x /home/ubuntu/h2/start-h2.sh

echo "Creating H2 systemd service..."
sudo bash -c 'cat > /etc/systemd/system/h2.service << "EOF"
[Unit]
Description=H2 Database Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/h2
ExecStart=/home/ubuntu/h2/start-h2.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF'

echo "Creating H2 data directory..."
mkdir -p /home/ubuntu/h2/data

echo "Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow from $APP_HOST to any port 9092 proto tcp
sudo ufw --force enable

echo "Starting H2 service..."
sudo systemctl daemon-reload
sudo systemctl enable h2
sudo systemctl start h2