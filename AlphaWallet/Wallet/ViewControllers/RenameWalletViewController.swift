//
//  RenameWalletViewController.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 30.03.2021.
//

import UIKit

protocol RenameWalletViewControllerDelegate: class {
    func didFinish(in viewController: RenameWalletViewController)
}

class RenameWalletViewController: UIViewController {

    private let viewModel: RenameWalletViewModel
    private var config: Config

    private lazy var nameTextField: TextField = {
        let textField = TextField()
        textField.label.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textField.autocorrectionType = .no
        textField.textField.autocapitalizationType = .none
        textField.returnKeyType = .done
        textField.isSecureTextEntry = false

        return textField
    }()
    private let buttonsBar = ButtonsBar(configuration: .green(buttons: 1))
    private var footerBottomConstraint: NSLayoutConstraint!
    private lazy var keyboardChecker = KeyboardChecker(self)
    private let roundedBackground = RoundedBackground()
    weak var delegate: RenameWalletViewControllerDelegate?

    init(viewModel: RenameWalletViewModel, config: Config) {
        self.viewModel = viewModel
        self.config = config

        super.init(nibName: nil, bundle: nil)

        let footerBar = ButtonsBarBackgroundView(buttonsBar: buttonsBar, edgeInsets: .zero, separatorHeight: 0.0)
        
        footerBottomConstraint = footerBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        footerBottomConstraint.constant = -UIApplication.shared.bottomSafeAreaHeight
        keyboardChecker.constraint = footerBottomConstraint

        let stackview = [
            nameTextField.label,
            .spacer(height: 4),
            nameTextField,
            .spacer(height: 4),
            nameTextField.statusLabel
        ].asStackView(axis: .vertical)

        stackview.translatesAutoresizingMaskIntoConstraints = false

        roundedBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundedBackground)

        roundedBackground.addSubview(stackview)
        roundedBackground.addSubview(footerBar)
        
        NSLayoutConstraint.activate([
            stackview.topAnchor.constraint(equalTo: roundedBackground.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackview.leadingAnchor.constraint(equalTo: roundedBackground.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stackview.trailingAnchor.constraint(equalTo: roundedBackground.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stackview.bottomAnchor.constraint(lessThanOrEqualTo: footerBar.topAnchor),

            footerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerBottomConstraint,
        ] + roundedBackground.createConstraintsWithContainer(view: view))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        buttonsBar.configure()
        nameTextField.configureOnce()
        buttonsBar.buttons[0].addTarget(self, action: #selector(saveWalletNameSelected), for: .touchUpInside)

        configure(viewModel: viewModel)
        fulfillTextField(account: viewModel.account)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapSelected))
        roundedBackground.addGestureRecognizer(tap)
    }

    @objc private func tapSelected(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardChecker.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardChecker.viewWillDisappear()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(viewModel: RenameWalletViewModel) {
        navigationItem.title = viewModel.title
        nameTextField.label.text = viewModel.walletNameTitle
        buttonsBar.buttons[0].setTitle(viewModel.saveWalletNameTitle, for: .normal)
    }

    @objc private func saveWalletNameSelected(_ sender: UIButton) {
        let name = nameTextField.value

        if name.isEmpty {
            config.deleteWalletName(forAccount: viewModel.account)
        } else {
            config.saveWalletName(name, forAddress: viewModel.account)
        }

        delegate?.didFinish(in: self)
    }

    private func fulfillTextField(account: AlphaWallet.Address) {
        let serverToResolveEns = RPCServer.main
        ENSReverseLookupCoordinator(server: serverToResolveEns).getENSNameFromResolver(forAddress: account) { result in
            guard let ensName = result.value else { return }
            self.nameTextField.textField.placeholder = ensName
        }

        let walletNames = config.walletNames
        nameTextField.textField.text = walletNames[account]
    }
}

extension RenameWalletViewController: TextFieldDelegate {

    func shouldReturn(in textField: TextField) -> Bool {
        view.endEditing(true)
        return true
    }

    func doneButtonTapped(for textField: TextField) {
        //no-op
    }

    func nextButtonTapped(for textField: TextField) {
        //no-op
    }
}
