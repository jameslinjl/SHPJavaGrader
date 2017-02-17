import Vapor
import Fluent

final class GradingResult: Model {
    var id: Node?
    var username: String
    var assignmentId: String
    var status: String
    var content: String
    var exists: Bool = false
    
    init(username: String, assignmentId: String, status: String, content: String) {
        self.username = username
        self.assignmentId = assignmentId
        self.status = status
        self.content = content
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("_id")
        username = try node.extract("username")
        assignmentId = try node.extract("assignmentId")
        status = try node.extract("status")
        content = try node.extract("content")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "_id": id,
            "username": username,
            "assignmentId": assignmentId,
            "status": status,
            "content": content
        ])
    }

    static func prepare(_ database: Database) throws {}

    static func revert(_ database: Database) throws {}
}
