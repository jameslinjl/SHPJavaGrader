import Vapor
import HTTP

final class AssignmentController {
	func create(_ req: Request) throws -> ResponseRepresentable {
		if let labNumberString = req.data["labNumber"]?.string {
			if let labNumber = Int(labNumberString) {
				// ensure that a lab with this number exists
				let assignmentMapping = try AssignmentMapping.query().filter(
					"lab_number",
					labNumber
				).first()
				if assignmentMapping != nil {
					if let username = try req.session().data["username"]?.string {
						var assignment = Assignment(
							username: username,
							labNumber: labNumber,
							content: ""
						)
						try assignment.save()
					}
				}
				else {
					return Response(status: .badRequest)
				}
			}
		}
		return Response(status: .ok)
	}

	func show(_ req: Request, _ assignment: Assignment) -> ResponseRepresentable {
		return assignment
	}

	func update(_ req: Request, _ assignment: Assignment) throws -> ResponseRepresentable {
		// only PATCHes source right now, expand to do everything eventually
		if let source = req.data["source"]?.string, let id = assignment.id {
			if var modAssignment = try Assignment.find(id) {
				modAssignment.content = source
				try modAssignment.save()
			}
		}
		return Response(status: .ok)
	}

	func destroy(_ req: Request, _ assignment: Assignment) throws -> ResponseRepresentable {
		// delete all grades associated with that assignment
		let grades = try GradingResult.query().filter(
			"assignmentId",
			assignment.id!
		).all()
		for grade in grades {
			try grade.delete()
		}
		try assignment.delete()
		return Response(status: .ok)
	}
}

extension AssignmentController: ResourceRepresentable {
	func makeResource() -> Resource<Assignment> {
		return Resource(
			store: create,
			show: show,
			modify: update,
			destroy: destroy
		)
	}
}
