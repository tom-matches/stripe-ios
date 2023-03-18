//
//  SavedPaymentMethodsSheetDelegate.swift
//  StripePaymentSheet
//

public protocol SavedPaymentMethodSheetDelegate: AnyObject {
    func didCloseWith(paymentOptionSelection: SavedPaymentMethodsSheet.PaymentOptionSelection?)
    func didError(_ error: SavedPaymentMethodsSheetError)
}
