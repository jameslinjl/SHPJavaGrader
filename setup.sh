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
    sudo mongod --fork --syslog
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

# kick off grade_runner
GRADE_RUNNER_PID=`pgrep -f 'python grade_runner.py'`
if [[ -n $GRADE_RUNNER_PID ]]; then
    echo "Killing existing grade_runner.py and starting new one"
    sudo kill -9 $GRADE_RUNNER_PID
else
    echo "No grade_runner.py currently running. Starting now."
fi

# cd hack to make $PATH correct?
cd Resources/Scripts
if [[ -n $1 && $1 == "prod" ]]; then
    echo "Running prod grading script"
    # make this actually log to a real place and not /dev/null someday
    nohup python grade_runner.py prod > /dev/null 2>&1 &
else
    echo "Running dev grading script"
    nohup python grade_runner.py > /dev/null 2>&1 &
fi
cd ../..
