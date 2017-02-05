# SHP Java Grader

![Swift](https://img.shields.io/badge/swift-3.0-brightgreen.svg)
[![Build Status](https://travis-ci.org/jameslinjl/SHPJavaGrader.svg?branch=master)](https://travis-ci.org/jameslinjl/SHPJavaGrader)
[![StackShare](https://img.shields.io/badge/tech-stack-0690fa.svg?style=flat)](https://stackshare.io/jameslinjl/shp-java-grader)

## Overview
This project was born out of a desire to provide simple evaluation and feedback
for students of Columbia University's Science Honors Program (enrichment program
for high school students), and specifically the Java Programming course taught
there. The hope is to build a web service which will easily enable students with
very little programming background to get valuable feedback and testing of their
code. An additional hope is that instructors and TAs will be able to easily add
new assignments to be graded.

## Setup

Step 0. Use Mac or Linux. Sorry Windows friends :P

First, you'll need to make sure Swift and Vapor are installed. (Vapor has some
sweet docs for doing so: https://vapor.github.io/documentation/getting-started/install-swift-3-macos.html )

Next, you'll want to make sure that MongoDB is installed. (MongoDB has some easy docs to
follow for this: https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/ )

You also need to make sure that you have Python 2. You may also need to install
pip, bson, and pymongo. On Ubuntu, this probably looks something like:
```
# do the right thing for your OS
sudo apt-get install python-pip
sudo pip install bson
sudo pip install pymongo
```

You should also make sure that you have a JDK installed. (You can download that here: 
http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html )

Now, you'll want to run the setup script at the top level of the repo. This will
sudo rm -rf root... jk... it'll do some insertion of static data and get other
processes kicked off:
```
./setup.sh
```

You're almost there now! All that's left to do is build the app and run it:
```
vapor build
vapor run serve
```

Voila! You should be good to go!
