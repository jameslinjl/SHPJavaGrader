# SHP Java Grader

[![Build Status](https://travis-ci.org/jameslinjl/SHPJavaGrader.svg?branch=master)](https://travis-ci.org/jameslinjl/SHPJavaGrader)

## Overview
This project was born out of a desire to provide simple evaluation and feedback
for students of Columbia University's Science Honors Program (enrichment program
for high school students), and specifically the Java Programming course taught
there. The hope is to build a web service which will easily enable students with
very little programming background to get valuable feedback and testing of their
code. An additional hope is that instructors and TAs will be able to easily add
new assignments to be graded.

## Tech Stack
Rudimentary so far... looking to use better technology after getting an MVP out.
* Web Framework: Vapor (Swift)
* Database: MongoDB + MongoKitten (Swift)
* Frontend / Templating: Leaf (Swift) with basic JQuery (JavaScript)
* Testing Framework: JUnit (Java)
* Job Scheduler (Python)

## Setup

Step 0. Use Mac or Linux. Sorry Windows friends :P

First, you'll need to make sure Swift and Vapor are installed. (Vapor has some
sweet docs for doing so: https://vapor.github.io/documentation/getting-started/install-swift-3-macos.html )

Next, you'll want to make sure that MongoDB is installed.

You also need to make sure that you have Python 2. You may also need to install
pip, bson, and pymongo. On Ubuntu, this probably looks something like:
```
# do the right thing for your OS
sudo apt-get install python-pip
sudo pip install bson
sudo pip install pymongo
```

You should also make sure that you have java and javac installed.

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