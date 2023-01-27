//
//  WalletModeConfiguration.swift
//  StripePaymentSheet
//
//

import Foundation

public typealias CreateSetupIntentCallback = ((@escaping (String?) -> Void) -> Void)

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

    public var customer: CustomerConfiguration
    public var createSetupIntent: CreateSetupIntentCallback?

    public init (customer: CustomerConfiguration,
                 createSetupIntent: CreateSetupIntentCallback?) {
        self.customer = customer
        self.createSetupIntent = createSetupIntent
    }        
    
}
