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
let assignmentCollection = database["assignment"]
let assignmentMappingsCollection = database["assignmentMappings"]
let memory = MemorySessions()
let sessions = SessionsMiddleware(sessions: memory)
let formatter = DateFormatter()
let drop = Droplet()
drop.middleware.append(sessions)

// see the home page if authenticated, otherwise go to login
drop.get { req in
    // TODO: convert this into server-side authentication rather than trust the cookie
    if let username = try req.session().data["username"]?.string, let expirationTime = try req.session().data["expiration"]?.string {
        let doubleExpirationTime = Date(timeIntervalSince1970: Double(expirationTime)!)
        let currentTime = Date()
        if doubleExpirationTime > currentTime {
            // init Node array that we are going to return
            var assignmentMappingNodes: [Node] = [Node]()
            let assignmentMappingDocs = try assignmentMappingsCollection.find()
            // populate Node array with db results
            for assignmentMappingDoc in assignmentMappingDocs {
                let assignmentName = assignmentMappingDoc["name"].stringValue
                let assignmentLabNumber = assignmentMappingDoc["lab_number"].int32Value
                if assignmentName != nil && assignmentLabNumber != nil {
                    assignmentMappingNodes.append(
                        Node(
                            [
                                "name": Node(assignmentName!),
                                "lab_number": Node(UInt(assignmentLabNumber!))
                            ]
                        )
                    )
                } else {
                    return Response(status: .badRequest)
                }
            }

            var assignmentNodes: [Node] = [Node]()
            let assignmentDocs = try assignmentCollection.find(matching: "username" == username)
            for assignmentDoc in assignmentDocs {
                let assignmentId = assignmentDoc["_id"].objectIdValue?.hexString
                // TODO: fix the POST and make this int32
                let assignmentLabNumber = assignmentDoc["lab_number"].int64Value
                if assignmentId != nil && assignmentLabNumber != nil {
                    assignmentNodes.append(
                        Node(
                            [
                                "id": Node(assignmentId!),
                                "lab_number": Node(UInt(assignmentLabNumber!))
                            ]
                        )
                    )
                } else {
                    return Response(status: .badRequest)
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

// TODO: refactor assignment API into a controller and make RESTful
drop.post("assignment") { req in
    if let labNumber = req.data["labNumber"]?.string {
        // ensure that a lab with this number exists
        let check = Array(try assignmentMappingsCollection.find(matching: "lab_number" == Int(labNumber)!))
        if check.count != 1 {
            return Response(status: .badRequest)
        }
        if let username = try req.session().data["username"]?.string {
            let assignmentDocument: Document = [
                "username": ~username,
                // TODO: make this insertt an int32 rather than int64
                "lab_number": ~Int(labNumber)!,
                "content": ""
            ]
            try assignmentCollection.insert(assignmentDocument)
        }
    }
    return Response(status: .ok)
}

drop.post("auth") { req in
    if let username = req.data["username"]?.string, let password = req.data["password"]?.string {
        let password_enc = try drop.hash.make(password)
        let result = Array(try userCollection.find(matching: "username" == username))
        if result.count == 1 && result[0]["password_enc"].string == password_enc {
            // TODO: convert this into server-side authentication
            try req.session().data["username"] = Node.string(username)
            let unixTimestamp = String(Date(timeIntervalSinceNow: 60 * 60).timeIntervalSince1970)
            try req.session().data["expiration"] = Node.string(unixTimestamp)
            return Response(status: .ok)
        }
    }
    return Response(status: .badRequest)
}

// TODO: delete all this
// drop.resource("posts", PostController())

drop.run()
