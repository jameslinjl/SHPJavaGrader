import os
from pymongo import MongoClient
from random import choice
from selenium import webdriver
from string import ascii_uppercase
from sys import exit
from time import sleep


def travis_ci_setup():
    capabilities = {'browserName': 'chrome'}
    if os.environ['TRAVIS_OS_NAME'] == 'linux':
        capabilities['platform'] = 'Linux'
        capabilities['version'] = '48.0'
    else:
        capabilities['platform'] = 'OS X 10.11'
        capabilities['version'] = '55.0'
    capabilities['tunnel-identifier'] = os.environ['TRAVIS_JOB_NUMBER']
    capabilities['build'] = os.environ['TRAVIS_BUILD_NUMBER']

    username = os.environ['SAUCE_USERNAME']
    access_key = os.environ['SAUCE_ACCESS_KEY']
    hub_url = '%s:%s@localhost:4445' % (username, access_key)
    driver = webdriver.Remote(desired_capabilities=capabilities, command_executor='http://%s/wd/hub' % hub_url)
    return driver


def generate_random_string():
    return ''.join(choice(ascii_uppercase) for i in range(12))


def test_case_auth_crash(driver):
    driver.get('localhost:8080')
    usern = driver.find_element_by_name('username')
    passw = driver.find_element_by_name('password')

    usern.send_keys(generate_random_string())
    passw.send_keys(generate_random_string())
    passw.submit()

    try:
        # sleep to make sure crash has time to propogate
        sleep(5)
        driver.get('localhost:8080')
        # try to get username element, which won't be there if page doesn't load
        usern = driver.find_element_by_name('username')
    except:
        return False
    return True


def test_case_user_creation_bug(driver):
    driver.get('localhost:8080')
    signup = driver.find_element_by_id('signUpButton')
    signup.click()

    usern = driver.find_element_by_name('username')
    passw = driver.find_element_by_name('password')
    confm = driver.find_element_by_name('confirm')

    generated_username = generate_random_string()
    generated_password = generate_random_string()
    usern.send_keys(generated_username)
    passw.send_keys(generated_password)
    confm.send_keys(generated_password)
    confm.submit()
    sleep(1)

    client = MongoClient('127.0.0.1', 27017)
    db = client.shp_practice
    user_collection = db.user
    query_result = user_collection.find_one({'username': generated_username})

    if len(query_result) == 0:
        return False
    return True


if os.environ.get('CI') and os.environ.get('TRAVIS'):
    driver = travis_ci_setup()
else:
    driver = webdriver.Firefox()

print '----------------RUNNING SELENIUM FUNCTIONAL TESTS----------------'
all_tests = [
    'test_case_auth_crash',
    'test_case_user_creation_bug'
]
failed_tests = []
errored_tests = []
passing_tests = 0
for test in all_tests:
    print 'Running ' + test
    try:
        test_passed = globals()[test](driver)
        if test_passed:
            passing_tests = passing_tests + 1
        else:
            failed_tests.append(test)
    except:
        errored_tests.append(test)
driver.close()

print '--------------FINISHED SELENIUM FUNCTIONAL TEST RUN--------------'
print 'Passing Tests Count: ' + str(passing_tests)
print 'Failing Tests Count: ' + str(len(failed_tests))
print 'Errored Tests Count: ' + str(len(errored_tests))
print 'Failing Tests: '
print failed_tests
print 'Errored Tests: '
print errored_tests

if passing_tests != len(all_tests):
    exit(1)
exit(0)
