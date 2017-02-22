#!/bin/bash

# uncomment this once some vapor tests are added
# vapor test

# setup for selenium
mongo localhost:27017/shp_practice Resources/Scripts/mongo_up_test.js
nohup vapor run serve &
python Test/selenium_functional_tests.py

# one re-run chance in case of instability
if [ $? -ne 0 ]; then
	python Test/selenium_functional_tests.py
	if [ $? -ne 0 ]; then
		echo "Tests failed twice"
		exit 1
	fi
fi

# kill vapor server 
VAPOR_PID=`pgrep -f 'vapor run serve'`
if [[ -n $VAPOR_PID ]]; then
    sudo kill -9 $VAPOR_PID
else
    echo "Vapor not currently running. Starting now."
fi

# kill app running
APP_PID=`pgrep -f 'build/debug/App serve'`
if [[ -n $APP_PID ]]; then
    sudo kill -9 $APP_PID
else
    echo "No app currently running. Starting now."
fi
