#!/bin/bash

# check that mongodb is up and running
MONGOD_PID=`pgrep mongod`
if [[ -n $MONGOD_PID ]]; then
    echo "Make sure mongod is running on default port 27017"
    echo "You can check by running: $ sudo lsof -iTCP -sTCP:LISTEN | grep mongod"
    echo "Will add smarter logic later"
else
    echo "Launching mongod and logging to syslog"
    # make sure that default data/db location is there
    sudo mkdir -p /data/db
    # fork so that the script will terminate
    if [[ $1 == "prod" ]]; then
        sudo mongod --fork --syslog --dbpath /var/lib/mongodb --bind_ip 127.0.0.1
    else
        sudo mongod --fork --syslog
    fi
fi

# generate the static data
mongo localhost:27017/shp_practice Resources/Scripts/mongo_up.js
mongo localhost:27017/shp Resources/Scripts/mongo_up.js

# download junit and hamcrest-core jar files
if [[ -s Resources/JUnit/junit-4.12.jar ]]; then
    echo "JUnit jar already found. Not downloading."
else
    echo "JUnit jar not found. Downloading now."
    curl --location 'http://search.maven.org/remotecontent?filepath=junit/junit/4.12/junit-4.12.jar' > Resources/JUnit/junit-4.12.jar
fi
if [[ -s Resources/JUnit/hamcrest-core-1.3.jar ]]; then
    echo "Hamcrest jar already found. Not downloading."
else
    echo "Hamcrest jar not found. Downloading now."
    curl --location 'http://search.maven.org/remotecontent?filepath=org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar' > Resources/JUnit/hamcrest-core-1.3.jar
fi
