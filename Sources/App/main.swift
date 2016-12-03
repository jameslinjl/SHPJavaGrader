import Foundation
import HTTP
import MongoKitten
import Sessions
import Vapor

let server: MongoKitten.Server
do {
    server = try MongoKitten.Server(mongoURL: "mongodb://localhost:27017", automatically: true)
} catch {
    // Unable to connect
    fatalError("MongoDB is not available on the given host and port")
}

let database = server["shp_practice"]
let userCollection = database["user"]
let memory = MemorySessions()
let sessions = SessionsMiddleware(sessions: memory)
let formatter = DateFormatter()
let drop = Droplet()
drop.middleware.append(sessions)

// see the home page if authenticated, otherwise go to login
drop.get { req in
    // TODO: convert this into server-side authentication rather than trust the cookie
    if let name = try req.session().data["username"]?.string, let expirationTime = try req.session().data["expiration"]?.string {
        let doubleExpirationTime = Date(timeIntervalSince1970: Double(expirationTime)!)
        let currentTime = Date()
        if doubleExpirationTime > currentTime {
            return try drop.view.make("welcome", [
                "message": drop.localization[req.lang, "welcome", "title"]
            ])
        }
    }
    return Response(redirect: "login")
}

// see the login page
drop.get("login") { req in
    return try drop.view.make("login.html")
}

// see the signup page
drop.get("signup") { req in
    return try drop.view.make("signup.html")
}

// create a user using POST
drop.post("user") { req in
    if let username = req.data["username"]?.string, let password = req.data["password"]?.string {
        // ensure a username doesn't already exist
        let check = Array(try userCollection.find(matching: "username" == username))
        if check.count > 0 {
            return Response(status: .badRequest)
        }

        // TODO: salt the password as well
        let password_enc = try drop.hash.make(password)
        let userDocument: Document = [
            "username": ~username,
            "password_enc": ~password_enc
        ]
        try userCollection.insert(userDocument)
    }
    return Response(status: .ok)
}

// TODO: delete this
// get all the users from the db
drop.get("user") { req in
    let resultEntries = try userCollection.find()
    let arr = resultEntries.map {$0.makeExtendedJSON()}
    var jsonString = "["
    jsonString += arr.joined(separator: ",")
    jsonString += "]"
    return jsonString
}

drop.post("auth") { req in
    if let username = req.data["username"]?.string, let password = req.data["password"]?.string {
        let password_enc = try drop.hash.make(password)
        let result = Array(try userCollection.find(matching: "username" == username))
        if result.count == 1 && result[0]["password_enc"].string == password_enc {
            // TODO: convert this into server-side authentication
            try req.session().data["username"] = Node.string(username)
            let unixTimestamp = String(Date(timeIntervalSinceNow: 10).timeIntervalSince1970)
            try req.session().data["expiration"] = Node.string(unixTimestamp)
            return Response(status: .ok)
        }
    }
    return Response(status: .badRequest)
}

// TODO: delete all this
// drop.resource("posts", PostController())

drop.run()
