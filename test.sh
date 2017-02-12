#!/bin/bash

# uncomment this once some vapor tests are added
# vapor test

# setup for selenium
mongo localhost:27017/shp_practice Resources/Scripts/mongo_up_test.js
nohup vapor run serve &
python Test/selenium_functional_tests.py
