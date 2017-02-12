import Foundation
import HTTP
import MongoKitten
import Sessions
import Vapor

let drop = Droplet()
let dbName = drop.config["servers", "default", "mongoDBName"]?.string ?? "practice"
let mongoHost = drop.config["servers", "mongo-host"]?.string ?? "localhost"
let mongoPort = drop.config["servers", "mongo-port"]?.string ?? "27017"

let server: MongoKitten.Server
do {
    server = try MongoKitten.Server(mongoURL: "mongodb://" + mongoHost + ":" + mongoPort)
} catch {
    fatalError("MongoDB is not available on the given host and port")
}

let database = server[dbName]
let userCollection = database["user"]
let assignmentCollection = database["assignment"]
let assignmentMappingsCollection = database["assignmentMappings"]
let gradingResultCollection = database["gradingResult"]
let memory = MemorySessions()
let sessions = SessionsMiddleware(sessions: memory)
let formatter = DateFormatter()
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
                let assignmentName = assignmentMappingDoc[raw: "name"]?.stringValue
                let assignmentLabNumber = assignmentMappingDoc[raw: "lab_number"]?.int32Value
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
                    return Response(status: .internalServerError)
                }
            }

            var assignmentNodes: [Node] = [Node]()
            let assignmentDocs = try assignmentCollection.find(matching: "username" == username)
            for assignmentDoc in assignmentDocs {
                let assignmentId = assignmentDoc[raw: "_id"]?.objectIdValue?.hexString
                // TODO: fix the POST and make this int32
                let assignmentLabNumber = assignmentDoc[raw: "lab_number"]?.int64Value
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

drop.get("website") { req in
    return Response(redirect: "http://www.columbia.edu/~jl3782/shp")
}

// see the login page
drop.get("login") { req in
    return try drop.view.make("login")
}

// see the signup page
drop.get("signup") { req in
    return try drop.view.make("signup")
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
            "username": username,
            "password_enc": password_enc
        ] as Document
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
                "username": username,
                // TODO: make this insertt an int32 rather than int64
                "lab_number": Int64(labNumber)!,
                "content": ""
            ] as Document
            try assignmentCollection.insert(assignmentDocument)
        }
    }
    return Response(status: .ok)
}

drop.patch("assignment") { req in
    // only PATCHes source right now, expand to do everything eventually
    if let source = req.data["source"]?.string, let id = req.data["id"]?.string {
        try assignmentCollection.update(matching: "_id" == ObjectId(id), to: ["$set": ["content": source] as Document])
    }
    return Response(status: .ok)
}

drop.get("assignment", ":id") { req in
    guard let assignmentId = req.parameters["id"]?.string else {
        throw Abort.badRequest
    }

    let result = Array(try assignmentCollection.find(matching: "_id" == ObjectId(assignmentId)))
    if result.count == 1 {
        if let content = result[0][raw: "content"]?.string,
           let labNumber = result[0][raw: "lab_number"]?.int64Value {
            return try drop.view.make("assignment", [
                "savedSource": content,
                "labNumber": labNumber
            ])
        }
    }
    return Response(status: .badRequest)
}

drop.delete("assignment") { req in
    if let id = req.data["id"]?.string {
        try gradingResultCollection.remove(matching: "assignmentId" == id)
        try assignmentCollection.remove(matching: "_id" == ObjectId(id))
    }
    return Response(status: .ok)
}

drop.get("grade", ":id") { req in
    guard let gradingResultId = req.parameters["id"]?.string else {
        throw Abort.badRequest
    }

    let result = Array(try gradingResultCollection.find(matching: "_id" == ObjectId(gradingResultId)))
    if result.count == 1 {
        if let content = result[0][raw: "content"]?.string,
           let assignmentId = result[0][raw: "assignmentId"]?.string {
            return try drop.view.make("grade", [
                "savedSource": content,
                "assignmentId": assignmentId
            ])
        }
    }
    return Response(status: .internalServerError)
}

drop.post("grade") { req in
    if let source = req.data["source"]?.string, let id = req.data["id"]?.string {
        // save first
        // TODO: use a controller instead
        try assignmentCollection.update(matching: "_id" == ObjectId(id), to: ["$set": ["content": source] as Document])

        // create a grading result document
        if let username = try req.session().data["username"]?.string {
            let gradingResultDocument: Document = [
                "username": username,
                "assignmentId": id,
                "status": "pending",
                "content": "Waiting to be processed"
            ] as Document
            let result = try gradingResultCollection.insert(gradingResultDocument)
            return try JSON(node: [
                "gradeId": result.objectIdValue?.hexString
            ])
        }
    }
    return Response(status: .badRequest)
}

drop.post("auth") { req in
    if let username = req.data["username"]?.string, let password = req.data["password"]?.string {
        let password_enc = try drop.hash.make(password)
        if let result = try userCollection.findOne(matching: "username" == username) {
            if let storedPass = result[raw: "password_enc"]?.string {
                if storedPass == password_enc {
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

// TODO: delete all this
// drop.resource("posts", PostController())

drop.run()
