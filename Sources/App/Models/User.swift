import Vapor
import Fluent

final class User: Model {
	var id: Node?
	var username: String
	var password: String
	var exists: Bool = false
	
	init(name: String, pass: String) {
		self.username = name
		self.password = pass
	}

	init(node: Node, in context: Context) throws {
		id = try node.extract("_id")
		username = try node.extract("username")
		password = try node.extract("password_enc")
	}

	func makeNode(context: Context) throws -> Node {
		return try Node(node: [
			"_id": id,
			"username": username,
			"password_enc": password
		])
	}

	static func prepare(_ database: Database) throws {}

	static func revert(_ database: Database) throws {}
}
