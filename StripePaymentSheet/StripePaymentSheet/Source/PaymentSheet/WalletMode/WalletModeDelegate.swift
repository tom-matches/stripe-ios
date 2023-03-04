//
//  WalletModeDelegate.swift
//  StripePaymentSheet
//

public protocol WalletModeDelegate: AnyObject {
    func didError(_ error: WalletModeError)
    func didLoadWith(paymentOptionSelection: WalletMode.PaymentOptionSelection?)
    func didCancelWith(paymentOptionSelection: WalletMode.PaymentOptionSelection?)
    func didFinishWith(paymentOptionSelection: WalletMode.PaymentOptionSelection)
}
