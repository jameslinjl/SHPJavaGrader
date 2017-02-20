import Foundation
import HTTP
import Vapor

final class GradingResultController {
	var dbName: String
	var workDir: String

	init(dbName: String, dir: String) {
		self.dbName = dbName
		self.workDir = dir
	}

	func create(_ req: Request) throws -> ResponseRepresentable {
		if let source = req.data["source"]?.string,
			let id = req.data["id"]?.string {

			// save the assignment first
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

				// launch grading script
				let nohupPath = "/usr/bin/nohup"
				let pyPath = "/usr/bin/python"
				let scriptPath = workDir + "Resources/Scripts/grade_runner.py"
				if (dbName == "shp") {
					shell(
						launchPath: nohupPath,
						arguments: [
							pyPath,
							scriptPath,
							"prod",
							"&"
						]
					)
				}
				else {
					shell(
						launchPath: nohupPath,
						arguments: [
							pyPath,
							scriptPath,
							"&"
						]
					)
				}

				return try JSON(node: [
					"gradeId": gradingResult.id
				])
			}
		}
		return Response(status: .badRequest)
	}

	func show(_ req: Request, _ gradingResult: GradingResult) -> ResponseRepresentable {
		return gradingResult
	}

	func shell(launchPath: String, arguments: [String] = []) {
		let task = Process()
		task.launchPath = launchPath
		task.arguments = arguments

		let pipe = Pipe()
		task.standardOutput = pipe
		task.launch()
	}
}

extension GradingResultController: ResourceRepresentable {
	func makeResource() -> Resource<GradingResult> {
		return Resource(
			store: create,
			show: show
		)
	}
}
