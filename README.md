## Deploying Wordpress site in LEMP stack on Docker container

   This is a Bash script to set up a new WordPress site using Docker containers for the LEMP stack. The script creates a new directory for the site, generates the necessary configuration files for    the Docker containers, and launches the containers using Docker Compose.

### Installation
#### 1.	Clone the repository:
    $ git clone https://github.com/AmanWalekar-99/rtcamp_assigment.git

#### 2.	Change directory to the cloned repository:
     $ cd wordpress-setup

#### 3. Make the script executable:
     $ chmod +x wordpress-setup.sh

### Usage
To create a new WordPress site, run the script with the site name as an argument:
$ sudo ./wordpress-setup.sh SITE_NAME
Replace **SITE_NAME** with the desired name for your WordPress site.
The script will create a new directory with the name SITE_NAME in the current working directory, generate the necessary configuration files, and launch the Docker containers.
By default, the site will be accessible at http://localhost:8085. You can change the port number by modifying the docker-compose.yml file.

### Subcommands
The script also supports the following subcommands:

#### 1.	Stop 
   To stop the Docker containers for the site, run:
    
    $ sudo ./wordpress-setup.sh SITE_NAME stop



#### 2.	Start
   To start the Docker containers for the site, run:
   
     $ sudo ./wordpress-setup.sh SITE_NAME start

#### 3.	Delete
   To delete the site and its associated Docker containers and files, run:
   
    $ sudo ./wordpress-setup.sh SITE_NAME delete
