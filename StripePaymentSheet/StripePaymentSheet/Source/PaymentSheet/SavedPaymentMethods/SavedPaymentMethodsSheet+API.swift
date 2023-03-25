//
//  SavedPaymentMethodsSheet+API.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension SavedPaymentMethodsSheet {
    func confirmIntent(
//        configuration: PaymentSheet.Configuration,
//        authenticationContext: STPAuthenticationContext,
        intent: Intent,
        paymentOption: PaymentOption,
//        paymentHandler: STPPaymentHandler,
        completion: @escaping (SavedPaymentMethodsSheetResult) -> Void
    ) {
//        let paymentHandler = self.paymentHandler
        // Translates a STPPaymentHandler result to a PaymentResult
        let paymentHandlerCompletion: (STPPaymentHandlerActionStatus, NSObject?, NSError?) -> Void =
            {
                (status, intent, error) in
                switch status {
                case .canceled:
                    completion(.canceled)
                case .failed:
                    // Hold a strong reference to paymentHandler
                    let unknownError = PaymentSheetError.unknown(debugDescription: "STPPaymentHandler failed without an error: \(self.paymentHandler.description)")
                    completion(.failed(error: error ?? unknownError))
                case .succeeded:
                    completion(.completed(intent))
                @unknown default:
                    // Hold a strong reference to paymentHandler
                    let unknownError = PaymentSheetError.unknown(debugDescription: "STPPaymentHandler failed without an error: \(self.paymentHandler.description)")
                    completion(.failed(error: error ?? unknownError))
                }
            }
        switch paymentOption {
            // MARK: - Apple Pay
        case .applePay:
            print("TODO")
            /*
            guard let applePayContext = STPApplePayContext.create(
                intent: intent,
                configuration: configuration,
                completion: completion
            ) else {
                let message = "Attempted Apple Pay but it's not supported by the device, not configured, or missing a presenter"
                assertionFailure(message)
                completion(.failed(error: PaymentSheetError.unknown(debugDescription: message)))
                return
            }
            applePayContext.presentApplePay()
             */
        case .new(let confirmParams):
            switch intent {
            case .paymentIntent(_):
                print("this shouldn't happen -- pI")
            case .setupIntent(let setupIntent):
                let setupIntentParams = confirmParams.makeParams(setupIntentClientSecret: setupIntent.clientSecret)
//                setupIntentParams.returnURL = configuration.returnURL
                setupIntentParams.additionalAPIParameters = ["expand" : ["payment_method"]]
                paymentHandler.confirmSetupIntent(
                    setupIntentParams,
                    with: self.bottomSheetViewController,
                    completion: paymentHandlerCompletion)
            }
        case .saved(_):
            print("do we need to re-confirm these, i hope not")
        case .link(_):
            print("nope.")
        }
    }
}
