//
//  SavedPaymentMethodsSheetConfiguration.swift
//  StripePaymentSheet
//

import Foundation
import UIKit
@_spi(STP) import StripePaymentsUI

extension SavedPaymentMethodsSheet {

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
        /// Describes the appearance of SavdPaymentMethodsSheet
        public var appearance = PaymentSheet.Appearance.default

        /// Configuration related to the Stripe Customer
        public var customerContext: STPBackendAPIAdapter

        /// Configuration for setting the text for the header
        public var selectingSavedCustomHeaderText: String?

        public weak var delegate: SavedPaymentMethodsSheetDelegate?

        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = STPAPIClient.shared

        public init (customerContext: STPBackendAPIAdapter,
                     createSetupIntentHandler: CreateSetupIntentHandlerCallback?,
                     delegate: SavedPaymentMethodsSheetDelegate? = nil) {
            self.customerContext = customerContext
            self.createSetupIntentHandler = createSetupIntentHandler
            self.delegate = delegate
        }
    }
}


extension SavedPaymentMethodsSheet {
    public struct PaymentOptionSelection {

        public struct PaymentOptionDisplayData {
            public let image: UIImage
            public let label: String
        }
        public let paymentMethodId: String
        public let displayData: PaymentOptionDisplayData
    }
}
