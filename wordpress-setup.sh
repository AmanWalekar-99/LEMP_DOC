#!/bin/bash

#Check for docker and docker-compose if not present then install
docker --version >> /dev/null
if [ $? -eq 0 ]
then
  echo "Docker is installed"
else
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
fi
#check if docker compose is installed

docker-compose --version &>> /dev/null
if [ $? -eq 0 ]
then
  echo "Docker compose is installed"
else
  apt-get install docker-compose -y
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

#release port
fuser -k 8085/tcp

#Creating docker compose and nginx config file

echo "Creating nginx config file in conf.d directory"
mkdir conf.d
cd conf.d

# adding Configuraation to config file
cat > nginx.conf << EOF
server {
  listen 80;
  listen [::]:80;
  server_name localhost;

  root /var/www/html;

  access_log off;

  index index.php;

  server_tokens off;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass wordpress-fpm:9000;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param SCRIPT_NAME $fastcgi_script_name;
  }

}
EOF
echo "Config file has been created"
cd ..

#Creating docker compose file
cat > docker-compose.yml << EOF
version: "3.7"
services:

  db:
    image: mariadb:10
    container_name: wp-db
    environment:
      MYSQL_DATABASE: wp-db
      MYSQL_USER: wp-user
      MYSQL_PASSWORD: wp-pass
      MYSQL_ROOT_PASSWORD: password

  wordpress-fpm:
    image: wordpress:latest
    container_name: wp-fpm
    links:
      - db
    volumes:
      - wp_files:/var/www/html
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: wp-db
      WORDPRESS_DB_USER: wp-user
      WORDPRESS_DB_PASSWORD: wp-pass

  nginx:
    image: nginx:alpine
    container_name: wp-nginx
    depends_on:
      - wordpress-fpm
    ports:
      - 8085:80
    volumes:
      - ./conf.d:/etc/nginx/conf.d
      - wp_files:/var/www/html

volumes:
  wp_files:
EOF
echo "Docker compose file has been created"

#Entry in /etc/hosts file
echo "127.0.0.1 $SITE_NAME" >> /etc/hosts

#Creating LEMP stack
echo "running LEMP stack in docker for wordpress"
docker-compose up -d
echo "created"

# prompting user to open site in browser
echo "Site is up and healthy. Open $SITE_NAME in any browser to view it."
echo "Or type http://localhost:8085"

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
