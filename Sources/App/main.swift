import Foundation
import HTTP
import Sessions
import Vapor
import VaporMongo

let drop = Droplet()

// DATABASE SETUP
let dbName = drop.config[
	"servers",
	"default",
	"mongoDBName"
]?.string ?? "shp_practice"
// TODO: actually use correct db authentication
let mongo = try VaporMongo.Provider(
	database: dbName,
	user: "",
	password: ""
)
drop.addProvider(mongo)
User.database = drop.database
AssignmentMapping.database = drop.database
Assignment.database = drop.database
GradingResult.database = drop.database

// MIDDLEWARE SETUP
let memory = MemorySessions()
let sessions = SessionsMiddleware(sessions: memory)
let formatter = DateFormatter()
drop.middleware.append(sessions)

// CONTROLLER SETUP
let userController = UserController()
drop.resource("user", userController)
let assignmentController = AssignmentController()
drop.resource("assignment", assignmentController)
let gradeController = GradingResultController(dbName: dbName, dir: drop.workDir)
drop.resource("grade", gradeController)

// VIEWS
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

drop.get("view", "grade", ":id") { req in
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

drop.get { req in
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

drop.post("auth") { req in
	if let username = req.data["username"]?.string,
		let password = req.data["password"]?.string {
		let password_enc = try drop.hash.make(password)
		if let user = try User.query().filter("username", username).first() {
			if user.password == password_enc {
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
