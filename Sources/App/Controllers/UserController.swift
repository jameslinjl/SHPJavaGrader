import Vapor
import HTTP

final class UserController {
	func index(_ req: Request) throws -> ResponseRepresentable {
		return try User.all().makeNode().converted(to: JSON.self)
	}

	func create(_ req: Request) throws -> ResponseRepresentable {
		if let username = req.data["username"]?.string,
		let password = req.data["password"]?.string {
			let check = try User.query().filter("username", username).first()
			if check != nil {
				return Response(status: .badRequest)
			}
			// TODO: salt the password as well
			let password_enc = try drop.hash.make(password)
			var user = User(name: username, pass: password_enc)
			try user.save()
		}
		return Response(status: .ok)
	}

	func show(_ req: Request, _ user: User) -> ResponseRepresentable {
		return user
	}
}

extension UserController: ResourceRepresentable {
	func makeResource() -> Resource<User> {
		return Resource(
			index: index,
			store: create,
			show: show
		)
	}
}
