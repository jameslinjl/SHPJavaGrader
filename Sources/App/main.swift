import Foundation
import HTTP
import Sessions
import Vapor
import VaporMongo

let drop = Droplet()

// TODO: actually use correct db authentication
let mongo = try VaporMongo.Provider(
	database: "shp_practice",
	user: "",
	password: ""
)
drop.addProvider(mongo)
User.database = drop.database
AssignmentMapping.database = drop.database
Assignment.database = drop.database
GradingResult.database = drop.database

let memory = MemorySessions()
let sessions = SessionsMiddleware(sessions: memory)
let formatter = DateFormatter()
drop.middleware.append(sessions)

let userController = UserController()
drop.resource("user", userController)

let assignmentController = AssignmentController()
drop.resource("assignment", assignmentController)

drop.get { req in
	// TODO: convert this into server-side authentication rather than trust the cookie
	if let username = try req.session().data["username"]?.string,
	   let expirationTime = try req.session().data["expiration"]?.string {
		let doubleExpirationTime = Date(timeIntervalSince1970: Double(expirationTime)!)
		let currentTime = Date()
		if doubleExpirationTime > currentTime {
			// init Node array that we are going to return
			var assignmentMappingNodes: [Node] = [Node]()
			let assignmentMappings = try AssignmentMapping.all()
			// populate Node array with db results
			for assignmentMapping in assignmentMappings {
				assignmentMappingNodes.append(
					Node(
						[
							"name": Node(assignmentMapping.name),
							"lab_number": Node(assignmentMapping.labNumber)
						]
					)
				)
			}

			var assignmentNodes: [Node] = [Node]()
			let assignments = try Assignment.query().filter("username", username).all()
			for assignment in assignments {
				if let assignmentId = assignment.id {
					assignmentNodes.append(
						Node(
							[
								"id": Node(assignmentId),
								"lab_number": Node(assignment.labNumber)
							]
						)
					)
				} else {
					return Response(status: .internalServerError)
				}
			}
			return try drop.view.make("home", [
				"assignmentMappings": Node(assignmentMappingNodes),
				"assignments": Node(assignmentNodes)
			])
		}
	}
	return Response(redirect: "login")
}

drop.get("login") { req in
	return try drop.view.make("login")
}

drop.get("signup") { req in
	return try drop.view.make("signup")
}

drop.get("view", "assignment", ":id") { req in
	guard let assignmentId = req.parameters["id"]?.string else {
		throw Abort.badRequest
	}

	if let assignment = try Assignment.find(assignmentId) {
		return try drop.view.make("assignment", [
			"savedSource": assignment.content,
			"labNumber": assignment.labNumber,
			"id": assignmentId
		])    	
	}
	return Response(status: .badRequest)
}

drop.get("grade", ":id") { req in
	guard let gradingResultId = req.parameters["id"]?.string else {
		throw Abort.badRequest
	}

	if let gradingResult = try GradingResult.find(gradingResultId) {
		return try drop.view.make("grade", [
			"savedSource": gradingResult.content,
			"assignmentId": gradingResult.assignmentId
		])
	}
	return Response(status: .badRequest)
}

drop.post("grade") { req in
	if let source = req.data["source"]?.string, let id = req.data["id"]?.string {
		// save first
		// TODO: use a controller instead
		if var assignment = try Assignment.find(id) {
			assignment.content = source
			try assignment.save()
		}

		// create a grading result document
		if let username = try req.session().data["username"]?.string {
			var gradingResult = GradingResult(
				username: username,
				assignmentId: id,
				status: "pending",
				content: "Waiting to be processed"
			)
			try gradingResult.save()
			return try JSON(node: [
				"gradeId": gradingResult.id
			])
		}
	}
	return Response(status: .badRequest)
}

drop.post("auth") { req in
	if let username = req.data["username"]?.string, let password = req.data["password"]?.string {
		let password_enc = try drop.hash.make(password)
		if let user = try User.query().filter("username", username).first() {
			if user.password == password_enc {
				// TODO: convert this into server-side authentication
				try req.session().data["username"] = Node.string(username)
				let unixTimestamp = String(
					Date(
						timeIntervalSinceNow: 60 * 60
					).timeIntervalSince1970
				)
				try req.session().data["expiration"] = Node.string(unixTimestamp)
				return Response(status: .ok)
			}
		}
	}
	return Response(status: .badRequest)
}

drop.post("logout") { req in
	do {
		try req.session().destroy()
	} catch {
		return Response(status: .internalServerError)
	}
	return Response(status: .ok)
}

drop.run()
