import Vapor

let drop = Droplet()

drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

drop.get("login") { req in
    return try drop.view.make("login.html")
}

drop.post("auth") { req in
    print("i hit the thing!")
    return "yeah"
}

// drop.resource("posts", PostController())

drop.run()
