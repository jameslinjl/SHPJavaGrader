import MongoKitten
import Vapor

let server: Server
do {
    server = try Server(mongoURL: "mongodb://localhost:27017", automatically: true)
} catch {
    // Unable to connect
    fatalError("MongoDB is not available on the given host and port")
}

let database = server["shp_practice"]
let myCollection = database["user"]
let drop = Droplet()

// see the home page
drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
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
        // TODO: salt the password as well
        let password_enc = try drop.hash.make(password)
        let userDocument: Document = [
            "username": ~username,
            "password_enc": ~password_enc
        ]
        try myCollection.insert(userDocument)
    }
    return "yeah"
}

// TODO: delete this
// get all the users from the db
drop.get("user") { req in
    let resultEntries = try myCollection.find()
    let arr = resultEntries.map {$0.makeExtendedJSON()}
    var jsonString = "["
    jsonString += arr.joined(separator: ",")
    jsonString += "]"
    return jsonString
}

// TODO: implement auth and stuff
drop.post("auth") { req in
    print("i hit the thing!")
    print(req.data["username"]?.string)
    print(req.data["password"]?.string)
    return "yeah"
}

// TODO: delete all this
// drop.resource("posts", PostController())

drop.run()
