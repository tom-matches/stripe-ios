//
//  PersistablePaymentMethodOption.swift
//  StripePaymentsUI
//

@objc public enum PersistablePaymentMethodOptionType: Int {
    case applePay
    case link
    case stripe
    case none
}

public typealias PersistablePaymentMethodOptionIdentifier = String

public enum PersistablePaymentMethodOptionError: Error {
    case noCorrespondingType(PersistablePaymentMethodOptionType, PersistablePaymentMethodOptionIdentifier?)
}

public enum PersistablePaymentMethodOption: Equatable {
    case applePay
    case link
    case stripe(id: String)

    public var value: String {
        switch self {
        case .applePay:
            return "apple_pay"
        case .link:
            return "link"
        case .stripe(let id):
            return id
        }
    }

    public init(value: String) {
        switch value {
        case "apple_pay":
            self = .applePay
        case "link":
            self = .link
        default:
            self = .stripe(id: value)
        }
    }
    public init?(type: PersistablePaymentMethodOptionType, id: PersistablePaymentMethodOptionIdentifier?) {
        switch(type) {
        case .stripe:
            if let id = id {
                self = .stripe(id: id)
            } else {
                return nil
            }
        case .applePay:
            self = .applePay
        case .link:
            self = .link
        case .none:
            return nil
        }
    }
}
