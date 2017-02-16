import Vapor
import Fluent

final class Assignment: Model {
	var id: Node?
	var username: String
	var labNumber: Int
	var content: String
	var exists: Bool = false
	
	init(username: String, labNumber: Int, content: String) {
		self.username = username
		self.labNumber = labNumber
		self.content = content
	}

	init(node: Node, in context: Context) throws {
		id = try node.extract("_id")
		username = try node.extract("username")
		labNumber = try node.extract("lab_number")
		content = try node.extract("content")
	}

	func makeNode(context: Context) throws -> Node {
		return try Node(node: [
			"_id": id,
			"username": username,
			"lab_number": labNumber,
			"content": content
		])
	}

	static func prepare(_ database: Database) throws {}

	static func revert(_ database: Database) throws {}
}
