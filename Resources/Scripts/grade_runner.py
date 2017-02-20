from bson.objectid import ObjectId
from pymongo import MongoClient
from subprocess import call
import sys
from tempfile import mkdtemp
from time import sleep

client = MongoClient('127.0.0.1', 27017)
db = client.shp_practice
if len(sys.argv) > 1 and sys.argv[1] == 'prod':
	db = client.shp
collection = db.gradingresults
assignmentCollection = db.assignments
assignmentMappingCollection = db.assignmentmappings
last_assignment_number = -1
path_to_junit = ''
expected_class = ''
expected_junit = ''

results = collection.find({'status': 'pending'})
for result in results:
	print 'processing ' + str(result['_id'])
	assignment = assignmentCollection.find_one(
		{'_id': ObjectId(result['assignmentId'])}
	)

	# rudimentary caching
	if last_assignment_number != assignment['lab_number']:
		print 'lookup'
		assignmentMapping = assignmentMappingCollection.find_one(
			{'lab_number': assignment['lab_number']}
		)
		print assignmentMapping
		last_assignment_number = assignment['lab_number']
		path_to_junit = assignmentMapping['junit_path']
		expected_class = assignmentMapping['expected_class']
		expected_junit = assignmentMapping['expected_junit']

	log_content = ''
	tmp_dir = mkdtemp()
	f = open(tmp_dir + '/' + expected_class + '.java', 'w')
	f.write(assignment['content'].encode('utf-8'))
	f.close()

	log_file = open(tmp_dir + '/' + expected_class + '.log', 'a')
	log_file.write('\n$ javac ' + tmp_dir + '/' + expected_class + '.java\n')
	log_file.flush()
	call(
		['javac', tmp_dir + '/' + expected_class + '.java'],
		stdout=log_file,
		stderr=log_file
	)
	call(['rm', '-rf', 'Resources/JUnit/*.class'])

	log_file.write(
		'\n$ javac -cp .:Resources/JUnit/junit-4.12.jar ' +
		tmp_dir +
		'/' + expected_class + '.java ' +
		path_to_junit +
		'\n'
	)
	log_file.flush()

	call(['pwd'], stdout=log_file, stderr=log_file)

	call(
		[
			'javac',
			'-cp',
			'.:Resources/JUnit/junit-4.12.jar',
			tmp_dir + '/' + expected_class + '.java',
			'Resources/JUnit/' + expected_junit + '.java'
		],
		stdout=log_file,
		stderr=log_file
	)
	log_file.write('\n$ java -cp .:Resources/JUnit/junit-4.12.jar:' + tmp_dir +\
		':Resources/JUnit/ ' + expected_junit + '\n')
	log_file.flush()

	call(
		[
			'java',
			'-cp',
			'.:Resources/JUnit/junit-4.12.jar:' + tmp_dir + ':Resources/JUnit/',
			expected_junit
		],
		stdout=log_file,
		stderr=log_file
	)
	log_file.close()

	log_content = ''
	log_file = open(tmp_dir + '/' + expected_class + '.log', 'r')
	for line in log_file:
		log_content += line
	log_file.close()

	collection.update(
		{'_id': result['_id']},
		{'$set': {'status': 'completed','content': log_content}}
	)
	call(['rm', '-rf', 'Resources/JUnit/*.class'])
	print 'finished processing ' + str(result['_id'])
