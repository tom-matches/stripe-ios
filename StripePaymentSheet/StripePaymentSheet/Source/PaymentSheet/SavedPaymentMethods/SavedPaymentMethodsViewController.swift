//
//  SavedPaymentMethodsViewController.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

protocol SavedPaymentMethodsViewControllerDelegate: AnyObject {
    func savedPaymentMethodsViewControllerDidCancel(_ savedPaymentMethodsViewController: SavedPaymentMethodsViewController)
    func savedPaymentMethodsViewControllerDidFinish(_ savedPaymentMethodsViewController: SavedPaymentMethodsViewController)
}

@objc(STP_Internal_SavedPaymentMethodsViewController)
class SavedPaymentMethodsViewController: UIViewController {

    // MARK: - Read-only Properties
    let savedPaymentMethods: [STPPaymentMethod]
    let isApplePayEnabled: Bool
    let configuration: SavedPaymentMethodsSheet.Configuration

    // MARK: - Writable Properties
    weak var delegate: SavedPaymentMethodsViewControllerDelegate?
    private(set) var isDismissable: Bool = true
    enum Mode {
        case selectingSaved
        case addingNew
    }

    private var mode: Mode
    private(set) var error: Error?
    private var intent: Intent?
    private var addPaymentMethodViewController: SavedPaymentMethodsAddPaymentMethodViewController?

    var selectedPaymentOption: PaymentOption? {
        switch mode {
        case .addingNew:
            if let paymentOption = addPaymentMethodViewController?.paymentOption {
                return paymentOption
            }
            return nil
        case .selectingSaved:
            return savedPaymentOptionsViewController.selectedPaymentOption
        }
    }
    
