import Vapor
import Fluent
import AddaSharedModels
import VaporRouting
import BSON
import Twilio
import JWT
import AddaSharedModels
import MongoKitten
import AppExtensions

public func authenticationHandler(
    request: Request,
    route: AuthenticationRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .login(input: let input):
        let verification = input

        let phoneNumber = verification.phoneNumber.removingInvalidCharacters
        let code = String.randomDigits(ofLength: 6)
        let message = "Hello there! Your verification code is \(code)"

        guard let SENDER_NUMBER = Environment.get("SENDER_NUMBER") else {
            fatalError("No value was found at the given public key environment 'SENDER_NUMBER'")
        }
        let sms = OutgoingSMS(body: message, from: SENDER_NUMBER, to: phoneNumber)

        request.logger.info("SMS is \(message)")

        switch request.application.environment {
        case .production:
            _ = try await request.application.twilio.send(sms).get()

            let smsAttempt = SMSVerificationAttempt(
                code: code,
                expiresAt: Date().addingTimeInterval(5.0 * 60.0),
                phoneNumber: phoneNumber
            )

            _ = try await smsAttempt.save(on: request.db).get()
            let attemptId = try! smsAttempt.requireID()
            return SendUserVerificationResponse(
                phoneNumber: phoneNumber,
                attemptId: attemptId
            )

        case .development:

            let smsAttempt = SMSVerificationAttempt(
                code: "336699",
                expiresAt: Date().addingTimeInterval(5.0 * 60.0),
                phoneNumber: phoneNumber
            )
            _ = try await smsAttempt.save(on: request.db).get()

            let attemptId = try! smsAttempt.requireID()
            return SendUserVerificationResponse(phoneNumber: phoneNumber, attemptId: attemptId)

        default:
            let smsAttempt = SMSVerificationAttempt(
                code: "336699",
                expiresAt: Date().addingTimeInterval(5.0 * 60.0),
                phoneNumber: phoneNumber
            )
            _ = smsAttempt.save(on: request.db).map { smsAttempt }

            let attemptId = try! smsAttempt.requireID()
            return SendUserVerificationResponse(phoneNumber: phoneNumber, attemptId: attemptId)
        }
    case .verifySms(input: let payload):

        guard
            let code = payload.code,
            let attemptId = payload.attemptId,
            let attemptIdObj = ObjectId(attemptId)
        else {
            throw Abort(.notFound, reason: "input code or attemptId is nil!")
        }
        let phoneNumber = payload.phoneNumber.removingInvalidCharacters

        guard let attempt = try await SMSVerificationAttempt.query(on: request.db)
            .filter(\.$code == code)
            .filter(\.$phoneNumber == phoneNumber)
            .filter(\.$id == attemptIdObj)
            .first()
            .get()
        else {
            throw Abort(.notFound, reason: "SMSVerificationAttempt not found!")
        }

            guard let expirationDate = attempt.expiresAt else {
                return LoginResponse.init(status: "invalid-code")
            }

            guard expirationDate > Date() else {
                return LoginResponse.init(status: "invalid-code")
            }

        return try await verificationResponseForValidUser(with: phoneNumber, on: request)
    case .refreshToken(input: let data):

        let refreshTokenFromData = data.refreshToken
        let jwtPayload: RefreshToken = try request.application
            .jwt.signers.verify(refreshTokenFromData, as: RefreshToken.self)

        guard let userID = jwtPayload.id else {
            throw Abort(.notFound, reason: "User id missing from RefreshToken")
        }

        guard let user = try await User.query(on: request.db)
            .with(\.$attachments)
            .filter(\.$id == userID)
            .first()
            .get()
        else {
            throw Abort(.notFound, reason: "User not found by id: \(userID) for refresh token")
        }

        let payload = Payload(id: user.id!, phoneNumber: user.phoneNumber)
        let refreshPayload = RefreshToken(user: user)

        do {
            let refreshToken = try request.application.jwt.signers.sign(refreshPayload)
            let payloadString = try request.application.jwt.signers.sign(payload)
            return RefreshTokenResponse(accessToken: payloadString, refreshToken: refreshToken)
        } catch {
            throw Abort(.notFound, reason: "jwt signers error: \(error)")
        }
    }
}

private func verificationResponseForValidUser(
    with phoneNumber: String,
    on req: Request) async throws -> LoginResponse {

        let createNewUser = User.init(phoneNumber: phoneNumber)

        if try await findUserResponse(with: phoneNumber, on: req) == nil {
            _ = try await createNewUser.save(on: req.db).get()
        }

        guard let user = try await findUserResponse(with: phoneNumber, on: req) else {
            throw Abort(.notFound, reason: "User not found")
        }

        do {
            let userPayload = Payload(id: user.response.id!, phoneNumber: user.response.phoneNumber)
            let refreshPayload = RefreshToken(user: user)

            let accessToken = try req.application.jwt.signers.sign(userPayload)
            let refreshToken = try req.application.jwt.signers.sign(refreshPayload)

            let access = RefreshTokenResponse(accessToken: accessToken, refreshToken: refreshToken)
            return LoginResponse(status: "ok", user: user.response,  access: access)
        }
        catch {
            throw error
        }

}

private func findUserResponse(
    with phoneNumber: String,
    on req: Request) async throws -> User? {

    try await User.query(on: req.db)
        .with(\.$attachments)
        .filter(\.$phoneNumber == phoneNumber)
        .first()
        .get()
}
