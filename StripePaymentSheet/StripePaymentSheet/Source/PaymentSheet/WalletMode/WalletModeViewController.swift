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
    enum Mode {
        case selectingSaved
        case addingNew
    }
    private var mode: Mode
    private var intent: Intent?
    private var addPaymentMethodViewController: WalletModeAddPaymentMethodViewController?


    // MARK: - Views
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.delegate = self
        return navBar
    }()

    private lazy var savedPaymentOptionsViewController: SavedPaymentOptionsViewController = {
        let showApplePay = false         // TODO Plumb this through
        return SavedPaymentOptionsViewController(
            savedPaymentMethods: savedPaymentMethods,
            configuration: .init(
                customerID: configuration.customer.id,
                showApplePay: showApplePay,
                showLink: false,
                //Changed to just default first
                autoSelectDefaultBehavior: .defaultFirst
            ),
            appearance: configuration.appearance,
            delegate: self
        )
    }()
    private lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        savedPaymentMethods: [STPPaymentMethod],
        configuration: WalletModeConfiguration,
// TODO
//        isApplePayEnabled: Bool,,
        delegate: WalletModeViewControllerDelegate
    ) {
        self.savedPaymentMethods = savedPaymentMethods
        self.configuration = configuration
        self.delegate = delegate
        self.mode = .selectingSaved
        self.addPaymentMethodViewController = nil
        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = configuration.appearance.colors.background
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let stackView = UIStackView(arrangedSubviews: [
            //headerLabel,
           //walletHeader,
            paymentContainerView
            //errorLabel, buyButton, bottomNoticeTextField
        ])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.setCustomSpacing(32, after: paymentContainerView)

        paymentContainerView.directionalLayoutMargins = .insets(
            leading: -PaymentSheetUI.defaultSheetMargins.leading,
            trailing: -PaymentSheetUI.defaultSheetMargins.trailing
        )
        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])

        updateUI(animated: false)
    }

    private func updateUI(animated: Bool = true) {

//        switch mode {
//        case .addingNew:
//
//        case .selectingSaved:
//        }

        // Content
        switchContentIfNecessary(
            to: mode == .selectingSaved
                ? savedPaymentOptionsViewController : addPaymentMethodViewController!,
            containerView: paymentContainerView
        )
    }
    func initAddPaymentMethodViewController(intent: Intent) {
        self.addPaymentMethodViewController = WalletModeAddPaymentMethodViewController(
            intent: intent,
            configuration: self.configuration,
            delegate: self
        )
    }
    func fetchSetupIntent(clientSecret: String, completion: @escaping ((Intent?) -> Void) ) {
        configuration.apiClient.retrieveSetupIntentWithPreferences(withClientSecret: clientSecret) { result in
            switch result {
            case .success(let setupIntent):
                completion(.setupIntent(setupIntent))
            case .failure:
                //TODO ... update errors etc.
                completion(nil)
            }

        }
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
extension WalletModeViewController: WalletModeAddPaymentMethodViewControllerDelegate {
    func didUpdate(_ viewController: WalletModeAddPaymentMethodViewController) {
        //TODO
    }
//    func shouldOfferLinkSignup(_ viewController: AddPaymentMethodViewController) -> Bool {
//        return false
//    }
    func updateErrorLabel(for: Error?) {
        //TODO
    }
}

extension WalletModeViewController: SavedPaymentOptionsViewControllerDelegate {
    func didUpdateSelection(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection) {
            if case .add = paymentMethodSelection {
                mode = .addingNew
                // error = nil  // Clear any errors
                if let intent = self.intent {
                    // TODO: check to make sure intent isn't final
                    initAddPaymentMethodViewController(intent: intent)
                } else {
                    self.configuration.createSetupIntentHandler?({ result in
                        guard let clientSecret = result else {
                            //error -- we couldn't get a setup intent
                            return
                        }
                        self.fetchSetupIntent(clientSecret: clientSecret) { intent in
                            guard let intent = intent else {
                                // error, dude.
                                self.updateUI()
                                return
                            }
                            self.initAddPaymentMethodViewController(intent: intent)
                            self.updateUI()
                        }
                    })
                }
            }
//            updateUI()
        }
    func didSelectRemove(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection) {
            //todo
        }
}
