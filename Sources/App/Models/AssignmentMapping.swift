import Vapor
import Fluent

final class AssignmentMapping: Model {
	var id: Node?
	var name: String
	var labNumber: Int
	var jUnitPath: String
	var expectedClass: String
	var expectedJUnit: String
	var exists: Bool = false
	
	init(name: String, labNumber: Int, jUnitPath: String, expectedClass: String, expectedJUnit: String) {
		self.name = name
		self.labNumber = labNumber
		self.jUnitPath = jUnitPath
		self.expectedClass = expectedClass
		self.expectedJUnit = expectedJUnit
	}

	init(node: Node, in context: Context) throws {
		id = try node.extract("_id")
		name = try node.extract("name")
		labNumber = try node.extract("lab_number")
		jUnitPath = try node.extract("junit_path")
		expectedClass = try node.extract("expected_class")
		expectedJUnit = try node.extract("expected_junit")
	}

	func makeNode(context: Context) throws -> Node {
		return try Node(node: [
			"_id": id,
			"name": name,
			"lab_number": labNumber,
			"junit_path": jUnitPath,
			"expected_class": expectedClass,
			"expected_junit": expectedJUnit
		])
	}

	static func prepare(_ database: Database) throws {}

	static func revert(_ database: Database) throws {}
}
