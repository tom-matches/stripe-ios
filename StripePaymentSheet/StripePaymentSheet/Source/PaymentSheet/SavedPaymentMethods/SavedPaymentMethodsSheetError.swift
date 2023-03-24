//
//  SavedPaymentMethodsSheetError.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments

public enum SavedPaymentMethodsSheetError: Error {
    
    case errorFetchingSavedPaymentMethods(Error)
    
    /// setupIntent is invalid
    case setupIntentClientSecretInvalid
    
    /// Unable to fetch setup intent using client secret
    case setupIntentFetchError(Error)

    /// Unable to create payment method
    case createPaymentMethod(Error)

    /// Unable to attach a payment method to the customer
    case attachPaymentMethod(Error)
    
    /// An unknown error.
    case unknown(debugDescription: String)
}
