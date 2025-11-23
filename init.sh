#!/bin/sh

apk add --no-cache docker-cli docker-cli-compose
apk add --no-cache php php-phar php-iconv php-mbstring
apk --update add curl zip make sudo nmap git

# Vérification de l'état du service Docker sans systemctl
if ! ps | grep -v grep | grep dockerd > /dev/null; then
  echo "Docker daemon is not running. Starting Docker daemon..."
  dockerd &
  sleep 5  # Attendez quelques secondes que Docker Daemon démarre
fi

# Configuration iptables si nécessaire
if ! iptables -t nat -L | grep -q DOCKER; then
  echo "Setting up iptables for Docker..."
  sudo iptables -t nat -N DOCKER
fi

# Ajout de l'utilisateur au groupe Docker
if id -nG "$USER" | grep -qw docker; then
  echo "User $USER is already in the docker group."
else
  echo "Adding user $USER to the docker group..."
  addgroup -g $(stat -c "%g" /var/run/docker.sock) docker
  adduser $USER docker
fi

curl -sSk https://getcomposer.org/installer | php -- --disable-tls && mv composer.phar /usr/local/bin/composer