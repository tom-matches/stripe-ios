//
//  WalletModeDelegate.swift
//  StripePaymentSheet
//

public protocol WalletModeDelegate: AnyObject {
    func didCloseWith(paymentOptionSelection: WalletMode.PaymentOptionSelection?)
    func didError(_ error: WalletModeError)
}
