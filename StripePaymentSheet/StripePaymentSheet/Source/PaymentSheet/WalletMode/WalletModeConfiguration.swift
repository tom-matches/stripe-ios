//
//  WalletModeConfiguration.swift
//  StripePaymentSheet
//
//

import Foundation
import UIKit
@_spi(STP) import StripePaymentsUI
extension WalletMode {

    /// An address.
    public struct Address: Equatable {
        /// City, district, suburb, town, or village.
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var city: String?

        /// Two-letter country code (ISO 3166-1 alpha-2).
        public var country: String?

        /// Address line 1 (e.g., street, PO Box, or company name).
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var line1: String?

        /// Address line 2 (e.g., apartment, suite, unit, or building).
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var line2: String?

        /// ZIP or postal code.
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var postalCode: String?

        /// State, county, province, or region.
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var state: String?

        /// Initializes an Address
        public init(city: String? = nil, country: String? = nil, line1: String? = nil, line2: String? = nil, postalCode: String? = nil, state: String? = nil) {
            self.city = city
            self.country = country
            self.line1 = line1
            self.line2 = line2
            self.postalCode = postalCode
            self.state = state
        }
    }

    /// Billing details of a customer
    public struct BillingDetails: Equatable {
        /// The customer's billing address
        public var address: Address = Address()

        /// The customer's email
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var email: String?

        /// The customer's full name
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var name: String?

        /// The customer's phone number without formatting (e.g. 5551234567)
        public var phone: String?
    }

    public struct Configuration {
        public typealias CreateSetupIntentHandlerCallback = ((@escaping (String?) -> Void) -> Void)
        
        /// A block that provides a SetupIntent which, when confirmed, will attach a PaymentMethod to the current customer.
        /// Upon calling this, return a SetupIntent with the current customer set as the `customer`.
        /// If this is not set, the PaymentMethod will be attached directly to the customer instead.
        public var createSetupIntentHandler: CreateSetupIntentHandlerCallback?
        
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

        /// A closure that returns the customer's shipping details.
        /// This is used to display a "Billing address is same as shipping" checkbox if `defaultBillingDetails` is not provided
        /// If `name` and `line1` are populated, it's also [attached to the PaymentIntent](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-shipping) during payment.
        public var shippingDetails: () -> AddressViewController.AddressDetails? = { return nil }
        
        /// Wallet Mode pre-populates fields with the values provided.
        public var defaultBillingDetails: BillingDetails = BillingDetails()

        /// Describes the appearance of WalletMode
        public var appearance = PaymentSheet.Appearance.default

        /// Configuration related to the Stripe Customer
        public var customerContext: STPBackendAPIAdapter

        /// Configuration for setting the text for the header
        public var selectingSavedCustomHeaderText: String?

        public weak var delegate: WalletModeDelegate?

        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = STPAPIClient.shared

        public init (customerContext: STPBackendAPIAdapter,
                     createSetupIntentHandler: CreateSetupIntentHandlerCallback?,
                     delegate: WalletModeDelegate? = nil) {
            self.customerContext = customerContext
            self.createSetupIntentHandler = createSetupIntentHandler
            self.delegate = delegate
        }
    }
}


extension WalletMode {
    public struct PaymentOptionSelection {

        public struct PaymentOptionDisplayData {
            public let image: UIImage
            public let label: String
        }

        public let paymentMethodId: String
        public let displayData: PaymentOptionDisplayData
    }
}
