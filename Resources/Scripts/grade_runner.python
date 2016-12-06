from bson.objectid import ObjectId
import os
from pymongo import MongoClient
from subprocess import call
from tempfile import mkdtemp
from time import sleep

client = MongoClient('localhost', 27017)
db = client.shp_practice
collection = db.gradingResult
assignmentCollection = db.assignment

while True:
    results = collection.find({'status': 'pending'})
    for result in results:
        print 'processing ' + str(result['_id'])
        assignment = assignmentCollection.find_one({'_id': ObjectId(result['assignmentId'])})
        log_content = ''
        tmp_dir = mkdtemp()
        f = open(tmp_dir + '/EasterCalculator.java', 'w')
        f.write(assignment['content'].encode('utf-8'))
        f.close()

        log_file = open(tmp_dir + '/EasterCalculator.log', 'a')
        log_file.write('\n$ javac ' + tmp_dir + '/EasterCalculator.java\n')
        log_file.flush()
        call(['javac', tmp_dir + '/EasterCalculator.java'], stdout=log_file, stderr=log_file)

        call(['rm', '-rf', '/Users/jameslin/Desktop/*.class'])
        # javac -cp .:junit-4.12.jar tmp/EasterCalculator.java EasterChecker.java
        log_file.write('\n$ javac -cp .:/Users/jameslin/Desktop/junit-4.12.jar ' + tmp_dir + '/EasterCalculator.java' + ' /Users/jameslin/Desktop/EasterChecker.java\n')
        log_file.flush()
        call(['javac', '-cp', '.:/Users/jameslin/Desktop/junit-4.12.jar', tmp_dir + '/EasterCalculator.java', '/Users/jameslin/Desktop/EasterChecker.java'], stdout=log_file, stderr=log_file)
        log_file.write('\n$ java -cp .:/Users/jameslin/Desktop/junit-4.12.jar:' + tmp_dir + ':/Users/jameslin/Desktop EasterChecker\n')
        log_file.flush()
        # java -cp .:junit-4.12.jar:tmp EasterChecker
        call(['java', '-cp', '.:/Users/jameslin/Desktop/junit-4.12.jar:' + tmp_dir + ':/Users/jameslin/Desktop', 'EasterChecker'], stdout=log_file, stderr=log_file)
        log_file.close()

        log_content = ''
        log_file = open(tmp_dir + '/EasterCalculator.log', 'r')
        for line in log_file:
            log_content += line
        log_file.close()

        collection.update({'_id': result['_id']}, {'$set': {'status': 'completed', 'content': log_content}})
        call(['rm', '-rf', '/Users/jameslin/Desktop/*.class'])
        print 'finished processing ' + str(result['_id'])
    sleep(10)
