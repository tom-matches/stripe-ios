//
//  WalletModeViewController.swift
//  StripePaymentSheet
//
//  Created by John Woo on 1/26/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

protocol WalletModeViewControllerDelegate: AnyObject {
}

@objc(STP_Internal_WalletModeViewController)
class WalletModeViewController: UIViewController {

    // MARK: - Read-only Properties
    let savedPaymentMethods: [STPPaymentMethod]
    let configuration: WalletModeConfiguration

    // MARK: - Writable Properties
    weak var delegate: WalletModeViewControllerDelegate?
    private(set) var isDismissable: Bool = true

    // MARK: - Views
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.delegate = self
        return navBar
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        savedPaymentMethods: [STPPaymentMethod],
        configuration: WalletModeConfiguration,
        delegate: WalletModeViewControllerDelegate
    ) {
        self.savedPaymentMethods = savedPaymentMethods
        self.configuration = configuration
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = configuration.appearance.colors.background
    }
}

extension WalletModeViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return isDismissable
    }

    func didTapOrSwipeToDismiss() {
        // TODO
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: - SheetNavigationBarDelegate
/// :nodoc:
extension WalletModeViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // TODO
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // TODO
    }
}
