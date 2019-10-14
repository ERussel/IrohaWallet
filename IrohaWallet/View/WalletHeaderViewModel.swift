/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import CommonWallet

protocol WalletHeaderViewModelProtocol: WalletViewModelProtocol {
    var title: String { get }
    var style: WalletTextStyleProtocol { get }
}

final class WalletHeaderViewModel: WalletHeaderViewModelProtocol {
    var cellReuseIdentifier: String = "co.jp.demo.header.identifier"
    var itemHeight: CGFloat = 60.0

    var title: String
    var style: WalletTextStyleProtocol

    var command: WalletCommandProtocol? { return nil }

    init(title: String, style: WalletTextStyleProtocol) {
        self.title = title
        self.style = style
    }
}
