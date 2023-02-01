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
    func walletModeViewControllerDidFinish(_ walletModeViewController: WalletModeViewController, result: WalletModeResult)
    func walletModeViewControllerDidCancel(_ walletModeViewController: WalletModeViewController)
}

@objc(STP_Internal_WalletModeViewController)
class WalletModeViewController: UIViewController {

    // MARK: - Read-only Properties
    let savedPaymentMethods: [STPPaymentMethod]
    let configuration: WalletMode.Configuration

    // MARK: - Writable Properties
    weak var delegate: WalletModeViewControllerDelegate?
    private(set) var isDismissable: Bool = true
    enum Mode {
        case selectingSaved
        case addingNew
    }

    private var mode: Mode
    private(set) var error: Error?
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
    private lazy var actionButton: ConfirmButton = {
//        let callToAction: ConfirmButton.CallToActionType = {
//            if let customCtaLabel = configuration.primaryButtonLabel {
//                return .customWithLock(title: customCtaLabel)
//            }
//
//            switch intent {
//            case .paymentIntent(let paymentIntent):
//                return .pay(amount: paymentIntent.amount, currency: paymentIntent.currency)
//            case .setupIntent:
//                return .setup
//            }
//        }()

        let button = ConfirmButton(
            callToAction: .setup,
            applePayButtonType: .plain,
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapActionButton()
            }
        )
        return button
    }()
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        savedPaymentMethods: [STPPaymentMethod],
        configuration: WalletMode.Configuration,
// TODO
//        isApplePayEnabled: Bool,
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
            paymentContainerView,
            actionButton
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

    // MARK: Private Methods
    private func updateUI(animated: Bool = true) {

        // Update our views (starting from the top of the screen):
        configureNavBar()

        switch(mode) {
        case .addingNew:
            actionButton.isHidden = false
        case .selectingSaved:
            actionButton.isHidden = true
        }

        guard let contentViewController = contentViewControllerFor(mode: mode) else {
            // TODO: if we return nil here, it means we didn't create a
            // view controller, and if this happens, it is most likely because didn't
            // properly create setupIntent -- how do we want to handlet his situation?
            return
        }

        switchContentIfNecessary(to: contentViewController, containerView: paymentContainerView)
    }
    private func contentViewControllerFor(mode: Mode) -> UIViewController? {
        if mode == .addingNew {
            return addPaymentMethodViewController
        }
        return savedPaymentOptionsViewController
    }

    private func configureNavBar() {
        navigationBar.setStyle(
            {
                switch mode {
                case .selectingSaved:
                    if self.savedPaymentOptionsViewController.hasRemovablePaymentMethods {
                        self.configureEditSavedPaymentMethodsButton()
                        return .close(showAdditionalButton: true)
                    } else {
                        self.navigationBar.additionalButton.removeTarget(
                            self, action: #selector(didSelectEditSavedPaymentMethodsButton),
                            for: .touchUpInside)
                        return .close(showAdditionalButton: false)
                    }
                case .addingNew:
                    self.navigationBar.additionalButton.removeTarget(
                        self, action: #selector(didSelectEditSavedPaymentMethodsButton),
                        for: .touchUpInside)
                    return savedPaymentMethods.isEmpty ? .close(showAdditionalButton: false) : .back
                }
            }())

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
    private func didTapActionButton() {
        guard mode == .addingNew,
        let newPaymentOption = addPaymentMethodViewController?.paymentOption else {
            //Button will only appear while adding a new payment method
            return
        }
        addPaymentOption(paymentOption: newPaymentOption)

    }
    private func addPaymentOption(paymentOption: PaymentOption) {
        print("todo, make calls out to sevice to actually add payment method")
    }

    // MARK: Helpers
    func configureEditSavedPaymentMethodsButton() {
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            navigationBar.additionalButton.setTitle(UIButton.doneButtonTitle, for: .normal)
            actionButton.update(state: .disabled)
        } else {
            actionButton.update(state: .enabled)
            navigationBar.additionalButton.setTitle(UIButton.editButtonTitle, for: .normal)
        }
        navigationBar.additionalButton.accessibilityIdentifier = "edit_saved_button"
        navigationBar.additionalButton.titleLabel?.adjustsFontForContentSizeCategory = true
        navigationBar.additionalButton.addTarget(
            self, action: #selector(didSelectEditSavedPaymentMethodsButton), for: .touchUpInside)
    }

    @objc
    func didSelectEditSavedPaymentMethodsButton() {
        savedPaymentOptionsViewController.isRemovingPaymentMethods.toggle()
        configureEditSavedPaymentMethodsButton()
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
        delegate?.walletModeViewControllerDidCancel(self)
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            savedPaymentOptionsViewController.isRemovingPaymentMethods = false
            configureEditSavedPaymentMethodsButton()
        }

    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        switch mode {
        case .addingNew:
            error = nil
            mode = .selectingSaved
            updateUI()
        default:
            assertionFailure()
        }
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
            // TODO: Add some boolean flag here to avoid making duplicate calls
            if case .add = paymentMethodSelection {
                mode = .addingNew
                error = nil  // Clear any errors
                if let intent = self.intent,
                   !intent.isInTerminalState {
                    // TODO: check to make sure intent isn't final
                    initAddPaymentMethodViewController(intent: intent)
                    self.updateUI()
                } else {
                    self.configuration.createSetupIntentHandler({ result in
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
                            self.intent = intent
                            self.initAddPaymentMethodViewController(intent: intent)
                            self.updateUI()
                        }
                    })
                }
            }
        }
    func didSelectRemove(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection) {
            //todo
        }
}
