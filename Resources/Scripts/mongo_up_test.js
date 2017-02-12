db.assignmentMappings.drop();
db.assignmentMappings.insert({"name" : "Easter Calculator", "lab_number" : NumberInt(1), "junit_path" : "../JUnit/EasterChecker.java", "expected_class": "EasterCalculator", "expected_junit": "EasterChecker"});
db.assignmentMappings.insert({"name" : "Change Calculator", "lab_number" : NumberInt(2), "junit_path" : "../JUnit/ChangeCalculatorChecker.java", "expected_class": "ChangeCalculator", "expected_junit": "ChangeCalculatorChecker"});
db.user.drop();
db.user.insert({"username":"jameslin","password_enc":"7e6a0302078e89ab949c706565a3a817f6f24b3b7e177c6cce754da336117180"});