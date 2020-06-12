// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit
import BigInt

struct FungibleTokenViewCellViewModel {
    private let shortFormatter = EtherNumberFormatter.short
    private let token: TokenObject
    private let server: RPCServer
    private let assetDefinitionStore: AssetDefinitionStore
    private let isVisible: Bool

    init(token: TokenObject, server: RPCServer, assetDefinitionStore: AssetDefinitionStore, isVisible: Bool = true) {
        self.token = token
        self.server = server
        self.assetDefinitionStore = assetDefinitionStore
        self.isVisible = isVisible
    }

    var title: String {
        return token.titleInPluralForm(withAssetDefinitionStore: assetDefinitionStore)
    }

    var amount: String {
        return shortFormatter.string(from: BigInt(token.value) ?? BigInt(), decimals: token.decimals)
    }

    var blockChainName: String {
        return server.blockChainName
    }

    var backgroundColor: UIColor {
        return Screen.TokenCard.Color.background
    }

    var contentsBackgroundColor: UIColor {
        return Screen.TokenCard.Color.background
    }

    var titleColor: UIColor {
        return Screen.TokenCard.Color.title
    }

    var subtitleColor: UIColor {
        return Screen.TokenCard.Color.subtitle
    }

    var titleFont: UIFont {
        return Screen.TokenCard.Font.title
    }

    var subtitleFont: UIFont {
        return Screen.TokenCard.Font.subtitle
    }

    var alpha: CGFloat {
        return isVisible ? 1.0 : 0.4
    }

    var iconImage: UIImage? {
        if let image = token.iconImage {
            return image
        } else {
            return UIView.tokenSymbolBackgroundImage(backgroundColor: token.symbolBackgroundColor)
        }
    }

    var symbolInIcon: String {
        guard token.iconImage == nil else { return "" }
        let i = [EthTokenViewCellViewModel.numberOfCharactersOfSymbolToShow, token.symbol.count].min()!
        return token.symbol.substring(to: i)
    }

    var symbolColor: UIColor {
        Colors.appWhite
    }

    var symbolFont: UIFont {
        UIFont.systemFont(ofSize: 13)
    }
}
