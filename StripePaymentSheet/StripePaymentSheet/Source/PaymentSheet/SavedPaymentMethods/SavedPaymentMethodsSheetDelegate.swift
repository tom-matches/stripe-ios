//
//  SavedPaymentMethodsSheetDelegate.swift
//  StripePaymentSheet
//

public protocol SavedPaymentMethodsSheetDelegate: AnyObject {
    func didCloseWith(paymentOptionSelection: SavedPaymentMethodsSheet.PaymentOptionSelection?)
    func didError(_ error: SavedPaymentMethodsSheetError)
}
