//
//  TokenInstanceActionAdapter.swift
//  AlphaWalletFoundation
//
//  Created by Vladyslav Shepitko on 01.03.2023.
//

import Foundation
import BigInt
import AlphaWalletLogger

public struct TokenInstanceActionAdapter {
    private let session: WalletSession
    private let token: Token
    private let tokenHolder: TokenHolder
    private let tokenActionsProvider: SupportedTokenActionsProvider

    public init(session: WalletSession,
                token: Token,
                tokenHolder: TokenHolder,
                tokenActionsProvider: SupportedTokenActionsProvider) {

        self.tokenActionsProvider = tokenActionsProvider
        self.session = session
        self.token = token
        self.tokenHolder = tokenHolder
    }

    public func availableActions() -> [TokenInstanceAction] {
        let xmlHandler = session.tokenAdaptor.xmlHandler(token: token)

        switch token.type {
        case .erc1155, .erc721, .erc721ForTickets, .erc875:
            let actionsFromTokenScript = xmlHandler.actions
            infoLog("[TokenScript] actions names: \(actionsFromTokenScript.map(\.type))")
            let results: [TokenInstanceAction]
            if xmlHandler.hasAssetDefinition {
                results = actionsFromTokenScript
            } else {
                switch token.type {
                case .erc1155, .erc721:
                    results = [.init(type: .nonFungibleTransfer) ]
                case .erc875, .erc721ForTickets:
                    results = [
                        .init(type: .nftSell),
                        .init(type: .nonFungibleTransfer)
                    ]
                case .nativeCryptocurrency, .erc20:
                    results = []
                }
            }

            if Features.default.isAvailable(.isNftTransferEnabled) {
                return results
            } else {
                return results.filter { $0.type != .nonFungibleTransfer }
            }
        case .erc20, .nativeCryptocurrency:
            let actionsFromTokenScript = xmlHandler.actions
            infoLog("[TokenScript] actions names: \(actionsFromTokenScript.map(\.type))")
            if actionsFromTokenScript.isEmpty {
                switch token.type {
                case .erc875, .erc721, .erc721ForTickets, .erc1155:
                    return []
                case .erc20, .nativeCryptocurrency:
                    let actions: [TokenInstanceAction] = [
                        .init(type: .erc20Send),
                        .init(type: .erc20Receive)
                    ]

                    return actions + tokenActionsProvider.actions(token: token)
                }
            } else {
                switch token.type {
                case .erc875, .erc721, .erc721ForTickets, .erc1155:
                    return []
                case .erc20:
                    return actionsFromTokenScript + tokenActionsProvider.actions(token: token)
                case .nativeCryptocurrency:
                    //TODO we should support retrieval of XML (and XMLHandler) based on address + server. For now, this is only important for native cryptocurrency. So might be ok to check like this for now
                    if let server = xmlHandler.server, server.matches(server: token.server) {
                        return actionsFromTokenScript + tokenActionsProvider.actions(token: token)
                    } else {
                        //TODO .erc20Send and .erc20Receive names aren't appropriate
                        let actions: [TokenInstanceAction] = [
                            .init(type: .erc20Send),
                            .init(type: .erc20Receive)
                        ]

                        return actions + tokenActionsProvider.actions(token: token)
                    }
                }
            }
        }
    }

    public func state(for action: TokenInstanceAction,
                      fungibleBalance: BigInt?) -> TokenInstanceActionAdapter.ActionState {

        state(
            for: action,
            selectedTokenHolders: [tokenHolder],
            fungibleBalance: fungibleBalance)
    }

    public func tokenScriptWarningMessage(for action: TokenInstanceAction,
                                          fungibleBalance: BigInt?) -> TokenInstanceActionAdapter.TokenScriptWarningMessage? {

        tokenScriptWarningMessage(
            for: action,
            selectedTokenHolders: [tokenHolder],
            fungibleBalance: fungibleBalance)
    }

    private func tokenScriptWarningMessage(for action: TokenInstanceAction,
                                           selectedTokenHolders: [TokenHolder],
                                           fungibleBalance: BigInt?) -> TokenInstanceActionAdapter.TokenScriptWarningMessage? {

        if let selection = action.activeExcludingSelection(selectedTokenHolders: [tokenHolder], forWalletAddress: session.account.address) {
            if let denialMessage = selection.denial {
                return .warning(string: denialMessage)
            } else {
                //no-op shouldn't have reached here since the button should be disabled. So just do nothing to be safe
                return .undefined
            }
        } else {
            return nil
        }
    }

    private func state(for action: TokenInstanceAction,
                       selectedTokenHolders: [TokenHolder],
                       fungibleBalance: BigInt?) -> TokenInstanceActionAdapter.ActionState {

        func _configButton(action: TokenInstanceAction) -> TokenInstanceActionAdapter.ActionState {
            if let selection = action.activeExcludingSelection(selectedTokenHolders: [tokenHolder], forWalletAddress: session.account.address, fungibleBalance: fungibleBalance) {
                if selection.denial == nil {
                    return .isDisplayed(false)
                }
            }
            return .noOption
        }

        switch session.account.type {
        case .real:
            return _configButton(action: action)
        case .watch:
            if session.config.development.shouldPretendIsRealWallet {
                return _configButton(action: action)
            } else {
                return .isEnabled(false)
            }
        }
    }
}

extension TokenInstanceActionAdapter {

    public enum TokenScriptWarningMessage {
        case warning(string: String)
        case undefined
    }

    public enum ActionState {
        case isDisplayed(Bool)
        case isEnabled(Bool)
        case noOption
    }
}
