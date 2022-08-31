//
//  File.swift
//  
//
//  Created by Saroar Khandoker on 29.11.2020.
//

import Vapor
import Fluent
import AddaSharedModels
import VaporRouting
import BSON
import AppExtensions

public func devicesHandler(
    request: Request,
    route: DevicesRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case let .createOrUpdate(input: content):

        var currentUserID: ObjectId? = nil
        
        if request.loggedIn {
            currentUserID = request.payload.userId
        }
        
        let data = Device(
            name: content.name,
            model: content.model,
            osVersion: content.osVersion,
            token: content.token,
            voipToken: content.voipToken,
            userId: currentUserID
        )
        
        let device = try await Device.query(on: request.db)
            .filter(\.$token == content.token)
            .first()
            .get()
        
        guard let device = device else {
            try await data.save(on: request.db).get()
            return data.res
        }
        
        try await device.update(content)
        try await device.update(on: request.db)
        return device.res
        
    }
}
