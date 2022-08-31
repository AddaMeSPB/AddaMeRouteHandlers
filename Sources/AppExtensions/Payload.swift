//
//  Payload.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import JWT
import JWTKit
import MongoKitten

public struct PayloadKey: StorageKey {
    public typealias Value = Payload
}

public struct Payload: JWTPayload {
    public let firstname: String?
    public let lastname: String?
    public let phoneNumber: String
    public let userId: ObjectId
    public var status: Int = 0
    public let exp: Int
    public let iat: Int

    public init(id: ObjectId, phoneNumber: String) {
        self.userId = id
        self.phoneNumber = phoneNumber
        self.firstname = nil
        self.lastname = nil
        self.exp = Int( Date(timeIntervalSinceNow: 60*60*24*7).timeIntervalSince1970 ) // week
        self.iat = Int( Date().timeIntervalSince1970 )
    }

   public func verify(using signer: JWTSigner) throws {
        let expiration = Date(timeIntervalSince1970: Double(self.exp))
        try ExpirationClaim(value: expiration).verifyNotExpired()
    }

}


