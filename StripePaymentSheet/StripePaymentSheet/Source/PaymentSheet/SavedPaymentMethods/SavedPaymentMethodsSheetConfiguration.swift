//
//  SavedPaymentMethodsSheetConfiguration.swift
//  StripePaymentSheet
//

import Foundation
import UIKit
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

extension SavedPaymentMethodsSheet {

    public struct Configuration {
        public typealias CreateSetupIntentHandlerCallback = ((@escaping (String?) -> Void) -> Void)
               
        private var styleRawValue: Int = 0  // SheetStyle.automatic.rawValue
        /// The color styling to use for PaymentSheet UI
        /// Default value is SheetStyle.automatic
        /// @see SheetStyle
        @available(iOS 13.0, *)
        public var style: PaymentSheet.UserInterfaceStyle {  // stored properties can't be marked @available which is why this uses the styleRawValue private var
            get {
                return PaymentSheet.UserInterfaceStyle(rawValue: styleRawValue)!
            }
            set {
                styleRawValue = newValue.rawValue
            }
        }
        /// Describes the appearance of SavdPaymentMethodsSheet
        public var appearance = PaymentSheet.Appearance.default

        /// Configuration related to the Stripe Customer
        public var customerContext: STPBackendAPIAdapter

        /// Configuration for setting the text for the header
        public var selectingSavedCustomHeaderText: String?
        

        /// A block that provides a SetupIntent which, when confirmed, will attach a PaymentMethod to the current customer.
        /// Upon calling this, return a SetupIntent with the current customer set as the `customer`.
        /// If this is not set, the PaymentMethod will be attached directly to the customer instead.
        public var createSetupIntentHandler: CreateSetupIntentHandlerCallback?

        /// A URL that redirects back to your app that PaymentSheet can use to auto-dismiss
        /// web views used for additional authentication, e.g. 3DS2
        public var returnURL: String?
 
        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = STPAPIClient.shared

        public var applePay: ApplePayConfiguration?
        
        public init (customerContext: STPBackendAPIAdapter,
                     createSetupIntentHandler: CreateSetupIntentHandlerCallback?,
                     applePay: ApplePayConfiguration? = nil) {
            self.customerContext = customerContext
            self.createSetupIntentHandler = createSetupIntentHandler
            self.applePay = applePay
        }
    }
    /// Configuration related to Apple Pay
    public struct ApplePayConfiguration {
        /// The Apple Merchant Identifier to use during Apple Pay transactions.
        /// To obtain one, see https://stripe.com/docs/apple-pay#native
        public let merchantId: String

        /// The two-letter ISO 3166 code of the country of your business, e.g. "US"
        /// See your account's country value here https://dashboard.stripe.com/settings/account
        public let merchantCountryCode: String

        /// Initializes a ApplePayConfiguration
        public init(
            merchantId: String,
            merchantCountryCode: String
        ) {
            self.merchantId = merchantId
            self.merchantCountryCode = merchantCountryCode
        }
    }
}

extension SavedPaymentMethodsSheet {
    public enum PaymentOptionSelection {
        
        public struct PaymentOptionDisplayData {
            public let image: UIImage
            public let label: String
        }
        case applePay(paymentOptionDisplayData: PaymentOptionDisplayData)
        case saved(paymentMethod: STPPaymentMethod, paymentOptionDisplayData: PaymentOptionDisplayData)
        case new(paymentMethod: STPPaymentMethod, paymentOptionDisplayData: PaymentOptionDisplayData)

        public static func savedPaymentMethod(_ paymentMethod: STPPaymentMethod) -> PaymentOptionSelection {
            let data = PaymentOptionDisplayData(image: paymentMethod.makeIcon(), label: paymentMethod.paymentSheetLabel)
            return .saved(paymentMethod: paymentMethod, paymentOptionDisplayData: data)
        }
        public static func newPaymentMethod(_ paymentMethod: STPPaymentMethod) -> PaymentOptionSelection {
            let data = PaymentOptionDisplayData(image: paymentMethod.makeIcon(), label: paymentMethod.paymentSheetLabel)
            return .new(paymentMethod: paymentMethod, paymentOptionDisplayData: data)
        }
        public static func applePay() -> PaymentOptionSelection {
            let displayData = SavedPaymentMethodsSheet.PaymentOptionSelection.PaymentOptionDisplayData(image: Image.apple_pay_mark.makeImage().withRenderingMode(.alwaysOriginal),
                                                                                                       label: String.Localized.apple_pay)
            return .applePay(paymentOptionDisplayData: displayData)
        }
        
        public func displayData() -> PaymentOptionDisplayData {
            switch(self) {
            case .applePay(let paymentOptionDisplayData):
                return paymentOptionDisplayData
            case .saved(_, let paymentOptionDisplayData):
                return paymentOptionDisplayData
            case .new(_, let paymentOptionDisplayData):
                return paymentOptionDisplayData
            }
        }
        
        func persistablePaymentMethodOption() -> (PersistablePaymentMethodOptionType, PersistablePaymentMethodOptionIdentifier?) {
            switch(self) {
            case .applePay:
                return (.applePay, nil)
            case .saved(let paymentMethod, _):
                return (.stripe, paymentMethod.stripeId)
            case .new(let paymentMethod, _):
                return (.stripe, paymentMethod.stripeId)
            }
        }
    }
}
