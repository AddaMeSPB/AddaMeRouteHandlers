import Vapor
import AddaSharedModels
import Fluent
import URLRouting
import BSON

public func attachmentsHandler(
    request: Request,
    route: AttachmentsRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .create(input: let input):
        if request.loggedIn == false { throw Abort(.unauthorized) }
        
        let inputData = input
        
        let attachment = Attachment(
            type: inputData.type,
            userId: inputData.userId,
            imageUrlString: inputData.imageUrlString,
            audioUrlString: inputData.audioUrlString,
            videoUrlString: inputData.videoUrlString,
            fileUrlString: inputData.fileUrlString)
        
        try await attachment.save(on: request.db).get()
        return  attachment.response
        
        // have to delete
    case .list:
        if request.loggedIn == false { throw Abort(.unauthorized) }
        
        let attactments = try await Attachment.query(on: request.db)
            .filter(\.$user.$id == request.payload.userId)
            .all()
            .get()
        
        return attactments.map { $0.response }
        
    case .delete(id: let id):
        if request.loggedIn == false { throw Abort(.unauthorized) }

        guard let id = ObjectId(id) else {
            throw Abort(.notFound, reason: "Attachment id is not found!")
        }
        
        guard let attachment = try await Attachment.query(on: request.db)
            .filter(\.$id == id)
            .filter(\.$user.$id == request.payload.userId)
            .first()
            .get()
        else {
            throw Abort(.notFound, reason: "No Attachment. found! by ID \(id)")
        }
          
        try await attachment.delete(on: request.db).get()
        return HTTPStatus.ok
    }
}

