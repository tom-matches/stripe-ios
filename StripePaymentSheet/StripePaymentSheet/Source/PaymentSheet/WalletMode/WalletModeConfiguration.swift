//
//  WalletModeConfiguration.swift
//  StripePaymentSheet
//
//

import Foundation
import UIKit

public typealias CreateSetupIntentHandlerCallback = ((@escaping (String?) -> Void) -> Void)

public struct WalletModeConfiguration {

    /// Configuration related to the Stripe Customer
    public struct CustomerConfiguration {
        /// The identifier of the Stripe Customer object.
        /// See https://stripe.com/docs/api/customers/object#customer_object-id
        public let id: String

        /// A short-lived token that allows the SDK to access a Customer's payment methods
        public let ephemeralKeySecret: String

        /// Initializes a CustomerConfiguration
        public init(id: String, ephemeralKeySecret: String) {
            self.id = id
            self.ephemeralKeySecret = ephemeralKeySecret
        }
    }

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

    /// Describes the appearance of PaymentSheet
    public var appearance = PaymentSheet.Appearance.default

    /// Configuration related to the Stripe Customer
    public var customer: CustomerConfiguration

    /// Handler for creating a setup intent
    public var createSetupIntentHandler: CreateSetupIntentHandlerCallback?

    /// The APIClient instance used to make requests to Stripe
    public var apiClient: STPAPIClient = STPAPIClient.shared

    public init (customer: CustomerConfiguration,
                 createSetupIntentHandler: CreateSetupIntentHandlerCallback?) {
        self.customer = customer
        self.createSetupIntentHandler = createSetupIntentHandler
    }        
    
}
