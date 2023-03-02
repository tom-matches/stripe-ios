//
//  WalletModeDelegate.swift
//  StripePaymentSheet
//

public protocol WalletModeDelegate: AnyObject {
    func didError(_ error: WalletModeError)
    func didCancelWith(paymentOptionSelection: WalletMode.PaymentOptionSelection?)
    func didFinishWith(paymentOptionSelection: WalletMode.PaymentOptionSelection)
}
