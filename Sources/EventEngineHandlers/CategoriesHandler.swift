import Vapor
import BSON
import Fluent
import JWT
import AddaSharedModels

public func categoriesHandler(request: Request, route: CategoriesRoute) async throws -> AsyncResponseEncodable {
    switch route {
    case .create:

        let input = try request.content.decode(CreateCategory.self)
        let category = Category(name: input.name)
        try await category.save(on: request.db)
        return category.response

    case .list:

        let categories = try await Category.query(on: request.db).all()
        let response = categories.map { $0.response }
        return CategoriesResponse(
            categories: response,
            url: request.application.router.url(for: .eventEngine(.categories(.list)))
        )
        
    case .update:
        
        if request.loggedIn == false { throw Abort(.unauthorized) }
        
        let originalCatrgory = try request.content.decode(Category.self)
        guard
            let id = originalCatrgory.id
        else {
            throw Abort(.notFound, reason: "no category id is missing")
        }
        
        let category = try await Category.query(on: request.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Category. found! by ID: \(id)"))
            .get()
        
        originalCatrgory.id = category.id
        originalCatrgory.name = category.name
        originalCatrgory._$id.exists = true
        try await originalCatrgory.update(on: request.db)
        return originalCatrgory.response
        
    case .delete(id: let id):
        
        if request.loggedIn == false { throw Abort(.unauthorized) }
        
        guard let id = ObjectId(id) else {
            throw Abort(.notFound)
        }
        
        let category = try await Category.find(id, on: request.db)
            .unwrap(or: Abort(.notFound, reason: "Cant find Category by id: \(id) for delete"))
            .get()
        try await category.delete(force: true, on: request.db)
        return HTTPStatus.ok
    }
}

