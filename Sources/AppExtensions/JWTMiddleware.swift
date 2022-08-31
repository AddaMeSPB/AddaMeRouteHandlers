//
//  JWTMiddleware.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import JWT
import VaporRouting

public final class JWTMiddleware: AsyncMiddleware {
    public init() {}

    public func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let token = req.headers.bearerAuthorization?.token.utf8 else {
            
            if ["/v1/auth/login","/v1/auth/verify_sms", "/v1/devices"].contains(req.url.string ) {
                return try await next.respond(to: req)
            }
            
            return Response(status: .unauthorized, body: .init(string: "Missing authorization bearer header"))
        }

        do {
            req.payload = try req.jwt.verify(Array(token), as: Payload.self)
        } catch let JWTError.claimVerificationFailure(name: name, reason: reason) {
            throw JWTError.claimVerificationFailure(name: name, reason: reason)
        } catch let error {
            return Response(status: .unauthorized, body: .init(string: "You are not authorized this token \(error)"))
        }

        return try await next.respond(to: req)
    }

}

extension AnyHashable {
    static let payload: String = "jwt_payload"
}

extension Request {
    public var loggedIn: Bool {
        return self.storage[PayloadKey.self] != nil ?  true : false
    }

    public var payload: Payload {
        get { self.storage[PayloadKey.self]! } // should not use it
        set { self.storage[PayloadKey.self] = newValue }
    }
}
