#!/bin/bash
set -e

installDocker() {
    curl -fsSL "https://get.docker.com" | /bin/bash
    sudo usermod -aG docker $(whoami)
}

changeDockerSource() {
    sudo cat>/etc/docker/daemon.json<<EOF
{
  "registry-mirrors" : [
    "https://6pgyz01d.mirror.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "debug" : true
}
EOF
}

installDockerCompose() {
  sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
}



# ensure amd64
if [ $(uname -m) != "x86_64" ]; then
    echo "Sorry, the architecture of your device is not supported yet."
    exit
fi

# ensure run as root
if [ $EUID -ne 0 ]; then
    echo "Please run as root"
    exit
fi

echo "
Now starting installation...
"

echo "starting update and install system packages..."

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install build-essential -y
sudo apt-get install -y  zlib1g-dev yasm screen 
sudo apt-get install zlib* -y
sudo apt-get install nano vim screen -y
sudo apt-get install git -y
sudo apt-get install python3-venv -y

if [ -x "$(command -v docker)" ]; then
    echo "docker found, skip installation"
    changeDockerSource
else
    echo "installing docker..."
    installDocker
    changeDockerSource
installDockerCompose
fi

echo "Pulling image..."
docker pull ghcr.io/mrs4s/go-cqhttp:1.0.0-beta8-fix2 # specify version

echo "Starting docker daemon"
sudo systemctl start docker

echo "create a new screen"

screen -dmS backend

echo "cloning repository..."
git clone https://hub.fastgit.org/BOTUnion/docker_backend.git
# wait for username and password

cd ./docker_backend

echo "create pyvenv..."
sudo python3 -m venv .

source ./bin/activate

echo "installing python packages..."
python3 -m pip install wheel
python3 -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

cp ./backend_config_default.json ./backend_config.json

echo "successfully finished."
echo "I. use screen -r backend enter screen session."
echo "II. configure ./backend_config.json"
echo "III. use source ./bin/activate to activate pyenv."
echo "IV. use python3 __init__.py to run."