    // MARK: - Views
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.delegate = self
        return navBar
    }()

    private lazy var savedPaymentOptionsViewController: SavedPaymentMethodsCollectionViewController = {
        let showApplePay = isApplePayEnabled
        return SavedPaymentMethodsCollectionViewController(
            savedPaymentMethods: savedPaymentMethods,
            savedPaymentMethodsConfiguration: self.configuration,
            configuration: .init(
                showApplePay: showApplePay,
                autoSelectDefaultBehavior: savedPaymentMethods.isEmpty ? .none : .onlyIfMatched
            ),
            appearance: configuration.appearance,
            delegate: self
        )
    }()
    private lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()
    private lazy var actionButton: ConfirmButton = {
        let callToAction: ConfirmButton.CallToActionType = {
            switch (mode) {
            case .selectingSaved:
//                if let confirm = configuration.primaryButtonLabel {
                    return .custom(title: STPLocalizedString(
                        "Confirm",
                        "A button used to confirm selecting a saved payment method"
                    ))
  //              }
            case .addingNew:
                return .setup
            }
        }()

//            switch intent {
//            case .paymentIntent(let paymentIntent):
//                return .pay(amount: paymentIntent.amount, currency: paymentIntent.currency)
//            case .setupIntent:
//                return .setup
//            }
//        }()

        let button = ConfirmButton(
            callToAction: callToAction,
            applePayButtonType: .plain,
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapActionButton()
            }
        )
        return button
    }()
    private lazy var headerLabel: UILabel = {
        return PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        savedPaymentMethods: [STPPaymentMethod],
        configuration: SavedPaymentMethodsSheet.Configuration,
        isApplePayEnabled: Bool,
        delegate: SavedPaymentMethodsViewControllerDelegate
    ) {
        self.savedPaymentMethods = savedPaymentMethods
        self.configuration = configuration
        self.isApplePayEnabled = isApplePayEnabled
        self.delegate = delegate
        self.mode = .selectingSaved
        self.addPaymentMethodViewController = nil
                super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = configuration.appearance.colors.background
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel,
           //walletHeader,
            paymentContainerView,
            actionButton,
            //errorLabel,
            //, bottomNoticeTextField
        ])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.bringSubviewToFront(headerLabel)
        stackView.setCustomSpacing(32, after: paymentContainerView)
        stackView.setCustomSpacing(0, after: actionButton)

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
        case .selectingSaved:
            actionButton.isHidden = true
            if let text = configuration.selectingSavedCustomHeaderText, !text.isEmpty {
                headerLabel.text = text
            } else {
                headerLabel.text = STPLocalizedString(
                    "Select your payment method",
                    "Title shown above a carousel containing the customer's payment methods")
            }
        case .addingNew:
            actionButton.isHidden = false
            headerLabel.text = STPLocalizedString(
                "Add your payment information",
                "Title shown above a form where the customer can enter payment information like credit card details, email, billing address, etc."
            )
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

    func fetchSetupIntent(clientSecret: String, completion: @escaping ((Result<STPSetupIntent, Error>) -> Void) ) {
        configuration.apiClient.retrieveSetupIntentWithPreferences(withClientSecret: clientSecret) { result in
            switch result {
            case .success(let setupIntent):
                completion(.success(setupIntent))
            case .failure(let error):
                completion(.failure(error))
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
        print("stubbed out")
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

extension SavedPaymentMethodsViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return isDismissable
    }

    func didTapOrSwipeToDismiss() {
        if isDismissable {
            if case .saved(let paymentOption) = self.savedPaymentOptionsViewController.selectedPaymentOption {
                self.configuration.delegate?.didCloseWith(paymentOptionSelection: paymentOption.toPaymentOptionSelection())
            } else {
                self.configuration.delegate?.didCloseWith(paymentOptionSelection: nil)
            }
            delegate?.savedPaymentMethodsViewControllerDidCancel(self)
        }
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: - SheetNavigationBarDelegate
/// :nodoc:
extension SavedPaymentMethodsViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        if case .saved(let paymentOption) = self.savedPaymentOptionsViewController.selectedPaymentOption {
            self.configuration.delegate?.didCloseWith(paymentOptionSelection: paymentOption.toPaymentOptionSelection())
        } else {
            self.configuration.delegate?.didCloseWith(paymentOptionSelection: nil)
        }
        delegate?.savedPaymentMethodsViewControllerDidCancel(self)

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
extension SavedPaymentMethodsViewController: SavedPaymentMethodsAddPaymentMethodViewControllerDelegate {
    func didUpdate(_ viewController: SavedPaymentMethodsAddPaymentMethodViewController) {
        //TODO
    }
//    func shouldOfferLinkSignup(_ viewController: AddPaymentMethodViewController) -> Bool {
//        return false
//    }
    func updateErrorLabel(for: Error?) {
        //TODO
    }
}

extension SavedPaymentMethodsViewController: SavedPaymentMethodsCollectionViewControllerDelegate {
    func didUpdateSelection(
        viewController: SavedPaymentMethodsCollectionViewController,
        paymentMethodSelection: SavedPaymentMethodsCollectionViewController.Selection) {
            // TODO: Add some boolean flag here to avoid making duplicate calls
            if case .add = paymentMethodSelection {
                mode = .addingNew
                error = nil  // Clear any errors
                if let intent = self.intent,
                   !intent.isInTerminalState {
                    initAddPaymentMethodViewController(intent: intent)
                    self.updateUI()
                } else {
                    if let createSetupIntentHandler = self.configuration.createSetupIntentHandler {
                        createSetupIntentHandler({ result in
                            guard let clientSecret = result else {
                                self.configuration.delegate?.didError(.setupIntentClientSecretInvalid)
                                return
                            }
                            self.fetchSetupIntent(clientSecret: clientSecret) { result in
                                switch(result) {
                                case .success(let stpSetupIntent):
                                    let setupIntent = Intent.setupIntent(stpSetupIntent)
                                    self.intent = setupIntent
                                    self.initAddPaymentMethodViewController(intent: setupIntent)

                                case .failure(let error):
                                    self.configuration.delegate?.didError(.setupIntentFetchError(error))
                                }
                                self.updateUI()
                            }
                        })
                    } else {
                        // Directly attach the PaymentMethod using the STPCustomerContext or user's API adapter.
//                        TODO: The PaymentMethod must be available for us to do this. Create a PaymentMethod and attach it here.
//                        self.configuration.customerContext.attachPaymentMethod(toCustomer: paymentMethod) { error in
//                            if let error = error {
//                                // TODO: Error for attaching payment method to customer
//                                self.configuration.delegate?.didError(.unknown(debugDescription: "Implement this"))
//                            }
//                        }
                    }
                }
            } else if case .saved(let paymentMethod) = paymentMethodSelection {
                let displayData = SavedPaymentMethodsSheet.PaymentOptionSelection.PaymentOptionDisplayData(image: paymentMethod.makeIcon(),
                                                                                             label: paymentMethod.paymentSheetLabel)
                let paymentOptionSelection = SavedPaymentMethodsSheet.PaymentOptionSelection(paymentMethodId: paymentMethod.stripeId,
                                                                               displayData: displayData)
                self.configuration.delegate?.didCloseWith(paymentOptionSelection: paymentOptionSelection)
                self.delegate?.savedPaymentMethodsViewControllerDidFinish(self)
            }
        }
    private func initAddPaymentMethodViewController(intent: Intent) {
        self.addPaymentMethodViewController = SavedPaymentMethodsAddPaymentMethodViewController(
            intent: intent,
            configuration: self.configuration,
            delegate: self
        )
    }
    func didSelectRemove(
        viewController: SavedPaymentMethodsCollectionViewController,
        paymentMethodSelection: SavedPaymentMethodsCollectionViewController.Selection) {
            //todo
        }
}


extension STPPaymentMethod {
    func toPaymentOptionSelection() -> SavedPaymentMethodsSheet.PaymentOptionSelection {
        let displayData = SavedPaymentMethodsSheet.PaymentOptionSelection.PaymentOptionDisplayData(image: self.makeIcon(),
                                                                                     label: self.paymentSheetLabel)
        return SavedPaymentMethodsSheet.PaymentOptionSelection(paymentMethodId: self.stripeId,
                                                 displayData: displayData)
    }
}
