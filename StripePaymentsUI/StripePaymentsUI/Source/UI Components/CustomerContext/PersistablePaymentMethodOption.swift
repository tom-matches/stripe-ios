//
//  PersistablePaymentMethodOption.swift
//  StripePaymentsUI
//

public enum PersistablePaymentMethodOptionError: Error {
    case unableToEncode(PersistablePaymentMethodOption)
    case unableToDecode(String?)
}

@objc public class PersistablePaymentMethodOption: NSObject, Codable {
    public let isApplePay: Bool
    public let isLink: Bool
    public let stripePaymentMethodId: String?
    
    public var value: String? {
        if isApplePay {
            return "apple_pay"
        } else if isLink {
            return "link"
        } else {
            return stripePaymentMethodId
        }
    }

    public static func applePay() -> PersistablePaymentMethodOption {
        return PersistablePaymentMethodOption(isApplePay: true, isLink: false, stripePaymentMethodId: nil)
    }
    public static func link() -> PersistablePaymentMethodOption {
        return PersistablePaymentMethodOption(isApplePay: false, isLink: true, stripePaymentMethodId: nil)
    }

    public static func stripePaymentMethod(_ paymentMethodId: String) -> PersistablePaymentMethodOption {
        return PersistablePaymentMethodOption(isApplePay: false, isLink: false, stripePaymentMethodId: paymentMethodId)
    }

    public init?(legacyValue: String) {
        switch legacyValue {
        case "apple_pay":
            self.isApplePay = true
            self.isLink = false
            self.stripePaymentMethodId = nil
        case "link":
            self.isApplePay = false
            self.isLink = true
            self.stripePaymentMethodId = nil
        default:
            if legacyValue.hasPrefix("pm_") {
                self.isApplePay = false
                self.isLink = false
                self.stripePaymentMethodId = legacyValue
            } else {
                 return nil
            }
        }
    }
    private init(isApplePay: Bool, isLink: Bool, stripePaymentMethodId: String?) {
        self.isApplePay = isApplePay
        self.isLink = isLink
        self.stripePaymentMethodId = stripePaymentMethodId
    }
}
