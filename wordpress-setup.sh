#!/bin/bash

#Check for docker and docker-compose if not present then install

docker --version >> /dev/null
if [ $? -eq 0 ]
then
  echo "Docker is installed"
else
  echo "Docker is not present... Installing Docker"
  sudo apt-get update &>> /dev/null
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update $>> /dev/null
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io &>> /dev/null
fi
#check if docker compose is installed

docker-compose --version &>> /dev/null
if [ $? -eq 0 ]
then
  echo "Docker compose is installed"
else
  apt-get install docker-compose -y &>> /dev/null
fi


#Prompting user to provide site name in command line argument in variable

# Check if site name is provided
if [ $# -eq 0 ]
then
  echo "Error: site name is required."
  echo "create SITE_NAME"
  exit 1
fi

# Get site name from command-line argument
SITE_NAME=$1


echo "New wordpress site creating with name ${SITE_NAME}"

mkdir "${SITE_NAME}"
cd "${SITE_NAME}"

#Creating docker compose and nginx config file

echo "Creating nginx config file in directory"

# adding Configuraation to config file
cat > nginx.conf << EOF
worker_processes 1;

events { worker_connections 1024; }

http {

    sendfile on;

    upstream wordpress {
        server wordpress:80;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://wordpress;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}

EOF
echo "Config file has been created"
cd ..

#Creating docker compose file
cat > docker-compose.yml << EOF
version: '3'

services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: wp-db
      MYSQL_USER: wp-user
      MYSQL_PASSWORD: wp-pass

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    ports:
      - "8000:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wp-user
      WORDPRESS_DB_PASSWORD: wp-pass
      WORDPRESS_DB_NAME: wp-db

  nginx:
    depends_on:
      - wordpress
    image: nginx:latest
    ports:
      - "8081:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    restart: always

  php:
    depends_on:
      - db
    image: php:7.4-fpm
    volumes:
      - ./wordpress:/var/www/html
    restart: always

volumes:
  db_data:

EOF
echo "Docker compose file has been created"

#Entry in /etc/hosts file
echo "127.0.0.1 $SITE_NAME" >> /etc/hosts

#Creating LEMP stack
echo "running LEMP stack in docker for wordpress"
docker-compose up -d &>> /dev/null
echo "created"

# prompting user to open site in browser
echo "Site is up and healthy. Open $SITE_NAME in any browser to view it."
echo "Or type http://localhost:8081"

#Adding subcommand to enable/disable the site (stopping/starting the containers)
# Check if subcommand is provided
if [ $# -eq 1 ]
then
  if [ $2 == "stop" ]
  then
    echo "Stopping the site containers"
    docker-compose stop
    exit 0
  elif [ $2 == "start" ]
  then
    echo "Starting the site containers"
    docker-compose start
    exit 0
  fi
fi

#subcommand to delete the site (deleting containers and local files)
if [ $# -eq 1 ]
then
  if [ $2 == "delete" ]
  then
    echo "Deleting the site and containers"
    docker-compose down -v

#removing hosts entry
    sed -i "/$SITE_NAME/d" /etc/hosts

#removing all local files
    rm -rf ./
  fi
fi
