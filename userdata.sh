#!/bin/bash

set -e

export APP_DIR=/opt/app
mkdir -p $APP_DIR
cd $APP_DIR

apt update -y
apt install -y python3 git python3-venv nginx

git clone https://github.com/subramanian252/mlops-intent-classifier.git .
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt

python3 model/train.py


cat >/etc/systemd/system/mlops-intent-classifier.service <<EOL
[Unit]
Description=mlops-intent-classifier service
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/.venv/bin"
ExecStart=/bin/bash -c "source .venv/bin/activate && gunicorn --workers 3 --bind 127.0.0.1:6000 wsgi:app"
Restart=always
[Install]
WantedBy=multi-user.target
EOL

cat >/etc/nginx/conf.d/mlops-intent-classifier.conf <<'EOL'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:6000/predict;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_connect_timeout 60s;
        proxy_read_timeout 120s;
    }
}
EOL

chown -R ubuntu:ubuntu "$APP_DIR"


rm -f /etc/nginx/sites-enabled/default

nginx -t

systemctl daemon-reload
systemctl enable mlops-intent-classifier
systemctl start mlops-intent-classifier
systemctl enable nginx
systemctl restart nginx
echo "Done"