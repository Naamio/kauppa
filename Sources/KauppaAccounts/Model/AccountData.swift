import Foundation

import KauppaCore

/// User-supplied data for an account.
public struct AccountData: Mappable {
    /// Name of the user
    public var name: String = ""
    /// User's emails
    public var emails = ArraySet<Email>()
    /// User's phone number
    public var phone: Phone? = nil
    /// A list of user's addresses
    public var address = ArraySet<Address>()

    /// Try some basic validations on the data.
    public func validate() throws {
        if name.isEmpty {
            throw AccountsError.invalidName
        }

        if emails.isEmpty {
            throw AccountsError.emailRequired
        }

        for email in emails {
            /// A popular regex pattern that matches a wide range of cases.
            if !email.value.isMatching(regex: "(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$)") {
                throw AccountsError.invalidEmail
            }
        }

        if let number = phone {
            if number.value.isEmpty {
                throw AccountsError.invalidPhone
            }
        }

        for addr in address {
            try addr.validate()
        }
    }

    public init() {}

    /// Get the list of verified emails associated with this account.
    public func getVerifiedEmails() -> [String] {
        var list = [String]()
        for email in emails {
            if email.isVerified {
                list.append(email.value)
            }
        }

        return list
    }
}
