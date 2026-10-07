#!bin/bash

set -e

export APP_DIR=/opt/app
mkdir -p $APP_DIR
cd $APP_DIR

apt update -y
apt install -y python3-pip git python3-venv nginx

pip3 install -r requirements.txt