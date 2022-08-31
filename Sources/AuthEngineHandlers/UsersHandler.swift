
import Vapor
import MongoKitten
import Fluent
import URLRouting
import AddaSharedModels
import BSON

public func usersHandler(
    request: Request,
    route: UsersRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .user(id: let id, route: let userRoute):
        return try await userHandler(request: request, usersId: id, route: userRoute)
    case .update(input: let input):
        if request.loggedIn == false { throw Abort(.unauthorized) }
        let data = input
        
        let encoder = BSONEncoder()
        let encoded: Document = try encoder.encode(data)
        let updator: Document = ["$set": encoded]
        
        if request.payload.userId == data.id {
            throw Abort(.notFound, reason: "\(#line) not authorized")
        }
        
        _ = try await request.mongoDB[User.schema]
            .updateOne(where: "_id" == data.id!, to: updator)
            .get()
        return data
    }
}
